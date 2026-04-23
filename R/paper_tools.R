#' Leontief and Paper-Style Comparison Tools
#'
#' These helpers expose the Leontief matrices already computed by
#' [compute_sube()], build comparison datasets that align Leontief and SUBE
#' estimates, and generate plots modeled on the archived paper workflow.
#'
#' @param results A `sube_results` object returned by [compute_sube()].
#' @param matrix Which matrix to extract. One of `"A"` or `"L"`.
#' @param format Output format. One of `"list"`, `"long"`, or `"wide"`.
#' @param leontief A `sube_results` object.
#' @param models A `sube_models` object returned by [estimate_elasticities()].
#' @param measure Which quantity to compare. One of `"multiplier"` or
#'   `"elasticity"`.
#' @param aggregate_years Whether yearly Leontief and OLS results should be
#'   averaged over time as in the paper comparison tables.
#' @param variables Variables to include.
#' @param apply_paper_filters Whether to apply the 2024 paper exclusion rules.
#' @param data A tidy comparison table returned by [prepare_sube_comparison()].
#' @param kind Plot type: `"by_country"`, `"by_product"`, or `"density"`.
#' @param type Comparison types to plot. Defaults to all available types.
#' @param label_outliers Whether to annotate Tukey outliers.
#' @param method Model type to compare against Leontief in regression plots.
#' @param include_ci Whether to include the prediction interval ribbon.
#' @param by Orientation for interval range plots.
#'
#' @return `extract_leontief_matrices()` returns a list or `data.table`.
#'   `prepare_sube_comparison()` returns a tidy `data.table`.
#'   `plot_paper_comparison()`, `plot_paper_regression()`, and
#'   `plot_paper_interval_ranges()` return named lists of `ggplot` objects.
#' @export
extract_leontief_matrices <- function(results, matrix = c("A", "L"), format = c("list", "long", "wide")) {
  .validate_class(results, "sube_results")
  matrix <- match.arg(matrix)
  format <- match.arg(format)

  mats <- lapply(results$matrices, function(entry) {
    list(country = entry$country, year = entry$year, data = entry[[matrix]])
  })
  names(mats) <- names(results$matrices)

  if (format == "list") {
    return(mats)
  }

  long <- rbindlist(lapply(mats, function(entry) {
    mat <- entry$data
    dt <- data.table::as.data.table(as.table(mat))
    setnames(dt, c("row", "col", "value"))
    dt[, `:=`(COUNTRY = entry$country, YEAR = entry$year, matrix = matrix)]
    setcolorder(dt, c("COUNTRY", "YEAR", "matrix", "row", "col", "value"))
    dt[]
  }), fill = TRUE)

  if (format == "long") {
    return(long[])
  }

  wide <- rbindlist(lapply(mats, function(entry) {
    mat <- data.table::as.data.table(entry$data, keep.rownames = "row")
    mat[, `:=`(COUNTRY = entry$country, YEAR = entry$year, matrix = matrix)]
    setcolorder(mat, c("COUNTRY", "YEAR", "matrix", "row", setdiff(names(mat), c("COUNTRY", "YEAR", "matrix", "row"))))
    mat[]
  }), fill = TRUE)
  wide[]
}

.paper_cpa_group <- function(cpaagg) {
  ifelse(cpaagg %in% sprintf("P%02d", 1:11), "P01-P11", "P12-P22")
}

.paper_outlier_labels <- function(data, group_col, label_col, value_col = "value") {
  split_data <- split(data, data[[group_col]])
  out <- rbindlist(lapply(split_data, function(chunk) {
    vals <- chunk[[value_col]]
    q1 <- stats::quantile(vals, 0.25, na.rm = TRUE, names = FALSE)
    q3 <- stats::quantile(vals, 0.75, na.rm = TRUE, names = FALSE)
    iqr <- q3 - q1
    is_out <- vals < (q1 - 1.5 * iqr) | vals > (q3 + 1.5 * iqr)
    chunk[, outlier := ifelse(is_out, as.character(get(label_col)), NA_character_)]
    chunk[]
  }), fill = TRUE)
  out[]
}

.paper_theme <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = NA, colour = "black"),
      panel.border = ggplot2::element_rect(fill = NA, colour = "black"),
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1)
    )
}

.models_to_comparison <- function(models, measure) {
  tables <- list(ols = models$ols, pooled = models$pooled, between = models$between)
  value_col <- if (identical(measure, "multiplier")) "estimate" else "elasticity"
  rbindlist(lapply(names(tables), function(name) {
    data <- data.table::copy(tables[[name]])
    data[, CPAagg := term]
    data[, variable := y]
    data[, measure := measure]
    data[, value := get(value_col)]
    data[, type := name]
    keep <- c("COUNTRY", "YEAR", "CPAagg", "variable", "measure", "type", "value", "estimate", "elasticity", "lwr", "upr")
    data[, ..keep]
  }), fill = TRUE)
}

