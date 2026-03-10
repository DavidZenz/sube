\name{estimate_elasticities}
\alias{estimate_elasticities}
\title{Estimate OLS and Panel Elasticity Models}
\usage{
estimate_elasticities(
  data,
  response_vars = c("GO", "VA", "EMP", "CO2"),
  predictor_vars = NULL,
  country_col = "COUNTRY",
  year_col = "YEAR",
  entity_col = "INDUSTRIES"
)
}
\arguments{
  \item{data}{Prepared model matrix.}
  \item{response_vars}{Response columns to estimate.}
  \item{predictor_vars}{Predictor columns.}
  \item{country_col}{Country column name.}
  \item{year_col}{Year column name.}
  \item{entity_col}{Entity index column name.}
}
\value{
A `sube_models` object with `ols`, `pooled`, `between`, and combined tidy
tables.
}
\description{
Runs country-year OLS models and country-level pooled and between panel models
for a prepared modeling dataset.
}

