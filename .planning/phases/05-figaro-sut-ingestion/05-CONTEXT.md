# Phase 5: FIGARO SUT Ingestion - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a `read_figaro()` importer that reads Eurostat FIGARO industry-by-industry
flat-format supply and use CSV files and emits the canonical `sube_suts` long
table (`REP, PAR, CPA, VAR, VALUE, YEAR, TYPE`). The existing pipeline
(`extract_domestic_block → build_matrices → compute_sube`) must run unchanged
on the output.

Scope is the flat long-format CSVs only (e.g.,
`flatfile_eu-ic-supply_25ed_2023.csv` / `flatfile_eu-ic-use_25ed_2023.csv`).
Out of scope for this phase: product-by-product SIOT tables, auto-downloading
data, shipping real FIGARO data in the tarball, and any performance
infrastructure (chunked reads, pre-filters) beyond what `data.table::fread()`
already provides.

</domain>

<decisions>
## Implementation Decisions

### Format Verification (done in-session)

- **D-01:** Live FIGARO flat files at `inst/extdata/figaro/` were inspected
  during discussion — path is `.gitignore`d and files are not committed. The
  research assumption of *wide CSVs with compound labels requiring
  `.parse_figaro_row()` / `.parse_figaro_col()` helpers* is **incorrect** for
  modern FIGARO releases. The parser work collapses significantly.
- **D-02:** Observed header schema (identical for supply and use, both long
  format, ~10M rows per file, ~400–500 MB each):
  ```
  icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue
  AL_CPA_A01,AL_A01,AL,CPA_A01,AL,A01,3547.257
  ```
  `icsupRow`/`icsupCol` (or `icuseRow`/`icuseCol` for use) are pre-joined
  composite keys that can be **ignored** — the split fields (`refArea`,
  `counterpartArea`, `rowPi`, `colPi`) already carry all the dimensional
  information needed.
- **D-03:** Canonical schema mapping is a direct rename + projection, no
  label splitting required:
  | FIGARO column       | sube_suts column |
  |---------------------|------------------|
  | `refArea`           | `REP`            |
  | `counterpartArea`   | `PAR`            |
  | `rowPi` (stripped)  | `CPA`            |
  | `colPi`             | `VAR`            |
  | `obsValue`          | `VALUE`          |
  | (from filename arg) | `YEAR`           |
  | (from filename arg) | `TYPE`           |
- **D-04:** Pitfall #1 ("FIGARO column layout does not match what
  `import_suts()` expects") from `.planning/research/PITFALLS.md` is largely
  retired by D-01/D-02. The dedicated test fixture and synthetic validation
  remain required, but the parsing helpers become trivial or unnecessary.

### File Layout

- **D-05:** `read_figaro()` and its internal helpers live in `R/import.R`
  alongside `import_suts()`, not in a new `R/figaro.R`. Research had
  recommended a separate file anticipating substantial parsing helpers; since
  D-01 eliminates most parsing, the function is small enough to stay with
  its siblings. If helpers grow past ~100 lines, revisit in planning.

### CPA / VAR Code Normalization

- **D-06:** Strip the `CPA_` prefix from `rowPi` when writing the `CPA`
  column so product codes (`A01`, `C10`, `G46`, ...) match the NACE-style
  industry codes in `colPi` / `VAR`. This keeps CPA and VAR lexically
  comparable and avoids forcing mapping tables to carry a `CPA_` prefix.
- **D-07:** `colPi` values pass through to `VAR` unchanged.

### Year Handling

- **D-08:** `read_figaro()` requires an **explicit** `year =` argument. It
  does **not** infer year from the filename. If `year` is missing or not a
  four-digit integer, the function hard-errors with a clear message. This
  directly mitigates Pitfall #11 ("Year parsing returns `NA_integer_`
  silently").
- **D-09:** By convention, the year in the FIGARO filename (e.g., `2023` in
  `flatfile_eu-ic-supply_25ed_2023.csv`) is the **reference / data** year,
  not the release year. Document this in `@details` so users pass the year
  that appears in the filename.

### Domestic Block Semantics

- **D-10:** `read_figaro()` returns the **full inter-country table**
  (`REP != PAR` rows included). This matches `import_suts()` symmetry.
  Callers who want the domestic block run `extract_domestic_block()`
  explicitly — no hidden filtering inside `read_figaro()`. This preserves
  FIGARO's primary value (multi-regional flows) for researchers who need it.

