\name{filter_sube}
\alias{filter_sube}
\alias{plot_sube}
\alias{write_sube}
\title{Filter, Plot, and Export SUBE Results}
\usage{
filter_sube(
  data,
  country_exclusions = character(),
  year_exclusions = NULL,
  product_exclusions = character(),
  bounds = list(multiplier = list(GO = c(1, 4), VA = c(0, 1), EMP = c(0, Inf), CO2 = c(0, Inf)),
    elasticity = list(default = c(0, Inf))),
  drop_negative_elasticities = TRUE
)

plot_sube(data, by = c("country", "product"), kind = c("boxplot", "density"),
  measure = NULL, variable = NULL)

write_sube(path, data, format = c("csv", "rds", "dta"))
}
\arguments{
  \item{data}{Tidy SUBE data.}
  \item{country_exclusions}{Country codes to remove.}
  \item{year_exclusions}{Years to remove.}
  \item{product_exclusions}{Product codes to remove.}
  \item{bounds}{Named bounds by measure and variable.}
  \item{drop_negative_elasticities}{Whether to remove negative elasticities.}
  \item{by}{Grouping used for boxplots.}
  \item{kind}{Plot type.}
  \item{measure}{Optional measure filter.}
  \item{variable}{Optional variable filter.}
  \item{path}{Output path.}
  \item{format}{Output format.}
}
\value{
`filter_sube()` returns a filtered table, `plot_sube()` returns a `ggplot`
object, and `write_sube()` returns the output path invisibly.
}
\description{
Utilities for constraining, visualizing, and exporting tidy SUBE outputs.
}

