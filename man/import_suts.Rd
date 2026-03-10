\name{import_suts}
\alias{import_suts}
\alias{extract_domestic_block}
\alias{sube_example_data}
\title{Import and Prepare Supply-Use Data}
\usage{
import_suts(path, sheets = c("SUP", "USE"), recursive = FALSE)

extract_domestic_block(data)

sube_example_data(name = c("sut_data", "cpa_map", "ind_map", "inputs", "model_data"))
}
\arguments{
  \item{path}{Path to an Excel workbook, normalized CSV, or directory of inputs.}
  \item{sheets}{Sheet names to read from workbook inputs.}
  \item{recursive}{Whether to search subdirectories.}
  \item{data}{Imported SUT data.}
  \item{name}{Example dataset name.}
}
\value{
`import_suts()` returns a long-form `data.table` with standard SUBE columns.
`extract_domestic_block()` returns the domestic subset. `sube_example_data()`
returns a small shipped example table.
}
\description{
Helpers for reading SUBE-style supply-use tables and loading sample data.
}