### Input API

- **D-11:** `read_figaro()` accepts a **directory** path and auto-pairs one
  supply and one use file inside it. The expected layout is one supply file
  + one use file per year, matching the observed `inst/extdata/figaro/`
  convention. Selection rules:
  - Supply file: filename matches `-supply-` or `_supply_` (case-insensitive)
  - Use file: filename matches `-use-` or `_use_` (case-insensitive)
  - If zero or multiple candidates match either side, hard-error with the
    matched filenames listed
- **D-12:** `read_figaro()` does **not** accept a single file path or mixed
  directory contents in v1.1. This matches the one-file-per-type-per-year
  reality of FIGARO releases and avoids proliferating error modes. Callers
  with non-standard layouts can wrangle paths before calling.
- **D-13:** Proposed signature:
  ```r
  read_figaro(path, year)
  ```
  Required args only. No `sheets=`, no `recursive=`, no `type=` override.
  Class-tag output as `c("sube_suts", "data.table", "data.frame")`
  identical to `import_suts()`.

### Test Fixture

- **D-14:** Commit a minimal synthetic fixture at
  `inst/extdata/figaro-sample/`:
  - `flatfile_eu-ic-supply_sample.csv`
  - `flatfile_eu-ic-use_sample.csv`
  - Content: **2 countries × 3 CPA × 3 NACE**, both SUP and USE present
    (~36 rows per file, ~72 rows total across both)
  - Must include both domestic (REP == PAR) and cross-country (REP != PAR)
    rows to exercise inter-country parsing
  - Values are synthetic (non-confidential), preserving the real column
    layout (`icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`)
- **D-15:** `tests/testthat/test-figaro.R` is a new test file validating:
  1. `read_figaro()` on the fixture directory returns a `sube_suts` object
  2. Output contains all seven canonical columns with correct types
  3. `CPA_` prefix is stripped from `CPA` column
  4. `REP != PAR` rows are preserved (inter-country)
  5. `extract_domestic_block()` on the result produces only `REP == PAR` rows
  6. `build_matrices()` + `compute_sube()` run end-to-end on a tiny
     `cpa_map` / `ind_map` derived from the fixture (integration check with
     FIG-03 synonym extension)

### `.coerce_map()` NACE Synonyms (FIG-03)

