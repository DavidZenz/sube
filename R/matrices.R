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

  # model_data: Leontief-transformed regression matrix.
  # Only computed when `inputs` is supplied (needs GO per raw industry).
  #
  # The legacy regression (06_SUBE_regress.R) operates on the Z matrix at the
  # raw industry level: Z = U %*% solve(t(S + I)) %*% diag(GO), where S and U
  # are 56×56 raw matrices. Only Z's product dimension (rows) is aggregated
  # from 56 to 22; the industry dimension (columns) stays at 56 raw codes.
  # The result is transposed to give 56 industry rows × 22 product columns,
  # which, together with GO/VA/EMP/CO2 per raw industry, forms the regression
  # data for estimate_elasticities().
  model_data <- data.table()

  if (!is.null(inputs)) {
    inputs_dt <- .standardize_names(data.table::copy(inputs))
    ind_col <- intersect(c("INDUSTRY", "IND", "INDUSTRIES"), names(inputs_dt))
    if (length(ind_col) > 0L) setnames(inputs_dt, ind_col[1L], "INDUSTRIES", skip_absent = TRUE)
    .sube_required_columns(inputs_dt, c("YEAR", "REP", "INDUSTRIES", "GO"))

    raw_vars <- sort(unique(tagged$VAR))
    raw_cpas <- sort(unique(tagged$CPA))
    cpa_to_agg <- unique(cpa_map[, .(CPA, CPAagg)])

    model_data_list <- lapply(seq_len(nrow(ids)), function(i) {
      year_i <- ids$YEAR[[i]]
      country_i <- ids$REP[[i]]

      inp <- inputs_dt[YEAR == year_i & REP == country_i]
      if (nrow(inp) == 0L) return(NULL)

      sub <- tagged[YEAR == year_i & REP == country_i]
      if (nrow(sub) == 0L) return(NULL)

      # Build raw 56×56 supply and use matrices (CPA rows × VAR columns)
      sup_raw <- dcast(sub[TYPE == "SUP"], CPA ~ VAR, value.var = "VALUE",
                       fill = 0, fun.aggregate = sum)
      use_raw <- dcast(sub[TYPE == "USE"], CPA ~ VAR, value.var = "VALUE",
                       fill = 0, fun.aggregate = sum)

      present_cpas <- intersect(raw_cpas, intersect(sup_raw$CPA, use_raw$CPA))
      present_vars <- intersect(raw_vars, intersect(names(sup_raw)[-1], names(use_raw)[-1]))
      if (length(present_cpas) < 2L || length(present_vars) < 2L) return(NULL)

      sup_raw <- sup_raw[match(present_cpas, CPA)]
      use_raw <- use_raw[match(present_cpas, CPA)]
      S_raw <- as.matrix(sup_raw[, ..present_vars])
      U_raw <- as.matrix(use_raw[, ..present_vars])

      # A = U %*% solve(t(S + I)), matching legacy 03_SUBE.R lines 176-177
      S_adj <- S_raw + diag(nrow(S_raw))
      tS_inv <- .safe_solve(t(S_adj))
      if (is.null(tS_inv)) return(NULL)
      A_raw <- U_raw %*% tS_inv

      # Z = A %*% diag(GO) — intermediate demand in monetary units
      # GO must be aligned to the column order (present_vars = raw industries)
      go_vec <- inp[match(present_vars, INDUSTRIES)]$GO
      if (length(go_vec) != length(present_vars) || anyNA(go_vec)) return(NULL)
      Z_raw <- A_raw %*% diag(go_vec)  # 56 CPA rows × 56 industry columns

      # Aggregate Z's ROW dimension (products) from 56 → 22, keep columns raw
      # Result: 22 aggregated products × 56 raw industries
      Z_dt <- data.table(Z_raw)
      setnames(Z_dt, present_vars)
      Z_dt[, CPA := present_cpas]
      Z_long <- melt(Z_dt, id.vars = "CPA", variable.name = "INDUSTRIES",
                      value.name = "ZVAL")
      Z_long <- merge(Z_long, cpa_to_agg, by = "CPA", all.x = TRUE)
      Z_agg <- Z_long[!is.na(CPAagg),
                       .(ZVAL = sum(ZVAL, na.rm = TRUE)),
                       by = .(INDUSTRIES, CPAagg)]

      # Dcast: 56 raw industry rows × 22 aggregated product columns
      wide <- dcast(Z_agg, INDUSTRIES ~ CPAagg, value.var = "ZVAL", fill = 0)

      # Append GO/VA/EMP/CO2 per raw industry
      inp_aligned <- inp[match(wide$INDUSTRIES, INDUSTRIES)]
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
