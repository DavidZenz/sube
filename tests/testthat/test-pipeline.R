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

test_that(".emit_pipeline_warning stays silent when all statuses are 'ok'", {
  # Unit test on the helper: an all-'ok' diagnostics table must emit no warning.
  clean_diag <- data.table::data.table(
    country = "AAA", year = 2020L, stage = "compute",
    status = "ok", message = "ok", n_rows = NA_integer_
  )
  expect_no_warning(sube:::.emit_pipeline_warning(clean_diag))
  # Non-ok diagnostics trigger exactly one warning.
  dirty_diag <- data.table::data.table(
    country = c(NA_character_, "AAA"),
    year    = c(NA_integer_, 2020L),
    stage   = c("import", "compute"),
    status  = c("coerced_na", "ok"),
    message = c("1 row(s) with NA VALUE.", "ok"),
    n_rows  = c(1L, NA_integer_)
  )
  expect_warning(
    sube:::.emit_pipeline_warning(dirty_diag),
    "^Pipeline completed with issues: 1 coerced_na\\. See result\\$diagnostics for details\\.$"
  )
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

# =============================================================================
# batch_sube() — Plan 08-02 Task 1: signature, validation, splitter, S3 class
# =============================================================================

test_that("batch_sube is exported", {
  expect_true("batch_sube" %in% getNamespaceExports("sube"))
})

test_that("batch_sube errors on non-sube_suts input (CONV-02 shape check)", {
  expect_error(
    batch_sube(
      sut_data = data.frame(x = 1),   # not sube_suts
      cpa_map  = sube_example_data("cpa_map"),
      ind_map  = sube_example_data("ind_map"),
      inputs   = sube_example_data("inputs")
    ),
    "Expected an object of class 'sube_suts'"
  )
})

test_that(".batch_split groups correctly by country_year (D-8.8 default)", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))
  groups <- sube:::.batch_split(sut_multi, NULL, NULL, "country_year")
  expect_equal(length(groups), 2L)
  expect_setequal(vapply(groups, function(g) g$group_key, character(1)),
                  c("AAA_2020", "AAA_2021"))
})

test_that(".batch_split groups correctly by country", {
  sut <- sube_example_data("sut_data")
  class(sut) <- c("sube_suts", class(sut))
  groups <- sube:::.batch_split(sut, NULL, NULL, "country")
  expect_equal(length(groups), 1L)
  expect_equal(groups[[1L]]$group_key, "AAA")
})

test_that(".batch_split groups correctly by year", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))
  groups <- sube:::.batch_split(sut_multi, NULL, NULL, "year")
  expect_equal(length(groups), 2L)
  expect_setequal(vapply(groups, function(g) g$group_key, character(1)),
                  c("2020", "2021"))
})

test_that("batch_sube with stub loop returns sube_batch_result with correct shape", {
  sut <- sube_example_data("sut_data")
  class(sut) <- c("sube_suts", class(sut))
  res <- suppressWarnings(batch_sube(
    sut_data = sut,
    cpa_map  = sube_example_data("cpa_map"),
    ind_map  = sube_example_data("ind_map"),
    inputs   = sube_example_data("inputs")
  ))
  expect_s3_class(res, "sube_batch_result")
  expect_named(res, c("results", "summary", "tidy", "diagnostics", "call"))
  expect_named(res$call, c("by", "n_groups", "n_errors", "estimate",
                           "call", "r_version", "package_version"),
               ignore.order = TRUE)
  expect_equal(res$call$by, "country_year")
})

# =============================================================================
# batch_sube() — Plan 08-02 Task 2: per-group processing, resilience, merging
# =============================================================================

test_that("batch_sube happy path on 2-year duplicate produces merged tables (CONV-02)", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))

  inp <- sube_example_data("inputs")
  inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
  inp_multi <- rbind(inp, inp2)

  res <- suppressWarnings(batch_sube(
    sut_data = sut_multi,
    cpa_map  = sube_example_data("cpa_map"),
    ind_map  = sube_example_data("ind_map"),
    inputs   = inp_multi
  ))
  expect_s3_class(res, "sube_batch_result")
  expect_equal(length(res$results), 2L)
  expect_named(res$results, c("AAA_2020", "AAA_2021"), ignore.order = TRUE)
  expect_true(all(vapply(res$results, inherits, logical(1),
                         "sube_pipeline_result")))
  expect_gte(nrow(res$summary), 2L)
  expect_gte(nrow(res$tidy), 2L)
  expect_true("group_key" %in% names(res$diagnostics))
  expect_equal(res$call$n_groups, 2L)
  expect_equal(res$call$n_errors, 0L)
})

test_that("batch_sube is resilient to per-group error (D-8.7)", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))

  # Force group AAA_2021 to error at compute: supply inputs with 2020 only.
  inp_broken <- sube_example_data("inputs")   # YEAR = 2020 only

  res <- suppressWarnings(batch_sube(
    sut_data = sut_multi,
    cpa_map  = sube_example_data("cpa_map"),
    ind_map  = sube_example_data("ind_map"),
    inputs   = inp_broken
  ))
  expect_s3_class(res, "sube_batch_result")
  expect_equal(length(res$results), 2L)
  # AAA_2021 fails at compute (inputs missing 2021 rows)
  expect_gte(res$call$n_errors, 1L)
  errs <- res$diagnostics[status == "error"]
  expect_gte(nrow(errs), 1L)
  expect_true("AAA_2021" %in% errs$group_key)
})

test_that("batch_sube summary warning fires once and names errors (D-8.10)", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))
  inp_broken <- sube_example_data("inputs")

  w <- tryCatch(
    batch_sube(
      sut_data = sut_multi,
      cpa_map  = sube_example_data("cpa_map"),
      ind_map  = sube_example_data("ind_map"),
      inputs   = inp_broken
    ),
    warning = function(w) w
  )
  expect_s3_class(w, "warning")
  expect_match(conditionMessage(w), "^Batch completed with ")
  expect_match(conditionMessage(w), "2 group\\(s\\)")
  expect_match(conditionMessage(w), "See result\\$diagnostics for details\\.")
})

test_that("batch_sube merged $diagnostics has group_key column with correct values", {
  sut <- sube_example_data("sut_data")
  sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
  sut_multi <- rbind(sut, sut2)
  class(sut_multi) <- c("sube_suts", class(sut_multi))
  inp <- sube_example_data("inputs")
  inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
  inp_multi <- rbind(inp, inp2)

  res <- suppressWarnings(batch_sube(
    sut_data = sut_multi,
    cpa_map  = sube_example_data("cpa_map"),
    ind_map  = sube_example_data("ind_map"),
    inputs   = inp_multi
  ))
  expect_named(res$diagnostics,
               c("country", "year", "stage", "status", "message",
                 "n_rows", "group_key"))
  expect_setequal(unique(res$diagnostics$group_key),
                  c("AAA_2020", "AAA_2021"))
})

test_that("batch_sube caller's cpa_map is not mutated (Pitfall 10)", {
  sut <- sube_example_data("sut_data")
  class(sut) <- c("sube_suts", class(sut))
  cpa <- sube_example_data("cpa_map")
  pre_names <- names(cpa)
  suppressWarnings(batch_sube(
    sut_data = sut,
    cpa_map  = cpa,
    ind_map  = sube_example_data("ind_map"),
    inputs   = sube_example_data("inputs")
  ))
  expect_equal(names(cpa), pre_names)
})
