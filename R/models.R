#' Estimate Elasticity Regressions
#'
#' Runs country-year OLS models plus country-level pooled and between panel
#' regressions for a prepared model matrix.
#'
#' @param data Modeling data with country, year, entity, response, and predictor
#'   columns.
#' @param response_vars Response variable names. Defaults to `c("GO", "VA",
#'   "EMP", "CO2")`.
#' @param predictor_vars Predictor columns. Defaults to all non-response,
#'   non-index columns.
#' @param country_col Country column name.
#' @param year_col Year column name.
#' @param entity_col Entity column name, for example industries or products.
#'
#' @return A list containing `ols`, `pooled`, `between`, and `tidy` tables. The
#'   object has class `"sube_models"`.
#'
#' @details `estimate_elasticities()` requires the `plm` package because pooled
#'   and between estimators are part of the supported public API.
#' @export
estimate_elasticities <- function(
    data,
    response_vars = c("GO", "VA", "EMP", "CO2"),
    predictor_vars = NULL,
    country_col = "COUNTRY",
    year_col = "YEAR",
    entity_col = "INDUSTRIES") {
  data <- .standardize_names(data)
  country_col <- toupper(country_col)
  year_col <- toupper(year_col)
  entity_col <- toupper(entity_col)
  response_vars <- toupper(response_vars)
  .sube_required_columns(data, c(country_col, year_col, entity_col, response_vars))

  if (is.null(predictor_vars)) {
    predictor_vars <- setdiff(names(data), c(country_col, year_col, entity_col, response_vars))
  }
  predictor_vars <- toupper(predictor_vars)
  .sube_required_columns(data, predictor_vars)

  make_result <- function(base, fit, response, type, country, year = NA_integer_) {
    estimates <- data.table::as.data.table(broom::tidy(fit))
    intervals <- .safe_confint(fit)
    estimates <- merge(
      data.table(term = predictor_vars),
      estimates,
      by = "term",
      all.x = TRUE
    )
    estimates <- merge(estimates, intervals, by = "term", all.x = TRUE)
    mean_x <- as.list(base[, lapply(.SD, mean), .SDcols = predictor_vars])
    estimates[, mean := unlist(mean_x[term])]
    mean_y <- mean(base[[response]], na.rm = TRUE)
    estimates[, mean_y := mean_y]
    estimates[, elasticity := estimate * mean / mean_y]
    estimates[, `:=`(COUNTRY = country, YEAR = year, y = response, type = type)]
    estimates[]
  }

  ols <- list()
  pooled <- list()
  between <- list()

  ids <- unique(data[, .(COUNTRY = get(country_col), YEAR = get(year_col))])
  for (i in seq_len(nrow(ids))) {
    country <- ids$COUNTRY[[i]]
    year <- ids$YEAR[[i]]
    subset <- data[get(country_col) == country & get(year_col) == year]
    for (response in response_vars) {
      formula <- as.formula(sprintf("%s ~ %s - 1", response, paste(predictor_vars, collapse = " + ")))
      fit <- lm(formula, data = subset)
      ols[[paste(country, year, response, sep = "_")]] <- make_result(subset, fit, response, "ols", country, year)
    }
  }

  countries <- unique(data[[country_col]])
  for (country in countries) {
    subset <- data[get(country_col) == country]
    for (response in response_vars) {
      pdata <- plm::pdata.frame(
        as.data.frame(subset[, c(year_col, entity_col, predictor_vars, response_vars), with = FALSE]),
        index = c(year_col, entity_col)
      )
      pooled_formula <- as.formula(sprintf("%s ~ %s - 1", response, paste(predictor_vars, collapse = " + ")))
      pooled_fit <- plm::plm(pooled_formula, data = pdata, model = "pooling", effect = "time")
      pooled[[paste(country, response, sep = "_")]] <- make_result(data.table::as.data.table(pdata), pooled_fit, response, "pooled", country)

      between_formula <- as.formula(sprintf("%s ~ %s", response, paste(predictor_vars, collapse = " + ")))
      between_fit <- plm::plm(between_formula, data = pdata, model = "between", effect = "time")
      between_result <- make_result(data.table::as.data.table(pdata), between_fit, response, "between", country)
      between[[paste(country, response, sep = "_")]] <- between_result[term != "(Intercept)"]
    }
  }

  out <- list(
    ols = rbindlist(ols, fill = TRUE),
    pooled = rbindlist(pooled, fill = TRUE),
    between = rbindlist(between, fill = TRUE)
  )
  out$tidy <- rbindlist(out, fill = TRUE)
  class(out) <- c("sube_models", class(out))
  out
}
