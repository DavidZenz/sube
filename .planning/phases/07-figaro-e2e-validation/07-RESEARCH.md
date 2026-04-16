# Phase 7: FIGARO End-to-End Validation & Fallback Hardening — Research

**Researched:** 2026-04-15
**Domain:** R package testing, FIGARO SUT data schema, testthat 3 snapshot mechanics, gated-test hardening
**Confidence:** HIGH (verified against the real FIGARO 2023 flatfile on disk + the existing codebase + Eurostat/testthat docs)

## Summary

Phase 7 closes v1.2's FIGARO validation loop on three axes at once: (1) a gated real-data test exercising the full import-to-multiplier pipeline on FIGARO 2023 flatfiles, (2) an extended synthetic fixture that drives the same pipeline deterministically on every CRAN build, (3) a standalone `figaro-workflow.Rmd` vignette, plus (4) collapsing the silent-fallback contract gap that caused the v1.1 ~4.4% WIOD drift.

The key technical finding is that **FIGARO 2023 does NOT use NACE-R2 at the 3-digit level** (as stated in CONTEXT.md D-7.1). The real flatfile uses the standard Eurostat **A*64 / CPA*64 aggregation** — 64 codes that mix NACE section letters (`B`, `F`, `I`, `L`, `T`, `U`), 2-digit codes (`A01`, `C16`), and range codes (`C10T12`, `E37T39`, `M74_75`, `N80T82`, `R90T92`). The "NACE is equivalent to CPA on the 3-digit level" framing in CONTEXT.md is imprecise but the *equivalence claim itself holds*: in FIGARO 2023, CPA*64 codes are lexically identical to industry codes (stripping `CPA_`), so a single correspondence table serves as both `cpa_map` and `ind_map`. The aggregation target that cleanly groups all 64 codes and produces 21 aggregated rows with zero ambiguity is the **NACE section letter** (A-U, 21 sections in NACE Rev 2) extracted by `substr(code, 1, 1)` after stripping `CPA_`.

