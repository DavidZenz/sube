---
phase: 07-figaro-e2e-validation
plan: 03
type: execute
wave: 2
depends_on:
  - "07-01"
  - "07-02"
files_modified:
  - tests/testthat/helper-gated-data.R
  - tests/testthat/test-figaro-pipeline.R
autonomous: true
requirements:
  - FIG-E2E-02
tags:
  - testing
  - figaro
  - pipeline

must_haves:
  truths:
    - "tests/testthat/helper-gated-data.R exports build_nace_section_map() that returns a list(cpa_map, ind_map) via substr(code, 1, 1) derivation"
    - "tests/testthat/helper-gated-data.R exports build_figaro_pipeline_fixture_from_synthetic() that reads inst/extdata/figaro-sample/, pipes through read_figaro → extract_domestic_block → build_matrices → compute_sube, and returns the full pipeline bundle"
    - "tests/testthat/test-figaro-pipeline.R exists with a `[FIG-E2E-02]`-labelled test_that block that runs on every CRAN/CI build with no env-var guard"
    - "The synthetic-fixture contract test asserts pipeline completion (class sube_results), correct country coverage (DE, FR, IT), non-empty summary rows, non-NA GO column, all diagnostics status == ok"
    - "devtools::test(filter = 'figaro-pipeline') runs and the synthetic contract block passes green"
  artifacts:
    - path: "tests/testthat/helper-gated-data.R"
      provides: "build_nace_section_map(), build_figaro_pipeline_fixture_from_synthetic()"
      contains: "build_nace_section_map"
    - path: "tests/testthat/test-figaro-pipeline.R"
      provides: "FIG-E2E-02 contract test on the synthetic fixture (non-gated). File also hosts the FIG-E2E-01 gated block added by plan 07-04."
      contains: "FIG-E2E-02"
  key_links:
    - from: "tests/testthat/test-figaro-pipeline.R"
      to: "inst/extdata/figaro-sample/"
      via: "system.file() + read_figaro()"
      pattern: "figaro-sample"
    - from: "tests/testthat/helper-gated-data.R build_figaro_pipeline_fixture_from_synthetic()"
      to: "sube::compute_sube"
      via: "full-pipeline call chain"
      pattern: "compute_sube\\("
---

<objective>
Deliver FIG-E2E-02: a contract test that pushes the extended synthetic
FIGARO fixture (from plan 07-02) through the full `read_figaro →
extract_domestic_block → build_matrices → compute_sube` pipeline on
every CRAN/CI build with no external data. Ship two reusable helpers
in `helper-gated-data.R` (renamed in plan 07-01) — a section-letter
mapping builder and a synthetic-fixture pipeline runner — that plan
07-04 will also consume for the gated real-data branch.

Purpose: Proves the pipeline works on realistic inputs on every build,
catches regressions in any of the four functions in the chain, and
establishes the scaffolding (helpers + test file) that the gated
real-data test in plan 07-04 grafts onto.

Output: two new helper functions, one new test file hosting a single
synthetic-contract `test_that` block, zero env-var dependency, green
under `devtools::test(filter = "figaro-pipeline")`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md
@.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md
@.planning/phases/07-figaro-e2e-validation/07-VALIDATION.md

# Prior-plan outputs this plan consumes
@.planning/phases/07-figaro-e2e-validation/07-01-SUMMARY.md
@.planning/phases/07-figaro-e2e-validation/07-02-SUMMARY.md

# Source code referenced during execution
@R/import.R
@R/compute.R
@R/matrices.R
@tests/testthat/helper-gated-data.R
</context>

<interfaces>
<!-- build_matrices() signature (R/matrices.R:32) -->
build_matrices(sut_data, cpa_map, ind_map, final_demand_var = "FU_bas", inputs = NULL)
  → returns list(aggregated, final_demand, matrices, [model_data]) with class "sube_matrices"

