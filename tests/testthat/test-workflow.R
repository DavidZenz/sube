library(sube)

test_that("example data loads and imports cleanly", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  sut <- import_suts(sut_path)

  expect_s3_class(sut, "sube_suts")
  expect_true(all(c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE") %in% names(sut)))

  domestic <- extract_domestic_block(sut)
  expect_true(all(domestic$REP == domestic$PAR))
})

test_that("matrix workflow computes leontief outputs", {
  sut <- sube_example_data("sut_data")
  cpa_map <- sube_example_data("cpa_map")
  ind_map <- sube_example_data("ind_map")
  inputs <- sube_example_data("inputs")

  bundle <- build_matrices(sut, cpa_map, ind_map)
  result <- compute_sube(bundle, inputs)

  expect_s3_class(bundle, "sube_matrices")
  expect_s3_class(result, "sube_results")
  expect_true(nrow(result$summary) == 2)
  expect_true(all(c("YEAR", "COUNTRY", "CPAagg", "GO", "VA", "EMP", "CO2", "GOe", "VAe") %in% names(result$summary)))
  expect_true(all(result$diagnostics$status == "ok"))
})

test_that("regression workflow returns all model tables", {
  model_data <- sube_example_data("model_data")
  models <- estimate_elasticities(model_data, predictor_vars = c("P01", "P02"))

  expect_s3_class(models, "sube_models")
  expect_true(all(c("COUNTRY", "y", "type", "term", "estimate", "elasticity") %in% names(models$tidy)))
  expect_true(all(c("ols", "pooled", "between") %in% models$tidy$type))
})

test_that("filtering, plotting, and writing behave", {
  sut <- sube_example_data("sut_data")
  cpa_map <- sube_example_data("cpa_map")
  ind_map <- sube_example_data("ind_map")
  inputs <- sube_example_data("inputs")
  result <- compute_sube(build_matrices(sut, cpa_map, ind_map), inputs)

  filtered <- filter_sube(result$tidy)
  expect_true(nrow(filtered) <= nrow(result$tidy))

  plot <- plot_sube(filtered, by = "country", kind = "boxplot", measure = "multiplier")
  expect_s3_class(plot, "ggplot")

  tmp <- tempfile("sube-", fileext = ".csv")
  out <- write_sube(tmp, filtered, format = "csv")
  expect_true(file.exists(out))
})
