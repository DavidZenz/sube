---
phase: 06-paper-replication-verification
plan: 01
subsystem: testing
tags: [replication, testthat, paper-verification, REP-01]
requires:
  - sube::import_suts
  - sube::extract_domestic_block
  - sube::build_matrices (inputs= path producing model_data)
provides:
  - tests/testthat/helper-replication.R
  - tests/testthat/test-replication.R
  - REP-01 gated numerical replication proof
affects:
  - CI test suite (adds 3 gated skips when data unavailable)
tech_stack_added: []
tech_stack_patterns:
  - testthat helper-*.R auto-sourcing
  - skip_on_cran + skip_if_not env-var gate pattern
  - Memoised fixture closure to amortise pipeline cost across blocks
key_files_created:
  - tests/testthat/helper-replication.R
  - tests/testthat/test-replication.R
key_files_modified: []
decisions: []
metrics:
  duration: ~6 minutes
  tasks_completed: 2
  commits: 2
  completed: "2026-04-15T12:22:27Z"
---

# Phase 06 Plan 01: Replication Test Summary

Gated testthat suite that proves the `import_suts -> extract_domestic_block -> build_matrices` pipeline reproduces the paper's raw SUP, raw USE, and `W = t(SUP_agg - USE_agg)` matrices to within 1e-6 for AUS/DEU/USA/JPN x 2005, skipping cleanly on CRAN and when SUBE_WIOD_DIR is unset.

## What Was Built

- **`tests/testthat/helper-replication.R`** — two test-scoped helpers:
  - `resolve_wiod_root()` — resolves WIOD root from `SUBE_WIOD_DIR` env var, falling back to `system.file("extdata","wiod", package = "sube")`, else returns `""` for caller to skip on.
  - `build_replication_fixtures(root, countries, year)` — runs `import_suts -> extract_domestic_block`, loads `CorrespondenceCPA56.dta` / `CorrespondenceInd56.dta`, assembles `inputs_raw` from `GOVAcur/*.dta` + `EMP/*.dta` + `CO2/*.dta`, and returns `build_matrices(..., inputs = inputs_raw)` — including `$model_data`.

- **`tests/testthat/test-replication.R`** — three `test_that` blocks, each opening with the same `skip_on_cran() + skip_if_not(nzchar(root), "SUBE_WIOD_DIR not set ...")` gate:
  1. **`model_data W matrix matches legacy ground truth within 1e-6`** — for each country: load `Regression/data/{country}_2005.csv`, sort both tables by `INDUSTRIES`, `expect_equal` for each of P01..P22 at `tolerance = 1e-6`. Includes `expect_gt(nrow(our), 0)` and `expect_equal(nrow(our), 56L)` guards (Pitfall 4).
  2. **`raw SUP cells match legacy wide CSV within 1e-6`** — reads `Int_SUTs_domestic_SUP_2005_May18.csv`, filters to `REP == country & PAR == country`, strips aggregate columns (`DSUP_bas`, `IMP`, `SUP_bas`, `ExpTTM`, `ReEXP`, `IntTTM`, `REP`, `PAR`, `YEAR`, `TYPE`), defensively strips the `CPA_` prefix, compares industry-column-by-column against `dcast(sut[... TYPE == "SUP" & VAR != "FU_BAS"], CPA ~ VAR)`.
  3. **`raw USE cells match legacy wide CSV within 1e-6`** — identical shape with `TYPE == "USE"` and the USE CSV.

- **Memoised bundle loader** at file scope (`.replication_bundle`) ensures the expensive `build_replication_fixtures()` call runs at most once per test-file invocation and that block 1 skips rather than errors when the fixture fails.

## How It Meets REP-01

- **SC-1 (numerical match):** When a developer sets `SUBE_WIOD_DIR=...` and runs `devtools::test(filter = "replication")`, the three blocks run 4 countries x (22 P-cols + row-order + nrow) + 4 countries x ~56 industry cols x 2 (SUP/USE) expect_equal assertions at 1e-6. Verification deferred to manual exec at milestone close; CI lacks the data.
- **SC-2 (clean skip):** Verified this plan. Ungated run: `SKIPPED: 3, FAILED: 0`, single SKIP line per block citing `SUBE_WIOD_DIR`.

## Verification

- **Ungated run** (no `SUBE_WIOD_DIR`): `devtools::test(filter = "replication")` -> `SSS` (3 skips, 0 failures, 0 errors). SKIP messages contain the expected text.
- **Full-suite regression check** (`devtools::test()`): `PASSED: 102, FAILED: 0, SKIPPED: 3` — no regression from prior phases (figaro + workflow still fully green).

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria satisfied:

- Helper defines both `resolve_wiod_root()` and `build_replication_fixtures()`, uses `SUBE_WIOD_DIR`, `system.file("extdata","wiod", package = "sube")`, the `setnames(..., "CPAagg", "CPA_AGG")` / `setnames(..., "Indagg", "IND_AGG")` pattern, and `build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)`.
- Test file has exactly 3 `test_that(` blocks, 3 `skip_on_cran()` calls, 3 `skip_if_not(` gates with the `SUBE_WIOD_DIR` message, uses `tolerance = 1e-6`, uses `setorder(`, references all four countries, references both `Int_SUTs_domestic_{SUP,USE}_2005_May18.csv` filenames, references `Regression/data` and `sprintf("%s_2005.csv"`, and does not reference `compute_sube`, `estimate_elasticities`, or `filter_paper_outliers`.

## Commits

- `040c039` — test(06-01): add helper-replication fixtures
- `d71c6a1` — test(06-01): add REP-01 paper replication test

## Self-Check: PASSED

- FOUND: tests/testthat/helper-replication.R
- FOUND: tests/testthat/test-replication.R
- FOUND: commit 040c039
- FOUND: commit d71c6a1
- Ungated replication filter run: 0 failures, 3 skips
- Full suite: 102 passed, 0 failed, 3 skipped (expected)
