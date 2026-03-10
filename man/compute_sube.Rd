\name{compute_sube}
\alias{compute_sube}
\title{Compute SUBE Multipliers and Elasticities}
\usage{
compute_sube(
  matrix_bundle,
  inputs,
  metrics = c("GO", "VA", "EMP", "CO2"),
  diagonal_adjustment = 1,
  zero_replacement = 1e-06
)
}
\arguments{
  \item{matrix_bundle}{A `sube_matrices` object.}
  \item{inputs}{Industry-level input data including `GO`.}
  \item{metrics}{Metrics to compute.}
  \item{diagonal_adjustment}{Value added to the supply diagonal before inversion.}
  \item{zero_replacement}{Replacement value for zero `GO` elements.}
}
\value{
A `sube_results` object with summary tables, tidy results, diagnostics, and
coefficient matrices.
}
\description{
Computes Leontief-style multipliers and final-demand elasticities for each
country-year matrix bundle.
}

