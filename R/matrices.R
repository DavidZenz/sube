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
#' @return A list with class `"sube_matrices"` containing:
#'   \describe{
#'     \item{aggregated}{Fully aggregated long-form data (22 products × 22 industries).}
#'     \item{final_demand}{Final demand by aggregated product.}
#'     \item{matrices}{Country-year supply and use matrices (22×22).}
#'     \item{model_data}{Leontief-transformed regression matrix (56 raw industries
#'       × 22 aggregated products per country-year) suitable for
#'       [estimate_elasticities()]. Only present when `inputs` is supplied.
#'       Contains columns `YEAR`, `COUNTRY`, `INDUSTRIES`, `P01`..`P22`,
#'       `GO`, `VA`, `EMP`, `CO2`.}
#'   }
#' @param inputs Optional industry-level inputs with columns `YEAR`, `REP`,
#'   an industry identifier (`INDUSTRY`, `IND`, or `INDUSTRIES`), and at
#'   least `GO`. When supplied, `model_data` is computed by building raw
#'   56×56 S/U matrices, computing Z = A × diag(GO), and aggregating only
#'   the product columns. Metrics `VA`, `EMP`, `CO2` are included if present.
#' @export
build_matrices <- function(sut_data, cpa_map, ind_map, final_demand_var = "FU_bas",
                           inputs = NULL) {
  sut_data <- .standardize_names(sut_data)
  .sube_required_columns(sut_data, c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE"))
  sut_data[, VAR := toupper(as.character(VAR))]

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
  tagged <- merge(core, cpa_map, by = "CPA", all.x = TRUE)
  tagged <- merge(tagged, ind_map, by = "VAR", all.x = TRUE)
  tagged <- tagged[!is.na(CPAagg) & !is.na(INDagg)]

  # aggregated: fully aggregate both products and industries (22×22)
  aggregated <- tagged[
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

  # model_data: Net-supply regression matrix (W = SUP - USE).
  # Only computed when `inputs` is supplied (needs GO/VA/EMP/CO2 per industry).
  #
  # The legacy regression (05_SUBE_regress.R lines 28-55) builds the regression
  # input as:
  #   1. Read raw per-country SUP and USE CSVs (56 CPA rows × 56 industry cols)
  #   2. Merge CPA with product correspondence → get CPAagg
  #   3. Melt + aggregate by CPAagg → 22 product rows × 56 industry cols
  #   4. W = SUP_agg - USE_agg (net supply at 22 products × 56 industries)
  #   5. Transpose → 56 industries × 22 products
  #   6. Append GO, VA, EMP, CO2 per raw industry
  #
  # This net-supply matrix is then regressed as:
  #   GO ~ P01 + P02 + ... + P22 - 1  (OLS, pooled, between)
  model_data <- data.table()

  if (!is.null(inputs)) {
    inputs_dt <- .standardize_names(data.table::copy(inputs))
    ind_col <- intersect(c("INDUSTRY", "IND", "INDUSTRIES"), names(inputs_dt))
    if (length(ind_col) > 0L) setnames(inputs_dt, ind_col[1L], "INDUSTRIES", skip_absent = TRUE)
    .sube_required_columns(inputs_dt, c("YEAR", "REP", "INDUSTRIES", "GO"))

    raw_vars <- sort(unique(tagged$VAR))
    cpa_to_agg <- unique(cpa_map[, .(CPA, CPAagg)])

    model_data_list <- lapply(seq_len(nrow(ids)), function(i) {
      year_i <- ids$YEAR[[i]]
      country_i <- ids$REP[[i]]

      inp <- inputs_dt[YEAR == year_i & REP == country_i]
      if (nrow(inp) == 0L) return(NULL)

      sub <- tagged[YEAR == year_i & REP == country_i]
      if (nrow(sub) == 0L) return(NULL)

      # Product-aggregate SUP and USE separately (keep raw industry columns)
      # tagged already has CPAagg from the CPA correspondence merge
      sup_agg <- sub[TYPE == "SUP",
                     .(VALUE = sum(as.numeric(VALUE), na.rm = TRUE)),
                     by = .(CPAagg, VAR)]
      use_agg <- sub[TYPE == "USE",
                     .(VALUE = sum(as.numeric(VALUE), na.rm = TRUE)),
                     by = .(CPAagg, VAR)]

      # Dcast: 22 product rows × 56 industry columns
      sup_wide <- dcast(sup_agg, CPAagg ~ VAR, value.var = "VALUE", fill = 0)
      use_wide <- dcast(use_agg, CPAagg ~ VAR, value.var = "VALUE", fill = 0)

      # Align rows and columns
      common_prods <- intersect(sup_wide$CPAagg, use_wide$CPAagg)
      common_vars <- intersect(names(sup_wide)[-1], names(use_wide)[-1])
      if (length(common_prods) < 2L || length(common_vars) < 2L) return(NULL)

      sup_wide <- sup_wide[match(sort(common_prods), CPAagg)]
      use_wide <- use_wide[match(sort(common_prods), CPAagg)]

      # W = SUP - USE (net supply), 22 products × 56 industries
      W <- as.matrix(sup_wide[, ..common_vars]) - as.matrix(use_wide[, ..common_vars])
      rownames(W) <- sort(common_prods)
      colnames(W) <- common_vars

      # Transpose: 56 industries × 22 products
      W_t <- t(W)

      # Build the regression data.table
      wide <- data.table(W_t)
      setnames(wide, sort(common_prods))
      wide[, INDUSTRIES := rownames(W_t)]

      # Append GO/VA/EMP/CO2 per raw industry
      inp_aligned <- inp[match(wide$INDUSTRIES, INDUSTRIES)]
      if (anyNA(inp_aligned$GO)) return(NULL)
      wide[, YEAR := year_i]
      wide[, COUNTRY := country_i]
      wide[, GO := inp_aligned$GO]
      for (metric in intersect(c("VA", "EMP", "CO2"), names(inp_aligned))) {
        wide[, (metric) := inp_aligned[[metric]]]
      }
      wide
    })
    model_data <- rbindlist(
      model_data_list[!vapply(model_data_list, is.null, logical(1))],
      fill = TRUE
    )
  }

  out <- list(
    aggregated = aggregated[],
    final_demand = fd[],
    matrices = matrices,
    model_data = model_data[]
  )
  class(out) <- c("sube_matrices", class(out))
  out
}
