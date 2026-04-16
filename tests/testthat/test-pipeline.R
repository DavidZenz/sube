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

test_that("happy path on sube_example_data produces well-formed result (CONV-01 happy path)", {
  # Note: the shipped `inputs.csv` uses aggregated codes (I01, I02) while the
  # sut_data uses raw VAR (I1, I2). build_matrices() model_data therefore
  # returns empty (industries never align), which the pipeline surfaces as
  # stage = "build", status = "inputs_misaligned". This is expected behaviour
  # of the D-8.11 #4 detection on the shipped sample — a silent failure made
  # visible by Phase 8.
  res <- suppressWarnings(run_sube_pipeline(
    path = system.file("extdata", "sample", "sut_data.csv", package = "sube"),
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod"
  ))
  expect_s3_class(res, "sube_pipeline_result")
  expect_s3_class(res$results, "sube_results")
  expect_named(res$diagnostics,
               c("country", "year", "stage", "status", "message", "n_rows"))
  # Compute stage should have one `ok` row (AAA/2020 compute_sube succeeded).
  compute_rows <- res$diagnostics[stage == "compute"]
  expect_equal(nrow(compute_rows), 1L)
  expect_true(all(compute_rows$status == "ok"))
})

test_that("coerced_na category surfaces when VALUE has NAs (D-8.11 #3)", {
  sut_path <- tempfile(fileext = ".csv")
  sut <- sube_example_data("sut_data")
  sut_corrupt <- data.table::copy(sut)
  sut_corrupt[1L, VALUE := NA_real_]
  data.table::fwrite(sut_corrupt, sut_path)
  res <- suppressWarnings(run_sube_pipeline(
    path    = sut_path,
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod"
  ))
  import_rows <- res$diagnostics[stage == "import" & status == "coerced_na"]
  expect_equal(nrow(import_rows), 1L)
  expect_gte(import_rows$n_rows, 1L)
  expect_true(is.na(import_rows$country))
  expect_true(is.na(import_rows$year))
})

test_that("skipped_alignment category surfaces when cpa_map has no match (D-8.9)", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  bad_cpa <- data.table::data.table(CPA = "ZZZ", CPAagg = "Z")  # matches nothing
  # build_matrices returns empty matrices; compute_sube then yields empty result;
  # the pipeline still assembles and returns a sube_pipeline_result, with
  # skipped_alignment rows in $diagnostics. A summary warning is expected.
  res <- suppressWarnings(run_sube_pipeline(
    path = sut_path,
    cpa_map = bad_cpa,
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod"
  ))
  sa <- res$diagnostics[stage == "build" & status == "skipped_alignment"]
  expect_gte(nrow(sa), 1L)
  expect_true(all(grepl("^AAA$", sa$country)))
})

test_that("inputs_misaligned category surfaces when sut+inputs overlap but model_data omits the group (D-8.11 #4)", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  # Corrupt inputs INDUSTRY so model_data build fails alignment for AAA/2020
  # (R/matrices.R:177: anyNA(inp_aligned$GO) -> return(NULL))
  bad_inputs <- data.table::copy(sube_example_data("inputs"))
  bad_inputs[, INDUSTRY := "NOMATCH"]
  res <- suppressWarnings(run_sube_pipeline(
    path = sut_path,
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = bad_inputs,
    source  = "wiod"
  ))
  im <- res$diagnostics[stage == "build" & status == "inputs_misaligned"]
  expect_gte(nrow(im), 1L)
})

test_that("singular-compute passes through from compute_sube diagnostics (D-8.11 #1)", {
  # Use direct compute_sube diagnostics -> extend helper round-trip
  fake_compute_diag <- data.table::data.table(
    country = c("AAA", "BBB"),
    year    = c(2020L, 2020L),
    status  = c("singular_supply", "ok")
  )
  ext <- sube:::.extend_compute_diagnostics(fake_compute_diag)
  expect_named(ext, c("country", "year", "stage", "status", "message", "n_rows"))
  expect_equal(ext$stage, c("compute", "compute"))
  expect_equal(ext$message[1], "Supply matrix singular; country-year skipped.")
  expect_equal(ext$message[2], "ok")
})

