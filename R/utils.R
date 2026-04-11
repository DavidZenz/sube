.sube_required_columns <- function(data, required, call = NULL) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop(
      sprintf("Missing required columns: %s", paste(missing, collapse = ", ")),
      call. = isTRUE(call)
    )
  }
}

.as_data_table <- function(x) {
  data <- data.table::as.data.table(x)
  data.table::setDT(data)
  data
}

.standardize_names <- function(data) {
  out <- .as_data_table(data)
  setnames(out, names(out), toupper(names(out)))
  out
}

.parse_year_from_name <- function(path) {
  file_name <- basename(path)
  hit <- regmatches(file_name, regexpr("intsut[0-9]{2}", tolower(file_name)))
  if (length(hit) == 1L && nzchar(hit)) {
    return(as.integer(sprintf("20%s", substr(hit, 7L, 8L))))
  }

  hit <- regmatches(file_name, gregexpr("(19|20)[0-9]{2}", file_name))[[1L]]
  if (length(hit) > 0L && nzchar(hit[1L])) {
    return(as.integer(hit[1L]))
  }

  NA_integer_
}

.coerce_map <- function(map, from_name, to_name) {
  data <- .standardize_names(map)
  if (ncol(data) < 2L) {
    stop("Mapping tables must have at least two columns.", call. = FALSE)
  }

  synonyms <- list(
    cpa = c("CPA", "CPA56", "CPA_CODE"),
    cpa_agg = c("CPAAGG", "CPA_AGG", "PRODUCT", "PRODUCT_AGG"),
    vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2"),
    ind_agg = c("INDAGG", "IND_AGG", "INDUSTRY_AGG", "SECTOR")
  )

  lookup <- function(target) {
    hits <- intersect(synonyms[[target]], names(data))
    if (length(hits) > 0L) hits[1L] else names(data)[match(target, c(from_name, to_name))]
  }

  from_col <- lookup(from_name)
  to_col <- lookup(to_name)
  setnames(data, c(from_col, to_col), c(from_name, to_name), skip_absent = TRUE)
  data[, .SD, .SDcols = c(from_name, to_name)]
}

.safe_solve <- function(x) {
  tryCatch(solve(x), error = function(e) NULL)
}

.safe_confint <- function(model) {
  tryCatch(
    {
      intervals <- data.table::as.data.table(confint(model))
      intervals[, term := rownames(confint(model))]
      setcolorder(intervals, c("term", "V1", "V2"))
      setnames(intervals, c("V1", "V2"), c("lwr", "upr"))
      intervals
    },
    error = function(e) data.table(term = names(coef(model)), lwr = NA_real_, upr = NA_real_)
  )
}

.safe_density_limits <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(range(c(0, x), na.rm = TRUE))
  }
  c(min(x, na.rm = TRUE), quantile(x, probs = 0.99, na.rm = TRUE, names = FALSE))
}

.validate_class <- function(x, expected) {
  if (!inherits(x, expected)) {
    stop(sprintf("Expected an object of class '%s'.", expected), call. = FALSE)
  }
}

.as_long_result <- function(data, id_cols, value_cols, measure, type) {
  long <- melt(.as_data_table(data), id.vars = id_cols, measure.vars = value_cols,
    variable.name = "variable", value.name = "value"
  )
  long[, measure := measure]
  long[, type := type]
  long
}
