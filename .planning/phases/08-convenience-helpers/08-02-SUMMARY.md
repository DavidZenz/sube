---
phase: 08-convenience-helpers
plan: 02
subsystem: r-batch-processor
tags:
  - r-package
  - batch
  - diagnostics
  - conv-02
  - conv-03
requires:
  - R/pipeline.R::run_sube_pipeline (from Plan 01)
  - R/pipeline.R::.sube_pipeline_result (from Plan 01)
  - R/pipeline.R::.empty_diagnostics (from Plan 01)
  - R/pipeline.R::.detect_coerced_na (from Plan 01)
  - R/pipeline.R::.detect_skipped_alignment (from Plan 01)
  - R/pipeline.R::.detect_inputs_misaligned (from Plan 01)
  - R/pipeline.R::.extend_compute_diagnostics (from Plan 01)
  - R/pipeline.R::.validate_pipeline_inputs (from Plan 01)
  - R/matrices.R::build_matrices
  - R/compute.R::compute_sube
  - R/models.R::estimate_elasticities
  - R/utils.R::.validate_class
provides:
  - R/pipeline.R::batch_sube (exported)
  - R/pipeline.R::.sube_batch_result (S3 constructor)
  - R/pipeline.R::.batch_split (group splitter)
  - R/pipeline.R::.batch_run_one (per-group pipeline with tryCatch)
  - R/pipeline.R::.emit_batch_warning (single summary warning)
affects:
  - NAMESPACE (+1 export line)
  - tests/testthat/test-pipeline.R (+11 test_that blocks appended)
tech-stack:
  added: []
  patterns:
    - S3 class c("sube_batch_result", "list") — matches sube_pipeline_result pattern (no inheritance from sube_results; $results list preserves per-group objects)
    - data.table::copy() on cpa_map / ind_map / inputs at batch entry — Pitfall 10 mutation guard
    - Two-tier tryCatch: compute_sube wrap inside .batch_run_one for deep alignment errors, outer helper-level tryCatch as safety net for programming errors
    - rbindlist(fill = TRUE) for unequal schemas across groups (RESEARCH §6 Risk 2)
    - setNames(per_group, group_keys) pairs per-group pipeline_result objects with their keys
key-files:
  created: []
  modified:
    - R/pipeline.R
    - NAMESPACE
    - tests/testthat/test-pipeline.R
decisions:
  - "D-8.5 honoured: signature (sut_data, cpa_map, ind_map, inputs, countries, years, by, estimate, ...); sube_suts class-guarded at entry via .validate_class()"
  - "D-8.6 honoured: sube_batch_result with $results (named list of sube_pipeline_result) + $summary/$tidy/$diagnostics merged via rbindlist + $call provenance (by, n_groups, n_errors)"
  - "D-8.7 honoured: per-group tryCatch. Data-quality errors inside build/compute become stage=compute status=error rows (via resilient compute_sube wrap); programming errors bubble to outer tryCatch and become stage=pipeline status=error rows"
  - "D-8.8 honoured: by = c('country_year', 'country', 'year'), default 'country_year'. group_key format REP_YEAR / REP / YEAR respectively"
  - "D-8.10 honoured: exactly one warning() per batch when n_errors > 0 OR any non-ok diagnostics row; silent on fully-clean batch"
  - "errored detection extended to include compute-stage errors (diagnostics$status == 'error'), not just outer-tryCatch catches — matches D-8.7 intent that a group counts as 'errored' when its per-group diagnostics surface an error row"
metrics:
  duration: "~18 min"
  completed: 2026-04-16
  tasks_completed: 2
  commits: 4
  files_created: 0
  files_modified: 3
  tests_added: 11
  regressions: 0
---

# Phase 08 Plan 02: batch-sube Summary

