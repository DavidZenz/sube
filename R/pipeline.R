# Phase 8: Convenience Helpers — one-call and batch wrappers with CONV-03 diagnostics.

# Unified diagnostics schema per D-8.12 / RESEARCH §3 Open Item 3.
# Column order is load-bearing for rbindlist.
.empty_diagnostics <- function() {
  data.table::data.table(
    country = character(),
    year    = integer(),
    stage   = character(),
    status  = character(),
    message = character(),
    n_rows  = integer()
  )
}

# Class per RESEARCH §3 Open Item 1: no inheritance from sube_results.
# $results holds the sube_results; wrappers stay distinct S3 tags.
.sube_pipeline_result <- function(results, models, diagnostics, call_meta) {
  out <- list(
    results     = results,
    models      = models,
    diagnostics = diagnostics,
    call        = call_meta
  )
  class(out) <- c("sube_pipeline_result", "list")
  out
}

# D-8.11 #3 / RESEARCH §3 Open Item 2. Primary-input rows in read_figaro are
# dropped BEFORE as.numeric() (R/import.R:247 vs 255), so sum(is.na(VALUE)) at
# this point is the exact count of coercion-introduced NAs.
.detect_coerced_na <- function(sut_raw) {
  n <- sum(is.na(sut_raw$VALUE))
  if (n <= 0L) return(.empty_diagnostics())
  data.table::data.table(
    country = NA_character_,
    year    = NA_integer_,
    stage   = "import",
    status  = "coerced_na",
    message = sprintf(
      "%d row(s) with NA VALUE at import boundary (e.g. non-numeric obsValue).",
      n
    ),
    n_rows  = n
  )
}

