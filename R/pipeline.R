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

  # --- 3. coerced-NA diagnostics at import boundary (Task 2 fills) ---
  diag_import <- .empty_diagnostics()

  # --- 4. domestic filter ---
  sut <- if (isTRUE(domestic_only)) extract_domestic_block(sut_raw) else sut_raw

  # --- 5. build_matrices ---
  matrix_bundle <- build_matrices(sut, cpa_map, ind_map, inputs = inputs)

  # --- 6. diagnostics: skipped_alignment + inputs_misaligned (Task 2 fills) ---
  diag_build <- .empty_diagnostics()

  # --- 7. compute_sube ---
  results <- compute_sube(matrix_bundle, inputs, ...)

  # --- 8. diagnostics: extend compute_sube output to unified schema (Task 2 fills) ---
  diag_compute <- .empty_diagnostics()

  # --- 9. opt-in estimate_elasticities (Task 3) ---
  models <- NULL

  # --- 10. assemble + summary warning (Task 3) ---
  diagnostics <- data.table::rbindlist(
    list(diag_import, diag_build, diag_compute),
    fill = TRUE
  )

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

  .sube_pipeline_result(results, models, diagnostics, call_meta)
}
