# Getting Started with sube

The package centers on five workflow steps:

```r
library(sube)

sut <- sube_example_data("sut_data")
cpa_map <- sube_example_data("cpa_map")
ind_map <- sube_example_data("ind_map")
inputs <- sube_example_data("inputs")

bundle <- build_matrices(sut, cpa_map, ind_map)
result <- compute_sube(bundle, inputs)
head(result$tidy)
```

Regression inputs stay separate from Leontief computation:

```r
model_data <- sube_example_data("model_data")
models <- estimate_elasticities(model_data, predictor_vars = c("P01", "P02"))
head(models$tidy)
```