- **D-16:** Extend `synonyms$vars` in `R/utils.R::.coerce_map()` to include
  `"NACE"` and `"NACE_R2"` so FIGARO-derived `ind_map` files with those
  column names route to `VAR` correctly instead of falling through to
  positional matching (Pitfall #4).
- **D-17:** Keep the existing synonym list intact (no breaking changes to
  WIOD mapping). Add a targeted unit test in `test-figaro.R` or
  `test-workflow.R` verifying a `NACE`-named column maps correctly.

### Performance Guardrails

- **D-18:** No code-level guardrails (no chunked reads, no country/year
  pre-filters, no streaming). `data.table::fread()` handles the ~400–500 MB
  flat files on research hardware with acceptable memory. Document memory
  expectations in `@details`: "Real FIGARO flat files load ~3–5 GB peak
  memory during `fread`; ensure sufficient RAM before calling on full
  releases."

### Research-Driven Additions (2026-04-09, post-RESEARCH.md)

The gsd-phase-researcher verified D-01..D-18 against live code and the
live FIGARO flat files (inspected in session at `inst/extdata/figaro/`)
and surfaced three gaps plus one follow-up decision. The following are
locked additions with the same authority as D-01..D-18.

- **D-19: Filter primary-input rows on the USE file.** The FIGARO USE
  file contains non-product rows (`B2A3G`, `D1`, `D21X31`, `D29X39`,
  `OP_RES`, `OP_NRES`) carrying `refArea = "W2"`. These are SNA/ESA
  primary-input blocks (value added, taxes, operating surplus), not
  products. `read_figaro()` MUST drop rows where `rowPi` does not start
  with `CPA_` before applying the `CPA_` prefix strip from D-06. The
  planner should implement this defensively as
  `dt <- dt[startsWith(rowPi, "CPA_")]` rather than
  `dt <- dt[refArea != "W2"]` so it survives future FIGARO releases that
  may relocate primary inputs.

- **D-20: FIGARO final-demand columns aggregate to `VAR = "FU_bas"` by
  default, with optional `final_demand_vars=` argument.** FIGARO
  publishes five final-demand codes (`P3_S13`, `P3_S14`, `P3_S15`,
  `P51G`, `P5M`) where WIOD publishes one (`FU_bas`). Inside
  `read_figaro()`, sum these five codes per `(REP, PAR, CPA)` into a
  single synthetic row with `VAR = "FU_bas"` so `build_matrices()`
  consumes the result with its default `final_demand_var = "FU_bas"`
  filter. `build_matrices()` is NOT modified.
  - Expose an optional argument `final_demand_vars =
    c("P3_S13","P3_S14","P3_S15","P51G","P5M")` on `read_figaro()` so
    advanced users can override the aggregation set (e.g., to include
    only household consumption). Argument validates that all supplied
    codes exist in the USE file's `colPi` column and errors out with a
    clear message if any are missing.
  - Default behavior matches WIOD convention; non-default use is
    documented in `@details`.

- **D-21: `FIGW1` is a real country code — preserve as-is.** `FIGW1`
  ("FIGARO rest of world 1") appears in both `refArea` and
  `counterpartArea` of the live files alongside real countries. It MUST
  NOT be filtered. Do not add any `refArea`/`counterpartArea` filter
  beyond the D-19 primary-input filter. A regression test verifying
  `FIGW1` survives import is required.

- **D-22: Updated `read_figaro()` signature.** D-13 is superseded:
  ```r
  read_figaro(path, year, final_demand_vars = c("P3_S13","P3_S14","P3_S15","P51G","P5M"))
  ```
  `path` and `year` remain required; `final_demand_vars` is optional
  with the FIGARO default. Output class tag `c("sube_suts",
  "data.table", "data.frame")` is unchanged.

- **D-23: DESCRIPTION Version is NOT bumped in Phase 5.** Version stays
  at `0.1.2` through Phase 5 and Phase 6. Bump happens once at
  milestone v1.1 archive time (e.g., to `0.2.0` or `1.1.0`), not per
  phase. Phase 5 plans must NOT include a DESCRIPTION version-bump
  task. `NEWS.md` updates remain in scope.

### Claude's Discretion

- Exact error message wording for missing/invalid `year`, ambiguous
  directory contents, missing files, and invalid `final_demand_vars`
  entries (D-20)
- Whether to emit a `message()` summary on successful load (row count,
  country count, year, dropped-primary-inputs count) — researcher
  ergonomics
- Whether `.parse_figaro_row()` / `.parse_figaro_col()` exist at all as
  internal helpers, or if the transformation is inline in `read_figaro()`
  (inline is expected given D-01 + D-19 + D-20)
- pkgdown reference group placement (add to same group as `import_suts()`)
- Exact `NEWS.md` wording for the new function
- Whether the synthetic fixture uses `REP1`/`REP2` abstract codes or
  real country codes; researcher recommends abstract codes with a
  separate `FIGW1` regression test block

### Folded Todos

None.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — Milestone goals, constraints, v1.1 scope
- `.planning/REQUIREMENTS.md` — FIG-01 through FIG-04 acceptance criteria
- `.planning/ROADMAP.md` — Phase 5 goal and success criteria

### Research artifacts (treat as advisory after D-01 correction)
- `.planning/research/SUMMARY.md` — Overall v1.1 research executive summary
- `.planning/research/ARCHITECTURE.md` — Integration points and patterns.
  **Correction:** The compound-label splitting described for `read_figaro()`
  is obsolete (see D-01). The canonical-schema convergence pattern still
  applies.
- `.planning/research/FEATURES.md` §"Structural Notes on FIGARO SUT Format"
  — Partial; verify against D-02.
- `.planning/research/PITFALLS.md` — Pitfalls 1, 4, 7, 11, 12 apply to this
  phase. Pitfall 1 is largely retired (D-04); the others remain active.
- `.planning/research/STACK.md` — `data.table::fread` suffices, no new
  IMPORTS.

### Existing code the implementation touches or mirrors
- `R/import.R` — `import_suts()`, `extract_domestic_block()` — new function
  lives here and mirrors class-tagging pattern
- `R/utils.R` — `.coerce_map()` synonym list (D-16 extends `vars`)
- `R/matrices.R` — `build_matrices()` is the consumer of `read_figaro()`
  output; no changes expected
- `tests/testthat/test-workflow.R` — pattern for new `test-figaro.R`
- `inst/extdata/sample/` — pattern for new `inst/extdata/figaro-sample/`

### Live FIGARO data (reference, gitignored)
- `inst/extdata/figaro/flatfile_eu-ic-supply_25ed_2023.csv` —
  reference-year 2023 supply flat file (~415 MB)
- `inst/extdata/figaro/flatfile_eu-ic-use_25ed_2023.csv` —
  reference-year 2023 use flat file (~499 MB)

### Package docs to update
- `_pkgdown.yml` — add `read_figaro` to the appropriate reference group
  (Pitfall #12)
- `NEWS.md` — document the new importer under a v1.1 section
- `DESCRIPTION` — no change expected (no new IMPORTS)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.standardize_names()` (`R/utils.R`) — uppercase column names, already
  used by `import_suts()`; reuse verbatim in `read_figaro()` if post-rename
  normalization is needed
- `.sube_required_columns()` (`R/utils.R`) — validates canonical column set;
  use at the end of `read_figaro()` to assert output shape before class-tagging
- `data.table::fread()` — handles ~400 MB CSVs including gzip natively
- `class(out) <- c("sube_suts", class(out))` pattern — copy from
  `import_suts()` line 66 verbatim
- `inst/extdata/sample/` layout — mirror for `inst/extdata/figaro-sample/`

### Established Patterns
- Stage-gated S3 class tagging: every importer must produce
  `c("sube_suts", "data.table", "data.frame")` — the pipeline checks this
  class downstream
- Format adapter pattern: no format-specific logic leaks past the import
  function; `build_matrices()` and later stages are format-agnostic
- `.coerce_map()` synonym-based column routing: mapping tables can use any
  recognized synonym; the importer does not assume specific column names in
  user-provided map files
- Test fixtures live in `inst/extdata/*/` (not `tests/testthat/fixtures/`),
  loaded via `system.file(...)` for both tests and vignettes

### Integration Points
- `R/import.R` — new `read_figaro()` function co-located with `import_suts()`
- `R/utils.R` — `.coerce_map()` `synonyms$vars` list (one-line extension)
- `tests/testthat/test-figaro.R` — new test file, mirrors `test-workflow.R`
- `inst/extdata/figaro-sample/` — new directory for synthetic fixture
- `NAMESPACE` — add `export(read_figaro)` via roxygen `@export`
- `_pkgdown.yml` — reference group entry

### Non-Integration Points (locked by research + decisions)
- `R/matrices.R`, `R/compute.R`, `R/models.R`, `R/filter_plot_export.R`,
  `R/paper_tools.R` — **no changes**
- `DESCRIPTION` Imports — **no new dependencies**

</code_context>

<specifics>
## Specific Ideas

- The `CPA_` prefix on `rowPi` is the only consistent cosmetic quirk;
  stripping it at import time keeps the canonical table clean
- Symmetry with `import_suts()` is a guiding principle — same class tag,
  same return shape, no hidden filtering, same "one function, one job"
- The phase deliberately does NOT create `R/figaro.R` even though research
  proposed it — keeping the function in `R/import.R` reflects that the
  parsing work turned out much smaller than research assumed
- FIGARO inter-country flows (PAR != REP) are preserved because they are
  FIGARO's primary differentiator vs WIOD's diagonal-focused workflow; SUBE
  researchers who only need the domestic block pay the small cost of one
  extra `extract_domestic_block()` call

</specifics>

<deferred>
## Deferred Ideas

- **Chunked / streaming reader for extreme cases** — not needed for v1.1
  given current file sizes; revisit if FIGARO releases exceed ~2 GB per file
- **Country / year pre-filter arguments** (`countries =`, `years =`) —
  callers can subset post-import with `data.table`; not worth the API
  surface in v1.1
- **Support for single-file input** (`read_figaro("path/to/file.csv")`)
  without a paired supply/use sibling — only needed if FIGARO ever ships
  type-asymmetric releases
- **`type =` override argument** — not needed while filename conventions
  are stable
- **FIGARO SIOT (product-by-product) tables** — explicitly out of scope per
  `.planning/REQUIREMENTS.md` Out of Scope table
- **Auto-downloading FIGARO data from Eurostat** — explicitly out of scope
  per `.planning/REQUIREMENTS.md` Out of Scope table
- **Shipping real FIGARO data in the package tarball** — explicitly out of
  scope; `.gitignore` already excludes `inst/extdata/figaro/`

### Reviewed Todos (not folded)

None — no pending todos matched Phase 5.

</deferred>

---

*Phase: 05-figaro-sut-ingestion*
*Context gathered: 2026-04-09*
