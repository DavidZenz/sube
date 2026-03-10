# sube

`sube` turns the original SUBE script workflow into a reusable R package for
importing supply-use tables, building domestic matrices, computing
Leontief-style multipliers, estimating elasticity models, and exporting tidy
results.

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

## Documentation

- Get started with the package in `vignette("getting-started", package = "sube")`
- Learn how external inputs should be prepared in
  `vignette("data-preparation", package = "sube")`
- See the modeling and output workflow in
  `vignette("modeling-and-outputs", package = "sube")`

The full reference and articles are designed to be published with `pkgdown`.

## Development

Release-quality checks should be run from a built tarball:

```bash
R CMD build .
R CMD check sube_0.1.0.tar.gz --no-manual
```