Delivered `batch_sube()` — the CONV-02 country × year batch processor — together with the CONV-03 diagnostics contract applied at batch scope (single summary warning, merged `$diagnostics` with `group_key` column). Reuses every detection helper and the `sube_pipeline_result` constructor shipped by Plan 01, so the pipeline- and batch-level diagnostic contracts are bit-identical aside from the extra `group_key` column.

## What Shipped

**Exported function:**

- `batch_sube(sut_data, cpa_map, ind_map, inputs, countries, years, by, estimate, ...)` — loops per-group processing over a pre-imported `sube_suts`, returning an object of class `c("sube_batch_result", "list")` with:
  - `$results` — named list of `sube_pipeline_result` objects keyed by `group_key`
  - `$summary` — `rbindlist(fill = TRUE)` of per-group `$results$summary`
  - `$tidy` — `rbindlist(fill = TRUE)` of per-group `$results$tidy`
  - `$diagnostics` — `rbindlist(fill = TRUE)` of per-group `$diagnostics` with `group_key` appended as the 7th column (`country, year, stage, status, message, n_rows, group_key`)
  - `$call` — provenance metadata: `by`, `n_groups`, `n_errors`, `estimate`, `call` (match.call), `r_version`, `package_version`

**Internal helpers (R/pipeline.R):**

