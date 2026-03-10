#' Build Domestic Matrices
#'
#' Aggregates imported SUT data onto product and industry mappings, extracts
#' final demand, and builds country-year supply and use matrices.
#'
#' @param sut_data Imported or domestic SUT data with columns `REP`, `PAR`,
#'   `CPA`, `VAR`, `VALUE`, `YEAR`, and `TYPE`.
#' @param cpa_map Product correspondence table. The first two columns must map
#'   source product codes to aggregated product codes.
#' @param ind_map Industry correspondence table. The first two columns must map
#'   source industry codes to aggregated industry codes.
#' @param final_demand_var Column identifier used for final demand within the
#'   long SUT data. Defaults to `"FU_bas"`.
#'
#' @return A list with aggregated long-form data, final demand, and a list of
#'   country-year matrices. The object has class `"sube_matrices"`.
#' @export
build_matrices <- function(sut_data, cpa_map, ind_map, final_demand_var = "FU_bas") {
  sut_data <- .standardize_names(sut_data)
  .sube_required_columns(sut_data, c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE"))

  cpa_map <- .coerce_map(cpa_map, "cpa", "cpa_agg")
  ind_map <- .coerce_map(ind_map, "vars", "ind_agg")
  setnames(cpa_map, c("cpa", "cpa_agg"), c("CPA", "CPAagg"))
  setnames(ind_map, c("vars", "ind_agg"), c("VAR", "INDagg"))
  final_demand_var <- toupper(final_demand_var)

  fd <- merge(
    sut_data[TYPE == "USE" & VAR == final_demand_var, .(YEAR, REP, CPA, VALUE)],
    cpa_map,
    by = "CPA",
    all.x = TRUE
  )
  fd <- fd[!is.na(CPAagg), .(FD = sum(VALUE, na.rm = TRUE)), by = .(YEAR, REP, CPAagg)]

  core <- sut_data[VAR != final_demand_var]
  aggregated <- merge(core, cpa_map, by = "CPA", all.x = TRUE)
  aggregated <- merge(aggregated, ind_map, by = "VAR", all.x = TRUE)
  aggregated <- aggregated[!is.na(CPAagg) & !is.na(INDagg)]
  aggregated <- aggregated[
    ,
    .(VALUE = sum(as.numeric(VALUE), na.rm = TRUE)),
    by = .(YEAR, REP, PAR, TYPE, CPAagg, INDagg)
  ]

  products <- sort(unique(aggregated$CPAagg))
  industries <- sort(unique(aggregated$INDagg))
  ids <- unique(aggregated[, .(YEAR, REP)])

  matrices <- lapply(seq_len(nrow(ids)), function(i) {
    year <- ids$YEAR[[i]]
    country <- ids$REP[[i]]
    subset <- aggregated[YEAR == year & REP == country]
    sup <- dcast(
      subset[TYPE == "SUP"],
      CPAagg ~ INDagg,
      value.var = "VALUE",
      fill = 0,
      fun.aggregate = sum
    )
    use <- dcast(
      subset[TYPE == "USE"],
      CPAagg ~ INDagg,
      value.var = "VALUE",
      fill = 0,
      fun.aggregate = sum
    )

    sup <- sup[match(products, CPAagg)]
    use <- use[match(products, CPAagg)]
    if (anyNA(sup$CPAagg) || anyNA(use$CPAagg)) {
      return(NULL)
    }

    list(
      country = country,
      year = year,
      products = products,
      industries = industries,
      S = as.matrix(sup[, ..industries]),
      U = as.matrix(use[, ..industries])
    )
  })

  matrices <- Filter(Negate(is.null), matrices)
  names(matrices) <- vapply(matrices, function(x) paste(x$country, x$year, sep = "_"), character(1))

  out <- list(
    aggregated = aggregated[],
    final_demand = fd[],
    matrices = matrices
  )
  class(out) <- c("sube_matrices", class(out))
  out
}
