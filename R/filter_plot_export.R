#' Filter, Plot, and Export SUBE Results
#'
#' `filter_sube()` applies configurable exclusions and bounds to tidy SUBE
#' outputs.
#'
#' `plot_sube()` generates boxplots or densities from tidy SUBE outputs.
#'
#' `write_sube()` writes a `data.frame`, `data.table`, or named list of tables
#' to CSV, RDS, or DTA files.
#'
#' @param data Tidy SUBE data. Expected columns are `COUNTRY`, `CPAagg`,
#'   `variable`, `measure`, `type`, and `value`. `YEAR` is optional.
#' @param country_exclusions Countries to drop.
#' @param year_exclusions Years to drop.
#' @param product_exclusions Product codes to drop.
#' @param bounds Named list of lower and upper bounds by measure and variable.
#' @param drop_negative_elasticities Whether to remove negative elasticities.
#' @param by Orientation for boxplots.
#' @param kind Plot type.
#' @param measure Optional measure filter.
#' @param variable Optional variable filter.
#' @param path Output path. For lists, a directory will be created if needed.
#' @param format Output format.
#'
#' @return `filter_sube()` returns a filtered `data.table`. `plot_sube()`
#'   returns a `ggplot` object. `write_sube()` returns the normalized output
#'   path invisibly.
#' @export
filter_sube <- function(
    data,
    country_exclusions = character(),
    year_exclusions = NULL,
    product_exclusions = character(),
    bounds = list(
      multiplier = list(GO = c(1, 4), VA = c(0, 1), EMP = c(0, Inf), CO2 = c(0, Inf)),
      elasticity = list(default = c(0, Inf))
    ),
    drop_negative_elasticities = TRUE) {
  data <- .standardize_names(data)
  if ("Y" %in% names(data) && !"VARIABLE" %in% names(data)) {
    setnames(data, "Y", "VARIABLE")
  }
  .sube_required_columns(data, c("COUNTRY", "CPAAGG", "VARIABLE", "TYPE"))

  value_col <- intersect(c("VALUE", "ESTIMATE", "ELASTICITY"), names(data))
  if (length(value_col) == 0L) {
    stop("`data` must include VALUE, ESTIMATE, or ELASTICITY.", call. = FALSE)
  }
  value_col <- value_col[1L]
  setnames(data, value_col, "VALUE", skip_absent = TRUE)
  if (!"MEASURE" %in% names(data)) {
    data[, MEASURE := "multiplier"]
  }

  out <- data.table::copy(data)
  if (length(country_exclusions) > 0L) {
    out <- out[!COUNTRY %in% toupper(country_exclusions)]
  }
  if (!is.null(year_exclusions) && "YEAR" %in% names(out)) {
    out <- out[!YEAR %in% year_exclusions]
  }
  if (length(product_exclusions) > 0L) {
    out <- out[!CPAAGG %in% toupper(product_exclusions)]
  }

  if (drop_negative_elasticities) {
    out <- out[!(MEASURE == "elasticity" & VALUE < 0)]
  }

  for (measure_name in names(bounds)) {
    subset_bounds <- bounds[[measure_name]]
    measure_mask <- tolower(out$MEASURE) == tolower(measure_name)
    if (!any(measure_mask)) {
      next
    }
    for (variable_name in names(subset_bounds)) {
      lims <- subset_bounds[[variable_name]]
      var_mask <- if (variable_name == "default") measure_mask else measure_mask & out$VARIABLE == toupper(variable_name)
      out <- out[!(var_mask & (VALUE < lims[[1]] | VALUE > lims[[2]]))]
    }
  }

  out[]
}

#' @rdname filter_sube
#' @export
plot_sube <- function(data, by = c("country", "product"), kind = c("boxplot", "density"), measure = NULL, variable = NULL) {
  data <- .standardize_names(data)
  if ("Y" %in% names(data) && !"VARIABLE" %in% names(data)) {
    setnames(data, "Y", "VARIABLE")
  }
  value_col <- intersect(c("VALUE", "ESTIMATE", "ELASTICITY"), names(data))
  if (length(value_col) == 0L) {
    stop("`data` must include VALUE, ESTIMATE, or ELASTICITY.", call. = FALSE)
  }
  setnames(data, value_col[1L], "VALUE", skip_absent = TRUE)
  if (!"MEASURE" %in% names(data)) {
    data[, MEASURE := "multiplier"]
  }

  by <- match.arg(by)
  kind <- match.arg(kind)
  if (!is.null(measure)) {
    data <- data[tolower(MEASURE) == tolower(measure)]
  }
  if (!is.null(variable)) {
    data <- data[VARIABLE == toupper(variable)]
  }

  if (kind == "density") {
    limits <- .safe_density_limits(data$VALUE)
    return(
      ggplot(data, aes(x = VALUE, colour = TYPE, fill = TYPE)) +
        geom_density(alpha = 0.15) +
        facet_wrap(~VARIABLE, scales = "free") +
        labs(x = "Value", y = "Density") +
        theme_minimal() +
        ggplot2::coord_cartesian(xlim = limits)
    )
  }

  if (by == "country") {
    plot <- ggplot(data, aes(x = COUNTRY, y = VALUE, fill = TYPE)) +
      geom_boxplot(outlier.alpha = 0.4) +
      facet_wrap(~VARIABLE, scales = "free_y")
  } else {
    plot <- ggplot(data, aes(x = CPAAGG, y = VALUE, fill = TYPE)) +
      geom_boxplot(outlier.alpha = 0.4) +
      facet_wrap(~VARIABLE, scales = "free_y")
  }

  plot +
    labs(x = NULL, y = "Value") +
    theme_minimal() +
    theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))
}

#' @rdname filter_sube
#' @export
write_sube <- function(path, data, format = c("csv", "rds", "dta")) {
  format <- match.arg(format)

  write_one <- function(target, object) {
    if (format == "csv") {
      data.table::fwrite(object, target)
    } else if (format == "rds") {
      saveRDS(object, target)
    } else {
      haven::write_dta(as.data.frame(object), target)
    }
  }

  if (is.data.frame(data) || data.table::is.data.table(data)) {
    target <- path
    if (!grepl(sprintf("\\.%s$", format), target)) {
      target <- sprintf("%s.%s", path, format)
    }
    write_one(target, data)
    return(invisible(normalizePath(target, winslash = "/", mustWork = FALSE)))
  }

  if (!is.list(data) || is.null(names(data))) {
    stop("`data` must be a table or a named list of tables.", call. = FALSE)
  }

  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  for (name in names(data)) {
    write_one(file.path(path, sprintf("%s.%s", name, format)), data[[name]])
  }
  invisible(normalizePath(path, winslash = "/", mustWork = FALSE))
}