- `.batch_split(sut_data, countries, years, by)` — filters by `countries` / `years`, builds group keys per `by` mode, and returns a list of `(group_key, sut_slice)` pairs with the `sube_suts` class preserved on each slice (so downstream helpers see a valid `sube_suts`).
- `.sube_batch_result(results, summary_dt, tidy_dt, diagnostics, call_meta)` — S3 constructor; assigns `c("sube_batch_result", "list")`. Deliberately does NOT inherit from `sube_results` or `sube_pipeline_result` (matches Plan 01's class policy).
- `.batch_run_one(group, cpa_map, ind_map, inputs, estimate, dots)` — per-group pipeline wrapping build_matrices → compute_sube → (optional estimate) → unified diagnostics. Two-tier resilience: (1) compute_sube is wrapped in `tryCatch` so deep "Input rows do not align..." errors become `stage="compute"` / `status="error"` diagnostic rows; (2) the entire helper body is wrapped in `tryCatch` as a safety net — any programming error becomes a `stage="pipeline"` / `status="error"` row.
- `.emit_batch_warning(diagnostics, n_errors, n_groups)` — ONE `warning()` per batch when `n_errors > 0` OR any non-`"ok"` status exists. Wording: `"Batch completed with {n_errors} error(s) across {n_groups} group(s); issues: {count status}, ....  See result$diagnostics for details."` Silent when batch is entirely clean.

**Pitfall 10 guard:** `cpa_map`, `ind_map`, and `inputs` are `data.table::copy()`'d at batch entry so caller objects are never mutated by downstream `.standardize_names()` / `setnames()` calls inside `build_matrices()` / `compute_sube()`.

**Test coverage (tests/testthat/test-pipeline.R):** 11 new `test_that` blocks appended (25 total in the file):

Task 1 (signature, splitter, S3 class — 6 blocks):
1. `batch_sube` is exported
2. Errors on non-`sube_suts` input
3. `.batch_split` groups correctly by `country_year` (D-8.8 default)
4. `.batch_split` groups correctly by `country`
5. `.batch_split` groups correctly by `year`
6. Stub loop returns well-formed `sube_batch_result` with correct shape

Task 2 (per-group processing, resilience, merging — 5 blocks):
7. Happy path on 2-year duplicated fixture: 2 groups, merged `$summary`/`$tidy`, `$call$n_groups == 2`, `$call$n_errors == 0`
8. Per-group error resilience: 2021-only input missing → `AAA_2021` errors but `AAA_2020` succeeds; batch still returns
9. Summary warning fires exactly once with expected wording pattern
10. Merged `$diagnostics` has 7 columns in correct order with `group_key` populated for every row
11. Pitfall 10 guard: caller's `cpa_map` column names unchanged after batch

## Verification Results

- `Rscript -e 'devtools::test(filter = "pipeline", stop_on_failure = TRUE)'` — 87 pass / 0 fail / 2 skip (FIGARO E2E skips are gated `SUBE_FIGARO_DIR`; unchanged).
- `Rscript -e 'devtools::test(stop_on_failure = TRUE)'` — 195 pass / 0 fail / 7 expected skip.
- `grep -c "^export(batch_sube)$" NAMESPACE` → 1.
- `grep -c "^batch_sube <- function(" R/pipeline.R` → 1.
- `grep -c "^\.batch_split <- function" R/pipeline.R` → 1.
- `grep -c "^\.sube_batch_result <- function" R/pipeline.R` → 1.
- `grep -c "^\.batch_run_one <- function" R/pipeline.R` → 1.
- `grep -c "^\.emit_batch_warning <- function" R/pipeline.R` → 1.
- `grep -c "^test_that(" tests/testthat/test-pipeline.R` → 25 (>= 25 required).
- Live `batch_sube()` call on 2-year duplicated fixture:
  - `identical(names(r$diagnostics), c("country","year","stage","status","message","n_rows","group_key"))` → TRUE
  - `r$call$n_groups == 2`, `r$call$n_errors == 0`
- Live error-path call (2021-only inputs vs 2-year SUT):
  - `"AAA_2021" %in% r$diagnostics[status == "error"]$group_key` → TRUE
  - `r$call$n_errors == 1`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `errored` detection extended to include compute-stage errors**

- **Found during:** Task 2 error-resilience test (`AAA_2021` forced to fail by supplying 2020-only inputs).
- **Issue:** Plan's `.batch_run_one` sketch returned `errored = FALSE` on the success path and only set `errored = TRUE` in the outer `tryCatch` error handler. But the resilient `compute_sube` wrap converts deep `"Input rows do not align..."` errors into `stage = "compute"` / `status = "error"` diagnostic rows — those do NOT raise through the outer `tryCatch`, so a group with a compute-stage error would have `errored = FALSE` and `n_errors` would under-count by exactly the number of compute-deep-error groups. The D-8.7 contract ("a failing group appends a diagnostics row ... and the loop continues") and the test assertion (`res$call$n_errors == 1` when `AAA_2021` fails) both require compute-stage errors to be counted.
- **Fix:** Added `errored <- any(diagnostics$status == "error")` on the success path, immediately before returning the success-path list. Programming errors still surface via the outer `tryCatch` with `errored = TRUE`; compute-stage errors now also count via this flag. The two mechanisms are complementary, not duplicative.
- **Files modified:** R/pipeline.R (`.batch_run_one`)
- **Commit:** 6349eeb

**2. [Rule 3 - Blocking issue] `.emit_batch_warning()` hardened against empty diagnostics + nonzero errors**

- **Found during:** Task 2 implementation review — plan's sketch for `.emit_batch_warning()` had a subtle branching bug where if `diagnostics` had zero rows but `n_errors > 0`, the early `return(invisible(NULL))` would fire and suppress the warning.
- **Fix:** Rewrote the guards so the function stays silent only when BOTH the diagnostics are empty AND `n_errors == 0`. When either is non-empty, the warning fires, with `"none"` substituted for the per-status counts if the bad-subset is empty. In practice this edge case doesn't occur (every errored group adds at least one row), but the guard is cheap defensive wording.
- **Files modified:** R/pipeline.R (`.emit_batch_warning`)
- **Commit:** 6349eeb

**3. [Rule 3 - Blocking issue] `.batch_split` year-mode sorts years before stringifying**

- **Found during:** Task 1 GREEN — plan's sketch used `as.character(unique(ids$YEAR))`. `unique()` preserves insertion order from the data.table, which is not guaranteed to be sorted. The `.batch_split by year` test asserted a `setequal` comparison (so sorting didn't change the test outcome), but a reader of the group_keys would reasonably expect "2020, 2021" order, not insertion order.
- **Fix:** Changed to `as.character(sort(unique(ids$YEAR)))`. Stable ordering makes downstream iteration predictable (e.g. if a user does `names(result$results)` they get ascending years).
- **Files modified:** R/pipeline.R (`.batch_split`)
- **Commit:** a50ac06