<!-- compute_sube() signature (R/compute.R:17-22) -->
compute_sube(matrix_bundle, inputs, metrics = c("GO","VA","EMP","CO2"),
             diagonal_adjustment = 1, zero_replacement = 1e-6)
  → returns list(summary, tidy, diagonals, matrices) with class "sube_results"

<!-- Critical: compute_sube errors if metric columns are missing from inputs
     (R/compute.R:35-38). Default metrics = c("GO","VA","EMP","CO2"). For the
     synthetic fixture we can supply all four, or pass metrics = "GO" for the
     minimal GO-only path matching A3 escalation. Choice: supply all four so
     the contract test exercises the elasticity code path too. -->

<!-- compute_sube expects inputs rows matched per (YEAR, REP, INDUSTRY) against
     bundle$industries. bundle$industries comes from sort(unique(aggregated$INDagg))
     = sorted section letters A/C/F/G (4 entries after D-7.1 aggregation). -->

<!-- Existing helper file shape after plan 07-01:
     tests/testthat/helper-gated-data.R contains:
       - resolve_wiod_root()
       - resolve_figaro_root()
       - build_replication_fixtures()
     This plan APPENDS two functions to the same file. -->

<!-- Per RESEARCH § Derive the section-letter map (code block) + Pitfall 5:
     cpa_map and ind_map must have DIFFERENT column names so .coerce_map()
     routes them correctly. cpa_map: (CPA, CPAagg). ind_map: (NACE, INDagg). -->

<!-- Per RESEARCH Pitfall 5 + FIG-04 test pattern (test-figaro.R:183-189):
     return a list(cpa_map, ind_map) with correct column names. -->

Target function signatures (to be added to helper-gated-data.R):

```r
# Derive cpa_map + ind_map from a character vector of CPA codes per D-7.1
# (section-letter equivalence via substr(code, 1, 1)).
# Returns list(cpa_map, ind_map) — note different column names on each so
# .coerce_map()'s NACE synonym routes them correctly (see Pitfall 5).
build_nace_section_map <- function(codes) {
  sections <- substr(codes, 1L, 1L)
  list(
    cpa_map = data.table::data.table(CPA = codes, CPAagg = sections),
    ind_map = data.table::data.table(NACE = codes, INDagg = sections)
  )
}

# Run the full FIGARO pipeline against the shipped synthetic fixture.
# Returns list(sut, domestic, bundle, result) — all intermediates preserved
# for FIG-E2E-02 structural assertions.
build_figaro_pipeline_fixture_from_synthetic <- function() {
  fixture_dir <- system.file("extdata", "figaro-sample", package = "sube")
  stopifnot(nzchar(fixture_dir))

  sut <- sube::read_figaro(fixture_dir, year = 2023L)
  domestic <- sube::extract_domestic_block(sut)

  # D-7.1: section-letter aggregation. Note: domestic$VAR includes FU_bas
  # (per read_figaro synth); the industry map should cover only the
  # non-FD VAR values. Intersect with domestic$CPA to ensure equivalence.
  codes <- sort(unique(c(domestic$CPA,
                         setdiff(domestic$VAR, "FU_bas"))))
  maps <- build_nace_section_map(codes)

  # Aggregated industries from the section map: A, C, F, G.
  agg_inds <- sort(unique(maps$ind_map$INDagg))
  countries <- sort(unique(domestic$REP))

  # Synthetic inputs: GO/VA/EMP/CO2 with sane ratios per (country, aggregated industry).
  inputs <- data.table::CJ(YEAR = 2023L, REP = countries,
                           INDUSTRY = agg_inds, sorted = FALSE)
  inputs[, GO  := seq(100, by = 10, length.out = nrow(inputs))]
  inputs[, VA  := GO * 0.4]
  inputs[, EMP := GO * 0.1]
  inputs[, CO2 := GO * 0.05]

  bundle <- sube::build_matrices(domestic, maps$cpa_map, maps$ind_map)
  result <- sube::compute_sube(bundle, inputs,
                               metrics = c("GO", "VA", "EMP", "CO2"))

  list(sut = sut, domestic = domestic, bundle = bundle, result = result)
}
```

