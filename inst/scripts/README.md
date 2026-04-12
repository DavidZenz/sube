# Replication Scripts

## replicate_paper.R

Replicates the WIOD-based SUBE multiplier and elasticity computation from the
original paper (Stehrer & Zenz, 2018) using the `sube` R package, then compares
against the legacy output.

### What it does

1. **Imports** WIOD domestic SUTs from wide-format CSVs (46 files, 43 countries, 2000–2014)
2. **Melts** wide CSVs to long format and extracts the domestic block (REP == PAR)
3. **Loads** CPA and industry correspondence tables (56 → 22 aggregation)
4. **Builds** 645 country-year supply/use matrix pairs via `build_matrices()`
5. **Loads** GO, VA, EMP, CO2 inputs from Stata files, aggregates to 22 industries
6. **Computes** Leontief multipliers and final-demand elasticities via `compute_sube()`
7. **Compares** raw results against `final_multipliers.csv` / `final_elasticities.csv`
8. **Applies** the legacy 6-layer outlier treatment from `08_outlier_treatment.R`
9. **Re-compares** filtered results for a like-for-like match

### Results (as of 2026-04-12)

**After outlier treatment, matching the legacy averaging order:**

| Metric | Mean |diff| | Mean |%| | Max |%| |
|--------|-------------|---------|---------|
| GO multiplier | 0.049 | 2.69% | 42.7% |
| VA multiplier | 0.042 | 6.20% | 109.4% |
| GO elasticity | 0.003 share pts | — | — |

AUS GO multipliers: 17 of 18 products within 1% of legacy. The one outlier
(P07, 12%) is likely excluded in the legacy by the OLS-side merge filter.

### Known friction points

1. **Wide CSV format**: the WIOD domestic CSVs need manual `melt()` — `import_suts()`
   currently only handles pre-melted long CSVs or Excel workbooks.
2. **Case mismatch**: `build_matrices()` does `toupper(final_demand_var)` but melted
   VAR values keep original case. Fix: uppercase VAR values before calling.
3. **Inputs aggregation**: raw GO/VA/EMP/CO2 `.dta` files are 56-industry; must
   aggregate to 22 industries using the correspondence table.

### Requirements

- `sube` package installed (`devtools::install()`)
- WIOD data in `inst/extdata/wiod/` (gitignored, not shipped in tarball)
- Legacy results in `inst/extdata/wiod/Regression/final/`

### Usage

```r
Rscript inst/scripts/replicate_paper.R
# or source interactively in RStudio
```