# D-8.9 / RESEARCH §4. Catches BOTH correspondence-filter drops
# (R/matrices.R:55) AND dcast-alignment NULL returns (R/matrices.R:89-91 → :103
# Filter). Matrix keys are `paste(country, year, sep = "_")` per R/matrices.R:104.
.detect_skipped_alignment <- function(sut, matrix_bundle) {
  input_ids  <- unique(sut[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
  input_keys <- paste(input_ids$REP, input_ids$YEAR, sep = "_")
  output_keys <- names(matrix_bundle$matrices)
  dropped <- setdiff(input_keys, output_keys)
  if (length(dropped) == 0L) return(.empty_diagnostics())
  data.table::data.table(
    country = sub("_\\d+$", "", dropped),
    year    = as.integer(sub("^.*_", "", dropped)),
    stage   = "build",
    status  = "skipped_alignment",
    message = sprintf(
      "Country-year %s present in SUT data but absent from build_matrices output (missing CPA/industry alignment after correspondence merge).",
      dropped
    ),
    n_rows  = NA_integer_
  )
}

# D-8.11 #4 / RESEARCH §4. model_data column is COUNTRY (not REP) per
# R/matrices.R:179. Detects country-years present in both SUT and inputs but
# dropped from model_data (R/matrices.R alignment paths return NULL).
.detect_inputs_misaligned <- function(sut, inputs, matrix_bundle) {
  sut_ids <- unique(sut[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
  inp <- .standardize_names(data.table::copy(inputs))
  input_ids <- unique(inp[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
  joint <- merge(sut_ids, input_ids, by = c("YEAR", "REP"))
  if (nrow(joint) == 0L) return(.empty_diagnostics())

  md <- matrix_bundle$model_data
  if (is.null(md) || nrow(md) == 0L) {
    model_ids <- data.table::data.table(YEAR = integer(), REP = character())
  } else {
    model_ids <- unique(md[, .(YEAR = as.integer(YEAR), REP = as.character(COUNTRY))])
  }

  misaligned <- joint[!model_ids, on = c("YEAR", "REP")]
  if (nrow(misaligned) == 0L) return(.empty_diagnostics())
  data.table::data.table(
    country = misaligned$REP,
    year    = misaligned$YEAR,
    stage   = "build",
    status  = "inputs_misaligned",
    message = sprintf(
      "Country-year %s_%d present in both SUT and inputs but absent from build_matrices model_data.",
      misaligned$REP, misaligned$YEAR
    ),
    n_rows  = NA_integer_
  )
}

# D-8.11 #1. Transforms compute_sube()'s 3-column diagnostics (country, year,
# status) into the 6-column unified schema by stamping stage = "compute",
# filling concrete per-status messages, and setting n_rows = NA_integer_.
.extend_compute_diagnostics <- function(compute_diag) {
  if (is.null(compute_diag) || nrow(compute_diag) == 0L) {
    return(.empty_diagnostics())
  }
  out <- data.table::copy(compute_diag)
  out[, stage := "compute"]
  # Concrete message per status; unknown statuses fall through to the raw
  # status code. fcase()'s `default` must be a scalar, so we build the
  # message column via a named lookup with a scalar fallback, then fill any
  # unknowns in-place from the raw status.
  message_map <- c(
    ok                = "ok",
    singular_supply   = "Supply matrix singular; country-year skipped.",
    singular_go       = "GO diagonal singular; country-year skipped.",
    singular_leontief = "Leontief matrix (I-A) singular; country-year skipped."
  )
  raw_status <- as.character(out$status)
  mapped <- unname(message_map[raw_status])
  mapped[is.na(mapped)] <- raw_status[is.na(mapped)]
  out[, message := mapped]
  out[, n_rows := NA_integer_]
  out[, country := as.character(country)]
  out[, year    := as.integer(year)]
  data.table::setcolorder(out, c("country", "year", "stage", "status", "message", "n_rows"))
  out[]
}

# D-8.10. ONE warning() per run, counts sorted descending so the largest issue
# category surfaces first. "ok" rows excluded by construction.
.emit_pipeline_warning <- function(diagnostics) {
  if (is.null(diagnostics) || nrow(diagnostics) == 0L) return(invisible(NULL))
  bad <- diagnostics[status != "ok"]
  if (nrow(bad) == 0L) return(invisible(NULL))
  counts <- bad[, .N, by = status]
  data.table::setorder(counts, -N)
  parts <- sprintf("%d %s", counts$N, counts$status)
  warning(
    sprintf(
      "Pipeline completed with issues: %s. See result$diagnostics for details.",
      paste(parts, collapse = ", ")
    ),
    call. = FALSE
  )
}

# Upfront `inputs` validation (RESEARCH §3 Open Item 6). Uses data.table::copy()
# so the caller's object is never mutated by .standardize_names() (Pitfall 10).
.validate_pipeline_inputs <- function(inputs) {
  if (is.null(inputs)) {
    stop("`inputs` must be supplied (industry-level GO/VA/EMP/CO2).", call. = FALSE)
  }
  check <- .standardize_names(data.table::copy(inputs))
  .sube_required_columns(check, c("YEAR", "REP", "GO"))
  industry_col <- intersect(
    c("IND", "INDUSTRY", "INDUSTRIES", "INDAGG"), names(check)
  )
  if (length(industry_col) == 0L) {
    stop(
      paste0(
        "`inputs` must include an industry identifier column ",
        "(IND, INDUSTRY, INDUSTRIES, or INDAGG)."
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Run the SUBE Pipeline End-to-End
#'
#' Chains the SUBE import → domestic filter → matrix construction → compute
#' step into a single call, returning a structured result with unified
#' diagnostics. The FIGARO source routes through [read_figaro()]; WIOD-style
#' CSVs/workbooks route through [import_suts()].
#'
#' @param path Single character path to a SUT file or directory (WIOD:
#'   workbook/CSV or dir; FIGARO: directory containing supply+use flatfiles).
#' @param cpa_map,ind_map Correspondence tables; see [build_matrices()].
#' @param inputs Industry-level inputs with columns `YEAR`, `REP`, an industry
#'   identifier, and at least `GO`.
#' @param source One of `"wiod"` or `"figaro"`. Selects the importer. No
#'   auto-detect (D-8.2).
#' @param domestic_only If `TRUE` (default), runs [extract_domestic_block()] on
#'   the imported SUTs before building matrices.
#' @param estimate If `TRUE` and `build_matrices(..., inputs = inputs)`
#'   produces non-empty `$model_data`, also runs [estimate_elasticities()] and
#'   attaches the result to `$models`. Default `FALSE` (D-8.4).
#' @param ... Importer-specific arguments (e.g. `sheets`, `recursive` for WIOD;
#'   `year`, `final_demand_vars` for FIGARO) and compute-specific arguments
#'   (e.g. `metrics`, `diagonal_adjustment`, `zero_replacement`) forwarded to
#'   [compute_sube()].
#'
#' @return An object of class `c("sube_pipeline_result", "list")` with
#'   elements `$results` (the [sube_results][compute_sube] object), `$models`
#'   (a `sube_models` object from [estimate_elasticities()] or `NULL`),
#'   `$diagnostics` (a unified diagnostics `data.table`; see *Details*), and
#'   `$call` (provenance metadata).
#'
#' @details The diagnostics table has columns `country` (character; `NA` for
#'   pipeline-level aggregates), `year` (integer; `NA` for pipeline-level
#'   aggregates), `stage` (`import`, `build`, `compute`, or `pipeline`),
#'   `status` (`ok`, `singular_supply`, `singular_go`, `singular_leontief`,
#'   `skipped_alignment`, `coerced_na`, `inputs_misaligned`, or `error`),
#'   `message` (human-readable reason), and `n_rows` (optional row count,
#'   populated for `coerced_na` aggregates). If any row has `status != "ok"` a
#'   single `warning()` summarising counts is emitted at the end of the call.
#'
#' @seealso [batch_sube()], [compute_sube()], [build_matrices()],
#'   [import_suts()], [read_figaro()]
#'
#' @examples
#' sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
#' result <- run_sube_pipeline(
#'   path    = sut_path,
#'   cpa_map = sube_example_data("cpa_map"),
#'   ind_map = sube_example_data("ind_map"),
#'   inputs  = sube_example_data("inputs"),
#'   source  = "wiod"
#' )
#' result$results$summary
#' result$diagnostics
#'
#' \dontrun{
#' # FIGARO branch needs a directory with real or synthetic FIGARO flatfiles:
#' figaro_dir <- system.file("extdata", "figaro-sample", package = "sube")
#' run_sube_pipeline(
#'   path    = figaro_dir,
#'   cpa_map = my_cpa_map,     # user-supplied
#'   ind_map = my_ind_map,
#'   inputs  = my_inputs,
#'   source  = "figaro",
#'   year    = 2023L
#' )
#' }
#'
#' @export
run_sube_pipeline <- function(
    path,
    cpa_map,
    ind_map,
    inputs,
    source = c("wiod", "figaro"),
    domestic_only = TRUE,
    estimate = FALSE,
    ...
) {
  # --- 1. argument validation ---
  if (missing(path) || length(path) != 1L || !is.character(path) || !nzchar(path)) {
    stop("`path` must be a single non-empty character string.", call. = FALSE)
  }
  source <- match.arg(source)
  .validate_pipeline_inputs(inputs)

  call_snapshot <- match.call()

  # --- 2. import (source-dependent; full logic in Task 2) ---
  dots <- list(...)
  sut_raw <- switch(source,
    wiod = do.call(
      import_suts,
      c(list(path = path), dots[intersect(names(dots), c("sheets", "recursive"))])
    ),
    figaro = do.call(
      read_figaro,
      c(list(path = path), dots[intersect(names(dots), c("year", "final_demand_vars"))])
    )
  )

  # --- 3. coerced-NA diagnostics at import boundary ---
  diag_import <- .detect_coerced_na(sut_raw)

  # --- 4. domestic filter ---
  sut <- if (isTRUE(domestic_only)) extract_domestic_block(sut_raw) else sut_raw

  # --- 5. build_matrices ---
  matrix_bundle <- build_matrices(sut, cpa_map, ind_map, inputs = inputs)

  # --- 6. diagnostics: skipped_alignment + inputs_misaligned ---
  diag_build <- data.table::rbindlist(
    list(
      .detect_skipped_alignment(sut, matrix_bundle),
      .detect_inputs_misaligned(sut, inputs, matrix_bundle)
    ),
    fill = TRUE
  )

  # --- 7. compute_sube (resilient: converts deep alignment errors into
  #        pipeline-stage diagnostic rows so the wrapper always returns) ---
  compute_dots <- dots[intersect(
    names(dots),
    c("metrics", "diagonal_adjustment", "zero_replacement")
  )]
  results <- tryCatch(
    do.call(
      compute_sube,
      c(list(matrix_bundle = matrix_bundle, inputs = inputs), compute_dots)
    ),
    error = function(e) {
      diag_build <<- data.table::rbindlist(
        list(
          diag_build,
          data.table::data.table(
            country = NA_character_,
            year    = NA_integer_,
            stage   = "compute",
            status  = "error",
            message = conditionMessage(e),
            n_rows  = NA_integer_
          )
        ),
        fill = TRUE
      )
      # Return an empty, well-formed sube_results shell so downstream code
      # (and the returned `$results$summary`) stay usable even on failure.
      empty <- list(
        summary     = data.table::data.table(),
        tidy        = data.table::data.table(),
        diagnostics = data.table::data.table(
          country = character(), year = integer(), status = character()
        ),
        matrices    = list()
      )
      class(empty) <- c("sube_results", class(empty))
      empty
    }
  )

  # --- 8. diagnostics: extend compute_sube output to unified schema ---
  diag_compute <- .extend_compute_diagnostics(results$diagnostics)

  # --- 9. opt-in estimate_elasticities (D-8.4) ---
  models <- NULL
  if (isTRUE(estimate) &&
      !is.null(matrix_bundle$model_data) &&
      nrow(matrix_bundle$model_data) > 0L) {
    models <- estimate_elasticities(matrix_bundle$model_data)
  }

  # --- 10. assemble unified diagnostics ---
  diagnostics <- data.table::rbindlist(
    list(diag_import, diag_build, diag_compute),
    fill = TRUE
  )
  data.table::setcolorder(
    diagnostics,
    c("country", "year", "stage", "status", "message", "n_rows")
  )

  # --- 11. build call_meta ---
  n_countries <- length(unique(sut$REP))
  years <- unique(sut$YEAR)
  call_meta <- list(
    source          = source,
    path            = path,
    n_countries     = n_countries,
    n_years         = length(years),
    estimate        = isTRUE(estimate),
    call            = call_snapshot,
    r_version       = R.version.string,
    package_version = as.character(utils::packageVersion("sube"))
  )

  # --- 12. single summary warning (D-8.10) ---
  .emit_pipeline_warning(diagnostics)

  .sube_pipeline_result(results, models, diagnostics, call_meta)
}