Target test file shape (tests/testthat/test-figaro-pipeline.R):

```r
# tests/testthat/test-figaro-pipeline.R
# Phase 7 — FIGARO end-to-end pipeline tests.
# - FIG-E2E-02 (this plan 07-03): synthetic-fixture contract, runs on every build.
# - FIG-E2E-01 (plan 07-04):      gated SUBE_FIGARO_DIR test + golden snapshot.
library(testthat)

test_that("FIGARO pipeline completes on synthetic fixture (FIG-E2E-02)", {
  pipeline <- build_figaro_pipeline_fixture_from_synthetic()

  # Pipeline classes intact at every stage
  expect_s3_class(pipeline$sut,      "sube_suts")
  expect_s3_class(pipeline$domestic, "sube_domestic_suts")
  expect_s3_class(pipeline$bundle,   "sube_matrices")
  expect_s3_class(pipeline$result,   "sube_results")

  # Structural invariants on the final result
  expect_gt(nrow(pipeline$result$summary), 0L)
  expect_setequal(unique(pipeline$result$summary$COUNTRY), c("DE", "FR", "IT"))
  expect_true(all(!is.na(pipeline$result$summary$GO)))
  expect_true(all(pipeline$result$diagnostics$status == "ok"))

  # Aggregation worked — section letters, not raw codes
  expect_true(all(pipeline$result$summary$CPAagg %in% c("A", "C", "F", "G")))
})
```
</interfaces>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Append build_nace_section_map() + build_figaro_pipeline_fixture_from_synthetic() to helper-gated-data.R</name>
  <files>tests/testthat/helper-gated-data.R</files>
  <behavior>
    - `build_nace_section_map(c("A01", "C10T12", "F", "G46"))` returns a list with `cpa_map` (columns: CPA, CPAagg) and `ind_map` (columns: NACE, INDagg); both map codes to their first character
    - `build_figaro_pipeline_fixture_from_synthetic()` runs without error against the extended fixture from plan 07-02
    - The returned list contains four elements (sut, domestic, bundle, result) with correct classes
    - `result$summary` has rows for all three countries (DE, FR, IT)
    - `result$diagnostics$status` is all "ok"
  </behavior>
  <action>
    Per RESEARCH § "Derive the section-letter map" + § "Build the FIGARO
    gated-test fixture" + Pitfall 5.

    Append the two functions exactly as specified in the `<interfaces>` block
    above to `tests/testthat/helper-gated-data.R` (AFTER
    `build_replication_fixtures()`, BEFORE end of file).

    Key design notes preserved in the code comments:
    - `cpa_map` column is `CPA`; `ind_map` column is `NACE` — different names
      are required so `.coerce_map()` (R/utils.R:44-49) routes them via the
      correct synonym table. Otherwise `ind_map` would fall through positional
      matching and silently misalign.
    - The `codes` union uses `sort(unique(c(domestic$CPA, setdiff(domestic$VAR, "FU_bas"))))`
      because D-7.1 equivalence holds: the CPA codes and industry codes
      (`VAR` minus `FU_bas`) are drawn from the same NACE A*64 pool.
    - `metrics = c("GO","VA","EMP","CO2")` exercises the full elasticity
      branch in `compute_sube()` (R/compute.R:95-106). This is stronger than
      the metrics = "GO" path in A3's synthesis story; use the stronger path
      here because the synthetic fixture ships VA/EMP/CO2 via `inputs`.
    - `YEAR = 2023L` is hardcoded — the synthetic fixture is tagged with 2023
      at import (per `read_figaro(..., year = 2023)` in test-figaro.R:37).
  </action>
  <verify>
    <automated>Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); maps <- build_nace_section_map(c("A01", "C10T12", "F")); stopifnot(identical(maps$cpa_map$CPAagg, c("A","C","F")), identical(names(maps$ind_map), c("NACE","INDagg"))); pipeline <- build_figaro_pipeline_fixture_from_synthetic(); stopifnot(inherits(pipeline$result, "sube_results"), all(pipeline$result$diagnostics$status == "ok"), setequal(pipeline$result$summary$COUNTRY, c("DE","FR","IT")))'</automated>
  </verify>
  <done>
    Both functions exist in `helper-gated-data.R`; `build_nace_section_map()` returns a list with correctly-named columns; `build_figaro_pipeline_fixture_from_synthetic()` runs end-to-end on the synthetic fixture and returns `sube_results` with all three countries and `status == "ok"` diagnostics.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Create tests/testthat/test-figaro-pipeline.R with the FIG-E2E-02 synthetic contract block</name>
  <files>tests/testthat/test-figaro-pipeline.R</files>
  <behavior>
    - `devtools::test(filter = "figaro-pipeline")` discovers and runs exactly one `test_that` block
    - The block runs WITHOUT requiring `SUBE_FIGARO_DIR` — it's ungated, unlike the plan-07-04 block to come
    - All expectations green: pipeline classes (sut_suts, sube_domestic_suts, sube_matrices, sube_results), summary non-empty, all three countries present, non-NA GO, all diagnostics ok, CPAagg in {A,C,F,G}
  </behavior>
  <action>
    Per RESEARCH Pattern 1 (adapted: no gate here — this is the synthetic
    block) + FIG-E2E-02 requirement + VALIDATION.md Wave 0 requirement.

    Create `tests/testthat/test-figaro-pipeline.R` with the shape shown in
    the `<interfaces>` block.

    Two design notes for the executor:

    1. **Include a file-header comment block** that flags both blocks to
       come (FIG-E2E-02 now, FIG-E2E-01 from plan 07-04). This avoids the
       plan-07-04 executor wondering whether to create a new file.

    2. **Do NOT add the FIG-E2E-01 gated block in this task** — that is
       plan 07-04's scope. This file ships with exactly one `test_that`
       block after this task.

    3. The `build_figaro_pipeline_fixture_from_synthetic()` call is
       memoisation-free — the synthetic-fixture pipeline is cheap (all four
       functions combined should finish in ~100ms on this fixture size, per
       RESEARCH § Test Infrastructure). No caching closure needed.

    File content:

    ```r
    # tests/testthat/test-figaro-pipeline.R
    # Phase 7 FIGARO end-to-end pipeline tests.
    #   - FIG-E2E-02 (plan 07-03, this file): synthetic-fixture contract,
    #     runs on every CRAN/CI build. No env-var guard.
    #   - FIG-E2E-01 (plan 07-04, added after 07-03 ships): gated
    #     SUBE_FIGARO_DIR real-data test with testthat snapshot. Skipped
    #     on CRAN and when env var is unset.
    library(testthat)

    test_that("FIGARO pipeline completes on synthetic fixture (FIG-E2E-02)", {
      pipeline <- build_figaro_pipeline_fixture_from_synthetic()

      # Pipeline classes intact at every stage
      expect_s3_class(pipeline$sut,      "sube_suts")
      expect_s3_class(pipeline$domestic, "sube_domestic_suts")
      expect_s3_class(pipeline$bundle,   "sube_matrices")
      expect_s3_class(pipeline$result,   "sube_results")

      # Result-shape invariants — catch regressions in any of the four stages
      expect_gt(nrow(pipeline$result$summary), 0L)
      expect_setequal(unique(pipeline$result$summary$COUNTRY),
                      c("DE", "FR", "IT"))
      expect_true(all(!is.na(pipeline$result$summary$GO)))
      expect_true(all(pipeline$result$diagnostics$status == "ok"))

      # D-7.1 section-letter aggregation actually landed
      expect_true(all(pipeline$result$summary$CPAagg %in% c("A", "C", "F", "G")))

      # Summary has expected columns from compute_sube (R/compute.R:88-106)
      expect_true(all(c("YEAR", "COUNTRY", "CPAagg", "GO", "VA", "EMP", "CO2",
                       "FD", "GOe", "VAe", "EMPe", "CO2e") %in%
                     names(pipeline$result$summary)))
    })
    ```
  </action>
  <verify>
    <automated>Rscript -e 'res <- as.data.frame(devtools::test(filter = "figaro-pipeline")); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L, sum(res$skipped) == 0L); cat("figaro-pipeline: passed =", sum(res$passed), "\n")'</automated>
  </verify>
  <done>
    `tests/testthat/test-figaro-pipeline.R` exists with exactly one `test_that` block; `devtools::test(filter = "figaro-pipeline")` reports 1 test_that block, ≥8 expectations passed, 0 failures, 0 errors, 0 skipped.
  </done>