**4. [Rule 3 - Test API] `batch_sube()` calls in tests that might warn must be wrapped in `suppressWarnings()`**

- **Found during:** Task 1 test authoring — the "batch_sube with stub loop returns ... correct shape" test called `batch_sube()` on the shipped fixture. The shipped `inputs.csv` has the same `I01`/`I02` vs `I1`/`I2` industry misalignment flagged in Plan 01's SUMMARY §"Deviations", so the per-group call triggers the `inputs_misaligned` detection and the `.emit_batch_warning()` path. Plan's test code did not wrap in `suppressWarnings()`.
- **Fix:** Wrapped the `batch_sube()` calls in `suppressWarnings()` throughout Task 1 and Task 2 tests where the shipped fixture is used without the 2-year duplication (which happens to be clean). This is pure test-infrastructure hygiene; the warning assertion tests still use `tryCatch(..., warning = function(w) w)` to capture and inspect the warning.
- **Files modified:** tests/testthat/test-pipeline.R
- **Commit:** 7cdb1c6 (RED), a50ac06 (GREEN)

### Out-of-Scope Observations (not fixed)

The shipped `inputs.csv` industry-code mismatch (called out in Plan 01 SUMMARY) still fires the `inputs_misaligned` detection here. Any batch run on the single-year shipped fixture therefore emits the summary warning — which is the correct behaviour (Phase 8's CONV-03 contract is to surface this silent failure). The fixture-level fix is a docs/product decision outside Phase 8 scope.

## Commits

| Hash    | Type | Message |
| ------- | ---- | ------- |
| 7cdb1c6 | test | add failing tests for batch_sube signature, splitter, S3 class |
| a50ac06 | feat | add batch_sube signature, splitter, and S3 constructor |
| 6573dd6 | test | add failing tests for per-group processing and resilience |
| 6349eeb | feat | implement batch_sube per-group processing and merging |

## Known Stubs

None. Every data-flow path is wired end-to-end. Empty-batch handling returns a schema-correct `sube_batch_result` (empty `$results` list, empty `$summary`/`$tidy`, `.empty_diagnostics()` with `group_key` column, `$call$n_groups == 0`). `$models` per group is intentionally `NULL` when `estimate = FALSE` or `model_data` is empty — documented contract behaviour (D-8.4), not a stub.

## Self-Check: PASSED

- FOUND: /home/zenz/R/sube/R/pipeline.R (728 lines, up from 371 at Plan 01 close)
- FOUND: /home/zenz/R/sube/NAMESPACE (export(batch_sube) line present, alphabetically before build_matrices)
- FOUND: /home/zenz/R/sube/tests/testthat/test-pipeline.R (25 test_that blocks total, up from 14 at Plan 01 close)
- FOUND: commit 7cdb1c6 (RED for Task 1)
- FOUND: commit a50ac06 (GREEN for Task 1)
- FOUND: commit 6573dd6 (RED for Task 2)
- FOUND: commit 6349eeb (GREEN for Task 2)
- VERIFIED: `devtools::test(filter = "pipeline")` 87 pass / 0 fail / 2 expected skip
- VERIFIED: `devtools::test()` full suite 195 pass / 0 fail / 7 expected skip
- VERIFIED: Live batch call on 2-year duplicated fixture — 2 groups, both ok, `n_errors == 0`
- VERIFIED: Live batch call with inputs missing 2021 — `AAA_2021` errored, `AAA_2020` succeeded, batch still returned, `n_errors == 1`
- VERIFIED: Pitfall 10 guard — caller's `cpa_map` column names unchanged after batch