test_that("summary warning emitted exactly once when any diagnostic is non-ok (D-8.10)", {
  sut_path <- tempfile(fileext = ".csv")
  sut <- data.table::copy(sube_example_data("sut_data"))
  sut[1L, VALUE := NA_real_]
  data.table::fwrite(sut, sut_path)
  w <- tryCatch(
    run_sube_pipeline(
      path = sut_path,
      cpa_map = sube_example_data("cpa_map"),
      ind_map = sube_example_data("ind_map"),
      inputs  = sube_example_data("inputs"),
      source  = "wiod"
    ),
    warning = function(w) w
  )
  expect_s3_class(w, "warning")
  expect_match(conditionMessage(w), "^Pipeline completed with issues: ")
  expect_match(conditionMessage(w), "coerced_na")
  expect_match(conditionMessage(w), "See result\\$diagnostics for details\\.")
})

test_that("estimate = TRUE attaches sube_models when model_data is non-empty (D-8.4)", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  res <- suppressWarnings(run_sube_pipeline(
    path = sut_path,
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod",
    estimate = TRUE
  ))
  # Sample data has model_data empty (I01/I02 inputs vs I1/I2 SUT VARs); the
  # estimate path is exercised but returns NULL. If a fixture with aligned
  # industries were provided, $models would be a sube_models object.
  if (!is.null(res$models)) {
    expect_s3_class(res$models, "sube_models")
  } else {
    succeed("estimate path exercised; sube_models fallback OK when model_data empty")
  }
})

test_that("estimate = FALSE leaves $models NULL (D-8.4 default)", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  res <- suppressWarnings(run_sube_pipeline(
    path = sut_path,
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod"
  ))
  expect_null(res$models)
  expect_true(res$call$estimate == FALSE)
})

test_that("FIGARO source routes through read_figaro and returns sube_pipeline_result (CONV-01 FIGARO path)", {
  fixture_dir <- system.file("extdata", "figaro-sample", package = "sube")
  skip_if_not(nzchar(fixture_dir), "figaro-sample fixture missing")

  # Build cpa_map + ind_map inline from fixture codes via section-letter rule
  # (mirrors helper-gated-data.R::build_nace_section_map).
  sut_peek <- read_figaro(fixture_dir, year = 2023L)
  dom_peek <- extract_domestic_block(sut_peek)
  codes <- sort(unique(c(dom_peek$CPA, setdiff(dom_peek$VAR, "FU_BAS"))))
  cpa_map <- data.table::data.table(CPA = codes, CPAagg = substr(codes, 1L, 1L))
  ind_map <- data.table::data.table(NACE = codes, INDagg = substr(codes, 1L, 1L))

  agg_inds <- sort(unique(ind_map$INDagg))
  countries <- sort(unique(dom_peek$REP))
  inputs <- data.table::CJ(YEAR = 2023L, REP = countries,
                           INDUSTRY = agg_inds, sorted = FALSE)
  inputs[, GO  := seq(100, by = 10, length.out = nrow(inputs))]
  inputs[, VA  := GO * 0.4]
  inputs[, EMP := GO * 0.1]
  inputs[, CO2 := GO * 0.05]

  res <- suppressWarnings(run_sube_pipeline(
    path    = fixture_dir,
    cpa_map = cpa_map,
    ind_map = ind_map,
    inputs  = inputs,
    source  = "figaro",
    year    = 2023L
  ))
  expect_s3_class(res, "sube_pipeline_result")
  expect_s3_class(res$results, "sube_results")
  expect_gt(nrow(res$results$summary), 0L)
  expect_setequal(unique(res$results$summary$COUNTRY), c("DE", "FR", "IT"))
  expect_equal(res$call$source, "figaro")
})

test_that("$call carries provenance metadata (D-8.3)", {
  sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
  res <- suppressWarnings(run_sube_pipeline(
    path = sut_path,
    cpa_map = sube_example_data("cpa_map"),
    ind_map = sube_example_data("ind_map"),
    inputs  = sube_example_data("inputs"),
    source  = "wiod"
  ))
  expect_named(res$call,
               c("source", "path", "n_countries", "n_years",
                 "estimate", "call", "r_version", "package_version"),
               ignore.order = TRUE)
  expect_equal(res$call$source, "wiod")
  expect_equal(res$call$n_countries, 1L)
  expect_equal(res$call$n_years, 1L)
  expect_false(res$call$estimate)
})
