# Replication Scripts

## replicate_paper.R

Replicates the WIOD-based SUBE multiplier and elasticity computation from the
original paper (Stehrer & Zenz, 2018) using the `sube` R package, then compares
against the legacy output.

### What it does

1. **Imports** WIOD domestic SUTs from wide-format CSVs (46 files, 43 countries, 2000-2014)
2. **Melts** wide CSVs to long format and extracts the domestic block (REP == PAR)
3. **Loads** CPA and industry correspondence tables (56 -> 22 aggregation)
4. **Builds** 645 country-year supply/use matrix pairs via `build_matrices()`
5. **Loads** GO, VA, EMP, CO2 inputs from Stata files, aggregates to 22 industries
6. **Computes** Leontief multipliers and final-demand elasticities via `compute_sube()`
7. **Compares** raw results against `final_multipliers.csv` / `final_elasticities.csv`
8. **Applies** the legacy 6-layer outlier treatment from `08_outlier_treatment.R`
9. **Re-compares** filtered results for a like-for-like match
10. **Builds** the net-supply regression matrix W = t(SUP_agg - USE_agg) via
    `build_matrices(inputs=)` and runs `estimate_elasticities()`
11. **Compares** OLS, pooled, and between estimates against legacy regression output

### Results

**Leontief (after outlier treatment):**

| Metric | Mean |diff| | Mean |%| |
|--------|-------------|---------|
| GO multiplier | 0.049 | 2.69% |
| VA multiplier | 0.042 | 6.20% |
| GO elasticity | 0.003 share pts | -- |

AUS GO multipliers: 17 of 18 products within 1% of legacy.

**Regression:**

| Method | Mean |diff| estimate | Max |diff| estimate |
|--------|---------------------|---------------------|
| OLS | 0.017 (excl. set.zero) | 310.5 |
| Pooled | 0.030 | 26.7 |
| Between | 0.065 | 19.6 |

OLS estimates match to 4+ decimal places for statistically significant terms.
AUS 2005 GO: all 22 products within 0.001 of legacy.

**Exact matches:**
- Raw S/U matrices (56x56)
- Net-supply model matrix W = SUP - USE (56 industries x 22 products)

### Issues resolved during replication

1. **Wide CSV format**: `import_suts()` now auto-detects and melts wide-format CSVs.
2. **Case mismatch**: `build_matrices()` now uppercases VAR values internally.
3. **Regression model matrix**: The legacy regression uses the net-supply matrix
   W = t(SUP_agg - USE_agg) (found in `05_SUBE_regress.R`), not the Leontief Z
   matrix. `build_matrices(inputs=)` now computes this correctly.
4. **Panel regression errors**: `estimate_elasticities()` now wraps panel models
   in tryCatch to handle singular-matrix countries gracefully.

### Requirements

- `sube` package loaded via `devtools::load_all()` (or installed with latest code)
- WIOD data in `inst/extdata/wiod/` (gitignored, not shipped in tarball)
- Legacy results in `inst/extdata/wiod/Regression/final/` and `check/`

### Usage

```r
Rscript inst/scripts/replicate_paper.R
# or source interactively in RStudio
```
