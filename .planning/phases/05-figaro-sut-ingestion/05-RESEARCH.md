# Phase 5: FIGARO SUT Ingestion - Research

**Researched:** 2026-04-09
**Domain:** R package importer — Eurostat FIGARO industry-by-industry flat SUT CSVs into canonical `sube_suts`
**Confidence:** HIGH (CONTEXT.md decisions verified against live FIGARO files; additional gaps surfaced)

## Summary

Phase 5 adds a `read_figaro()` importer to `R/import.R` that reads Eurostat FIGARO flat-format supply and use CSV files and emits the canonical `sube_suts` long table. CONTEXT.md locks 17 decisions (D-01..D-18) that correctly describe the transformation as a rename-and-project operation — FIGARO flat files ship pre-split dimensions (`refArea`, `counterpartArea`, `rowPi`, `colPi`), so the compound-label parsing anticipated by earlier milestone research is unnecessary.

This research run verified the locked decisions against the live files in `inst/extdata/figaro/` (~900 MB total, gitignored) and confirms all 17 decisions are sound. **Three gaps not covered by CONTEXT.md were discovered during verification and must be addressed during planning**:

1. **Primary-input rows must be filtered out.** The USE file contains non-product rows (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES`) carrying `refArea = "W2"` — these are value added, taxes, and operating surplus. They have no `CPA_` prefix on `rowPi` and must be dropped before writing the `CPA` column (the blind strip specified in D-06 would leave garbage CPA codes otherwise).
2. **Final-demand columns need aggregation before `build_matrices()`.** The USE file has five non-industry `colPi` values (`P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M`) representing household / NPISH / government consumption, GFCF, and changes in inventories. `build_matrices()` currently accepts a single `final_demand_var` string (default `"FU_bas"`) and filters `VAR == final_demand_var`. FIGARO has five final-demand categories that together play the role of WIOD's single `FU_bas` column. The simplest fix — and the one that requires **no change to `build_matrices()`** — is for `read_figaro()` to aggregate these five columns into a single synthetic `VAR = "FU_bas"` row per `(REP, PAR, CPA)` triple during import.
3. **`FIGW1` is a real trading partner code, not an aggregate** — it is the FIGARO "rest of world 1" country. It appears in both `refArea` and `counterpartArea` alongside real countries (AL..ZA). Preserve it as-is. Do not confuse it with `W2` (the primary-input aggregate that only appears in `refArea`).

The primary research recommendation is to codify the above into the planning phase: the transformation is four lines of `data.table` code (rename → filter W2 → strip CPA_ → aggregate FD), plus a year argument, directory pairing, and class tagging. Total implementation surface: one new function (~60 lines), one line in `.coerce_map()`, one new test file, one synthetic fixture directory.

**Primary recommendation:** Implement `read_figaro()` as a 4-step data.table pipeline (`fread → filter primary inputs → rename/strip CPA_ → aggregate final demand into FU_bas`). Do not modify `build_matrices()`, `compute.R`, or any downstream file.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/05-figaro-sut-ingestion/05-CONTEXT.md`:

**Format Verification**
- **D-01:** Live FIGARO flat files at `inst/extdata/figaro/` were inspected during discussion — path is `.gitignore`d and files are not committed. The research assumption of *wide CSVs with compound labels requiring `.parse_figaro_row()` / `.parse_figaro_col()` helpers* is **incorrect** for modern FIGARO releases. The parser work collapses significantly.
- **D-02:** Observed header schema (identical for supply and use, both long format, ~10M rows per file, ~400–500 MB each):
  ```
  icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue
  AL_CPA_A01,AL_A01,AL,CPA_A01,AL,A01,3547.257
  ```
  `icsupRow`/`icsupCol` (or `icuseRow`/`icuseCol` for use) are pre-joined composite keys that can be **ignored** — the split fields (`refArea`, `counterpartArea`, `rowPi`, `colPi`) already carry all the dimensional information needed.
- **D-03:** Canonical schema mapping is a direct rename + projection, no label splitting required:

  | FIGARO column       | sube_suts column |
  |---------------------|------------------|
  | `refArea`           | `REP`            |
  | `counterpartArea`   | `PAR`            |
  | `rowPi` (stripped)  | `CPA`            |
  | `colPi`             | `VAR`            |
  | `obsValue`          | `VALUE`          |
  | (from filename arg) | `YEAR`           |
  | (from filename arg) | `TYPE`           |
- **D-04:** Pitfall #1 ("FIGARO column layout does not match what `import_suts()` expects") from `.planning/research/PITFALLS.md` is largely retired by D-01/D-02. The dedicated test fixture and synthetic validation remain required, but the parsing helpers become trivial or unnecessary.

**File Layout**
- **D-05:** `read_figaro()` and its internal helpers live in `R/import.R` alongside `import_suts()`, not in a new `R/figaro.R`. Research had recommended a separate file anticipating substantial parsing helpers; since D-01 eliminates most parsing, the function is small enough to stay with its siblings. If helpers grow past ~100 lines, revisit in planning.

**CPA / VAR Code Normalization**
- **D-06:** Strip the `CPA_` prefix from `rowPi` when writing the `CPA` column so product codes (`A01`, `C10`, `G46`, ...) match the NACE-style industry codes in `colPi` / `VAR`. This keeps CPA and VAR lexically comparable and avoids forcing mapping tables to carry a `CPA_` prefix.
- **D-07:** `colPi` values pass through to `VAR` unchanged.

**Year Handling**
- **D-08:** `read_figaro()` requires an **explicit** `year =` argument. It does **not** infer year from the filename. If `year` is missing or not a four-digit integer, the function hard-errors with a clear message. This directly mitigates Pitfall #11 ("Year parsing returns `NA_integer_` silently").
- **D-09:** By convention, the year in the FIGARO filename (e.g., `2023` in `flatfile_eu-ic-supply_25ed_2023.csv`) is the **reference / data** year, not the release year. Document this in `@details` so users pass the year that appears in the filename.

**Domestic Block Semantics**
- **D-10:** `read_figaro()` returns the **full inter-country table** (`REP != PAR` rows included). This matches `import_suts()` symmetry. Callers who want the domestic block run `extract_domestic_block()` explicitly — no hidden filtering inside `read_figaro()`. This preserves FIGARO's primary value (multi-regional flows) for researchers who need it.

**Input API**
- **D-11:** `read_figaro()` accepts a **directory** path and auto-pairs one supply and one use file inside it. The expected layout is one supply file + one use file per year, matching the observed `inst/extdata/figaro/` convention. Selection rules:
  - Supply file: filename matches `-supply-` or `_supply_` (case-insensitive)
  - Use file: filename matches `-use-` or `_use_` (case-insensitive)
  - If zero or multiple candidates match either side, hard-error with the matched filenames listed
- **D-12:** `read_figaro()` does **not** accept a single file path or mixed directory contents in v1.1. This matches the one-file-per-type-per-year reality of FIGARO releases and avoids proliferating error modes. Callers with non-standard layouts can wrangle paths before calling.
- **D-13:** Proposed signature:
  ```r
  read_figaro(path, year)
  ```
  Required args only. No `sheets=`, no `recursive=`, no `type=` override. Class-tag output as `c("sube_suts", "data.table", "data.frame")` identical to `import_suts()`.

**Test Fixture**
- **D-14:** Commit a minimal synthetic fixture at `inst/extdata/figaro-sample/`:
  - `flatfile_eu-ic-supply_sample.csv`
  - `flatfile_eu-ic-use_sample.csv`
  - Content: **2 countries × 3 CPA × 3 NACE**, both SUP and USE present (~36 rows per file, ~72 rows total across both)
  - Must include both domestic (REP == PAR) and cross-country (REP != PAR) rows to exercise inter-country parsing
  - Values are synthetic (non-confidential), preserving the real column layout (`icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`)
- **D-15:** `tests/testthat/test-figaro.R` is a new test file validating:
  1. `read_figaro()` on the fixture directory returns a `sube_suts` object
  2. Output contains all seven canonical columns with correct types
  3. `CPA_` prefix is stripped from `CPA` column
  4. `REP != PAR` rows are preserved (inter-country)
  5. `extract_domestic_block()` on the result produces only `REP == PAR` rows
  6. `build_matrices()` + `compute_sube()` run end-to-end on a tiny `cpa_map` / `ind_map` derived from the fixture (integration check with FIG-03 synonym extension)

**`.coerce_map()` NACE Synonyms (FIG-03)**
- **D-16:** Extend `synonyms$vars` in `R/utils.R::.coerce_map()` to include `"NACE"` and `"NACE_R2"` so FIGARO-derived `ind_map` files with those column names route to `VAR` correctly instead of falling through to positional matching (Pitfall #4).
- **D-17:** Keep the existing synonym list intact (no breaking changes to WIOD mapping). Add a targeted unit test in `test-figaro.R` or `test-workflow.R` verifying a `NACE`-named column maps correctly.

**Performance Guardrails**
- **D-18:** No code-level guardrails (no chunked reads, no country/year pre-filters, no streaming). `data.table::fread()` handles the ~400–500 MB flat files on research hardware with acceptable memory. Document memory expectations in `@details`: "Real FIGARO flat files load ~3–5 GB peak memory during `fread`; ensure sufficient RAM before calling on full releases."

### Claude's Discretion

- Exact error message wording for missing/invalid `year`, ambiguous directory contents, and missing files
- Whether to emit a `message()` summary on successful load (row count, country count, year) — researcher ergonomics
- Whether `.parse_figaro_row()` / `.parse_figaro_col()` exist at all as internal helpers, or if the transformation is inline in `read_figaro()` (likely inline given D-01)
- pkgdown reference group placement (add to same group as `import_suts()`)
- Exact `NEWS.md` wording for the new function

### Deferred Ideas (OUT OF SCOPE)

- **Chunked / streaming reader for extreme cases** — not needed for v1.1 given current file sizes; revisit if FIGARO releases exceed ~2 GB per file
- **Country / year pre-filter arguments** (`countries =`, `years =`) — callers can subset post-import with `data.table`; not worth the API surface in v1.1
- **Support for single-file input** (`read_figaro("path/to/file.csv")`) without a paired supply/use sibling — only needed if FIGARO ever ships type-asymmetric releases
- **`type =` override argument** — not needed while filename conventions are stable
- **FIGARO SIOT (product-by-product) tables** — explicitly out of scope per `.planning/REQUIREMENTS.md` Out of Scope table
- **Auto-downloading FIGARO data from Eurostat** — explicitly out of scope per `.planning/REQUIREMENTS.md` Out of Scope table
- **Shipping real FIGARO data in the package tarball** — explicitly out of scope; `.gitignore` already excludes `inst/extdata/figaro/`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **FIG-01** | User can import FIGARO industry-by-industry SUT CSV files into a canonical `sube_suts` long table | D-01 through D-13 lock the API and transformation; the verified file schema (`refArea, rowPi, counterpartArea, colPi, obsValue`) enables a direct rename+project implementation. Primary-input filter and FD aggregation gaps identified below must be covered by the plan. |
| **FIG-02** | FIGARO importer correctly splits composite country-industry labels into REP, PAR, CPA, VAR fields | Verified: the labels are NOT composite — FIGARO flat files ship pre-split. The criterion is satisfied by preserving `refArea → REP`, `counterpartArea → PAR`, `rowPi → CPA` (with `CPA_` strip), `colPi → VAR`. `.parse_figaro_row()` / `.parse_figaro_col()` helpers from milestone research are obsolete. |
| **FIG-03** | `.coerce_map()` recognizes NACE and NACE_R2 column names for industry mapping | D-16 locks the one-line extension to `synonyms$vars` in `R/utils.R`. D-17 requires a regression test that a `NACE`-named column routes correctly through `build_matrices()`. |
| **FIG-04** | Automated tests validate FIGARO import against a synthetic FIGARO-format CSV fixture | D-14 locks the fixture layout (`inst/extdata/figaro-sample/`, 2 × 3 × 3 synthetic grid, both SUP and USE), D-15 locks the six test assertions. Fixture files must include the seven-column header verbatim and preserve FIGARO's `CPA_` prefix + at least one off-diagonal `REP != PAR` row. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No project-level `CLAUDE.md` exists in this repository (verified 2026-04-09 via `ls`). No project-specific directives apply beyond the global GSD workflow. The planning phase should honor standard R package conventions (roxygen2 markdown, testthat edition 3, `@export` for public functions, no `Imports` additions without strong justification).

**Global operational constraints relevant to this phase:**
- No `Imports` additions — `data.table::fread` already handles the job.
- Existing class-tag pattern (`c("sube_suts", "data.table", "data.frame")`) is a downstream contract — `build_matrices()` calls `.validate_class` / `.sube_required_columns` which depend on it.
- All new R files and testthat files must live under `R/` and `tests/testthat/` respectively — the fixture goes under `inst/extdata/figaro-sample/` which is NOT in `.Rbuildignore` (verified) so it will ship with the package tarball.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `data.table` | ≥ 1.15.0 (installed) | FIGARO CSV read, rename, filter, aggregation | Already in `DESCRIPTION` Imports; `fread` handles multi-GB CSVs natively; `:=` and `setnames` are the canonical rename tools; `rbindlist` merges SUP/USE tables with zero overhead [VERIFIED: installed version 1.15.0 via `packageVersion("data.table")`] |

### Supporting

No supporting libraries needed. The entire transformation uses existing imported symbols (`fread`, `rbindlist`, `setnames`, `:=`).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `data.table::fread` | `vroom::vroom` | Adds Imports dependency; not appreciably faster for this workload; rejected by D-18 + STACK.md [CITED: .planning/research/STACK.md] |
| `data.table::fread` | `readr::read_csv` | Adds tidyverse Imports; slower; STACK.md already rejected this [CITED: .planning/research/STACK.md] |
| `data.table::fread` | base `read.csv` | ~100× slower on 400 MB files; not viable [ASSUMED] |

**Installation:**

No new packages required. All work uses symbols already in `NAMESPACE` [VERIFIED: NAMESPACE lines 18-26 import `fread`, `rbindlist`, `setnames`, `:=`, `.SD`, `data.table`].

**Version verification:** `data.table` 1.15.0 is installed [VERIFIED: `Rscript -e 'packageVersion("data.table")'`]. `DESCRIPTION` declares `Imports: data.table` without a version floor [VERIFIED: DESCRIPTION line 24] — no upper-bound risk. `fread` and `:=` have been stable since data.table 1.9.4 (2014), so no version floor needs adding in Phase 5.

## Architecture Patterns

### Recommended Project Structure

```
R/
├── import.R              # [MODIFIED] add read_figaro() alongside import_suts()
├── utils.R               # [MODIFIED] add NACE, NACE_R2 to synonyms$vars in .coerce_map()
├── matrices.R            # [UNCHANGED]
├── compute.R             # [UNCHANGED]
├── ...all other R/ files # [UNCHANGED]

tests/testthat/
├── test-workflow.R       # [UNCHANGED]
└── test-figaro.R         # [NEW] six assertions from D-15

inst/extdata/
├── sample/               # [UNCHANGED] WIOD-style fixtures
└── figaro-sample/        # [NEW]
    ├── flatfile_eu-ic-supply_sample.csv
    └── flatfile_eu-ic-use_sample.csv

_pkgdown.yml              # [MODIFIED] add read_figaro to "Data import and preparation" group
NEWS.md                   # [MODIFIED] add v1.1 section documenting read_figaro
NAMESPACE                 # [AUTO-GENERATED] roxygen2 will add export(read_figaro)
DESCRIPTION               # [UNCHANGED] no new Imports
```

### Pattern 1: Stage-Gated Class Tag Contract

**What:** Every function that creates a `sube_suts` object must end with `class(out) <- c("sube_suts", class(out))` and return `out[]`. This is the contract that `build_matrices()` checks via `.sube_required_columns()` and `.validate_class` downstream.

**When to use:** At the end of `read_figaro()`, immediately before returning.

**Example** [VERIFIED: `R/import.R` line 66]:
```r
out <- rbindlist(tables, fill = TRUE)
class(out) <- c("sube_suts", class(out))
out[]
```

**Note:** Because the two FIGARO files are combined with `rbindlist` and both tables are already `data.table`s from `fread`, the underlying classes will be `c("data.table", "data.frame")` — the final tag is `c("sube_suts", "data.table", "data.frame")`, matching D-13.

### Pattern 2: Roxygen Conventions (mirror `import_suts()`)

**What:** New `read_figaro()` documentation must mirror the style of `import_suts()` in `R/import.R` lines 1-24: markdown-formatted `@description`, `@param` per argument, `@return` with explicit class string, `@export`, and a standalone `@examples` block is NOT currently used in `import.R` — so none is needed here either.

**Template** based on existing conventions [VERIFIED: `R/import.R` lines 1-24]:
```r
#' Import FIGARO Supply-Use Tables
#'
#' `read_figaro()` reads Eurostat FIGARO industry-by-industry flat-format
#' supply and use CSV files from a directory and returns the canonical
#' `sube_suts` long table.
#'
#' The function auto-pairs one supply file and one use file in `path` using
#' filename pattern matching (case-insensitive `-supply-`/`_supply_` and
#' `-use-`/`_use_`), reads both with [data.table::fread()], and emits a long
#' table with columns `REP, PAR, CPA, VAR, VALUE, YEAR, TYPE` whose `TYPE`
#' is `"SUP"` for supply rows and `"USE"` for use rows.
#'
#' @details
#' The `year` argument must match the reference year in the FIGARO filename
#' (e.g., `2023` in `flatfile_eu-ic-supply_25ed_2023.csv`). This is the data
#' year, not the release year. No year inference from the filename is
#' performed; passing an invalid or missing `year` is a hard error.
#'
#' Real FIGARO flat files load ~3-5 GB peak memory during `fread`; ensure
#' sufficient RAM before calling on full releases. The synthetic fixture
#' shipped in `inst/extdata/figaro-sample/` is tiny and suitable for tests
#' and examples.
#'
#' @param path Directory containing exactly one FIGARO supply file and one
#'   FIGARO use file.
#' @param year Four-digit integer reference year (e.g., `2023`).
#'
#' @return An object of class `c("sube_suts", "data.table", "data.frame")`.
#' @export
```

### Pattern 3: Four-Step data.table Pipeline (per file)

**What:** Transform a loaded FIGARO file (SUP or USE) into canonical form in a minimal data.table pipeline with no intermediate allocations.

**Canonical implementation sketch** (inline in `read_figaro`, not a separate helper — per D-05 and Claude's discretion note):
```r
dt <- fread(file_path)                                   # 1. Read
dt <- dt[!startsWith(refArea, "W2")]                     # 2. Filter primary-input rows (GAP #1)
# Equivalent, safer check: dt <- dt[startsWith(rowPi, "CPA_")]
setnames(dt,
  c("refArea", "counterpartArea", "colPi", "obsValue"),
  c("REP",     "PAR",             "VAR",   "VALUE"))
dt[, CPA := sub("^CPA_", "", rowPi)]                     # 3. Strip CPA_ prefix
dt[, rowPi := NULL]                                      # drop original
dt[, `:=`(YEAR = year, TYPE = type_label)]               # 4. Stamp year + TYPE
dt[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)]           # project to canonical order
```

**Before SUP/USE rbind:** If file is the USE file, aggregate the five final-demand columns into a single synthetic `VAR == "FU_bas"` row per `(REP, PAR, CPA)`. See Gap #2 below.

### Pattern 4: Existing `.sube_required_columns()` Validation Before Class Tag

Call `.sube_required_columns(out, c("REP","PAR","CPA","VAR","VALUE","YEAR","TYPE"))` immediately before the class tag — mirrors the defensive check in `import_suts()` line 43 [VERIFIED: `R/import.R`]. This catches pipeline bugs that leave a column behind and produces the same error message WIOD users would see from `import_suts()`.

### Anti-Patterns to Avoid

- **Do NOT create `R/figaro.R`.** D-05 explicitly says keep `read_figaro()` in `R/import.R`. Earlier research suggested a split anticipating complex parsing that turned out not to exist.
- **Do NOT add `.parse_figaro_row()` / `.parse_figaro_col()` helpers.** D-01/D-04 retired this direction. The transformation is a rename, not a parse.
- **Do NOT modify `build_matrices()` to add FIGARO-specific branching.** The canonical schema is the convergence point. If FD handling needs special treatment, handle it inside `read_figaro()` by emitting a synthetic `FU_bas` VAR, not by teaching `build_matrices()` about `P3_S13`/`P51G`.
- **Do NOT add `@examples` blocks that run on real FIGARO data.** Real files are 400+ MB, gitignored, and absent from CI. Any `@examples` must use `inst/extdata/figaro-sample/` via `system.file("extdata", "figaro-sample", package = "sube")` so `R CMD check --run-donttest` can execute them.
- **Do NOT `message()` unconditionally on load** — if a summary message is emitted (Claude's discretion), gate it behind `getOption("sube.verbose", FALSE)` or only print it when `interactive()` returns `TRUE` to keep tests quiet.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CSV reading | Base R `read.csv` loop | `data.table::fread()` | Already imported; ~100× faster; handles gzip; parallel decode |
| Column rename | `names(dt) <- c(...)` assignment | `setnames(dt, old, new)` | In-place, no copy; matches existing style |
| Add a column | `dt$NEW <- value` | `dt[, NEW := value]` | In-place; avoids accidental copy; matches existing style |
| Row bind SUP + USE | `rbind(sup, use)` | `rbindlist(list(sup, use), fill = TRUE)` | Already used in `import_suts()` line 65; preserves keys |
| Prefix strip | `gsub("CPA_", "", x)` | `sub("^CPA_", "", x)` | Anchored, single replacement, no risk of stripping embedded `CPA_` if any ever exists |
| File pattern match | Custom regex loop | `list.files(path, pattern = ...)` or `grepl` on basename | Standard base R; no dependency; D-11 spells out the pattern |
| Column name synonyms | Build a separate lookup | Extend existing `synonyms` list in `.coerce_map()` | D-16 is a one-line extension |
| Class contract | Custom S3 constructor | `class(out) <- c("sube_suts", class(out))` | Matches `import_suts()` line 66; no machinery needed |

**Key insight:** Almost everything Phase 5 needs already exists in the package. The planner's job is to compose, not invent. Any planning task that introduces a new helper function should be scrutinized against this table first.

## Runtime State Inventory

Not applicable. Phase 5 is a greenfield feature addition — no rename, refactor, migration, or string replacement is in scope. No stored data, live service config, OS-registered state, secrets, or build artifacts carry FIGARO-related identifiers that would need updating.

- **Stored data:** None — FIGARO data is gitignored research input, not package state.
- **Live service config:** None — sube is a standalone R package, no external services.
- **OS-registered state:** None.
- **Secrets / env vars:** None.
- **Build artifacts:** `R CMD check` produces a fresh tarball per run; no stale artifacts to invalidate. Running `devtools::document()` will regenerate `NAMESPACE` and add `export(read_figaro)` automatically — this is a one-shot action, not a migration.

## Common Pitfalls

### Pitfall 1 (GAP #1): Primary-input rows leak into the canonical CPA column

**What goes wrong:** The USE file contains rows where `rowPi` is not a product code but a primary input code (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES`) and `refArea` is `W2` (a synthetic "world" aggregate used for primary inputs). A blind `sub("^CPA_", "", rowPi)` against these rows produces garbage CPA values like `B2A3G`, `D1`. `build_matrices()` will then try to left-join `cpa_map` on those codes, fail silently, and drop them via the `!is.na(CPAagg)` filter. But the unfiltered intermediate pollutes the `sube_suts` object and will confuse users who try to inspect it.

**Why it happens:** FIGARO publishes the USE table with primary inputs appended as extra "rows" below the product block. This is a SNA 2008 / ESA 2010 convention where the lower rows of the USE table are value added / taxes. It is NOT a product. The research file sample shows six primary-input codes all carrying `refArea = "W2"`.

**Consequences:** Silent junk in `CPA` column. Possibly confusing `extract_domestic_block()` behavior when `W2 == W2` (if `counterpartArea` is also `W2`, though it never is in the observed file — needs verification in the planning task). `build_matrices()` masks the issue by dropping unmapped rows, but this means a user who runs a mapping with aggressive fuzzy-match synonyms could silently include primary-input rows as "products".

**How to avoid:** Filter before rename. Two equivalent options:
1. `dt <- dt[startsWith(rowPi, "CPA_")]` — positive filter, preserves only product rows
2. `dt <- dt[refArea != "W2"]` — drops the primary-input block

Option 1 is more defensive (it survives a hypothetical future FIGARO release that moves primary inputs out of `W2` refArea) and is the recommended approach.

**Warning signs:** `read_figaro()` output contains `CPA` values that don't start with a letter followed by a digit (NACE A64 pattern). Unit test: `all(grepl("^[A-Z][0-9]", out$CPA))` should be TRUE after import. Note: the non-industry columns `P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M` would also fail this check but they appear in `VAR`, not `CPA`, and should be aggregated to `FU_bas` per Gap #2.

**Verification evidence:**
- Live USE file has 6 distinct `rowPi` values that don't start with `CPA_`: `B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_NRES`, `OP_RES` [VERIFIED: `awk` scan of `flatfile_eu-ic-use_25ed_2023.csv` during research]
- All six are paired exclusively with `refArea = "W2"` [VERIFIED: same scan]
- Live SUPPLY file has zero non-CPA_ rowPi values — the filter is a no-op for supply, idempotent for use [VERIFIED]

### Pitfall 2 (GAP #2): Five final-demand columns have no single-column equivalent in the existing `build_matrices()` contract

**What goes wrong:** `build_matrices()` at `R/matrices.R` line 18 hard-codes `final_demand_var = "FU_bas"` (uppercased to `"FU_BAS"` at line 26) and filters `sut_data[TYPE == "USE" & VAR == final_demand_var]` at line 29. FIGARO has five final-demand columns — household consumption (`P3_S14`), NPISH (`P3_S15`), government (`P3_S13`), gross fixed capital formation (`P51G`), and changes in inventories/valuables (`P5M`). None of them is called `FU_bas` in FIGARO. If `read_figaro()` passes them through unchanged, the default `build_matrices(final_demand_var = "FU_bas")` call finds nothing and the final-demand table `fd` will be empty — `compute_sube()` then divides by an empty FD vector and produces incorrect elasticities silently.

**Why it happens:** WIOD has a single `FU_bas` column representing "final use at basic prices" already pre-aggregated across household / government / NPISH. FIGARO publishes the disaggregated categories separately. The two formats have different pre-aggregation conventions.

**Consequences:** If unaddressed, `read_figaro()` → `build_matrices()` → `compute_sube()` would produce results with zero final demand, failing D-15 test #6 (end-to-end integration). The test would reveal the bug, but the fix belongs in Phase 5, not Phase 6.

**How to avoid:** Inside `read_figaro()`, before the per-file final `rbindlist`, aggregate the five FD columns into a synthetic `VAR = "FU_bas"` row per `(REP, PAR, CPA)`. This preserves the `build_matrices()` default and keeps FIGARO output 100% compatible with WIOD output at the schema level.

**Implementation sketch:**
```r
fd_codes <- c("P3_S13", "P3_S14", "P3_S15", "P51G", "P5M")
# After rename/strip, before bind:
if (type_label == "USE") {
  fd_rows <- dt[VAR %in% fd_codes,
                .(VAR = "FU_bas",
                  VALUE = sum(VALUE, na.rm = TRUE)),
                by = .(REP, PAR, CPA, YEAR, TYPE)]
  dt <- dt[!VAR %in% fd_codes]
  dt <- rbindlist(list(dt, fd_rows), use.names = TRUE)
}
```

**Alternative considered:** Add FIGARO final-demand column list to `build_matrices()` as a new `final_demand_vars = character()` argument that takes a vector. Rejected because (a) it changes a signature in an unchanged file, (b) requires coordinated updates in `compute_sube()` which consumes `matrix_bundle$final_demand`, and (c) violates the "format adapter" anti-pattern rule — format knowledge should stay inside the import layer. The synthetic-row approach is cheaper, reversible, and fits the existing architecture [CITED: .planning/research/ARCHITECTURE.md § "Anti-Pattern: Diverging Canonical Schemas"].

**Warning signs:** After `read_figaro()`, `unique(out[TYPE == "USE"]$VAR)` should include `"FU_bas"` exactly once per `(REP, PAR, CPA)` combination. Unit test: `expect_true("FU_bas" %in% out[TYPE == "USE"]$VAR)`. Another test: `expect_true(nrow(build_matrices(out, cpa_map, ind_map)$final_demand) > 0)` after a FIGARO import against the fixture.

**Decision for planning:** This gap IS NOT covered by CONTEXT.md D-01..D-18. The planner should add a dedicated task for the FD aggregation step and the planner or discuss-phase should confirm with the user whether they want (a) aggregation to `FU_bas` (recommended), (b) a `final_demand_var` argument exposed to the caller with default `"FU_bas"`, or (c) preserving the five raw FIGARO codes and calling `build_matrices(final_demand_var = <one of them>)` explicitly.

### Pitfall 3 (GAP #3): `FIGW1` is a real country code, not an aggregate

**What goes wrong:** A naive "drop unusual country codes" filter would also drop `FIGW1` rows. `FIGW1` is the FIGARO "rest of world 1" country code — treated as a regular trading partner. It appears in both `refArea` and `counterpartArea` alongside `AL`, `AT`, ..., `ZA`. Dropping it would silently lose ~2% of the inter-country table and would make `extract_domestic_block(REP == PAR)` miss the `FIGW1-FIGW1` diagonal.

**Why it happens:** The naming pattern looks unusual (`FIG` prefix, `W` letter, `1` digit — feels like an aggregate). It is not.

**How to avoid:** Do NOT add any `refArea`/`counterpartArea` filter other than `refArea != "W2"` (and only there because W2 pairs with primary-input rowPi values — option 1 from Pitfall 1 sidesteps this entirely).

**Warning signs:** After `read_figaro()`, `unique(out$REP)` should include `FIGW1`. Unit test: `expect_true("FIGW1" %in% out$REP)` (if the synthetic fixture includes it; recommend it does not — keep the fixture minimal and use `REP1`, `REP2` as country codes).

**Verification evidence:** `FIGW1` appears in both `refArea` and `counterpartArea` columns of the live supply and use files [VERIFIED: `awk` scan].

### Pitfall 4 (pre-existing, retained): `.coerce_map()` positional fallback

**What goes wrong:** `R/utils.R` line 51-54 `.coerce_map()` uses a synonym list: `vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE")`. If a FIGARO `ind_map` has a column named `NACE` or `NACE_R2`, the `intersect()` returns empty and the code falls back to `names(data)[match(target, c(from_name, to_name))]` — positional matching. This silently uses the "first" or "second" column whichever matches the `target` position. If the caller's map has columns `(NACE, AGG)`, the fallback happens to work; if the caller has `(AGG, NACE)`, it uses the wrong column silently. Either way, it is fragile.

**Why it happens:** The synonym list was built for WIOD inputs.

**How to avoid:** D-16 extends `synonyms$vars` to `c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2")`. One-line change. D-17 adds a regression test.

**Warning signs:** `build_matrices(sut, cpa_map, figaro_ind_map)` where `figaro_ind_map` has columns `(NACE, INDAGG)` produces a matrix bundle whose `matrices` list is empty and `aggregated` has zero rows. Detection test already exists in concept in the existing `test-workflow.R` pattern — the new `test-figaro.R` should add an explicit positive test.

**Phase coverage:** Pitfall 4 from `.planning/research/PITFALLS.md` remains active. CONTEXT.md D-16/D-17 addresses it. [CITED: `.planning/research/PITFALLS.md` Pitfall 4]

### Pitfall 5 (pre-existing, retained): Year returns `NA_integer_` silently

**What goes wrong:** `.parse_year_from_name()` in `R/utils.R` line 23-36 returns `NA_integer_` when no year pattern matches. D-08 prevents this by requiring an explicit `year` argument — `read_figaro()` never calls `.parse_year_from_name()`.

**How to avoid:** Validate the `year` argument at the top of `read_figaro()`:
```r
if (missing(year) || length(year) != 1L || is.na(year) ||
    !is.numeric(year) || year != as.integer(year) ||
    year < 1900 || year > 2100) {
  stop("`year` must be a single four-digit integer (e.g., 2023).", call. = FALSE)
}
year <- as.integer(year)
```

**Phase coverage:** Pitfall 11 in `.planning/research/PITFALLS.md`. Retired by D-08. [CITED: `.planning/research/PITFALLS.md` Pitfall 11]

### Pitfall 6 (pre-existing, retained): pkgdown and NEWS gaps

**What goes wrong:** Adding a new exported function without updating `_pkgdown.yml` reference groups and `NEWS.md` causes documentation gaps.

**How to avoid:** Every plan task that adds `@export read_figaro` MUST include sibling tasks updating `_pkgdown.yml` (adding `read_figaro` to the "Data import and preparation" group at line 12) and `NEWS.md` (new `# sube 0.2.0` or `# sube 0.1.3` heading with the bullet). The `NAMESPACE` file is auto-generated by roxygen2 — do not edit it manually.

**Phase coverage:** Pitfall 12 in `.planning/research/PITFALLS.md`. [CITED: `.planning/research/PITFALLS.md` Pitfall 12]

## Code Examples

Verified patterns from the sube codebase:

### Existing importer pattern (the template to mirror)

```r
# Source: R/import.R lines 25-68 (verified 2026-04-09)
import_suts <- function(path, sheets = c("SUP", "USE"), recursive = FALSE) {
  if (!dir.exists(path) && !file.exists(path)) {
    stop("`path` does not exist.", call. = FALSE)
  }
  # ... directory + file handling ...
  tables <- lapply(files, function(file_name) {
    # ... per-file parse ...
    long[, YEAR := year]
    long[, TYPE := toupper(sheet_name)]
    long[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)]
  })
  out <- rbindlist(tables, fill = TRUE)
  class(out) <- c("sube_suts", class(out))
  out[]
}
```

### Existing domestic block filter

```r
# Source: R/import.R lines 72-78 (verified 2026-04-09)
extract_domestic_block <- function(data) {
  data <- .standardize_names(data)
  .sube_required_columns(data, c("REP", "PAR"))
  out <- data[REP == PAR]
  class(out) <- c("sube_domestic_suts", "sube_suts",
                  setdiff(class(out), c("sube_domestic_suts", "sube_suts")))
  out[]
}
```

This is the function that a caller will invoke against `read_figaro()` output per D-10.

### `.coerce_map()` extension (FIG-03)

```r
# Source: R/utils.R lines 38-60 (verified 2026-04-09)
# Current:
synonyms <- list(
  cpa = c("CPA", "CPA56", "CPA_CODE"),
  cpa_agg = c("CPAAGG", "CPA_AGG", "PRODUCT", "PRODUCT_AGG"),
  vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE"),
  ind_agg = c("INDAGG", "IND_AGG", "INDUSTRY_AGG", "SECTOR")
)

# After D-16:
synonyms <- list(
  cpa = c("CPA", "CPA56", "CPA_CODE"),
  cpa_agg = c("CPAAGG", "CPA_AGG", "PRODUCT", "PRODUCT_AGG"),
  vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2"),
  ind_agg = c("INDAGG", "IND_AGG", "INDUSTRY_AGG", "SECTOR")
)
```

Note: `.standardize_names()` uppercases column names, so a user's `ind_map` with `"NACE"`, `"nace"`, or `"Nace"` all normalize to `"NACE"` before synonym matching [VERIFIED: `R/utils.R` lines 17-21].

### Existing test file pattern (the template for `test-figaro.R`)

```r
# Source: tests/testthat/test-workflow.R lines 1-52 (verified 2026-04-09)
library(testthat)
library(sube)

test_that("example data loads and imports cleanly", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  sut <- import_suts(sut_path)

  expect_s3_class(sut, "sube_suts")
  expect_true(all(c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE") %in% names(sut)))

  domestic <- extract_domestic_block(sut)
  expect_s3_class(domestic, "sube_domestic_suts")
  expect_true(all(domestic$REP == domestic$PAR))
})
```

The new `test-figaro.R` should follow the same header (`library(testthat); library(sube)`), use `system.file("extdata", "figaro-sample", package = "sube")` to locate the fixture, and produce six `test_that()` blocks matching D-15.

### Live FIGARO file format (verification)

```
# Source: inst/extdata/figaro/flatfile_eu-ic-supply_25ed_2023.csv (verified 2026-04-09, gitignored)
icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue
AL_CPA_A01,AL_A01,AL,CPA_A01,AL,A01,3547.257
AL_CPA_A01,AL_A02,AL,CPA_A01,AL,A02,0
AL_CPA_A01,AL_A03,AL,CPA_A01,AL,A03,0
AL_CPA_A01,AL_B,AL,CPA_A01,AL,B,0
```

```
# Source: inst/extdata/figaro/flatfile_eu-ic-use_25ed_2023.csv (verified 2026-04-09, gitignored)
icuseRow,icuseCol,refArea,rowPi,counterpartArea,colPi,obsValue
AL_CPA_A01,AL_A01,AL,CPA_A01,AL,A01,880.019592
AL_CPA_A01,AL_A02,AL,CPA_A01,AL,A02,0.585999
```

Header columns differ: `icsupRow/icsupCol` in supply, `icuseRow/icuseCol` in use. The remaining five columns are identical. The planner may safely ignore the first two columns — or use them for cross-check validation (they are concatenations of `refArea + "_" + rowPi` and `counterpartArea + "_" + colPi`).

### Live FIGARO universe (dimension cardinality)

| Dimension | Count | Values |
|-----------|-------|--------|
| `refArea` (supply) | 50 | AL, AR, AT, AU, BE, BG, BR, CA, CH, CN, CY, CZ, DE, DK, EE, ES, FI, **FIGW1**, FR, GB, GR, HR, HU, ID, IE, IN, IT, JP, KR, LT, LU, LV, ME, MK, MT, MX, NL, NO, PL, PT, RO, RS, RU, SA, SE, SI, SK, TR, US, ZA |
| `refArea` (use) | 51 | 50 countries + **`W2`** (primary-input aggregate) |
| `counterpartArea` | 50 | Same as supply refArea; NEVER contains `W2` |
| `rowPi` (supply) | 64 | `CPA_A01`..`CPA_U` (NACE A64 products, all `CPA_`-prefixed) |
| `rowPi` (use) | 70 | 64 `CPA_*` products + 6 primary inputs (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_NRES`, `OP_RES`) |
| `colPi` (supply) | 64 | `A01`..`U` NACE industries |
| `colPi` (use) | 69 | 64 NACE industries + 5 final demand codes (`P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M`) |

[VERIFIED: `awk` scans of both files, 2026-04-09]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Milestone research assumed compound labels (`AT_CPA_A01` as atomic keys requiring splitting) | FIGARO flat files ship pre-split: `refArea`, `rowPi`, `counterpartArea`, `colPi` as separate columns | 2026-04-09 CONTEXT.md session (D-01) | Parser helpers collapse to rename + filter |
| Milestone research suggested separate `R/figaro.R` file | Keep in `R/import.R` | D-05 | Smaller PR, easier discovery |
| Milestone research suggested `.parse_year_from_name()` extension for FIGARO | Require explicit `year` arg | D-08 | Removes NA-year silent failure mode |
| Milestone research unclear on domestic block | Return full inter-country, caller invokes `extract_domestic_block()` | D-10 | Preserves FIGARO multi-regional value |

**Deprecated / outdated research artifacts:**
- `.planning/research/ARCHITECTURE.md` § "Feature 1: FIGARO SUT Ingestion" block describing compound-label parsing — **SUPERSEDED** by D-01/D-02/D-03. The canonical-schema convergence pattern and the class-tag contract described in the same section are still correct.
- `.planning/research/FEATURES.md` § "Structural Notes on FIGARO SUT Format" paragraph claiming "FIGARO CSVs use explicit country-product row indices" — **PARTIALLY CORRECT**: modern flat files use explicit per-dimension columns, not row indices.
- `.planning/research/STACK.md` § "FIGARO Format" table row "Dimension labeling: Row label encodes country+industry, Col=country+industry" — **INCORRECT** for modern flat format; dimensions are in separate columns.
- `.planning/research/PITFALLS.md` Pitfall 1 — **RETIRED** by D-04.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Primary-input rows in the USE file (`B2A3G`, `D1`, ...) should be filtered out rather than mapped to a VA-like VAR | Pitfall 1 / Gap #1 | If user actually wants value-added primary inputs in their VA metric, filtering loses data. Mitigation: existing `inputs` table already provides VA/EMP/CO2 separately, so this is unlikely to matter for the published pipeline. User confirmation recommended. |
| A2 | Aggregating the five FIGARO final-demand columns (`P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M`) into a single synthetic `VAR = "FU_bas"` row is acceptable | Pitfall 2 / Gap #2 | If user wants to analyze disaggregated final demand (e.g., household vs. government consumption separately), aggregation loses that ability. Mitigation: an opt-out argument `aggregate_final_demand = TRUE` could be added, or raw codes preserved with a separate `final_demand_vars` vector passed to `build_matrices()`. User confirmation strongly recommended. |
| A3 | `base R 4.2.0` (package Depends) supports `startsWith()` natively | Pattern 3 | Low — `startsWith` has been in base R since 3.3.0 (2016). Not a real risk. |
| A4 | roxygen2 7.3.2 (DESCRIPTION) correctly regenerates NAMESPACE with `export(read_figaro)` from `#' @export` | Pitfall 6 | Low — standard roxygen2 behavior, widely used. |
| A5 | The synthetic fixture (2 × 3 × 3) is large enough to exercise both SUP and USE pipelines including the final-demand aggregation AND the NACE/NACE_R2 synonym routing | Test Fixture | Medium — need to verify during planning that the fixture explicitly includes at least one `P3_S14`-style final-demand row under USE, plus at least one cross-country (`REP != PAR`) row, plus uses `NACE` (not `VAR`) as the `ind_map` column header in the test. |
| A6 | The `fread` default `integer64 = "integer64"` behavior does not affect `obsValue` which is numeric | Pattern 3 | Low — `obsValue` has decimals; `fread` will parse as `numeric`. |
| A7 | FIGARO publishes only one file pair (one SUP, one USE) per reference year | D-11 directory pairing | Low if true — matches observed convention. Risk: a future release changes the convention (e.g., split by macro-region). The hard-error-on-multiple behavior from D-11 surfaces this cleanly. |
| A8 | `W2` refArea ALWAYS pairs with non-`CPA_` rowPi (no product rows carry `refArea = "W2"`) | Pitfall 1 | Low — verified by inspection that all W2 rows have rowPi in the primary-input set (`B2A3G`, `D1`, etc.). However, inspection was partial; planning task should add a defensive test. |

## Open Questions

1. **Should `read_figaro()` expose an option to preserve disaggregated final-demand columns?**
   - What we know: `build_matrices(final_demand_var = "FU_bas")` consumes exactly one VAR value. FIGARO publishes five.
   - What's unclear: Whether researchers need the five separately or are happy with the sum.
   - Recommendation: Default to aggregation (pass-through to existing `build_matrices` defaults). Optional: add `final_demand_vars = c("P3_S13","P3_S14","P3_S15","P51G","P5M")` argument in a future version to preserve raw codes. Flag for user decision in planning.

2. **Should primary-input rows (`B2A3G`, etc.) be filtered silently or emit a diagnostic message?**
   - What we know: These rows are unambiguously out-of-scope for CPA-indexed transformations.
   - What's unclear: Whether the user wants to see a summary of how many rows were dropped.
   - Recommendation: Silent filter by default; add `message()` under `interactive() || getOption("sube.verbose", FALSE)` showing count of primary-input rows dropped, count of FD rows aggregated, and count of surviving product rows. Purely discretionary per CONTEXT.md.

3. **Should the synthetic fixture include `FIGW1` as one of the two countries to exercise the "rest of world" code?**
   - What we know: `FIGW1` is a real FIGARO country code that must not be filtered.
   - What's unclear: Whether the 2-country minimum allows room for it.
   - Recommendation: Use `REP1`, `REP2` as the two synthetic country codes for the fixture (to keep it abstract and not depend on FIGARO-specific identifiers). Add a separate minimal test block that loads a 3-country fixture or injects a row with `refArea = "FIGW1"` to confirm the importer does not filter it.

4. **Do we need a DESCRIPTION version bump as part of this phase?**
   - What we know: Current version is `0.1.2` (DESCRIPTION line 3). NEWS.md mentions the v1.1 milestone.
   - What's unclear: Whether Phase 5 alone triggers `0.2.0` or `0.1.3`, or whether the bump waits for Phase 6 completion.
   - Recommendation: Version bump is the planner's decision; SemVer minor bump (`0.2.0`) is reasonable since `read_figaro` is a new public API.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R (>= 4.2.0) | Package base | ✓ | Installed R satisfies package DESCRIPTION | — |
| `data.table` (>= 1.9.4 for `fread`, `:=`) | FIGARO file read + transform | ✓ | 1.15.0 [VERIFIED: `packageVersion`] | — |
| `testthat` (>= 3.0.0) | Test file | ✓ | In Suggests + already used | — |
| `roxygen2` (7.3.2) | Regenerate NAMESPACE | Assumed available (in Config) | — | Manual NAMESPACE edit (not recommended) |
| Live FIGARO data (`inst/extdata/figaro/`) | Manual verification only | ✓ (locally, gitignored) | 25ed 2023 release (~900 MB) | Not needed for CI — synthetic fixture suffices |
| `R CMD check` | Verification | ✓ (standard R install) | — | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

All Phase 5 work can run locally and in CI with existing tooling. No new package installation needed.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `testthat` ≥ 3.0.0 [VERIFIED: DESCRIPTION line 34] |
| Config file | None (testthat 3rd edition, opt-in via `Config/testthat/edition: 3` in DESCRIPTION) [VERIFIED: DESCRIPTION line 35] |
| Quick run command | `Rscript -e 'devtools::test(filter = "figaro")'` (runs only files matching `test-figaro*`) |
| Full suite command | `Rscript -e 'devtools::test()'` |
| R CMD check command | `R CMD build . && R CMD check sube_*.tar.gz --as-cran` or `Rscript -e 'devtools::check()'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIG-01 | `read_figaro("fixture_dir", year = 2023)` returns a `sube_suts` object | unit | `Rscript -e 'testthat::test_file("tests/testthat/test-figaro.R", filter = "returns a sube_suts")'` | ❌ Wave 0 |
| FIG-01 | Output contains all seven canonical columns with correct types (`REP`, `PAR`, `CPA`, `VAR` character; `VALUE` numeric; `YEAR` integer; `TYPE` character) | unit | same file | ❌ Wave 0 |
| FIG-01 | `TYPE` contains exactly `"SUP"` and `"USE"` | unit | same file | ❌ Wave 0 |
| FIG-01 | Missing `year` arg is a hard error with a clear message | unit | `expect_error(read_figaro(path))` | ❌ Wave 0 |
| FIG-01 | `year` that is not a 4-digit integer is a hard error | unit | `expect_error(read_figaro(path, year = "twenty-three"))` | ❌ Wave 0 |
| FIG-01 | Path to a directory containing zero supply files is a hard error | unit | `expect_error` with tempdir containing only a use file | ❌ Wave 0 |
| FIG-01 | Path to a directory containing two supply files is a hard error (ambiguity) | unit | `expect_error` with tempdir | ❌ Wave 0 |
| FIG-01 | Path does not exist → hard error | unit | `expect_error(read_figaro("/nonexistent", 2023))` mirrors `import_suts` error contract | ❌ Wave 0 |
| FIG-02 | `CPA_` prefix is stripped from `CPA` column (e.g., `CPA_A01` → `A01`) | unit | `expect_true(all(!startsWith(out$CPA, "CPA_")))` | ❌ Wave 0 |
| FIG-02 | `REP` column matches `refArea` values (preserves country codes incl. off-diagonal) | unit | `expect_true(any(out$REP != out$PAR))` after import | ❌ Wave 0 |
| FIG-02 | `PAR` column matches `counterpartArea` values | unit | `expect_setequal(unique(out$PAR), c("REP1","REP2"))` | ❌ Wave 0 |
| FIG-02 | `VAR` column matches `colPi` values unchanged (no prefix manipulation) | unit | `expect_true(all(out[TYPE=="SUP"]$VAR %in% expected_industries))` | ❌ Wave 0 |
| FIG-02 | Primary-input rows (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES` with `refArea == "W2"`) are filtered out | unit | Fixture includes ≥1 such row; `expect_false("B2A3G" %in% out$CPA)` and `expect_false("W2" %in% out$REP)` | ❌ Wave 0 |
| FIG-02 | Five final-demand columns (`P3_S13`..`P5M`) are aggregated into a single `VAR = "FU_bas"` row per (REP, PAR, CPA) | unit | `expect_true("FU_bas" %in% out[TYPE == "USE"]$VAR)`; `expect_false(any(c("P3_S13","P3_S14","P3_S15","P51G","P5M") %in% out$VAR))` | ❌ Wave 0 |
| FIG-02 | Row count sanity: for N rows in supply fixture + N rows in use fixture (minus filtered + aggregated), `nrow(out)` equals the expected preserved count | unit | Exact arithmetic based on fixture size | ❌ Wave 0 |
| FIG-03 | `.coerce_map()` routes a column named `NACE` to `VAR` | unit | `map <- data.table(NACE = c("A01","A02"), INDAGG = c("X","Y")); result <- build_matrices(sut, cpa_map, map); expect_true(length(result$matrices) > 0)` | ❌ Wave 0 |
| FIG-03 | `.coerce_map()` routes a column named `NACE_R2` to `VAR` | unit | same test pattern with `NACE_R2` column name | ❌ Wave 0 |
| FIG-03 | Existing WIOD mapping (`VAR`/`IND`/`INDUSTRY`/`CODE`) still routes correctly (no regression) | unit | Covered by existing `test-workflow.R` — re-run to verify no regression | ✅ exists |
| FIG-04 | `inst/extdata/figaro-sample/` directory exists after installation | unit | `expect_true(nzchar(system.file("extdata", "figaro-sample", package = "sube")))` | ❌ Wave 0 |
| FIG-04 | Both fixture files are present after installation | unit | `expect_true(file.exists(system.file("extdata", "figaro-sample", "flatfile_eu-ic-supply_sample.csv", package = "sube")))` | ❌ Wave 0 |
| FIG-04 | End-to-end integration: `read_figaro()` → `extract_domestic_block()` → `build_matrices()` → `compute_sube()` produces `sube_results` with non-empty `$summary` | integration | One `test_that()` block chaining all four calls with minimal `cpa_map`/`ind_map`/`inputs` data.tables constructed inline | ❌ Wave 0 |
| FIG-04 | `extract_domestic_block()` on `read_figaro()` output produces only `REP == PAR` rows | unit | `domestic <- extract_domestic_block(out); expect_true(all(domestic$REP == domestic$PAR))` | ❌ Wave 0 |
| FIG-04 | `R CMD check --as-cran` passes with no errors, warnings, or notes introduced by Phase 5 | R CMD check | `Rscript -e 'devtools::check()'` or CI `.github/workflows/R-CMD-check.yaml` | ✅ CI exists |

### Sampling Rate

- **Per task commit:** `Rscript -e 'devtools::test(filter = "figaro")'` — runs only `test-figaro.R` (fast, < 5 seconds on the synthetic fixture).
- **Per wave merge:** `Rscript -e 'devtools::test()'` — full testthat suite (all test files including `test-workflow.R` for regression coverage). Should complete in under 30 seconds.
- **Phase gate:** `Rscript -e 'devtools::check()'` (or equivalently `R CMD check --as-cran` on a built tarball) must be green with 0 errors, 0 warnings, 0 new notes before `/gsd-verify-work` runs. Pre-existing acceptable notes (if any — verify during plan_check) must be documented.

### Wave 0 Gaps

- [ ] `tests/testthat/test-figaro.R` — covers FIG-01, FIG-02, FIG-03, FIG-04 (all test behaviors listed in the Requirements → Test Map above). Must `library(testthat); library(sube)` at top, use `system.file("extdata", "figaro-sample", package = "sube")` for the fixture path, and structure tests as one `test_that()` block per behavior group (matching `test-workflow.R` style).
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — synthetic supply fixture:
  - Seven-column header: `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`
  - 2 countries (`REP1`, `REP2`) × 3 CPA (`CPA_P01`, `CPA_P02`, `CPA_P03`) × 3 NACE (`I01`, `I02`, `I03`) × 2 counterparts = 36 rows
  - Synthetic non-zero `obsValue` values that will produce a non-singular supply matrix when aggregated
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — synthetic use fixture:
  - Same seven-column header with `icuseRow`/`icuseCol`
  - 36 intermediate-use rows (same shape as supply)
  - Plus at least 5 final-demand rows (one row with `colPi = "P3_S14"` for each product) to exercise FD aggregation
  - Plus at least 1 primary-input row (e.g., `refArea = "W2"`, `rowPi = "B2A3G"`, `colPi = "I01"`) to exercise the primary-input filter
  - Total ~45 rows
- [ ] Shared fixtures / helpers for `test-figaro.R` — inline inside the test file; no `conftest`-equivalent needed in testthat
- [ ] `.coerce_map()` extension itself is not a Wave 0 test gap — it is a one-line source edit. The test that `NACE`/`NACE_R2` route correctly IS a Wave 0 gap.

**Framework install:** Not needed — `testthat` is already in `DESCRIPTION` Suggests and available in CI.

## Security Domain

### Applicable ASVS Categories

`sube` is an R data-analysis package with no authentication, no network access, no web surface, no database, no file-system write to shared locations, and no long-running processes. Threat model is limited to malicious or corrupt input CSVs and user-supplied directory paths. ASVS categories are mostly non-applicable.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No authentication surface |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | No multi-user model |
| V5 Input Validation | yes | R-level type/length/range checks on `path` and `year` arguments; `data.table::fread` tolerant of malformed CSV but `.sube_required_columns()` catches missing columns |
| V6 Cryptography | no | No crypto operations |
| V7 Error Handling and Logging | partial | Use `stop(..., call. = FALSE)` for user-facing errors (matches existing `import_suts` style); do not echo raw user path into error messages that could leak environment details |
| V8 Data Protection | no | No sensitive data in transit or at rest managed by package |
| V9 Communication | no | No network communication |
| V10 Malicious Code | no | Package code is inspected and reviewed |
| V11 Business Logic | yes (proportionate) | Reject inputs whose structure violates the FIGARO contract (missing required columns, wrong dimensionality) — already the existing `.sube_required_columns` pattern |
| V12 File and Resources | yes | Do not follow symbolic links into parent directories; `dir.exists` + `list.files` in base R are safe defaults |
| V13 API | no | No web API |
| V14 Config | no | No config storage |

### Known Threat Patterns for R data-science packages ingesting user CSVs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious CSV with 100 GB single cell causing memory exhaustion | DoS | `data.table::fread` streams; peak RAM ~5× file size; document `@details` memory expectation per D-18. Not a defendable class of attack for a research package — the user controls their input. |
| Symlink path traversal (`path = "/etc/passwd"`) | Info disclosure | `read_figaro()` only calls `fread` on CSV-suffixed files it lists from `list.files(path, pattern = "\\.csv$")`. `fread` treats the file as opaque bytes and will error on non-CSV content. The function never writes or executes. Low risk. |
| CSV injection (`=cmd` formula injection) | Tampering | `sube` never writes output with formulas; all output is character/numeric data via `data.table`. The package doesn't execute CSV cell contents. Irrelevant. |
| R code injection via column names | Tampering | Column names pass through `toupper()` via `.standardize_names()` and are never `eval()`ed. `setnames` uses them as literal strings. Low risk. |
| Directory traversal via user-supplied `path` | Info disclosure | `read_figaro(path)` requires `path` to be a directory and only reads files matching the supply/use filename pattern. Does not allow writing. If `path` points to a directory outside the user's intended scope, that's the caller's responsibility — same trust model as `import_suts`. |
| Resource exhaustion via many small files | DoS | D-11 hard-errors on >1 supply or >1 use file in the directory. Cannot accumulate. |
| Non-UTF-8 encoding causing parser crash | DoS | `fread` handles Latin-1 / UTF-8 / UTF-16 reasonably; real FIGARO files are UTF-8. If crash occurs, it's bubbled as an R error. Not exploitable. |

**Threat model conclusion:** The only hardening action Phase 5 needs is strict input validation on `year` (D-08) and clear error messages on directory pairing (D-11). Both are already locked. No additional security tasks required.

## Sources

### Primary (HIGH confidence)

- Live code inspection [VERIFIED 2026-04-09]:
  - `/home/zenz/R/sube/R/import.R` (entire file, 90 lines)
  - `/home/zenz/R/sube/R/utils.R` (entire file, 101 lines)
  - `/home/zenz/R/sube/R/matrices.R` (entire file, 96 lines)
  - `/home/zenz/R/sube/R/compute.R` (lines 1-109)
  - `/home/zenz/R/sube/tests/testthat/test-workflow.R` (entire file, 253 lines)
  - `/home/zenz/R/sube/DESCRIPTION`, `/home/zenz/R/sube/NAMESPACE`, `/home/zenz/R/sube/_pkgdown.yml`, `/home/zenz/R/sube/NEWS.md`, `/home/zenz/R/sube/.gitignore`, `/home/zenz/R/sube/.Rbuildignore`
- Live FIGARO file inspection [VERIFIED 2026-04-09]:
  - `/home/zenz/R/sube/inst/extdata/figaro/flatfile_eu-ic-supply_25ed_2023.csv` (~415 MB, 10,240,001 rows)
  - `/home/zenz/R/sube/inst/extdata/figaro/flatfile_eu-ic-use_25ed_2023.csv` (~499 MB, 11,060,701 rows)
  - `awk` scans of refArea, rowPi, counterpartArea, colPi universes
- Installed `data.table` version 1.15.0 [VERIFIED: `packageVersion("data.table")`]

### Secondary (MEDIUM confidence)

- `.planning/phases/05-figaro-sut-ingestion/05-CONTEXT.md` — user decisions (authoritative for Phase 5 scope and constraints, though decisions are themselves cited as MEDIUM confidence where they describe live-file behavior I independently verified)
- `.planning/REQUIREMENTS.md` — FIG-01..FIG-04 acceptance criteria
- `.planning/ROADMAP.md` — Phase 5 goal and success criteria
- `.planning/research/ARCHITECTURE.md` — most material retired by D-01; convergence pattern and class-tag sections still correct
- `.planning/research/FEATURES.md`, `STACK.md` — advisory, superseded in FIGARO specifics by D-01/D-02
- `.planning/research/PITFALLS.md` — Pitfalls 4, 11, 12 still active; Pitfall 1 retired

### Tertiary (LOW confidence — flagged for validation)

- FIGARO `B2A3G` / `D1` / `D21X31` / `D29X39` / `OP_RES` / `OP_NRES` SNA code interpretations (inferred from NACE / ESA 2010 conventions — training knowledge) [ASSUMED]. Not critical: we need only to filter these rows, not interpret their economic meaning.
- Exact semantic definitions of `P3_S13` (government consumption), `P3_S14` (household consumption), `P3_S15` (NPISH consumption), `P51G` (GFCF), `P5M` (changes in inventories) are ESA 2010 standard codes [ASSUMED from training]. Planning task should not depend on the semantic distinctions — only on the fact that all five belong to the "final demand" bucket.

## Metadata

**Confidence breakdown:**
- CONTEXT.md decisions: HIGH — verified against live files during this research run, no contradictions found
- Standard stack: HIGH — only uses already-imported `data.table` symbols; version verified
- Architecture: HIGH — existing patterns (class tag, roxygen, test layout) fully documented and code-verified
- Pitfalls: HIGH for new gaps (Gap #1 and Gap #2 verified via live-file inspection); HIGH for retained pitfalls (4, 11, 12 derived from existing `R/` code)
- FIGARO file format: HIGH — live inspection of both supply and use files during this session
- Validation architecture: HIGH — tests mapped 1:1 from requirements and gap findings
- ESA 2010 code semantics: LOW but non-critical — we filter and aggregate, we do not interpret

**Research date:** 2026-04-09
**Valid until:** 2026-05-09 (30 days — FIGARO release cadence is annual, not monthly; format is stable)
