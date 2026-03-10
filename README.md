# sube

`sube` is an R package for supply-use based econometrics. It provides a
reproducible workflow for importing supply and use tables, building domestic
product-industry matrices, computing Leontief-style multipliers, estimating
SUBE regressions, and exporting tidy outputs for downstream analysis.

The package is also designed as a companion to the paper by Stehrer,
Rueda-Cantuche, Amores, and Zenz on wrapping input-output multipliers in
confidence intervals. In that context, `sube` helps operationalize the
Supply-Use-Based Econometric (SUBE) approach on rectangular supply and use
tables and panel-style modeling data.

## Installation

```r
# install.packages("pak")
pak::pak("davidzenz/sube")
```

The modeling workflow requires `plm`, which is installed automatically when you
install package dependencies.

## Workflow

```r
library(sube)

sut <- sube_example_data("sut_data")
cpa_map <- sube_example_data("cpa_map")
ind_map <- sube_example_data("ind_map")
inputs <- sube_example_data("inputs")

bundle <- build_matrices(
  sut_data = extract_domestic_block(sut),
  cpa_map = cpa_map,
  ind_map = ind_map
)

result <- compute_sube(bundle, inputs)
head(result$tidy)
```

Model estimation is a separate step on a prepared modeling table:

```r
model_data <- sube_example_data("model_data")
models <- estimate_elasticities(model_data, predictor_vars = c("P01", "P02"))
head(models$tidy)
```

## Paper context

The package follows the broader idea that supply and use tables can be used not
only for point-estimate Leontief multipliers, but also for econometric
estimation of multipliers and related uncertainty measures. The companion paper
uses the SUBE approach on WIOD-based supply and use data and panel-data
econometrics to compare Leontief and econometric multipliers across countries,
products, and years.

For local documentation work, the paper reference is kept in
`inst/references/`, but it is excluded from the built package tarball.

## Documentation

- Get started with the package in `vignette("getting-started", package = "sube")`
- Learn how external inputs should be prepared in
  `vignette("data-preparation", package = "sube")`
- See the modeling and output workflow in
  `vignette("modeling-and-outputs", package = "sube")`

The full reference and articles are designed to be published with `pkgdown`.

## Citation

If you use `sube` as part of a research workflow, cite the companion paper and
the package together. The package documentation will be expanded further around
that paper-oriented framing in the next documentation pass.

## Development

Release-quality checks should be run from a built tarball:

```bash
R CMD build .
R CMD check sube_0.1.1.tar.gz --no-manual
```
