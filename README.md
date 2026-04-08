# sube

`sube` is an R package for supply-use based econometrics. It supports a full
workflow from rectangular supply and use tables to domestic matrix
construction, Leontief-style benchmark multipliers, SUBE regression estimates,
and paper-style comparison plots.

The package is designed for applied input-output work, especially when supply
and use tables are part of a larger comparative or panel-data setting. It is
also a companion package to the paper by Stehrer, Rueda-Cantuche, Amores, and
Zenz, where supply-use based econometrics are used to compare benchmark
Leontief results with econometric multiplier estimates and uncertainty ranges.

The companion article is:

Stehrer, R., Rueda-Cantuche, J.M., Amores, A.F. et al. (2024),
*Wrapping input-output multipliers in confidence intervals*, *Journal of
Economic Structures* 13, 17.
[Springer article](https://link.springer.com/article/10.1186/s40008-024-00331-4),
[DOI](https://doi.org/10.1186/s40008-024-00331-4).

## Installation

```r
# install.packages("pak")
pak::pak("davidzenz/sube")
```

The modeling workflow requires `plm`, which is installed automatically when you
install package dependencies.

## What the package does

- imports and standardizes supply-use inputs
- extracts domestic blocks from multi-country tables
- builds product-industry matrices for rectangular systems
- computes Leontief-style multipliers and elasticities
- estimates OLS, pooled, and between SUBE models
- prepares paper-style comparison tables and plots

## Core workflow

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

Model estimation and comparison are separate steps on a prepared modeling
table:

```r
model_data <- sube_example_data("model_data")
models <- estimate_elasticities(model_data, predictor_vars = c("P01", "P02"))
comparison <- prepare_sube_comparison(result, models, measure = "multiplier")
head(extract_leontief_matrices(result, matrix = "L", format = "long"))
names(plot_paper_comparison(comparison, kind = "by_country", variables = "GO"))
```

`write_sube()` writes a single table to one file or a named list of tables to a directory of files, so comparison outputs can be exported without extra post-processing code.

## Why the package is structured this way

`sube` starts from a simple idea: supply and use tables are useful not only for
point-estimate multiplier analysis, but also for comparative econometric work.
The package therefore keeps both sides of the workflow visible:

- Leontief matrices and multipliers as the benchmark layer
- SUBE regressions as the econometric layer
- comparison objects and plots as the interpretation layer

This makes the package useful both for general supply-use based econometrics
and for reproducing the style of comparisons developed in the companion paper.

If you are new to the paper, the practical motivation is straightforward:
Leontief multipliers remain the benchmark, but empirical work often needs a way
to compare them with econometric estimates, uncertainty ranges, and
cross-country variation. `sube` is designed around that bridge.

For local documentation work, the paper reference is kept in
`inst/references/`, but it is excluded from the built package tarball.

## Documentation

- `vignette("getting-started", package = "sube")` for the end-to-end sample
  workflow
- `vignette("data-preparation", package = "sube")` for the input contracts
- `vignette("modeling-and-outputs", package = "sube")` for modeling and plot
  outputs
- `vignette("package-design", package = "sube")` for the paper-comparison
  framing and interpretation layer

The full reference and articles are designed to be published with `pkgdown`,
with the website acting as the main public documentation surface.

## Citation

If you use `sube` in research, cite both the package and the companion paper,
especially when using the Leontief-versus-SUBE comparison workflow.

BibTeX-style citation for the paper:

```bibtex
@article{stehrer2024wrapping,
  title   = {Wrapping input-output multipliers in confidence intervals},
  author  = {Stehrer, Robert and Rueda-Cantuche, Jos{\'e} Manuel and Amores, Antonio F. and Zenz, David},
  journal = {Journal of Economic Structures},
  year    = {2024},
  volume  = {13},
  pages   = {17},
  doi     = {10.1186/s40008-024-00331-4},
  url     = {https://doi.org/10.1186/s40008-024-00331-4}
}
```

## Development

Release-quality checks should be run from a built tarball:

```bash
R CMD build .
R CMD check sube_0.1.2.tar.gz --no-manual
```
