library(testthat)
library(sube)

test_that("run_sube_pipeline is exported", {
  expect_true("run_sube_pipeline" %in% getNamespaceExports("sube"))
})

test_that(".empty_diagnostics has the unified D-8.12 schema", {
  d <- sube:::.empty_diagnostics()
  expect_named(d, c("country", "year", "stage", "status", "message", "n_rows"))
  expect_type(d$country, "character")
  expect_type(d$year,    "integer")
  expect_type(d$stage,   "character")
  expect_type(d$status,  "character")
  expect_type(d$message, "character")
  expect_type(d$n_rows,  "integer")
})

test_that("run_sube_pipeline errors upfront when `inputs` is missing GO", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  bad_inputs <- sube_example_data("inputs")
  bad_inputs[, GO := NULL]
  expect_error(
    run_sube_pipeline(
      path = sut_path,
      cpa_map = sube_example_data("cpa_map"),
      ind_map = sube_example_data("ind_map"),
      inputs  = bad_inputs,
      source  = "wiod"
    ),
    "Missing required columns: GO"
  )
})
