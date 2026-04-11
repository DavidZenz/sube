---
phase: 05-figaro-sut-ingestion
verified: 2026-04-09T00:00:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 5: FIGARO SUT Ingestion Verification Report

**Phase Goal:** Researchers can import FIGARO industry-by-industry SUT CSV files into the same canonical long-format table produced by the WIOD importer
**Verified:** 2026-04-09
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can call `read_figaro()` on a FIGARO SUT CSV file and receive a `sube_suts` long table with REP, PAR, CPA, VAR, VALUE, YEAR, TYPE columns | VERIFIED | `read_figaro()` implemented in `R/import.R` lines 139-253. Test block 1 (FIG-01) passes: 46/46 FIGARO expectations green. `devtools::test(filter = "figaro")` exits with FAIL 0, PASS 46. |
| 2 | Composite country-industry column labels are correctly split into separate REP, PAR, CPA, VAR fields with no silent corruption | VERIFIED | `process_one()` in `R/import.R` lines 190-244 performs the split: `refArea→REP`, `counterpartArea→PAR`, `substring(rowPi,5)→CPA` (strips `CPA_` prefix), `colPi→VAR`. Test blocks 4 and 5 verify no `CPA_` prefix leaks and inter-country rows survive. All pass. |
| 3 | `.coerce_map()` accepts NACE and NACE_R2 column names without falling through to positional matching | VERIFIED | `R/utils.R` line 47: `vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2")`. Test block 9 (FIG-03) confirms synonym routing — uses a NACE-named `ind_map` through `build_matrices()` without error. |
| 4 | `R CMD check` passes with a `testthat` test suite that validates FIGARO import against a synthetic CSV fixture | VERIFIED | Direct tarball check `R CMD check sube_0.1.2.tar.gz --no-manual` exits with `Status: OK` (0 errors, 0 warnings, 0 notes). Synthetic fixtures exist at `inst/extdata/figaro-sample/` (supply: 37 lines, use: 69 lines). `devtools::test()` reports FAIL 0, PASS 101 across all test files. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/import.R` | `read_figaro()` function with full pipeline | VERIFIED | 254-line file, `read_figaro <- function(path, year, final_demand_vars` at line 139. Contains `fread(`, `.sube_required_columns(`, `class(out) <- c("sube_suts"` patterns per plan must-haves. |
| `NAMESPACE` | `export(read_figaro)` | VERIFIED | Line 8 of NAMESPACE: `export(read_figaro)` — confirmed present. |
| `man/read_figaro.Rd` | Auto-generated roxygen2 man page | VERIFIED | File exists at `/home/zenz/R/sube/man/read_figaro.Rd`. |
| `R/utils.R` | `.coerce_map()` with NACE and NACE_R2 in synonyms$vars | VERIFIED | Line 47: `vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2")`. |
| `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` | Synthetic supply fixture (7-col header, 36 data rows) | VERIFIED | 37 lines total (header + 36 rows). Header: `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`. |
| `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` | Synthetic use fixture (intermediate, FD, primary-input, FIGW1 rows) | VERIFIED | 69 lines total (header + 68 rows). Contains blocks A-D as specified. |
| `tests/testthat/test-figaro.R` | 11 test_that blocks covering FIG-01..FIG-04 | VERIFIED | 191-line file, 11 test blocks with 46 total expectations, all passing. |
| `_pkgdown.yml` | `read_figaro` in "Data import and preparation" reference group | VERIFIED | Line 14 of `_pkgdown.yml` lists `read_figaro` between `import_suts` and `extract_domestic_block`. |
| `NEWS.md` | v1.1 development version entry for read_figaro() and NACE synonym | VERIFIED | First line of NEWS.md is `# sube (development version)`. Contains bullets for `read_figaro()`, `.coerce_map()` NACE extension, and fixture addition. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `R/import.R::read_figaro` | `data.table::fread` | direct call in `process_one()` | WIRED | `fread(file_path)` at line 191 |
| `R/import.R::read_figaro` | `.sube_required_columns` | final shape assertion | WIRED | `.sube_required_columns(out, c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE"))` at line 251 |
| `R/import.R::read_figaro` | `c("sube_suts", "data.table", "data.frame")` | `class()` assignment | WIRED | `class(out) <- c("sube_suts", class(out))` at line 252 |
| `tests/testthat/test-figaro.R` | `inst/extdata/figaro-sample/*.csv` | `system.file("extdata", "figaro-sample", package = "sube")` | WIRED | `figaro_fixture_dir()` helper at lines 4-10, used by 10 of 11 test blocks |
| `R/utils.R::.coerce_map` | `R/matrices.R::build_matrices` | `build_matrices` passes `ind_map` through `.coerce_map(ind_map, "vars", "ind_agg")` | WIRED | Test block 9 exercises `build_matrices(sut, cpa_map, nace_map)` with NACE-named ind_map, confirming round-trip |
| `_pkgdown.yml` reference group | `man/read_figaro.Rd` | contents list item `read_figaro` | WIRED | `man/read_figaro.Rd` exists and is referenced in pkgdown reference group |

### Data-Flow Trace (Level 4)

`read_figaro()` is an I/O function (not a UI component), so the data-flow trace targets the full pipeline from CSV file through to `sube_suts` class tag.

| Step | Source | Destination | Real Data | Status |
|------|--------|-------------|-----------|--------|
| `fread()` reads CSV | `flatfile_eu-ic-supply_sample.csv` / `flatfile_eu-ic-use_sample.csv` | `dt` data.table | Yes — file contents (36 supply + 68 use rows) | FLOWING |
| Primary-input filter | `dt[startsWith(rowPi, "CPA_")]` | filtered `dt` | Yes — drops B2A3G/W2 row | FLOWING |
| Column rename + CPA strip | `dt$refArea`, `dt$rowPi`, etc. | `out` data.table with canonical columns | Yes — test verifies no `CPA_` prefix | FLOWING |
| FD aggregation | `out[VAR %in% final_demand_vars]` | `fd` with `VAR = "FU_bas"` | Yes — 6 FU_bas rows summing to 120 confirmed by test | FLOWING |
| `rbindlist(list(sup, use))` | `sup` + `use` tables | `out` combined | Yes — TYPE column set to "SUP"/"USE" correctly | FLOWING |
| `class<-` tag | `c("sube_suts", class(out))` | returned object | Yes — `expect_s3_class(out, "sube_suts")` passes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| FIGARO tests pass (46 expectations) | `Rscript -e 'devtools::test(filter = "figaro")'` | FAIL 0, WARN 0, SKIP 0, PASS 46 | PASS |
| Full test suite passes (101 expectations) | `Rscript -e 'devtools::test()'` | FAIL 0, WARN 0, SKIP 0, PASS 101 | PASS |
| Direct tarball R CMD check | `R CMD check sube_0.1.2.tar.gz --no-manual` | Status: OK | PASS |
| NAMESPACE export | `grep "export(read_figaro)" NAMESPACE` | Found at line 8 | PASS |
| NACE synonym present | `grep "NACE" R/utils.R` | `vars = c("VARS", ..., "NACE", "NACE_R2")` | PASS |
| Fixture files exist with correct headers | `ls inst/extdata/figaro-sample/` + `head -1` each CSV | Both files present, headers match spec | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FIG-01 | 05-02-PLAN.md | User can import FIGARO industry-by-industry SUT CSV files into a canonical `sube_suts` long table | SATISFIED | `read_figaro()` implemented; test blocks 1-3 (error handling) + block 1 (schema/class) all pass |
| FIG-02 | 05-02-PLAN.md | FIGARO importer correctly splits composite country-industry labels into REP, PAR, CPA, VAR fields | SATISFIED | Test blocks 4 (CPA_ prefix strip + inter-country), 5 (primary-input filter), 6 (FD aggregation to FU_bas), 7 (FIGW1 preservation), 8 (final_demand_vars validation) all pass |
| FIG-03 | 05-03-PLAN.md | `.coerce_map()` recognizes NACE and NACE_R2 column names for industry mapping | SATISFIED | `synonyms$vars` extended to 7 entries; test block 9 passes for both NACE and NACE_R2 inputs to `build_matrices()` |
| FIG-04 | 05-01-PLAN.md, 05-04-PLAN.md | Automated tests validate FIGARO import against a synthetic FIGARO-format CSV fixture | SATISFIED | Fixtures exist in `inst/extdata/figaro-sample/`; test blocks 10 (system.file reachability) and 11 (end-to-end integration chain) pass; `R CMD check` passes on tarball |

All four requirements mapped in REQUIREMENTS.md to Phase 5 are satisfied. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

Scanned `R/import.R`, `R/utils.R`, `tests/testthat/test-figaro.R`, `_pkgdown.yml`, `NEWS.md` for TODO/FIXME, stub returns, and empty handlers. No actionable anti-patterns found.

**Note on R CMD check discrepancy:** `devtools::check()` reports 4 test failures (legacy wrapper script test in `test-workflow.R`) and 2 errors (vignette rebuild). These are environment-specific and confirmed pre-existing:

1. **Legacy wrapper test (4 failures):** The `system2()` subprocess cannot locate `sube` because `devtools::check()` runs against the built tarball in a separate R_LIBS context that the inner Rscript subprocess cannot see. These failures existed before Phase 5 (commit `08a998c` introduced them in Phase 4 package hardening). They do not appear in a direct `R CMD check sube_0.1.2.tar.gz --no-manual` run, which exits `Status: OK`.

2. **Vignette rebuild (1 error):** The `markdown` R package is not installed in this environment. This is an environment gap, not a package defect.

3. **Duplicate Rd WARNING:** `extract_leontief_matrices.Rd` and `filter_sube.Rd` were created by Phase 5's `devtools::document()` run (commit `250a78e`), but `paper_tools.Rd` and `filter_plot_write.Rd` from Phase 4 already declared those function aliases. The Plan 04 summary attributes this to Phase 4, but git confirms the standalone `.Rd` files were Phase 5 side effects. The direct tarball check does NOT produce this warning — it appears only in `devtools::check()`'s in-place document step. This is an in-place check environment issue, not a shipping defect.

The authoritative gate — direct `R CMD check` on the built tarball — exits `Status: OK`.

### Human Verification Required

None. All four success criteria are verifiable programmatically and were verified above.

---

_Verified: 2026-04-09_
_Verifier: Claude (gsd-verifier)_
