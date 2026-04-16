---
phase: 08-convenience-helpers
plan: 01
subsystem: r-pipeline-wrapper
tags:
  - r-package
  - pipeline
  - diagnostics
  - conv-01
  - conv-03
requires:
  - R/compute.R::compute_sube
  - R/matrices.R::build_matrices
  - R/import.R::import_suts
  - R/import.R::read_figaro
  - R/import.R::extract_domestic_block
  - R/models.R::estimate_elasticities
  - R/utils.R (.standardize_names, .sube_required_columns)
provides:
  - R/pipeline.R::run_sube_pipeline (exported)
  - R/pipeline.R::.sube_pipeline_result (S3 constructor)
  - R/pipeline.R::.empty_diagnostics (6-col unified schema helper)
  - R/pipeline.R::.validate_pipeline_inputs (upfront validation)
  - R/pipeline.R::.detect_coerced_na (D-8.11 #3)
  - R/pipeline.R::.detect_skipped_alignment (D-8.9)
  - R/pipeline.R::.detect_inputs_misaligned (D-8.11 #4)
  - R/pipeline.R::.extend_compute_diagnostics (D-8.11 #1)
  - R/pipeline.R::.emit_pipeline_warning (D-8.10)
affects:
  - NAMESPACE (+1 export line)
  - tests/testthat/test-pipeline.R (+14 test_that blocks, new file)
tech-stack:
  added: []
  patterns:
    - S3 class c("sube_pipeline_result", "list") — no inheritance from sube_results (RESEARCH §3 Open Item 1)
    - data.table::copy() before .standardize_names() — avoids Pitfall 10 mutation
    - resilient tryCatch wrap on compute_sube — deep alignment errors become diagnostic rows
    - named-vector lookup for status->message mapping (fcase default-scalar limitation)
key-files:
  created:
    - R/pipeline.R
    - tests/testthat/test-pipeline.R
  modified:
    - NAMESPACE
decisions:
  - "D-8.1 path-only input signature honoured; FIGARO routes through read_figaro via ... year/final_demand_vars"
  - "D-8.2 explicit source=c('wiod','figaro') with match.arg; no auto-detect"
  - "D-8.3 sube_pipeline_result class with $results/$models/$diagnostics/$call fields"
  - "D-8.4 estimate=FALSE default; estimate_elasticities only runs when model_data has rows"
  - "D-8.9 + D-8.11 all four diagnostic categories detected inside pipeline with no modifications to compute_sube/build_matrices"
  - "D-8.10 exactly one warning() per run, status counts sorted descending"
  - "D-8.12 6-column diagnostics schema (country, year, stage, status, message, n_rows) in that order"
  - "Upfront inputs validation fires before importer (RESEARCH §3 Open Item 6)"
  - "resilient compute_sube wrap added: deep 'Input rows do not align...' errors now surface as stage=compute/status=error diagnostic rows instead of bubbling (Rule 3 blocking-issue fix)"
metrics:
  duration: "~8 min"
  completed: 2026-04-16
  tasks_completed: 3
  commits: 5
  files_created: 2
  files_modified: 1
  tests_added: 14
  regressions: 0
---

# Phase 08 Plan 01: pipeline-core Summary

Delivered `run_sube_pipeline()` — the one-call CONV-01 wrapper chaining import → domestic filter → matrix construction → compute (optionally → estimate) — together with the unified CONV-03 `$diagnostics` machinery that detects all four D-8.11 categories inside the pipeline without touching the frozen Phase 5–7 core functions.

## What Shipped

**Exported function:**

- `run_sube_pipeline(path, cpa_map, ind_map, inputs, source, domestic_only, estimate, ...)` — end-to-end wrapper returning an object of class `c("sube_pipeline_result", "list")` with `$results` (sube_results), `$models` (sube_models or NULL), `$diagnostics` (6-col unified table), and `$call` (provenance metadata: source, path, n_countries, n_years, estimate, match.call snapshot, r_version, package_version).

**Internal helpers (R/pipeline.R):**

- `.empty_diagnostics()` — returns the D-8.12 6-column schema as an empty data.table. Column order is load-bearing for `rbindlist(fill = TRUE)`.
- `.sube_pipeline_result()` — S3 constructor; assigns `c("sube_pipeline_result", "list")`. Deliberately does NOT inherit from `sube_results` (RESEARCH §3 Open Item 1).
- `.validate_pipeline_inputs()` — runs `.standardize_names()` on a `data.table::copy()` of inputs, then `.sube_required_columns(c("YEAR","REP","GO"))`, then checks for an industry identifier column. Fires BEFORE the importer so deep errors surface early.
- `.detect_coerced_na(sut_raw)` — counts `sum(is.na(sut_raw$VALUE))` post-import; emits a pipeline-level aggregate row with `stage="import"`, `status="coerced_na"`, `country=NA`, `year=NA`, `n_rows=<count>`. FIGARO primary-input rows are dropped at `R/import.R:247` before coercion at `:255`, so no double-counting.
- `.detect_skipped_alignment(sut, matrix_bundle)` — diffs `paste(REP, YEAR, sep="_")` input keys vs `names(matrix_bundle$matrices)`; emits `stage="build"`, `status="skipped_alignment"` rows per dropped country-year.
- `.detect_inputs_misaligned(sut, inputs, matrix_bundle)` — joint-merges SUT ids × inputs ids, then anti-joins against `model_data[, .(YEAR, REP=COUNTRY)]`; emits `stage="build"`, `status="inputs_misaligned"` rows. Model_data column is `COUNTRY` (not `REP`), per `R/matrices.R:179`.
- `.extend_compute_diagnostics(compute_diag)` — stamps `stage="compute"`, fills concrete per-status `message` text, adds `n_rows=NA_integer_`, and reorders to the unified schema. Used as pass-through for the existing `singular_supply`/`singular_go`/`singular_leontief` categories.
- `.emit_pipeline_warning(diagnostics)` — ONE `warning()` per run naming counts per non-"ok" status category, sorted descending. Silent when `nrow == 0` or all statuses are "ok".

**Resilience:** `compute_sube` is called inside a `tryCatch` so its deep "Input rows do not align for {country} {year}." stop() does NOT bubble to the researcher. Instead, the pipeline appends a `stage="compute"`, `status="error"` diagnostic row and returns a well-formed empty `sube_results` shell so `result$results$summary` stays defined.

**Test coverage (tests/testthat/test-pipeline.R):** 14 `test_that` blocks:

1. `run_sube_pipeline` is exported
2. `.empty_diagnostics` has the D-8.12 schema
3. Upfront inputs validation (missing GO)
4. Happy path returns well-formed `sube_pipeline_result` on sample data
5. `coerced_na` category detection
6. `skipped_alignment` category detection
7. `inputs_misaligned` category detection
8. `.extend_compute_diagnostics` round-trip (singular_supply → concrete message)
9. `.emit_pipeline_warning` silence + emission behaviour
10. Summary warning emitted exactly once with correct wording pattern
11. `estimate = TRUE` attaches `sube_models` when model_data non-empty
12. `estimate = FALSE` leaves `$models` NULL
13. FIGARO source end-to-end on `inst/extdata/figaro-sample/` (3 countries DE/FR/IT)
14. `$call` provenance metadata

## Verification Results

- `devtools::test(filter = "pipeline", stop_on_failure = TRUE)` — 14 blocks green.
- `devtools::test(stop_on_failure = TRUE)` — 164 pass / 0 fail / 5 skip (skips are gated `SUBE_WIOD_DIR` / `SUBE_FIGARO_DIR` paths; unchanged from baseline).
- `grep -c "^export(run_sube_pipeline)$" NAMESPACE` → 1.
- `grep -c "^\.detect_coerced_na <- function" R/pipeline.R` → 1 (same for the other three detection helpers and `.emit_pipeline_warning`).
- Live run on sample data returns `inherits(x, "sube_pipeline_result") == TRUE` and `inherits(x$results, "sube_results") == TRUE`.
- FIGARO path on synthetic fixture yields `nrow(result$results$summary) > 0` with `unique(COUNTRY) == {DE, FR, IT}`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Defensive wrap on `compute_sube`**

- **Found during:** Task 2 (the `inputs_misaligned` category test)
- **Issue:** Plan's `inputs_misaligned` test scenario corrupts `inputs[, INDUSTRY := "NOMATCH"]`, which makes `build_matrices` produce empty `model_data` AND makes `compute_sube` deep-fail at lines 58–62 with `"Input rows do not align with matrix industries for AAA 2020."`. The plan's Task 2 actions did not add a `tryCatch` around `compute_sube`, so the pipeline would have bubbled the hard error before diagnostics could be assembled — making the test impossible to pass without mutating `compute_sube` (a frozen Phase 5–7 contract).
- **Fix:** Wrapped `compute_sube` in `tryCatch`; on error, append a `stage="compute"`, `status="error"` diagnostic row via `<<-` into `diag_build` (accumulated pre-compute) and return an empty `sube_results` shell so `$results$summary` stays defined. This mirrors `D-8.7`'s batch-level resilience philosophy applied at the pipeline level.
- **Files modified:** R/pipeline.R (step 7 block).
- **Commit:** b572ee7

**2. [Rule 1 - Test expectation bug] Plan's happy-path assertions did not match shipped-fixture reality**

- **Found during:** Task 2 happy-path test.
- **Issue:** Plan asserted `all(res$diagnostics$status == "ok")` on the `sube_example_data()` happy path. In practice, the shipped `inst/extdata/sample/inputs.csv` uses aggregated industry codes (`I01`, `I02`) while `sut_data.csv` uses raw VAR codes (`I1`, `I2`). `build_matrices()` model_data therefore returns empty (industry join never aligns) — which is exactly the silent failure D-8.11 #4 is designed to surface. The new `inputs_misaligned` detection correctly fires on the shipped fixture.
- **Fix:** Adjusted the happy-path test to assert the *actual* correct behaviour: `compute_sube` produces one `ok` row; `inputs_misaligned` legitimately fires at the build stage. The original plan's assertion was wrong about the fixture, not about the detection logic.
- **Files modified:** tests/testthat/test-pipeline.R
- **Commit:** b572ee7

**3. [Rule 1 - Test expectation bug] `expect_no_warning` on happy path was incompatible with fixture reality**

- **Found during:** Task 3 warning-emission tests.
- **Issue:** Plan's `expect_no_warning(run_sube_pipeline(... sample data ...))` assumed the happy path emits no warning. Since (per deviation #2) the happy path legitimately produces an `inputs_misaligned` row, the summary warning correctly fires.
- **Fix:** Replaced with a unit test on `.emit_pipeline_warning(clean_diag)` — a crafted all-"ok" diagnostics table — which achieves the same contract coverage ("no warning when all statuses are ok") without depending on fixture alignment. Also asserted the positive case: `.emit_pipeline_warning(dirty_diag)` emits exactly the expected message pattern.
- **Files modified:** tests/testthat/test-pipeline.R
- **Commit:** 226ce79

**4. [Rule 1 - API compatibility] `data.table::fcase` `default` argument requires scalar**

- **Found during:** Task 2 `.extend_compute_diagnostics` unit test.
- **Issue:** Plan's action specified `default = as.character(status)` in `fcase()`, which is a vector (length equals `nrow`). `fcase()` requires `default` to be scalar (length 1).
- **Fix:** Replaced `fcase` with a named-vector lookup (`message_map[raw_status]`) plus in-place vectorised fallback for unknown statuses. Functionally identical; avoids the `fcase` scalar constraint.
- **Files modified:** R/pipeline.R (`.extend_compute_diagnostics` helper)
- **Commit:** b572ee7

### Out-of-Scope Observations (not fixed)

The shipped sample data's `inputs.csv` uses pre-aggregated industry codes (`I01`, `I02`) that do not match the raw VAR codes (`I1`, `I2`) in `sut_data.csv`. This is a data-fixture mismatch that has been silent until now. Phase 8's D-8.11 #4 detection correctly surfaces it. Whether to re-align the shipped fixture or leave it as an illustrative example of the diagnostic's value is a product/docs decision outside Phase 8's scope.

## Commits

| Hash | Type | Message |
|------|------|---------|
| 11cb8bd | test | add failing test for run_sube_pipeline skeleton |
| acb1178 | feat | add run_sube_pipeline skeleton with unified diagnostics schema |
| b572ee7 | feat | wire the four CONV-03 diagnostic detections |
| 1ff68e6 | test | add failing tests for estimate wiring, summary warning, FIGARO path |
| 226ce79 | feat | add estimate=TRUE wiring and summary warning emission |

## Known Stubs

None. All data flow paths are wired end-to-end; no placeholder empty values flow to user-facing results. The opt-in `$models` field is intentionally `NULL` when `estimate = FALSE` or `model_data` is empty — this is documented contract behaviour (D-8.4), not a stub.

## Self-Check: PASSED

- FOUND: /home/zenz/R/sube/R/pipeline.R (371 lines)
- FOUND: /home/zenz/R/sube/tests/testthat/test-pipeline.R (257 lines, 14 test_that blocks)
- FOUND: /home/zenz/R/sube/NAMESPACE (export(run_sube_pipeline) present)
- FOUND: commit 11cb8bd (test RED for Task 1)
- FOUND: commit acb1178 (Task 1 GREEN)
- FOUND: commit b572ee7 (Task 2 GREEN)
- FOUND: commit 1ff68e6 (test RED for Task 3)
- FOUND: commit 226ce79 (Task 3 GREEN)
- VERIFIED: `devtools::test()` 164 pass / 0 fail / 5 expected skip
- VERIFIED: Live pipeline call on sample data returns `sube_pipeline_result` with inner `sube_results`
- VERIFIED: FIGARO path succeeds on synthetic fixture with 3 countries (DE, FR, IT)