</task>

<task type="auto">
  <name>Task 3: Full-suite regression check after adding the pipeline test file</name>
  <files>(verification only — no file writes)</files>
  <action>
    Run `Rscript -e 'devtools::test()'` and confirm:

    1. Total test count is ≥ 103 (v1.1 baseline 102 + at least 1 new block from task 2 + 8 new blocks from plan 07-01)
    2. Zero failures, zero errors
    3. `test-figaro-pipeline.R` contributes exactly 1 test_that block (FIG-E2E-02 only; FIG-E2E-01 comes in 07-04)
    4. `test-gated-data-contract.R` (plan 07-01) contributes 8 blocks

    If `build_figaro_pipeline_fixture_from_synthetic()` throws (e.g. singular
    matrix from a fixture value-tuning miss), do NOT weaken the test — instead,
    adjust the fixture value layout in plan 07-02's generator script (which
    requires re-running that plan's task 1). Fixture value issues are a
    plan-02 bug, not a plan-03 bug.
  </action>
  <verify>
    <automated>Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L); cat("total passed:", sum(res$passed), "skipped:", sum(res$skipped), "\n")'</automated>
  </verify>
  <done>
    Full suite green; synthetic FIG-E2E-02 contract test passes on every run; helpers are ready for plan 07-04 to reuse.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A — this plan adds test helpers and a test file that read only from