#' Apply the paper's outlier treatment
#'
#' Applies the six exclusion layers from the 2024 paper's outlier
#' treatment to a SUBE comparison table or results summary. These are
#' historical, paper-specific filters - not general-purpose data-quality
#' rules.
#'
#' The six layers:
#' \enumerate{
#'   \item Drop whole countries: \code{CAN}, \code{CYP}.
#'   \item Drop country-year range: \code{BEL} 2000-2008; drop \code{CO2} rows with \code{YEAR > 2009}.
#'   \item Drop 38 country-product pairs across 14 countries (e.g. \code{LUX} P04/P05/P06/...).
#'   \item Drop \code{CO2} rows for \code{CHE}, \code{HRV}, \code{NOR}.
#'   \item Multiplier plausibility bounds (only when \code{apply_bounds = TRUE}):
#'     \code{GO} in \code{[1, 4]}, \code{VA} in \code{[0, 1]}, \code{EMP}/\code{CO2} >= 0.
#'   \item Drop rows where elasticity is negative.
#' }
#'
#' @param data A tidy comparison table (the shape returned by
#'   \code{\link{prepare_sube_comparison}}) or a SUBE results summary with
#'   \code{COUNTRY, YEAR, CPAagg, variable, measure, value} columns.
#' @param variables Character vector subset of \code{c("GO", "VA", "EMP", "CO2")}
#'   indicating which metrics to retain. Rows whose \code{variable} is not in
#'   this set are dropped before the layered filters apply. Defaults to all four.
#' @param apply_bounds Logical; whether to apply layer 5 (multiplier
#'   plausibility bounds). Defaults to \code{TRUE}. Set \code{FALSE} to keep
#'   multiplier outliers in the output.
#' @return A filtered \code{data.table} with the same columns as \code{data}.
#' @export
#' @examples
#' \dontrun{
#'   comp <- prepare_sube_comparison(leontief, models)
#'   filt <- filter_paper_outliers(comp)
#'   filt_no_bounds <- filter_paper_outliers(comp, apply_bounds = FALSE)
#' }
filter_paper_outliers <- function(data,
                                  variables = c("GO", "VA", "EMP", "CO2"),
                                  apply_bounds = TRUE) {
  variables <- toupper(variables)
  out <- data.table::copy(data)
  if ("variable" %in% names(out)) {
    out <- out[variable %in% variables]
  }
  out <- out[!COUNTRY %in% c("CAN", "CYP")]
  if ("YEAR" %in% names(out)) {
    out <- out[!(COUNTRY == "BEL" & YEAR %in% 2000:2008)]
    if ("variable" %in% names(out)) {
      out <- out[!(variable == "CO2" & YEAR > 2009)]
    }
  }

  exclusion_map <- list(
    BEL = "P14",
    BRA = "P11",
    DNK = c("P04", "P09"),
    FIN = "P20",
    GRC = c("P09", "P10"),
    HRV = c("P05", "P12", "P18"),
    IRL = "P06",
    LUX = c("P04", "P05", "P06", "P09", "P12", "P15", "P17"),
    KOR = "P11",
    MEX = "P19",
    MLT = c("P08", "P10", "P15", "P20"),
    POL = "P15",
    RUS = c("P20", "P22"),
    SVN = c("P05", "P19")
  )
  for (country in names(exclusion_map)) {
    out <- out[!(COUNTRY == country & CPAagg %in% exclusion_map[[country]])]
  }

  if ("variable" %in% names(out)) {
    out <- out[!(variable == "CO2" & COUNTRY %in% c("CHE", "HRV", "NOR"))]
  }

  if (isTRUE(apply_bounds) && "value" %in% names(out) && "variable" %in% names(out) && "measure" %in% names(out)) {
    out <- out[!(measure == "multiplier" & variable == "GO" & (value < 1 | value > 4))]
    out <- out[!(measure == "multiplier" & variable == "VA" & (value < 0 | value > 1))]
    out <- out[!(measure == "multiplier" & variable %in% c("EMP", "CO2") & value < 0)]
  }
  if ("value" %in% names(out) && "measure" %in% names(out)) {
    out <- out[!(measure == "elasticity" & value < 0)]
  }
  out[]
}

