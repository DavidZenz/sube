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
