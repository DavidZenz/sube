\name{build_matrices}
\alias{build_matrices}
\title{Build Domestic Supply and Use Matrices}
\usage{
build_matrices(sut_data, cpa_map, ind_map, final_demand_var = "FU_bas")
}
\arguments{
  \item{sut_data}{Long-form SUT data.}
  \item{cpa_map}{Product correspondence table.}
  \item{ind_map}{Industry correspondence table.}
  \item{final_demand_var}{Long-form variable used for final demand.}
}
\value{
A `sube_matrices` object containing aggregated long-form data, final demand,
and a list of country-year `S` and `U` matrices.
}
\description{
Aggregates long-form SUT data onto product and industry mappings and builds the
country-year matrix bundle used by `compute_sube()`.
}