#' @rdname extract_leontief_matrices
#' @export
prepare_sube_comparison <- function(
    leontief,
    models,
    measure = c("multiplier", "elasticity"),
    aggregate_years = TRUE,
    variables = c("GO", "VA", "EMP", "CO2"),
    apply_paper_filters = TRUE) {
  .validate_class(leontief, "sube_results")
  .validate_class(models, "sube_models")
  measure <- match.arg(measure)
  variables <- toupper(variables)

  leo <- data.table::copy(leontief$tidy)
  leo <- leo[tolower(measure) == tolower(leo$measure) & variable %in% variables]
  leo[, type := "leontief"]
  leo <- leo[, .(COUNTRY, YEAR, CPAagg, variable, measure, type, value)]

  model_data <- .models_to_comparison(models, measure)
  model_data <- model_data[variable %in% variables]
  comparison <- rbindlist(list(leo, model_data), fill = TRUE)

  if (aggregate_years) {
    yearly <- comparison[type %in% c("leontief", "ols"), .(
      value = mean(value, na.rm = TRUE),
      estimate = mean(estimate, na.rm = TRUE),
      elasticity = mean(elasticity, na.rm = TRUE),
      lwr = mean(lwr, na.rm = TRUE),
      upr = mean(upr, na.rm = TRUE)
    ), by = .(COUNTRY, CPAagg, variable, measure, type)]
    non_yearly <- comparison[!type %in% c("leontief", "ols"), .(
      value, estimate, elasticity, lwr, upr, COUNTRY, CPAagg, variable, measure, type
    )]
    comparison <- rbindlist(list(yearly, non_yearly), fill = TRUE)
  }

  comparison[, CPAgroup := .paper_cpa_group(CPAagg)]
  if (apply_paper_filters) {
    comparison <- filter_paper_outliers(comparison, variables = variables)
  }
  comparison[]
}

#' @rdname extract_leontief_matrices
#' @export
plot_paper_comparison <- function(
    data,
    kind = c("by_country", "by_product", "density"),
    measure = c("multiplier", "elasticity"),
    variables = c("GO", "VA", "EMP"),
    type = NULL,
    label_outliers = TRUE) {
  data <- .standardize_names(data)
  .sube_required_columns(data, c("COUNTRY", "CPAAGG", "VARIABLE", "MEASURE", "TYPE", "VALUE"))
  kind <- match.arg(kind)
  measure <- match.arg(measure)
  variables <- toupper(variables)
  plot_data <- data[tolower(MEASURE) == measure & VARIABLE %in% variables]
  plot_data[, TYPE := ifelse(tolower(TYPE) == "leontief", "Leontief", TYPE)]

  if (is.null(type)) {
    type <- unique(plot_data$TYPE)
  }

  if (kind == "density") {
    selected <- plot_data[TYPE %in% type]
    plots <- lapply(variables, function(v) {
      subset <- selected[VARIABLE == v]
      if (nrow(subset) == 0L) {
        return(NULL)
      }
      ggplot(subset, aes(x = VALUE, colour = TYPE, fill = TYPE)) +
        geom_density(alpha = 0.1) +
        labs(x = measure, y = "Density", title = v) +
        ggplot2::scale_colour_grey() +
        ggplot2::scale_fill_grey() +
        .paper_theme()
    })
    names(plots) <- variables
    return(Filter(Negate(is.null), plots))
  }

  plots <- list()
  for (current_type in type) {
    subset <- plot_data[TYPE == current_type]
    plots[[current_type]] <- lapply(variables, function(v) {
      variable_data <- subset[VARIABLE == v]
      if (nrow(variable_data) == 0L) {
        return(NULL)
      }
      if (kind == "by_country") {
        variable_data <- .paper_outlier_labels(variable_data, "COUNTRY", "CPAAGG")
        p <- ggplot(variable_data, aes(x = stats::reorder(COUNTRY, VALUE, stats::median), y = VALUE)) +
          geom_boxplot() +
          labs(x = NULL, y = paste(current_type, measure), title = v)
      } else {
        variable_data <- .paper_outlier_labels(variable_data, "CPAAGG", "COUNTRY")
        p <- ggplot(variable_data, aes(x = stats::reorder(CPAAGG, VALUE, stats::median), y = VALUE, fill = CPAgroup)) +
          geom_boxplot() +
          labs(x = NULL, y = paste(current_type, measure), title = v) +
          ggplot2::scale_fill_grey()
      }

      if (label_outliers) {
        p <- p + ggrepel::geom_text_repel(aes(label = outlier), na.rm = TRUE, size = 2)
      }
      p + ggplot2::scale_colour_grey() + .paper_theme()
    })
    keep_idx <- which(!vapply(plots[[current_type]], is.null, logical(1)))
    plots[[current_type]] <- plots[[current_type]][keep_idx]
    names(plots[[current_type]]) <- variables[keep_idx]
  }
  plots[lengths(plots) > 0L]
}

