#' Compute SUBE Multipliers and Elasticities
#'
#' Computes Leontief-style multipliers and final-demand elasticities for each
#' country-year matrix bundle.
#'
#' @param matrix_bundle Result of [build_matrices()].
#' @param inputs Industry-level inputs with columns `YEAR`, `REP`, an industry
#'   identifier (`IND`, `INDUSTRY`, or `INDUSTRIES`), and at least `GO`.
#' @param metrics Metrics to compute. Defaults to `c("GO", "VA", "EMP", "CO2")`.
#' @param diagonal_adjustment Value added to the supply matrix diagonal before
#'   inversion. Defaults to `1`.
#' @param zero_replacement Value used when `GO == 0`. Defaults to `1e-6`.
#'
#' @return A list with a wide summary table, a tidy result table, diagnostics,
#'   and coefficient matrices. The object has class `"sube_results"`.
#' @export
compute_sube <- function(
    matrix_bundle,
    inputs,
    metrics = c("GO", "VA", "EMP", "CO2"),
    diagonal_adjustment = 1,
    zero_replacement = 1e-6) {
  .validate_class(matrix_bundle, "sube_matrices")
  inputs <- .standardize_names(inputs)
  .sube_required_columns(inputs, c("YEAR", "REP", "GO"))

  industry_col <- intersect(c("IND", "INDUSTRY", "INDUSTRIES", "INDAGG"), names(inputs))
  if (length(industry_col) == 0L) {
    stop("`inputs` must include an industry identifier column.", call. = FALSE)
  }
  industry_col <- industry_col[1L]
  setnames(inputs, industry_col, "INDUSTRY", skip_absent = TRUE)

  metrics <- unique(toupper(metrics))
  missing_metrics <- setdiff(metrics, names(inputs))
  if (length(missing_metrics) > 0L) {
    stop(sprintf("Missing input metrics: %s", paste(missing_metrics, collapse = ", ")), call. = FALSE)
  }

  summaries <- list()
  tidy_results <- list()
  diagnostics <- list()
  coefficient_matrices <- list()

  for (name in names(matrix_bundle$matrices)) {
    bundle <- matrix_bundle$matrices[[name]]
    country <- bundle$country
    year <- bundle$year
    S <- bundle$S + diag(diagonal_adjustment, nrow(bundle$S))
    U <- bundle$U

    s_inv <- .safe_solve(t(S))
    if (is.null(s_inv)) {
      diagnostics[[name]] <- data.table(country = country, year = year, status = "singular_supply")
      next
    }

    input_rows <- inputs[YEAR == year & REP == country]
    input_rows <- input_rows[match(bundle$industries, INDUSTRY)]
    if (nrow(input_rows) != length(bundle$industries) || anyNA(input_rows$INDUSTRY)) {
      stop(sprintf("Input rows do not align with matrix industries for %s %s.", country, year), call. = FALSE)
    }

    go <- as.numeric(input_rows$GO)
    go[go == 0] <- zero_replacement
    x_hat <- diag(go)

    x_inv <- .safe_solve(x_hat)
    if (is.null(x_inv)) {
      diagnostics[[name]] <- data.table(country = country, year = year, status = "singular_go")
      next
    }

    A <- U %*% s_inv
    L <- .safe_solve(diag(nrow(A)) - A)
    if (is.null(L)) {
      diagnostics[[name]] <- data.table(country = country, year = year, status = "singular_leontief")
      next
    }
    dimnames(A) <- list(bundle$products, bundle$products)
    dimnames(L) <- list(bundle$products, bundle$products)

    fd_rows <- matrix_bundle$final_demand[YEAR == year & REP == country]
    fd_rows <- fd_rows[match(bundle$products, CPAagg)]
    fd <- fd_rows$FD
    fd[is.na(fd)] <- 0

    raw <- data.table(
      YEAR = year,
      COUNTRY = country,
      CPAagg = bundle$products
    )
    raw[, GO := as.numeric(colSums(L))]

    for (metric in setdiff(metrics, "GO")) {
      coeff <- as.numeric(input_rows[[metric]]) / go
      raw[[metric]] <- as.numeric(coeff %*% L)
    }

    elast <- data.table::copy(raw)
    for (metric in metrics) {
      denom <- sum(raw[[metric]], na.rm = TRUE)
      elast[[paste0(metric, "e")]] <- if (denom == 0) NA_real_ else raw[[metric]] * fd / denom
    }

    wide <- cbind(raw, FD = fd, elast[, paste0(metrics, "e"), with = FALSE])
    summaries[[name]] <- wide

    multiplier_tidy <- .as_long_result(raw, c("YEAR", "COUNTRY", "CPAagg"), metrics, "multiplier", "leontief")
    elasticity_tidy <- .as_long_result(
      elast[, c("YEAR", "COUNTRY", "CPAagg", paste0(metrics, "e")), with = FALSE],
      c("YEAR", "COUNTRY", "CPAagg"),
      paste0(metrics, "e"),
      "elasticity",
      "leontief"
    )
    elasticity_tidy[, variable := sub("e$", "", variable)]
    tidy_results[[name]] <- rbindlist(list(multiplier_tidy, elasticity_tidy), fill = TRUE)

    coefficient_matrices[[name]] <- list(
      country = country,
      year = year,
      A = A,
      L = L
    )
    diagnostics[[name]] <- data.table(country = country, year = year, status = "ok")
  }

  out <- list(
    summary = rbindlist(summaries, fill = TRUE),
    tidy = rbindlist(tidy_results, fill = TRUE),
    diagnostics = rbindlist(diagnostics, fill = TRUE),
    matrices = coefficient_matrices
  )
  class(out) <- c("sube_results", class(out))
  out
}