`inst/extdata/figaro-sample/` (shipped with the package, fully trusted
synthetic data). No external input, no network I/O, no user-supplied
content reaches the pipeline at test time.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-03 | N/A | tests/testthat/test-figaro-pipeline.R + helper-gated-data.R | accept | Test infrastructure. The `build_figaro_pipeline_fixture_from_synthetic()` helper reads only a shipped synthetic CSV — no tainted input. Failure mode is a test failure, not a security incident. |
</threat_model>

<verification>
- `devtools::test(filter = "figaro-pipeline")` — 1 test_that block green
- `devtools::test()` full suite — zero failures
- `build_nace_section_map()` returns list with cpa_map (CPA, CPAagg) and ind_map (NACE, INDagg) column names
- `build_figaro_pipeline_fixture_from_synthetic()` exercises all four pipeline stages without error
</verification>

<success_criteria>
- [ ] `build_nace_section_map()` exists in helper-gated-data.R, correct column names on both outputs
- [ ] `build_figaro_pipeline_fixture_from_synthetic()` exists in helper-gated-data.R, returns all four pipeline stages
- [ ] `tests/testthat/test-figaro-pipeline.R` exists with exactly one `test_that` block (FIG-E2E-02)
- [ ] File header comment flags the future FIG-E2E-01 block for plan 07-04
- [ ] `devtools::test(filter = "figaro-pipeline")` green with 0 skipped
- [ ] `devtools::test()` full suite zero failures
</success_criteria>

<output>
After completion, create `.planning/phases/07-figaro-e2e-validation/07-03-SUMMARY.md`
</output>