#' @rdname extract_leontief_matrices
#' @export
plot_paper_regression <- function(
    data,
    method = c("between", "pooled", "ols"),
    measure = c("multiplier", "elasticity"),
    variables = c("GO", "VA", "EMP"),
    include_ci = TRUE) {
  data <- .standardize_names(data)
  .sube_required_columns(data, c("COUNTRY", "CPAAGG", "VARIABLE", "MEASURE", "TYPE", "VALUE"))
  method <- match.arg(method)
  measure <- match.arg(measure)
  variables <- toupper(variables)

  comparison <- data[tolower(MEASURE) == measure & VARIABLE %in% variables & TYPE %in% c("leontief", method)]
  wide <- dcast(comparison, COUNTRY + CPAAGG + VARIABLE ~ TYPE, value.var = "VALUE")
  names(wide) <- sub("^LEONTIEF$", "leontief", names(wide))

  plots <- lapply(variables, function(v) {
    subset <- wide[VARIABLE == v]
    if (nrow(subset) == 0L) {
      return(NULL)
    }
    subset[, trend := seq_len(.N)]
    fit <- lm(stats::as.formula(sprintf("leontief ~ %s + trend", method)), data = subset)
    if (include_ci && nrow(subset) > 2L) {
      pred <- suppressWarnings(data.table::as.data.table(stats::predict(fit, interval = "prediction", level = 0.95)))
      subset <- cbind(subset, pred)
      subset[, outlier := ifelse(leontief < lwr | leontief > upr, paste(COUNTRY, CPAAGG, sep = "-"), NA_character_)]
    } else {
      subset[, `:=`(fit = NA_real_, lwr = NA_real_, upr = NA_real_, outlier = NA_character_)]
    }

    p <- ggplot(subset, aes(x = get(method), y = leontief)) +
      geom_point() +
      ggplot2::stat_smooth(method = "lm", formula = y ~ x, colour = "black", fill = "black", alpha = 0.2, se = FALSE)
    if (include_ci && any(is.finite(subset$lwr)) && any(is.finite(subset$upr))) {
      p <- p + ggplot2::geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "black", alpha = 0.15)
    }
    p +
      ggrepel::geom_text_repel(aes(label = outlier), na.rm = TRUE, size = 2) +
      labs(x = paste(method, measure), y = paste("Leontief", measure), title = v) +
      .paper_theme()
  })
  names(plots) <- variables
  Filter(Negate(is.null), plots)
}

#' @rdname extract_leontief_matrices
#' @export
plot_paper_interval_ranges <- function(models, by = c("country", "product"), variables = c("GO", "VA", "EMP")) {
  .validate_class(models, "sube_models")
  by <- match.arg(by)
  variables <- toupper(variables)

  data <- rbindlist(list(models$ols, models$pooled, models$between), fill = TRUE)
  data <- data[y %in% variables]
  data <- data[is.finite(lwr) & is.finite(upr) & is.finite(estimate)]
  data[, CPAagg := term]
  data[, CPAgroup := .paper_cpa_group(CPAagg)]
  data[, Dp := ((upr - lwr) * 100 / estimate) / 2]
  data <- filter_paper_outliers(data[, .(COUNTRY, CPAagg, CPAgroup, type, variable = y, Dp)])

  plots <- list()
  for (current_type in unique(data$type)) {
    subset <- data[type == current_type]
    plots[[current_type]] <- lapply(variables, function(v) {
      variable_data <- subset[variable == v]
      if (nrow(variable_data) == 0L) {
        return(NULL)
      }
      if (by == "country") {
        variable_data <- .paper_outlier_labels(variable_data, "COUNTRY", "CPAagg", "Dp")
        p <- ggplot(variable_data, aes(x = stats::reorder(COUNTRY, Dp, stats::median), y = Dp)) +
          geom_boxplot() +
          labs(x = NULL, y = paste("Range/2 in per cent for", v), title = paste(current_type, v))
      } else {
        variable_data <- .paper_outlier_labels(variable_data, "CPAagg", "COUNTRY", "Dp")
        p <- ggplot(variable_data, aes(x = stats::reorder(CPAagg, Dp, stats::median), y = Dp, fill = CPAgroup)) +
          geom_boxplot() +
          ggplot2::scale_fill_grey() +
          labs(x = NULL, y = paste("Range/2 in per cent for", v), title = paste(current_type, v))
      }
      p + ggrepel::geom_text_repel(aes(label = outlier), na.rm = TRUE, size = 2) + .paper_theme()
    })
    keep_idx <- which(!vapply(plots[[current_type]], is.null, logical(1)))
    plots[[current_type]] <- plots[[current_type]][keep_idx]
    names(plots[[current_type]]) <- variables[keep_idx]
  }
  plots[lengths(plots) > 0L]
}