Two locked decisions in CONTEXT.md need planner attention because they don't match the locally-available data shape:
- **D-7.4 country codes**: FIGARO 2023 uses **2-letter ISO codes** (`DE`, `FR`, `IT`, `NL`) — not 3-letter (`DEU`/`FRA`/`ITA`/`NLD`). WIOD uses 3-letter. The planner must hardcode 2-letter codes for the FIGARO test.
- **D-7.4 year**: The locally-mounted flatfile is `*_25ed_2023.csv` covering reference year **2023**. If the test must run on year 2019, the researcher needs to download the 2019 reference-year flatfile additionally. Recommend: either switch the scope to 2023 (what's on disk, no extra data) or explicitly document that `SUBE_FIGARO_DIR` must contain a 2019-reference-year flatfile with the expected filename pattern.

**Primary recommendation:** Lock the aggregation to NACE **section letters** (21 rows), hardcode the scope to **DE/FR/IT/NL × 2023** (matching the flatfile on disk) unless the user confirms a different year is available, and use `testthat::expect_snapshot_value(style = "serialize")` for the `compute_sube()` output because the object contains numeric matrices whose `deparse()` form is both verbose and floating-point-fragile in git diffs.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-7.1 — FIGARO mapping tables leverage NACE-R2 ↔ CPA equivalence at 3-digit level**
One shared aggregation table serves as both `cpa_map` (CPA → CPAagg) and `ind_map` (VAR → INDagg) because FIGARO CPA codes and industry codes are equivalent after stripping `CPA_`. Exact aggregation target is Claude's Discretion. Bundle the mapping either in `inst/extdata/figaro/` (local-only) or as a small shipped CSV under `inst/extdata/`.

**D-7.2 — FIG-E2E-01 exercises pipeline through `compute_sube()`; `estimate_elasticities()` is opt-in**
Default gated path: `read_figaro → extract_domestic_block → build_matrices → compute_sube`. Structural invariants + golden snapshot on `compute_sube()` output. The `estimate_elasticities()` run is opt-in via a separate env-var-pointed sidecar directory (VA/EMP/CO2); opt-in path has structural invariants only, no snapshot.

**D-7.3 — Golden digest via `testthat::expect_snapshot_value()` on `compute_sube()` output**
Snapshot storage: `tests/testthat/_snaps/figaro-pipeline/`. Snapshot only deterministic fields. Structural invariants run in addition to (not replacing) the snapshot. Planner picks `style = "deparse"` vs `"serialize"` based on reviewability.

**D-7.4 — Country × year scope: DEU/FRA/ITA/NLD × 2019**
Hardcoded. No env-var override. If a country produces a singular matrix at the D-7.1 aggregation, may substitute with justification.

**D-7.5 — Extend synthetic FIGARO fixture to 8-10 CPAs × 8-10 industries × 2-3 countries**
Diagonal-dominant values, ≤50 KB total, replaces existing fixture. All 46 existing `test-figaro.R` tests must still pass — any value-baked expectations must be updated.

**D-7.6 — Standalone `vignettes/figaro-workflow.Rmd` with 9-section full worked example; `eval = FALSE`**
No Eurostat links or FIGARO citation. Register in `_pkgdown.yml` articles group. NEWS.md bullet under `# sube (development version)`.

**D-7.7 — Remove the `inst/extdata/wiod/` fallback from `resolve_wiod_root()` entirely**
`resolve_wiod_root()` reads `SUBE_WIOD_DIR` or returns `""`. Introduce `resolve_figaro_root()` with the same one-line pattern reading `SUBE_FIGARO_DIR`. Add tests asserting the no-fallback behavior. Update skip messages. Update `paper-replication.Rmd` if it mentions the fallback. NEWS.md bullet documenting the behavior change.

### Claude's Discretion

1. Exact NACE-R2 aggregation target (section-level A-U vs 2-digit vs custom) — D-7.1
2. Shape/provenance of the bundled mapping table (local-only CSV vs shipped CSV) — D-7.1
3. Which rows/columns of `compute_sube()` output to snapshot — D-7.3
4. `style = "deparse"` vs `"serialize"` — D-7.3
5. Concrete ~8-10 NACE-R2 codes for the extended synthetic fixture — D-7.5
6. Final env-var name for the D-7.2 opt-in elasticity extension
7. Whether helpers stay in `helper-replication.R` or move to `helper-gated-data.R`

### Deferred Ideas (OUT OF SCOPE)

- Auto-download helpers for FIGARO flatfiles
- Env-var-configurable country/year scope for FIGARO
- FIGARO SIOT (product-by-product) tables
- Eurostat download link and FIGARO citation in vignette
- Full `CONV-*`-wrapped FIGARO example in vignette (Phase 8)
- `model_data`-level golden snapshot (D-7.2 makes `model_data` opt-in)

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIG-E2E-01 | Gated `SUBE_FIGARO_DIR` test through full pipeline for ~4 countries × 1 year with structural invariants + golden-digest regression | See `## Validation Architecture § FIG-E2E-01` below — snapshot target identified, country/year hardcoding pattern from `test-replication.R`, skip-on-cran pattern from `helper-replication.R` |
| FIG-E2E-02 | Contract test driving synthetic fixture through `build_matrices → compute_sube → estimate_elasticities` on every CRAN build | Extended fixture design in `## Extended Synthetic Fixture Design`; existing 46-test impact in `## Existing Test Breakage Analysis`; no external data needed because the fixture is shipped |
| FIG-E2E-03 | Standalone `vignettes/figaro-workflow.Rmd` with full worked example, `eval = FALSE` | 9-section structure pattern mirrored from `paper-replication.Rmd`; pkgdown articles registration already missing for paper-replication so both need wiring |
| INFRA-02 | `resolve_wiod_root()` env-var-only contract; `resolve_figaro_root()` parallel; tests for guarded-skip; no silent fallback | See `## INFRA-02 Implementation` — one-line helper pattern, test assertion shape, skip-message updates identified |

## Standard Stack

Phase 7 uses libraries already in the `sube` dependency tree; no new `Imports` or `Suggests` additions required.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `testthat` | `>= 3.0.0` (edition 3) | Snapshot testing via `expect_snapshot_value()` | [VERIFIED: DESCRIPTION] Already a `Suggests` with edition-3 config; native snapshot support is the lock-in reason for D-7.3 |
| `data.table` | current | Fixture CSV construction, test-file data operations | [VERIFIED: codebase] All existing tests and helpers use `data.table::data.table()` / `data.table::fread()` |
| `knitr` + `rmarkdown` | current | Vignette engine for `figaro-workflow.Rmd` | [VERIFIED: DESCRIPTION] `VignetteBuilder: knitr` already set; `paper-replication.Rmd` uses `%\VignetteEngine{knitr::knitr}` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `pkgdown` | current | Register vignette in articles group | [VERIFIED: _pkgdown.yml, Suggests] Already wired; Phase 7 adds one articles entry |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `expect_snapshot_value(style = "serialize")` | `digest::digest()` + hardcoded hash string | [ASSUMED] `digest` would require adding a `Suggests` and loses testthat's `snapshot_accept()` workflow — CONTEXT.md D-7.3 explicitly rejects hand-rolled capture scripts |
| `expect_snapshot_value(..., style = "serialize")` | `style = "deparse"` | Serialize is binary (not reviewable). Deparse is reviewable R code but floating-point fragile and produces huge text for numeric matrices — researcher phase recommendation below |

**Installation:**
No new packages required. `devtools` and `testthat` are already in the developer toolchain.

**Version verification:** [VERIFIED: DESCRIPTION line 33] `testthat (>= 3.0.0)` — snapshot API is stable since 3.0.0 (released April 2020). No version bump needed.

## Architecture Patterns

### Recommended File/Directory Structure

```
tests/testthat/
├── helper-replication.R      # RENAME → helper-gated-data.R (recommended, see below)
│                             # Contains: resolve_wiod_root(), resolve_figaro_root(),
│                             #          build_replication_fixtures(),
│                             #          build_figaro_pipeline_fixture()
├── test-replication.R        # WIOD gated test (existing; skip messages updated for D-7.7)
├── test-figaro.R             # Existing 46 unit tests (may need value-assertion updates per D-7.5)
├── test-figaro-pipeline.R    # NEW — FIG-E2E-01 (gated) + FIG-E2E-02 (synthetic-fixture contract)
├── test-gated-data-contract.R  # NEW — INFRA-02 assertion: env-var-only contract, no fallback
└── _snaps/
    └── figaro-pipeline/      # NEW — autogenerated snapshots for FIG-E2E-01

inst/extdata/
├── figaro-sample/
│   ├── flatfile_eu-ic-supply_sample.csv  # REPLACED — 8-10 CPA × 8-10 ind × 3 countries
│   └── flatfile_eu-ic-use_sample.csv     # REPLACED — matching extended fixture
├── figaro/                   # .Rbuildignore + .gitignore — local-only FIGARO data + mapping CSV
│   ├── flatfile_eu-ic-supply_25ed_2023.csv  # existing
│   ├── flatfile_eu-ic-use_25ed_2023.csv     # existing
│   └── nace_section_map.csv  # NEW bundled mapping (see "Mapping Table Provenance")
└── [no shipped mapping CSV — see rationale]

vignettes/
└── figaro-workflow.Rmd       # NEW — 9-section companion to paper-replication.Rmd
```

### Pattern 1: Gated test skeleton (mirrored from `test-replication.R`)

**What:** Memoised fixture closure, `skip_on_cran()` + `skip_if_not(nzchar(root))`, loop over country/year within a single `test_that` block so snapshot capture is atomic per country-year pair.

**When to use:** Every `test_that` block in `test-figaro-pipeline.R` that depends on `SUBE_FIGARO_DIR`.

**Example (derived from `tests/testthat/test-replication.R:9-59`):**
```r
# Memoised builder — pipeline runs at most once per test-file invocation
.figaro_pipeline_bundle <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      root <- resolve_figaro_root()
      if (!nzchar(root)) return(NULL)
      cache <<- build_figaro_pipeline_fixture(root)
    }
    cache
  }
})

test_that("FIGARO pipeline completes and matches golden snapshot (FIG-E2E-01)", {
  testthat::skip_on_cran()
  root <- resolve_figaro_root()
  testthat::skip_if_not(nzchar(root),
                        "SUBE_FIGARO_DIR not set — FIGARO E2E test skipped")

  bundle <- .figaro_pipeline_bundle()
  testthat::skip_if(is.null(bundle), "FIGARO pipeline fixture build failed")

  # Structural invariants
  expect_s3_class(bundle$result, "sube_results")
  expect_gt(nrow(bundle$result$summary), 0L)
  expect_setequal(unique(bundle$result$summary$COUNTRY),
                  c("DE", "FR", "IT", "NL"))
  expect_true(all(bundle$result$diagnostics$status == "ok"))

  # Golden snapshot on the deterministic projection
  snap_target <- .snapshot_projection(bundle$result)
  testthat::expect_snapshot_value(snap_target, style = "serialize")
})
```

### Pattern 2: Snapshot projection — strip non-deterministic fields

**What:** Before snapshotting `compute_sube()` output, project to a deterministic subset. Drop the `matrices` list (contains numeric matrices A and L whose floating-point deparse is platform-fragile), and keep the three data.tables (`summary`, `tidy`, `diagnostics`).

**Why:** `compute_sube()`'s return value has the shape:
```
list(
  summary      = data.table(YEAR, COUNTRY, CPAagg, GO, VA, EMP, CO2, FD, GOe, VAe, EMPe, CO2e),
  tidy         = data.table(YEAR, COUNTRY, CPAagg, variable, value, measure, type),
  diagnostics  = data.table(country, year, status),
  matrices     = list( <country_year> = list(country, year, A = <matrix>, L = <matrix>) )
)
```
[VERIFIED: R/compute.R:129-134]. The matrices list embeds `dimnames()` and dense doubles; snapshotting with `style = "deparse"` produces tens of KB of text per matrix and triggers false diffs on sub-ulp floating-point differences between R versions and BLAS builds. Snapshotting `summary`, `tidy`, `diagnostics` (which are derived from `L` but rounded to user-visible precision) gives the needed drift signal without the false-positive noise.

**Example:**
```r
.snapshot_projection <- function(result) {
  list(
    summary_rows    = nrow(result$summary),
    summary_cols    = sort(names(result$summary)),
    summary         = result$summary[order(COUNTRY, CPAagg)],
    tidy_rows       = nrow(result$tidy),
    diagnostics     = result$diagnostics[order(country, year)]
    # matrices list intentionally excluded — see Pattern 2 rationale
  )
}
```

### Pattern 3: One-line env-var-only resolver (D-7.7)

**What:** Replace multi-branch fallback logic with a one-liner that reads an env var or returns `""`.

**When to use:** For both `resolve_wiod_root()` and the new `resolve_figaro_root()`.

**Example:**
```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}

resolve_figaro_root <- function() {
  env <- Sys.getenv("SUBE_FIGARO_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}
```
[CITED: CONTEXT.md D-7.7 code block]

### Anti-Patterns to Avoid

- **Snapshotting the full `compute_sube()` result including `$matrices`.** The `A` and `L` matrices contain floating-point numbers whose deparsed form is huge and platform-fragile. Project to the tabular output only.
- **`match.arg()` on country codes.** The gated test hardcodes `DE/FR/IT/NL` as a fixed character vector — no need for `match.arg`.
- **Regenerating snapshots on CI.** CI has no `SUBE_FIGARO_DIR`, so the test skips; snapshots are captured locally and committed. The existing pattern in `test-replication.R` already enforces this via `skip_on_cran()`.
- **Depending on `YEAR` being an integer in the flatfile.** FIGARO 2023 has NO `YEAR` column in the CSV schema [VERIFIED: file header is `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`]. Year comes from `read_figaro(..., year = 2023)` caller arg only.
- **Assuming FIGARO codes are strict 3-digit NACE.** They are the A*64 aggregation: a mix of section letters, 2-digit codes, and range codes. Do not try to parse numerics out of the code.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Golden-value assertion | Custom `.rds` dump + manual comparison | `testthat::expect_snapshot_value()` | Auto-captures on first green run, diffs on subsequent runs, `testthat::snapshot_accept()` is the audit trail. CONTEXT.md D-7.3 locks this. |
| NACE section extraction | Lookup table of 64 codes to letters | `substr(gsub("^CPA_", "", code), 1, 1)` | Every FIGARO code starts with its NACE section letter. A 21-letter result is exactly the section count. |
| Fallback-detection logic in resolvers | Multi-branch `if` with `system.file()` check | Single `Sys.getenv` + `nzchar` check | D-7.7 mandates removing the fallback. The one-liner IS the contract. |
| "Does the data exist?" probing in tests | Custom filesystem checks | `resolve_figaro_root()` + `testthat::skip_if_not(nzchar(root))` | Matches existing `test-replication.R` convention; one source of truth. |
| Diagonal-dominance proof for fixture | Analytical derivation of `rho(A) < 1` | Pick values where diagonal supply is ~10× off-diagonal | Empirically stable; proven in the existing fixture (`REP1_CPA_P01,REP1,I01,111` vs. off-diagonal `12`). Keep the same "big diagonal" shape. |

**Key insight:** All three "hand-roll" temptations here (golden-file mgmt, code-classification mapping, env-var-gated skipping) already have one-line library-supplied solutions. The only genuine design work is the snapshot *projection* (Pattern 2) because that's a domain decision, not a plumbing choice.

## Runtime State Inventory

Phase 7 has light rename/refactor content (one file rename, one helper rename). Most risk is fixture replacement (D-7.5).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Extended synthetic fixture replaces current `inst/extdata/figaro-sample/*.csv`. Current fixture is 37 supply + 69 use rows with REP1/REP2 × P01/P02/P03 × I01/I02/I03. | Rewrite the two CSVs. No external store to migrate. |
| Live service config | None. `sube` is a code package with no deployed services. | None — verified by absence of any service config in repo. |
| OS-registered state | None. No tasks, cron, launchd, systemd entries. | None — verified by `.planning/` audit scope being package-only. |
| Secrets/env vars | `SUBE_WIOD_DIR` (existing, unchanged semantics after D-7.7 per researcher env, but semantics tightened — no fallback), `SUBE_FIGARO_DIR` (new, must be documented), and one new env var for the opt-in VA/EMP/CO2 sidecar directory (see "Open Item 5" resolution below). | Add new env var name to NEWS.md and vignette section 8. |
| Build artifacts | `.Rbuildignore` already excludes `inst/extdata/figaro/` and `inst/extdata/wiod/` [VERIFIED: lines 19-22]. `.gitignore` already excludes the same [VERIFIED: lines 13-14]. | None — build ignore list is already correct. |

**Downstream file touch-points for the fixture swap:**
- `tests/testthat/test-figaro.R` lines 16, 20, 25, 88, 102, 118, 119 have value/shape-baked assertions keyed to REP1/REP2/P01/P02/P03/I01/I02/I03 and the `6 rows × sum 120` FU_bas invariant. Every one must be audited and likely rewritten against the extended fixture. See `## Existing Test Breakage Analysis` below.
- Neither `test-workflow.R` nor `test-replication.R` references the FIGARO sample fixture, so they're unaffected by the fixture swap.

## Resolved Open Items

### Open Item 1 — Exact NACE-R2 aggregation target for D-7.1

**Recommendation: NACE section letter (21 rows, A-U).**

**Justification:**
- FIGARO 2023 uses 64 codes at A*64 / CPA*64 [VERIFIED: Eurostat docs + file inspection]. All 64 codes start with a single NACE section letter [VERIFIED: `awk` inspection showed clean 21-group split: 3A + 1B + 19C + 1D + 2E + 1F + 3G + 5H + 1I + 4J + 3K + 1L + 5M + 4N + 1O + 1P + 2Q + 2R + 3S + 1T + 1U = 64].
- 21 aggregated rows is comfortably above D-7.1's "≥ 2-3 aggregated rows" threshold.
- Section-letter aggregation is the **standard Eurostat A21 aggregation** [CITED: Eurostat nama_10 documentation], the same abstraction the A*64 scheme flattens into. Researchers and economists read this as "section-level".
- Extracted in one line (`substr(code, 1, 1)`) — no lookup table needed on disk for the real data. This sidesteps Open Item 2 entirely for the real-data case.
- **2-digit rollup rejected** because FIGARO's A*64 codes are not all 2-digit: some are section-only (`B`, `F`, `I`, `L`, `T`, `U`), some are ranges spanning 2-digit boundaries (`C10T12`, `E37T39`, `N80T82`, `R90T92`). A "2-digit" rollup would need an arbitrary tie-breaking rule for the range codes. Section-letter sidesteps this.
- **Custom grouping rejected** because it adds a maintenance artifact for no payoff at Phase 7's "prove the pipeline works" scope.

**Confidence: HIGH** — verified directly against the real flatfile.

### Open Item 2 — Shape and provenance of the bundled FIGARO aggregation table

**Recommendation: No shipped CSV. Provide `build_nace_section_map()` as a local helper in `helper-gated-data.R` that derives the mapping on the fly from the unique CPA codes in the imported `sube_suts`. Optionally also ship a tiny fallback `inst/extdata/figaro/nace_section_map.csv` in the local-only dir so researchers can eyeball it.**

**Justification:**
- Section-letter extraction is a one-liner (`data.table(CPA = codes, CPAagg = substr(codes, 1, 1))`). Shipping a CSV is 64 rows of redundancy.
- Shipping nothing under `inst/extdata/` keeps the tarball slim and avoids any FIGARO/Eurostat license question on published mapping.
- For the synthetic fixture case (FIG-E2E-02), the mapping is derived the same way from the extended fixture's codes (see Open Item 4 — fixture uses real FIGARO codes).
- Researchers can regenerate or inspect it locally at any time.

**Confidence: HIGH** — derivation is deterministic; no upstream licensing dependency.

### Open Item 3 — Which rows/columns of `compute_sube()` output to snapshot

**Recommendation: Snapshot a named list with `summary` (sorted by COUNTRY, CPAagg), `tidy` row count, and `diagnostics` (sorted). Exclude `matrices` (the list containing A and L).**

**Full shape of `compute_sube()` return** [VERIFIED: R/compute.R:129-134]:
```
list(
  summary     = data.table(YEAR, COUNTRY, CPAagg, GO, VA, EMP, CO2, FD, GOe, VAe, EMPe, CO2e),
  tidy        = data.table(YEAR, COUNTRY, CPAagg, variable, value, measure, type),
  diagnostics = data.table(country, year, status),
  matrices    = list( <key> = list(country, year, A = <nxn numeric>, L = <nxn numeric>) )
)
```

**Include in snapshot:**
- `summary` — the user-visible result, contains multipliers and elasticities as numeric doubles. Sort by (COUNTRY, CPAagg) for stable ordering.
- `diagnostics` — short, catches "one country went singular" regressions.
- Row counts + sorted column names of `summary` and `tidy` — cheap structural metadata.

**Exclude from snapshot:**
- `matrices` — contains dense `A` and `L` matrices (21 × 21 = 441 doubles each × 4 country-year keys = 1,764 doubles per matrix × 2 matrices = thousands of doubles). Floating-point values at the matrix-inverse level are BLAS-sensitive and will produce false diffs. The `summary` table's GO/VA/EMP/CO2 columns are derived from `L` (via `colSums(L)`) and catch the same drift at user-visible precision. [VERIFIED: R/compute.R:93, `raw[, GO := as.numeric(colSums(L))]`]
- `tidy` full content — redundant with `summary` (it's a melted reshape of `summary`). Assert row count only.

**Non-deterministic fields to check for (none found):** No timestamps, file paths, or `Sys.time()` calls in `compute_sube()` [VERIFIED by reading R/compute.R in full]. `matrix_bundle$matrices` names are `paste(country, year, sep = "_")` → deterministic.

**Confidence: HIGH** — derived directly from source.

### Open Item 4 — Concrete NACE-R2 codes for the extended synthetic fixture

**Recommendation: Use 8 real FIGARO A*64 codes selected from across 4 NACE sections so the D-7.1 aggregation produces 4 aggregated rows (not 2-3 — 4 is more stress). Same codes for products and industries (consistent with D-7.1 equivalence).**

**Proposed codes:**

| CPA / Ind code | NACE section | FIGARO description (typical) |
|---|---|---|
| `A01` | A | Crop / animal production |
| `A03` | A | Fishing and aquaculture |
| `C10T12` | C | Food, beverages, tobacco |
| `C13T15` | C | Textiles, apparel, leather |
| `C26` | C | Computer, electronic, optical |
| `F` | F | Construction |
| `G46` | G | Wholesale trade |
| `J62_63` | J | Computer programming, info services |

This gives **4 aggregated sections** (A, C, F, G, J — wait, that's 5; see alternative below) in both CPA and industry dimensions after section-letter aggregation. [VERIFIED: codes are all present in the real FIGARO 2023 rowPi set per `/tmp/` inspection.]

**Alternative (cleaner 4-section version):** Drop `J62_63`, keep `A01`, `A03`, `C10T12`, `C13T15`, `C26`, `F`, `G46`, `G47` (8 codes, 4 sections: A, C, F, G). Planner's choice.

**Country set:** `DE`, `FR`, `IT` (3 countries — gives domestic and cross-country rows and matches a subset of the D-7.4 real-data scope).

**Synthetic value structure for diagonal dominance** (Leontief stability):
- Supply file: diagonal cell `(CPA_Xi, Xi_ind)` gets `value = 1000`, off-diagonal gets `value in {10, 20, ..., 80}` (one per position). Diagonal is ~10-100× off-diagonal → `rho(A) ≪ 1` → Leontief inversion stable.
- Use file: diagonal cell gets `value = 100`, off-diagonal cell gets `value in {1, 2, ..., 8}`. Keeps use < supply (net supply positive for diagonal).
- Final-demand rows (P3_S13, P3_S14, P3_S15, P51G, P5M): small positive values per CPA × country (e.g., 2, 3, 4, 5, 6 per FD code — reuses the existing fixture's shape).
- Preserve one `B2A3G` primary-input row (for the FIG-02/D-19 test) and one `FIGW1` row (for FIG-02/D-21).
- Preserve at least one cross-country row in supply (REP ≠ PAR) to maintain FIG-02/D-10 coverage.

**Expected file size:** 8 CPAs × 3 REPs × 8 industries × 3 PARs ≈ 576 supply rows + FD block ≈ 720 use rows. ~30 KB per CSV × 2 = ~60 KB total. **Over the ≤50 KB budget in D-7.5.**

**Recommendation to stay under budget:** Drop cross-REP supply for 1 of 3 countries (keeps `REP1 × PAR1`, `REP1 × PAR2`, `REP2 × PAR2`, `REP3 × PAR3` with one inter-country row in each direction to preserve FIG-02 coverage). Reduces rows to ~400 supply + ~500 use, file size ~40 KB total.

**Confidence: MEDIUM** — code selection is sound; exact value layout and row count to be finalized by the planner against the 50 KB budget. Mark as "planner to finalize row count; this research validates that ~8 codes at real FIGARO A*64 levels with 3 countries fits the D-7.5 shape."

### Open Item 5 — Env-var name for the opt-in elasticity extension

**Recommendation: `SUBE_FIGARO_INPUTS_DIR`.**

**Justification:**
- Follows the existing `SUBE_<scope>_DIR` convention: `SUBE_WIOD_DIR` → root; `SUBE_FIGARO_DIR` → FIGARO root; `SUBE_FIGARO_INPUTS_DIR` → FIGARO VA/EMP/CO2 sidecar dir.
- Reads as a sentence: "FIGARO inputs directory". Distinguishes from "FIGARO directory" (the SUT flatfiles) clearly.
- `_INPUTS_` echoes the `inputs` argument name in `build_matrices()` and `compute_sube()`, reinforcing that what the env var points at IS the `inputs` data [VERIFIED: R/matrices.R:32, R/compute.R:17 both use `inputs`].
- No collision with any existing env var in the codebase [VERIFIED by grep across R/ and tests/].

**Alternatives considered:** `SUBE_FIGARO_SIDECAR_DIR` (less obvious), `SUBE_FIGARO_VA_DIR` (too specific — it's VA + EMP + CO2).

**Confidence: HIGH** — naming convention is consistent; no collision.

### Open Item 6 — File location for `resolve_wiod_root()` + `resolve_figaro_root()`

**Recommendation: Rename `helper-replication.R` → `helper-gated-data.R`.**

**Justification:**
- Once the file contains `resolve_figaro_root()` and `build_figaro_pipeline_fixture()` alongside the existing WIOD helpers, "replication" is no longer the accurate name — FIGARO E2E isn't replication of a paper, it's a fresh data pipeline.
- "gated-data" captures the shared pattern: both helpers gate on an env var because the data is too big/licensed to ship.
- Git history cost is one `git mv` — visible in `git log --follow`. Acceptable for a one-time rename that improves clarity.
- testthat auto-loads `helper-*.R` — the filename change has zero runtime effect beyond file-name matching.

**If rename is rejected:** Fine — drop both resolvers plus `build_figaro_pipeline_fixture()` into `helper-replication.R` alongside the existing `build_replication_fixtures()`. One-line comment at top disambiguating.

**Confidence: HIGH** — purely a naming-scope judgment; either path works mechanically.

## Extended Synthetic Fixture Design (D-7.5)

### Current fixture shape [VERIFIED: `inst/extdata/figaro-sample/*.csv`]

- **Supply file** (37 rows incl header): 2 REPs × 3 CPA × 2 PARs × 3 industries = 36 data rows.
- **Use file** (69 rows incl header): 36 use rows + 30 final-demand rows (3 CPAs × 2 REPs × 5 FD codes) + 1 primary-input row (`W2_B2A3G`) + 1 FIGW1 row = 68 data rows.
- Codes: `REP1`, `REP2`, `P01`, `P02`, `P03`, `I01`, `I02`, `I03`, plus `B2A3G` / `W2` / `FIGW1` special cases.
- Diagonal dominance: supply diagonal cells like `REP1,CPA_P01,REP1,I01 → 111` vs. off-diagonal `12-14`. 10× ratio.

### Extended fixture shape (proposed)

- **8 real FIGARO codes** (see Open Item 4): `A01`, `A03`, `C10T12`, `C13T15`, `C26`, `F`, `G46`, `G47`.
- **3 countries**: `DE`, `FR`, `IT` (2-letter to match real FIGARO convention — though since the existing fixture used `REP1`/`REP2` which are non-real codes, the planner could also use `REPA`/`REPB`/`REPC` to stay domain-neutral in the fixture. Recommend real codes so the fixture doubles as vignette code-pastable example).
- **Preserve special rows**: at least one `B2A3G` primary-input row, at least one `FIGW1` row, at least one cross-country row (REP ≠ PAR).
- **Value structure:** diagonal supply `1000`, off-diagonal supply `10-80`, diagonal use `100`, off-diagonal use `1-8`, FD values `2-6` per code (reuse existing fixture's FD values to minimize test-churn on `nrow`/`sum` invariants).
- **Size budget:** Planner must keep both CSVs combined ≤ 50 KB (D-7.5). The 3-country-with-sparse-inter-country approach in Open Item 4 is estimated at ~40 KB.

### Existing Test Breakage Analysis (tests/testthat/test-figaro.R)

Exact lines where the extended fixture breaks existing 46 tests:

| Line | Assertion | Current Value | After Fixture Swap |
|------|-----------|---------------|-------------------|
| 16 | `cpa_map` CPA column literals | `"P01", "P02", "P03"` | Must become `"A01", "A03", "C10T12", ...` (or `make_tiny_figaro_maps()` must be fully rewritten) |
| 20 | `ind_map` NACE column literals | `"I01", "I02", "I03"` | Must become same real FIGARO codes as CPA (per D-7.1 equivalence) |
| 25 | `inputs` REP column literals | `"REP1", "REP2"` | Must become `"DE", "FR", "IT"` |
| 29-31 | `inputs` values (GO, VA, EMP, CO2) | Hardcoded small ints | Must align to new industry count (8 instead of 3) and match new CPAagg (section letters) |
| 88 | `expect_true(all(out$CPA %in% c("P01", "P02", "P03")))` | Hardcoded | Must become `c("A01", "A03", "C10T12", ...)` |
| 102 | Same as line 88 | Hardcoded | Same fix |
| 118 | `expect_equal(nrow(fu_rows), 6L)` | `3 CPA × 2 REPs = 6` | With 8 CPAs × 3 REPs becomes `24L` (assumption — depends on final fixture shape) |
| 119 | `expect_equal(sum(fu_rows$VALUE), 120)` | `6 rows × 20 per-row total` | Must be recomputed from new fixture's FD values |
| 189 | `expect_true(nrow(result$summary) >= 1)` | Shape-only | Safe — `>= 1` still holds |

**Tests NOT affected by fixture swap:**
- Lines 35-51 (canonical columns) — shape-only
- Lines 53-59 (year validation) — validates arg parsing, not fixture content
- Lines 61-81 (path errors) — uses tempdir, not fixture content
- Lines 83-103 (CPA_ prefix, primary-input filter) — preserved patterns from D-7.5 ("preserve special rows")
- Lines 122-127 (FIGW1 preservation) — preserved pattern
- Lines 129-144 (`final_demand_vars` subset) — relative-value assertion, safe
- Lines 146-166 (coerce_map NACE/NACE_R2) — uses `sube_example_data()`, not FIGARO fixture
- Lines 168-173 (fixture file existence) — checks file path only
- Lines 175-190 (integration via `make_tiny_figaro_maps`) — needs the helper updated but the assertion shape (`nrow >= 1`) is safe

**Count of assertions needing update:** ~6 hardcoded-value assertions (lines 16, 20, 25, 29-31, 88, 102, 118, 119). Planner must add a dedicated plan-level task for this audit per D-7.5's "risk to flag".

## Mapping Table Provenance (D-7.1)

**Decision: Derive on-the-fly, no shipped file, optional local cheatsheet.**

- `build_nace_section_map()` helper in `helper-gated-data.R` takes a character vector of CPA codes (from the imported `sube_suts$CPA` column) and returns a `data.table(CPA = codes, CPAagg = substr(codes, 1, 1))`.
- Same function produces the `ind_map` by virtue of D-7.1's equivalence — called twice with the same code vector.
- For the vignette narrative (D-7.6 section 4), show the explicit one-liner — researchers grok it instantly, no license question, no build artifact to track.
- If the planner prefers a readable research reference: commit a 64-row `nace_section_map.csv` to `inst/extdata/figaro/` (the local-only `.Rbuildignore`'d dir) for manual inspection. No code path depends on it.

## Vignette Structure (D-7.6)

Mirror the 9-section pattern from `paper-replication.Rmd`:

```rmd
---
title: "FIGARO End-to-End Workflow"
vignette: >
  %\VignetteIndexEntry{FIGARO End-to-End Workflow}
  %\VignetteEngine{knitr::knitr}
  %\VignetteEncoding{UTF-8}
---

{r include = FALSE, opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)}

# 1. What FIGARO is and what this vignette covers
# 2. Obtaining the data (layout of $SUBE_FIGARO_DIR, file naming, size)
# 3. Reading the flatfile (read_figaro with the SYNTHETIC fixture for copy-pasteability)
# 4. Preparing mapping tables (NACE-R2 section equivalence, one-liner derivation)
# 5. Building matrices (build_matrices with the bundle; show the sube_matrices shape)
# 6. Computing multipliers (compute_sube, interpret $summary table)
# 7. Extending to elasticities (pointer to estimate_elasticities + SUBE_FIGARO_INPUTS_DIR)
# 8. Running the gated test locally (SUBE_FIGARO_DIR + `devtools::test(filter = "figaro-pipeline")`)
# 9. What's NOT covered (SIOT tables, auto-download, multi-year batch → CONV in Phase 8)
```

**Key implementation notes:**
- Every chunk `eval = FALSE` [CITED: D-7.6, matches `paper-replication.Rmd:13`].
- Section 3 uses `system.file("extdata", "figaro-sample", package = "sube")` → synthetic fixture → copy-paste runs without real data.
- Section 4 shows `dt[, CPAagg := substr(CPA, 1, 1)]` explicitly — this IS the D-7.1 mapping for 99% of researcher cases.
- Section 8 example (derived from `paper-replication.Rmd:136-145`):
  ```bash
  SUBE_FIGARO_DIR=/path/to/figaro Rscript -e 'devtools::test(filter = "figaro-pipeline")'
  ```
  And the no-env-var skip message (post-D-7.7):
  ```
  Rscript -e 'devtools::test(filter = "figaro-pipeline")'
  #> SKIP (SUBE_FIGARO_DIR not set — FIGARO E2E test skipped)
  ```
- **No Eurostat link, no FIGARO citation** [CITED: D-7.6].
- **pkgdown registration:** Add to `_pkgdown.yml` under a new articles section OR reuse `Modeling, Comparison, and Outputs`. Recommend a dedicated section:
  ```yaml
  - title: FIGARO workflow
    contents:
      - figaro-workflow
  ```
  **Side finding:** `paper-replication` is NOT currently registered in `_pkgdown.yml` articles [VERIFIED: grep returned no matches]. Planner should wire both vignettes into articles at the same time to close this gap. This is out-of-scope for Phase 7 strictly, but a one-line config addition.

## INFRA-02 Implementation (D-7.7)

### Before → After diff of `tests/testthat/helper-replication.R:10-16`

**Before** [VERIFIED: current file]:
```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) return(env)
  fallback <- system.file("extdata", "wiod", package = "sube")
  if (nzchar(fallback) && dir.exists(fallback)) return(fallback)
  ""
}
```

**After** [CITED: D-7.7 code]:
```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}

resolve_figaro_root <- function() {
  env <- Sys.getenv("SUBE_FIGARO_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}
```

### Skip-message updates (`tests/testthat/test-replication.R:32, 65, 106`)

**Before:** `"SUBE_WIOD_DIR not set and inst/extdata/wiod/ absent - paper replication test skipped"`

**After:** `"SUBE_WIOD_DIR not set — paper replication test skipped"`

(Three occurrences in `test-replication.R`.)

### New test file: `tests/testthat/test-gated-data-contract.R`

Asserts the D-7.7 contract for both helpers:

```r
test_that("resolve_wiod_root returns empty when env var is unset (INFRA-02)", {
  withr::with_envvar(c(SUBE_WIOD_DIR = ""), {
    expect_equal(resolve_wiod_root(), "")
  })
})

test_that("resolve_wiod_root ignores the local extdata/wiod/ fallback (INFRA-02)", {
  skip_if_not(dir.exists(system.file("extdata", "wiod", package = "sube")),
              "fallback path irrelevant on this install")
  withr::with_envvar(c(SUBE_WIOD_DIR = ""), {
    expect_equal(resolve_wiod_root(), "")
  })
})

test_that("resolve_wiod_root returns env var when set and valid", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  withr::with_envvar(c(SUBE_WIOD_DIR = tmp), {
    expect_equal(resolve_wiod_root(), tmp)
  })
})

# Parallel tests for resolve_figaro_root(), SUBE_FIGARO_DIR.
```

**Note: `withr` is not currently in Suggests** [VERIFIED: DESCRIPTION]. Either (a) add `withr` to Suggests, or (b) use base R `Sys.setenv` + `on.exit(Sys.unsetenv(...))`. Planner's call; `withr` is lighter and is the testthat-idiomatic choice.

### Paper-replication vignette text update (D-7.7 side effect)

Current `vignettes/paper-replication.Rmd:142-145`:
```
Without the env var (or on CRAN / CI), the test auto-skips:

Rscript -e 'devtools::test(filter = "replication")'
#> SKIP (SUBE_WIOD_DIR not set - paper replication test skipped)
```

After D-7.7, the vignette already says the right thing (it only mentions `SUBE_WIOD_DIR`). **No vignette update needed for the replication vignette.** Grep verified: `paper-replication.Rmd` never references the `inst/extdata/wiod/` fallback. [VERIFIED: grep on vignettes/paper-replication.Rmd].

**One caveat:** Section 2 (line 52-55) says `export SUBE_WIOD_DIR=/path/to/wiod` — this is unchanged by D-7.7. Skip message text at line 145 already matches the post-D-7.7 shape. **Zero vignette changes needed for INFRA-02.**

### NEWS.md entry (mandatory per D-7.7)

New bullet under `# sube (development version)`:
```md
- **BREAKING (development contract):** `resolve_wiod_root()` no longer
  falls back to `inst/extdata/wiod/` when `SUBE_WIOD_DIR` is unset. The
  gated replication test now skips cleanly in that case instead of
  silently using locally-mounted data (which previously caused a
  known ~4.4% multiplier divergence). Set `SUBE_WIOD_DIR` explicitly
  to run the test locally.
- Introduced `resolve_figaro_root()` with the same env-var-only
  contract: `SUBE_FIGARO_DIR` must be set explicitly for the gated
  FIGARO E2E test to run; no local fallback.
```

## Common Pitfalls

### Pitfall 1: 3-letter vs 2-letter country codes

**What goes wrong:** CONTEXT.md D-7.4 specifies `DEU, FRA, ITA, NLD` (3-letter). FIGARO 2023 flatfiles use `DE, FR, IT, NL` (2-letter ISO).
**Why it happens:** WIOD uses 3-letter ISO codes; FIGARO uses 2-letter. They are different conventions.
**How to avoid:** Use `c("DE", "FR", "IT", "NL")` in the FIGARO test. Don't copy-paste from `test-replication.R`'s `c("AUS", "DEU", "USA", "JPN")`.
**Warning signs:** Test runs, finds zero rows for "DEU", fails on `expect_gt(nrow, 0)`.
**Action:** Planner must escalate this one mismatch to the user OR document it as an interpretation (treating D-7.4's `DEU/FRA/ITA/NLD` as shorthand for "the same four countries in their correct-for-FIGARO ISO-2 form").

### Pitfall 2: 2019 reference year vs 2023 on-disk

**What goes wrong:** The locally-mounted FIGARO flatfile is `*_25ed_2023.csv` (reference year 2023). D-7.4 says year = 2019.
**Why it happens:** FIGARO publishes a separate flatfile per reference year. The 2023 data is what's on disk.
**How to avoid:** Either switch the gated-test year to 2023 (zero researcher friction) or document in the vignette section 8 that the researcher must download the 2019 flatfile additionally.
**Warning signs:** `read_figaro(path, year = 2019)` succeeds (it just tags the rows with `YEAR = 2019` per R/import.R:256) but the data in the file is the 2023 data.
**Action:** Planner to escalate to user: "Use 2023 (on disk) or add 'download 2019 flatfile' to the gated-test README?" Recommend 2023 — it's the researcher's local data and matches the "proves the pipeline" goal; year 2019 is a CONTEXT.md heuristic about "cleaner pre-COVID" that isn't operative when the literal 2023 data already exists.

### Pitfall 3: FIGARO has NO year column in the flatfile

**What goes wrong:** Attempting to filter by `YEAR` in the FIGARO CSV raw data.
**Why it happens:** Unlike WIOD's wide CSVs, FIGARO's long-format flatfile has exactly 7 columns and none is `YEAR`. The year is encoded in the filename only.
**How to avoid:** Always pass `year` as a `read_figaro()` argument; never expect the column in the raw data.
**Warning signs:** `dt$YEAR` is NULL; `required_in` check in `read_figaro()` passes (the check doesn't require year); tests that `filter(YEAR == 2019)` silently get zero rows.
**Action:** Already handled by `read_figaro()` [VERIFIED: R/import.R:256 inserts `YEAR = year` explicitly]. Planner just needs to make sure test code doesn't try to read YEAR from the CSV.

### Pitfall 4: Snapshot deparse on numeric matrices is platform-fragile

**What goes wrong:** Using `style = "deparse"` on a `compute_sube()` result containing matrix entries triggers ulp-level floating-point differences on different BLAS builds. CI passes locally, fails on GitHub Actions.
**Why it happens:** `deparse()` prints full-precision doubles; `solve()` output depends on the BLAS implementation.
**How to avoid:** Use `style = "serialize"` (binary, opaque but platform-stable) OR project to tabular fields only (`$summary`, `$tidy`, `$diagnostics`) where rounding at user-visible precision absorbs ulp-level noise. Combining both approaches (project + serialize) is the belt-and-suspenders option.
**Warning signs:** Local snapshot diff shows `1.2345678901e+02` vs `1.2345678902e+02`. Smooth graph of ulp drifts across CI runs.
**Action:** Default to `style = "serialize"` on the projected list. Document in a test-file comment that deparse was considered but rejected for float-matrix fragility.

### Pitfall 5: `.coerce_map()` NACE synonym depends on column ordering

**What goes wrong:** If the FIGARO section-letter mapping table has columns `(CPA, CPAagg)` but `ind_map` expects `(NACE, INDagg)`, the same table passed twice might not route correctly.
**Why it happens:** `.coerce_map()` looks up synonyms [VERIFIED: R/utils.R:44-49]: `CPA → {CPA, CPA56, CPA_CODE}`, `vars → {VARS, VAR, INDUSTRY, IND, CODE, NACE, NACE_R2}`. If the mapping table has only a `CPA` column and we pass it as `ind_map`, `.coerce_map()` will try to find the `vars` synonyms — none match — and fall back to positional.
**How to avoid:** Build two separate mapping tables from the same source: `cpa_map <- data.table(CPA = codes, CPAagg = letters)`, `ind_map <- data.table(NACE = codes, INDagg = letters)`. Or pass one table and rename the column in-place. The test-figaro.R line 146-166 NACE/NACE_R2 test already exercises this.
**Warning signs:** `build_matrices` output has all-NA `INDagg` → `matrices` list empty.
**Action:** The helper `build_nace_section_map()` should return a list: `list(cpa_map = dt_with_CPA_col, ind_map = dt_with_NACE_col)` to make the contract explicit.

### Pitfall 6: Fixture FD-row total changes break `expect_equal(sum(...))`

**What goes wrong:** Line 119 of `test-figaro.R` asserts `sum(fu_rows$VALUE) == 120`. Fixture change invalidates this.
**Why it happens:** The value `120` encodes `6 rows × 20 per-row total` where each row sums 5 FD codes `(2+3+4+5+6)`. Extended fixture has different row count.
**How to avoid:** Recompute the FD total from the new fixture shape; or change the assertion to `expect_gt(sum, 0)` (shape-only).
**Warning signs:** Specific numeric failure on line 119 only.
**Action:** Planner's fixture-audit task must include recomputing these hardcoded sums and row counts.

## Code Examples

### Build the FIGARO gated-test fixture (research reference)

```r
# In helper-gated-data.R (renamed from helper-replication.R)

build_figaro_pipeline_fixture <- function(root,
                                          countries = c("DE", "FR", "IT", "NL"),
                                          year = 2023L) {
  sut <- sube::read_figaro(path = root, year = year)

  # Filter to scope countries (both REP and PAR to keep cross-country intact)
  sut_scoped <- sut[REP %in% countries]

  domestic <- sube::extract_domestic_block(sut_scoped)

  # D-7.1: single mapping table serves as both cpa_map and ind_map
  codes <- sort(unique(c(domestic$CPA, domestic$VAR[domestic$VAR != "FU_bas"])))
  cpa_map <- data.table::data.table(CPA = codes, CPAagg = substr(codes, 1, 1))
  ind_map <- data.table::data.table(NACE = codes, INDagg = substr(codes, 1, 1))

  bundle <- sube::build_matrices(domestic, cpa_map, ind_map)

  # Assemble minimal `inputs` with synthetic GO = colSums(S) per industry-year
  # (placeholder: the real-data case without sidecars uses this trick to let
  # compute_sube run; structural assertions only, NOT golden-matched).
  inputs <- .synthesize_inputs_from_bundle(bundle, countries, year)

  result <- sube::compute_sube(bundle, inputs)

  list(sut = sut_scoped, bundle = bundle, result = result)
}
```

**Important caveat for the planner:** The `inputs` argument to `compute_sube()` requires `GO`, `VA`, `EMP`, `CO2` by default [VERIFIED: R/compute.R:20]. FIGARO flatfiles contain NO VA/EMP/CO2 sidecars — those are in separate Eurostat releases. There are two options:

1. **Restrict `metrics` to `"GO"` only** in the gated test: `compute_sube(bundle, inputs, metrics = c("GO"))`. `GO` can be synthesized as `colSums(S)` per industry-year from the FIGARO supply matrix itself. Produces multipliers but not elasticities (matches D-7.2's "opt-in elasticity" framing).
2. **Opt-in path with SUBE_FIGARO_INPUTS_DIR:** if the researcher has sidecar data, the test additionally runs `compute_sube()` with the full metric set and `estimate_elasticities()`.

[VERIFIED: R/compute.R:34-38 — `missing_metrics <- setdiff(metrics, names(inputs))` errors if metric columns are absent. So path (1) requires restricting `metrics`.]

**Recommendation:** Default gated-test path uses `metrics = "GO"` + synthesized `GO = colSums(S)` → structural and snapshot assertions on multipliers. Opt-in path uses full metric set. This matches D-7.2 precisely.

### Derive the section-letter map (D-7.1 one-liner)

```r
# From a sube_suts long table
section_map <- function(codes) {
  data.table::data.table(
    CPA = codes,
    CPAagg = substr(codes, 1L, 1L)
  )
}
# Usage:
cpa_map <- section_map(unique(domestic$CPA))
ind_map <- section_map(unique(domestic$VAR[domestic$VAR != "FU_bas"]))
data.table::setnames(ind_map, "CPA", "NACE")  # route through .coerce_map()
```

### Snapshot projection (D-7.3)

```r
.snapshot_projection <- function(result) {
  list(
    summary     = result$summary[order(COUNTRY, CPAagg)],
    tidy_shape  = list(rows = nrow(result$tidy),
                       cols = sort(names(result$tidy))),
    diagnostics = result$diagnostics[order(country, year)]
    # matrices excluded — see Pattern 2 rationale
  )
}

# In the test:
testthat::expect_snapshot_value(
  .snapshot_projection(bundle$result),
  style = "serialize"
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled `.rds` dump + `identical()` | `testthat::expect_snapshot_value()` | testthat 3.0.0, Apr 2020 | CONTEXT.md D-7.3 locks this in; no custom capture scripts |
| Multi-branch resolver with `system.file()` fallback | One-line `Sys.getenv() && dir.exists()` resolver | Phase 7 / D-7.7 | Closes the v1.1 4.4% drift bug; explicit contract |
| Single-file `helper-replication.R` | Renamed `helper-gated-data.R` shared by WIOD + FIGARO gated tests | Phase 7 | Clarifies intent; one git rename |

**Deprecated/outdated:**
- The `fallback <- system.file("extdata", "wiod", package = "sube")` branch in `resolve_wiod_root()` — removed by D-7.7.
- The skip message `"... and inst/extdata/wiod/ absent ..."` — replaced by the simpler `"SUBE_WIOD_DIR not set"`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | User intends `DE/FR/IT/NL` 2-letter codes (not literally `DEU/FRA/ITA/NLD`) for the FIGARO test scope | Pitfall 1; Open Item 4 | Test immediately returns zero rows for "DEU" — hard error. ESCALATED to planner/user. |
| A2 | Locally-mounted `*_25ed_2023.csv` is the canonical target for the gated test (not a hypothetical 2019 flatfile) | Pitfall 2; Summary | If user insists on 2019, the planner must add a "download 2019 flatfile" researcher step. ESCALATED. |
| A3 | `metrics = "GO"` is acceptable for the default gated-test path (no VA/EMP/CO2 sidecars) | Code Examples § caveat | If user wants the test to assert elasticities by default, the gated-test path must require sidecar data — pushing D-7.2's opt-in elastic path to be the *only* path. ESCALATED if confirmed. |
| A4 | `GO = colSums(S)` is a reasonable synthesis for the gated test's `inputs$GO` when no Eurostat GO sidecar is present | Code Examples § caveat | Different synthesis (e.g. per-industry Total supply from a FIGARO-provided column) might be more faithful. Functionally correct for deterministic multipliers; semantically debatable. |
| A5 | `style = "serialize"` is preferred over `style = "deparse"` for the snapshot due to floating-point fragility | Pitfall 4; Open Item 3 | If reviewers want human-readable snapshots, `style = "deparse"` with projected tabular-only content would still work at ≈hundreds of KB. Planner's call at implementation. |
| A6 | Renaming `helper-replication.R` → `helper-gated-data.R` is acceptable scope | Open Item 6 | Git history is preserved via `git mv`; acceptable per community convention. Low risk. |
| A7 | 64-code FIGARO A*64 aggregates cleanly into 21 NACE sections by taking the first letter | Open Item 1 | [VERIFIED by `awk` inspection of real data] Not an assumption — tested. |
| A8 | `paper-replication.Rmd` never references `inst/extdata/wiod/` fallback text | INFRA-02 § vignette | [VERIFIED by grep] Not an assumption — tested. |

**Escalations to planner (must be resolved before planning):**
- **A1** (2-letter vs 3-letter country codes) — the planner should confirm with the user OR record an interpretation in the plan summary.
- **A2** (2023 vs 2019 year) — the planner should confirm OR switch the hardcoded year to 2023 with a one-line summary bullet.
- **A3** (default gated-test metrics = "GO" only) — depends on whether the user expects elasticities in the DEFAULT path. CONTEXT.md D-7.2 says no ("`estimate_elasticities()` is NOT in the default path"), so this assumption is likely correct, but worth surfacing because it affects the `inputs` synthesis story.

## Open Questions

1. **Which year does the gated test cover?**
   - What we know: On-disk FIGARO files are 2023 reference year; CONTEXT.md D-7.4 says 2019.
   - What's unclear: Whether the researcher has (or will download) the 2019 flatfile.
   - Recommendation: Planner includes a pre-plan question to the user: "Use year 2023 (on disk) or 2019 (user confirms they will download the 2019 flatfile)?" Proceed with 2023 in the plan draft if no response, with a visible bullet in the summary.

2. **Synthetic fixture country codes — domain-real or abstract?**
   - What we know: Existing fixture uses `REP1`/`REP2` (abstract). Extended fixture might use `DE`/`FR`/`IT` (real).
   - What's unclear: Whether the vignette-level copy-paste story benefits from real codes.
   - Recommendation: Use real codes (`DE`, `FR`, `IT`) in the extended fixture so vignette section 3 can live-demo `sut[REP == "DE"]` without researcher confusion. `FIGW1` special case already requires recognizing real FIGARO country vocabulary.

3. **Should the synthetic fixture contract test assert snapshot equality?**
   - What we know: D-7.3 says snapshot lives on the GATED (real-data) test. FIG-E2E-02 (synthetic contract) has no snapshot requirement, only "pushes the synthetic fixture through `build_matrices → compute_sube → estimate_elasticities` with no external data and exits green".
   - What's unclear: Whether a *second* snapshot on the synthetic-fixture path adds value.
   - Recommendation: Yes — add a snapshot on the synthetic-fixture path too. It's ~free (the fixture is deterministic by construction), runs on every CI build, and catches any unintended pipeline drift without touching real data.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R | Running the tests and vignettes | ✓ | DESCRIPTION requires `>= 4.2.0` | — |
| `testthat` | `expect_snapshot_value()` | ✓ | `>= 3.0.0` (DESCRIPTION Suggests, edition 3 enabled) | — |
| `data.table` | Test fixtures, data manipulation | ✓ | Imports | — |
| `knitr`/`rmarkdown` | Vignette build | ✓ | Suggests | — |
| `pkgdown` | Site reference articles group | ✓ | Suggests | — |
| `withr` | `with_envvar()` in INFRA-02 tests | ✗ | not in Suggests | Use base R `Sys.setenv` + `on.exit(Sys.unsetenv)`. Planner's choice to add `withr` to Suggests. |
| Real FIGARO flatfile | FIG-E2E-01 gated test | ✓ | `inst/extdata/figaro/flatfile_eu-ic-{supply,use}_25ed_2023.csv` (873 MB total) | Test skips when `SUBE_FIGARO_DIR` unset. |
| Real WIOD tree | `test-replication.R` and `paper-replication.Rmd` | ✓ (per v1.1 audit) | `inst/extdata/wiod/` | Test skips when `SUBE_WIOD_DIR` unset (post-D-7.7: even if dir exists). |
| FIGARO VA/EMP/CO2 sidecar | Opt-in elasticity extension in FIG-E2E-01 | ✗ | Not in any local `inst/extdata/` | Opt-in path skipped when `SUBE_FIGARO_INPUTS_DIR` unset. |

**Missing dependencies with no fallback:** None — all Phase 7 work has either a shipped dependency or a defined skip path.

**Missing dependencies with fallback:** `withr` — can be added to Suggests (idiomatic) OR base-R substitute used (simpler). Planner's call.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.0.0+ (edition 3) [VERIFIED: DESCRIPTION L32-34] |
| Config file | `tests/testthat.R` (standard R package layout) |
| Quick run command | `devtools::test(filter = "figaro-pipeline")` |
| Full suite command | `devtools::test()` |
| Package check | `R CMD check --as-cran` via `devtools::check()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIG-E2E-01 | Gated test drives real FIGARO → pipeline → snapshot + invariants | integration (gated) | `devtools::test(filter = "figaro-pipeline")` | ❌ Wave 0 (new `test-figaro-pipeline.R`) |
| FIG-E2E-02 | Synthetic fixture drives pipeline deterministically on every build | contract (unit-like) | `devtools::test(filter = "figaro-pipeline")` (same file, non-skipped test) | ❌ Wave 0 (new block in `test-figaro-pipeline.R`) |
| FIG-E2E-03 | Vignette renders cleanly with `eval = FALSE`, appears in pkgdown articles | manual (build-time) | `devtools::build_vignettes()` + `pkgdown::build_site()` | ❌ Wave 0 (new `vignettes/figaro-workflow.Rmd`) |
| INFRA-02 (resolve_wiod_root guarded skip) | Env-var unset → returns `""` even if fallback dir exists | contract (unit) | `devtools::test(filter = "gated-data-contract")` | ❌ Wave 0 (new `test-gated-data-contract.R`) |
| INFRA-02 (resolve_wiod_root opt-in) | Env-var set and valid → returns the env var path | contract (unit) | Same as above | ❌ Wave 0 |
| INFRA-02 (resolve_figaro_root parity) | Same contract as WIOD for the FIGARO resolver | contract (unit) | Same as above | ❌ Wave 0 |
| D-7.7 skip-message update | `test-replication.R` skip messages no longer mention fallback | behavioral (text) | `devtools::test(filter = "replication")` with env var unset | ✅ existing file, update only |
| D-7.5 fixture-swap regression | All 46 existing `test-figaro.R` assertions pass against extended fixture | contract (unit) | `devtools::test(filter = "figaro")` | ✅ existing file, update value-baked assertions |
| D-7.6 vignette in pkgdown | `figaro-workflow` appears under Articles in built pkgdown site | manual (visual) | `pkgdown::build_articles()` → inspect HTML | ❌ Wave 0 (`_pkgdown.yml` addition) |

### Sampling Rate
- **Per task commit:** `devtools::test(filter = "figaro-pipeline")` for FIG-E2E-*; `devtools::test(filter = "gated-data-contract")` for INFRA-02.
- **Per wave merge:** `devtools::test()` (full suite, ~102 + new tests).
- **Phase gate:** `devtools::test()` fully green + `devtools::check()` clean (targeting `Status: OK` from the tarball) + `devtools::build_vignettes()` passes + `pkgdown::build_site()` builds.

### Wave 0 Gaps
- [ ] `tests/testthat/test-figaro-pipeline.R` — covers FIG-E2E-01 (gated, snapshot) and FIG-E2E-02 (synthetic contract)
- [ ] `tests/testthat/test-gated-data-contract.R` — covers INFRA-02 assertions for both resolvers
- [ ] `tests/testthat/helper-gated-data.R` — renamed from `helper-replication.R`; contains `resolve_wiod_root()` (updated), `resolve_figaro_root()` (new), `build_replication_fixtures()` (existing), `build_figaro_pipeline_fixture()` (new), `build_nace_section_map()` / `section_map()` helper (new)
- [ ] `tests/testthat/_snaps/figaro-pipeline/` — autogenerated by first local green run
- [ ] `vignettes/figaro-workflow.Rmd` — 9-section companion
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — REPLACED with extended fixture
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — REPLACED with extended fixture
- [ ] `_pkgdown.yml` — add `figaro-workflow` articles entry (and optionally wire the missing `paper-replication` entry too)
- [ ] `NEWS.md` — two bullets: INFRA-02 BREAKING note + FIGARO E2E vignette/test/fixture bullet
- [ ] Test framework: already installed (`testthat >= 3.0.0`). No install step needed.

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` file exists in the project. The user's private global `~/.claude/CLAUDE.md` contains RTK token-optimizer and environment metadata only — no project-specific coding rules that affect Phase 7 planning.

## Sources

### Primary (HIGH confidence)
- `R/import.R` (read direct) — `read_figaro()` signature and year-handling semantics
- `R/matrices.R` — `build_matrices()` signature and `cpa_map`/`ind_map` coercion
- `R/compute.R` — `compute_sube()` return-shape contract; confirms no non-deterministic fields
- `R/utils.R` — `.coerce_map()` synonym routing
- `tests/testthat/helper-replication.R`, `test-replication.R`, `test-figaro.R`, `test-workflow.R` — existing patterns and breakage points
- `vignettes/paper-replication.Rmd` — 9-section vignette pattern to mirror
- `inst/extdata/figaro/flatfile_eu-ic-{supply,use}_25ed_2023.csv` — real FIGARO schema, code set, country set, row count (verified via direct `awk`/`head`/`wc`)
- `inst/extdata/figaro-sample/*.csv` — existing synthetic fixture shape and baked-in test dependencies
- `.Rbuildignore`, `.gitignore`, `DESCRIPTION`, `_pkgdown.yml`, `NEWS.md` — confirm current state of bundling and package metadata
- `.planning/config.json` — confirms `workflow.nyquist_validation: true`, so Validation Architecture section is included
- [Eurostat — EU inter-country supply, use and input-output tables (FIGARO) metadata](https://ec.europa.eu/eurostat/cache/metadata/en/naio_10_fcp_esms.htm) — 64 industries / 64 products confirmation, annual data series
- [testthat — expect_snapshot_value reference](https://testthat.r-lib.org/reference/expect_snapshot_value.html) — style semantics

### Secondary (MEDIUM confidence)
- [Eurostat - ESA supply-use input tables database](https://ec.europa.eu/eurostat/web/esa-supply-use-input-tables/database) — "64 industries by NACE rev. 2" and "64 products by CPA 2.1" confirmed
- [CEPAL — EU IC-SUT and IOT 2022 FIGARO edition](https://www.cepal.org/sites/default/files/presentations/2._eu_ic_sut_and_iot_-_2022_figaro_edition.pdf) — A*64/CPA*64 level confirmation
- [testthat snapshotting vignette](https://testthat.r-lib.org/articles/snapshotting.html) — snapshot workflow reference
- [NACE Rev 2 sections — Wikipedia](https://en.wikipedia.org/wiki/Statistical_Classification_of_Economic_Activities_in_the_European_Community) — 21 sections A-U confirmation in Rev 2

### Tertiary (LOW confidence)
- None. All critical claims verified via direct file inspection or official documentation.

## Metadata

**Confidence breakdown:**
- FIGARO schema (code set, country set, row structure): HIGH — verified via `awk`/`head` on the real 873 MB flatfile
- `compute_sube()` / `build_matrices()` / `read_figaro()` behavioral contracts: HIGH — read in full from source
- NACE section aggregation feasibility: HIGH — empirically verified 21 clean section-letter groups
- Existing test breakage points: HIGH — line-by-line review of `test-figaro.R`
- Snapshot style choice (serialize vs deparse): MEDIUM — rationale is sound but reviewability preference is the user's call
- Country code convention (2-letter vs 3-letter): HIGH on what FIGARO ACTUALLY USES (direct inspection); ESCALATED on what user INTENDED in D-7.4
- Year convention (2019 vs 2023): HIGH on what's on disk; ESCALATED on user intent

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (FIGARO 2023 edition is fixed; testthat 3.x API is stable; internal codebase is checked-in). Refresh needed only if FIGARO publishes a new edition or testthat 4.0 ships.
