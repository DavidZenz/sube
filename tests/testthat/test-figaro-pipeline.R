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

# ---- FIG-E2E-01: gated real-data test + golden snapshot ------------------

# Memoised fixture builder — runs the real-data pipeline at most once per
# test-file invocation so both gated test_that blocks below can reuse the
# bundle without paying the full-pipeline cost twice.
.figaro_real_bundle <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      root <- resolve_figaro_root()
      if (!nzchar(root)) return(NULL)
      cache <<- build_figaro_pipeline_fixture_from_real(
        root,
        countries = c("DE", "FR", "IT", "NL"),
        year = 2023L
      )
    }
    cache
  }
})

test_that("FIGARO pipeline matches golden snapshot on real data (FIG-E2E-01)", {
  testthat::skip_on_cran()
  root <- resolve_figaro_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_FIGARO_DIR not set — FIGARO E2E test skipped"
  )

  bundle <- .figaro_real_bundle()
  testthat::skip_if(is.null(bundle), "FIGARO pipeline fixture build failed")

  # Structural invariants — catch logic regressions on real data
  expect_s3_class(bundle$result, "sube_results")
  expect_gt(nrow(bundle$result$summary), 0L)
  expect_setequal(unique(bundle$result$summary$COUNTRY),
                  c("DE", "FR", "IT", "NL"))
  expect_true(all(bundle$result$diagnostics$status == "ok"))

  # Golden snapshot on deterministic projection — catches floating-point
  # drift or aggregation bugs that survive the structural checks.
  testthat::expect_snapshot_value(
    .snapshot_projection(bundle$result),
    style = "serialize"
  )
})

test_that("FIGARO elasticity opt-in path runs when SUBE_FIGARO_INPUTS_DIR is set (FIG-E2E-01 opt-in)", {
  testthat::skip_on_cran()
  root <- resolve_figaro_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_FIGARO_DIR not set — FIGARO E2E opt-in elasticity test skipped"
  )
  inputs_dir <- Sys.getenv("SUBE_FIGARO_INPUTS_DIR", unset = "")
  testthat::skip_if_not(
    nzchar(inputs_dir) && dir.exists(inputs_dir),
    "SUBE_FIGARO_INPUTS_DIR not set — opt-in elasticity branch skipped"
  )

  bundle <- .figaro_real_bundle()
  testthat::skip_if(is.null(bundle), "FIGARO pipeline fixture build failed")
  testthat::skip_if(is.null(bundle$result_opt),
                    "SUBE_FIGARO_INPUTS_DIR present but sidecar files missing/malformed")

  # Structural invariants only — no snapshot on regression-flavored output
  expect_s3_class(bundle$result_opt, "sube_results")
  expect_true(all(bundle$result_opt$diagnostics$status == "ok"))
  expect_true(all(c("GOe","VAe","EMPe","CO2e") %in%
                  names(bundle$result_opt$summary)))
})
