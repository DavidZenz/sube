\name{extract_leontief_matrices}
\alias{extract_leontief_matrices}
\alias{prepare_sube_comparison}
\alias{plot_paper_comparison}
\alias{plot_paper_regression}
\alias{plot_paper_interval_ranges}
\title{Leontief Extraction and Comparison Workflow Tools}
\usage{
extract_leontief_matrices(results, matrix = c("A", "L"), format = c("list", "long", "wide"))

prepare_sube_comparison(
  leontief,
  models,
  measure = c("multiplier", "elasticity"),
  aggregate_years = TRUE,
  variables = c("GO", "VA", "EMP", "CO2"),
  apply_paper_filters = TRUE
)

plot_paper_comparison(
  data,
  kind = c("by_country", "by_product", "density"),
  measure = c("multiplier", "elasticity"),
  variables = c("GO", "VA", "EMP"),
  type = NULL,
  label_outliers = TRUE
)

plot_paper_regression(
  data,
  method = c("between", "pooled", "ols"),
  measure = c("multiplier", "elasticity"),
  variables = c("GO", "VA", "EMP"),
  include_ci = TRUE
)

plot_paper_interval_ranges(models, by = c("country", "product"), variables = c("GO", "VA", "EMP"))
}
\arguments{
  \item{results}{A \code{sube_results} object.}
  \item{matrix}{Which Leontief-related matrix to extract.}
  \item{format}{Output format.}
  \item{leontief}{A \code{sube_results} object.}
  \item{models}{A \code{sube_models} object.}
  \item{measure}{Comparison measure.}
  \item{aggregate_years}{Whether to average yearly Leontief and OLS results.}
  \item{variables}{Variables to include.}
  \item{apply_paper_filters}{Whether to apply the paper exclusion rules.}
  \item{data}{A tidy comparison table from \code{prepare_sube_comparison()}.}
  \item{kind}{Paper-style plot family.}
  \item{type}{Comparison types to plot.}
  \item{label_outliers}{Whether to annotate boxplot outliers.}
  \item{method}{Model method to compare against Leontief.}
  \item{include_ci}{Whether to show prediction intervals.}
  \item{by}{Orientation for interval-range plots.}
}
\value{
Extraction helpers return lists or \code{data.table} objects. Plot helpers
return named lists of \code{ggplot} objects.
}
\description{
Utilities for exposing Leontief matrices, preparing comparison tables, and reproducing the comparison, plotting, and interpretation workflow described in the package documentation and companion paper context.
}
