library(testthat)
library(sube)

make_singular_supply_bundle <- function() {
  bundle <- list(
    aggregated = data.table::data.table(),
    final_demand = data.table::data.table(
      YEAR = 2020,
      REP = "AT",
      CPAagg = "P1",
      FD = 1
    ),
    matrices = list(
      AT_2020 = list(
        country = "AT",
        year = 2020,
        products = "P1",
        industries = "I1",
        S = matrix(-1, nrow = 1, ncol = 1, dimnames = list("P1", "I1")),
        U = matrix(0, nrow = 1, ncol = 1, dimnames = list("P1", "I1"))
      )
    )
  )
  class(bundle) <- c("sube_matrices", "list")
  bundle
}

test_that("example data loads and imports cleanly", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  sut <- import_suts(sut_path)

  expect_s3_class(sut, "sube_suts")
  expect_true(all(c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE") %in% names(sut)))

  domestic <- extract_domestic_block(sut)
  expect_s3_class(domestic, "sube_domestic_suts")
  expect_true(all(domestic$REP == domestic$PAR))
})

test_that("import and matrix helpers fail explicitly for malformed inputs", {
  expect_error(import_suts(file.path(tempdir(), "missing-sut.csv")), "`path` does not exist.", fixed = TRUE)

  empty_dir <- file.path(tempdir(), "sube-empty-inputs")
  dir.create(empty_dir, showWarnings = FALSE)
  expect_error(import_suts(empty_dir), "No supported input files were found.", fixed = TRUE)

  bad_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(data.table::data.table(REP = "AT", PAR = "AT", CPA = "P1"), bad_csv)
  expect_error(
    import_suts(bad_csv),
    "Missing required columns: VAR, VALUE, YEAR, TYPE",
    fixed = TRUE
  )

  sut <- sube_example_data("sut_data")
  bad_cpa_map <- data.table::data.table(CPA = c("P1", "P2"))
  expect_error(
    build_matrices(sut, bad_cpa_map, sube_example_data("ind_map")),
    "Mapping tables must have at least two columns.",
    fixed = TRUE
  )
})

test_that("matrix workflow computes leontief outputs", {
  sut <- sube_example_data("sut_data")
  cpa_map <- sube_example_data("cpa_map")
  ind_map <- sube_example_data("ind_map")
  inputs <- sube_example_data("inputs")

  bundle <- build_matrices(sut, cpa_map, ind_map)
  result <- compute_sube(bundle, inputs)

  expect_s3_class(bundle, "sube_matrices")
  expect_true(all(c("aggregated", "final_demand", "matrices") %in% names(bundle)))
  expect_true(length(bundle$matrices) > 0)

  expect_s3_class(result, "sube_results")
  expect_true(nrow(result$summary) == 2)
  expect_true(all(c("YEAR", "COUNTRY", "CPAagg", "GO", "VA", "EMP", "CO2", "GOe", "VAe") %in% names(result$summary)))
  expect_true(all(result$diagnostics$status == "ok"))
})

test_that("compute workflow distinguishes input validation from diagnostics branches", {
  bundle <- build_matrices(
    sube_example_data("sut_data"),
    sube_example_data("cpa_map"),
    sube_example_data("ind_map")
  )
  inputs <- sube_example_data("inputs")

  expect_error(
    compute_sube(inputs = inputs[, .(YEAR, REP, GO, VA, EMP, CO2)], matrix_bundle = bundle),
    "`inputs` must include an industry identifier column.",
    fixed = TRUE
  )

  expect_error(
    compute_sube(bundle, inputs[, .(YEAR, REP, INDUSTRY, GO)]),
    "Missing input metrics: VA, EMP, CO2",
    fixed = TRUE
  )

  singular_inputs <- data.table::data.table(
    YEAR = 2020,
    REP = "AT",
    INDUSTRY = "I1",
    GO = 1,
    VA = 0,
    EMP = 0,
    CO2 = 0
  )
  singular_result <- compute_sube(make_singular_supply_bundle(), singular_inputs)
  expect_true("singular_supply" %in% singular_result$diagnostics$status)
})

test_that("regression workflow returns all model tables", {
  model_data <- sube_example_data("model_data")
  models <- suppressWarnings(estimate_elasticities(model_data, predictor_vars = c("P01", "P02")))

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

test_that("leontief extraction and comparison helpers work", {
  sut <- sube_example_data("sut_data")
  cpa_map <- sube_example_data("cpa_map")
  ind_map <- sube_example_data("ind_map")
  inputs <- sube_example_data("inputs")
  result <- compute_sube(build_matrices(sut, cpa_map, ind_map), inputs)
  models <- suppressWarnings(estimate_elasticities(sube_example_data("model_data"), predictor_vars = c("P01", "P02")))

  matrices_long <- extract_leontief_matrices(result, matrix = "L", format = "long")
  expect_true(all(c("COUNTRY", "YEAR", "matrix", "row", "col", "value") %in% names(matrices_long)))

  comparison <- prepare_sube_comparison(result, models, measure = "multiplier", variables = c("GO"))
  expect_true(all(c("COUNTRY", "CPAagg", "variable", "measure", "type", "value") %in% names(comparison)))
  expect_true(all(c("leontief", "ols", "pooled", "between") %in% unique(comparison$type)))

  paper_boxes <- plot_paper_comparison(comparison, kind = "by_country", measure = "multiplier", variables = c("GO"))
  expect_true(is.list(paper_boxes))
  expect_s3_class(paper_boxes[[1]][[1]], "ggplot")

  paper_reg <- plot_paper_regression(comparison, method = "between", measure = "multiplier", variables = c("GO"))
  expect_s3_class(paper_reg[[1]], "ggplot")

  interval_plots <- plot_paper_interval_ranges(models, by = "country", variables = c("GO"))
  expect_s3_class(interval_plots[[1]][[1]], "ggplot")
})
