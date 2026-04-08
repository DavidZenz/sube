# Feature Landscape

**Domain:** R package for supply-use based econometrics (sube v1.1 milestone)
**Researched:** 2026-04-08
**Confidence:** MEDIUM — FIGARO structural claims from domain knowledge and paper authorship context (JRC co-authors); one-call/batch patterns from codebase inspection and standard R package conventions; paper replication patterns from testthat idioms already in the repo.

---

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| FIGARO SUT ingestion producing the standard `sube_suts` long table | Second major SUT data source alongside WIOD; JRC paper authorship makes FIGARO the natural extension target | Medium | Existing `import_suts()` contract: REP, PAR, CPA, VAR, VALUE, YEAR, TYPE columns |
| Domestic block extraction from FIGARO (same REP == PAR filter) | Domestic block logic is data-source-agnostic once the long table is normalized | Low | FIGARO ingestion producing correct REP/PAR population |
| Paper replication test producing exact numerical match | Any package claiming to reproduce a paper must be verifiable; without a test, the claim is unauditable | Medium | Existing `prepare_sube_comparison()` and `plot_paper_comparison()` plus real WIOD data outside the package bundle |
| One-call pipeline covering import through compute | Users currently chain five calls with intermediate objects; a single entry point removes setup boilerplate | Low-Medium | All existing exported functions remain stable |
| Batch multi-country/multi-year collection into a single result | The paper covers 43 countries × 15 years; running loops manually is error-prone and repeated across users | Low-Medium | One-call pipeline or direct use of existing `compute_sube()` loop |

---

## Differentiators

Features that set the product apart from generic I-O toolkits.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| FIGARO and WIOD both producing identical `sube_suts` objects | Researchers can swap data sources without changing downstream code | Low (once FIGARO parser exists) | Requires careful column normalization; FIGARO uses different industry codes (NACE rev.2 A64) and file layout |
| Replication vignette with reproducible numerical targets | Makes the companion paper fully auditable from the package; rare in econometric I-O packages | Medium | Vignette runs against `inst/references/` data that is not bundled in release tarball; needs `skip_if_not` guard |
| Batch helper returning a single `sube_results`-like object | Enables country-level panel construction without manual `rbindlist()`; aligns with the panel structure of the paper | Low | Return class should be inspectable without knowing which countries were included |

---

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-downloading FIGARO or WIOD data from the internet | Creates network dependency, version drift, and breaks tarball-based `R CMD check` | Document download steps; accept local file paths only |
| Bundling real WIOD or FIGARO datasets in the package | Release artifacts must stay small; large CSVs break CRAN size limits and tarball checks | Use `inst/references/` (excluded from build) for local replication data; keep only toy examples in `inst/extdata/` |
| A `run_all()` / magic pipeline that hides required mapping tables | Mapping tables (cpa_map, ind_map) are research decisions, not defaults; hiding them encourages silent misuse | Require explicit cpa_map and ind_map arguments; supply sensible example maps as loadable objects |
| Returning different S3 classes from FIGARO vs WIOD importers | Downstream functions would need source-aware branching | FIGARO importer must produce `c("sube_suts", "data.table", "data.frame")` identical to WIOD importer |
| Fixed-tolerance numerical comparisons in shipped tests for real WIOD data | Real WIOD data not in the bundle; tests would always skip in CI or fail when data is missing | Put replication tests in a separate vignette/script that is skipped unless data path is provided via env var |

---

## Feature Dependencies

```
FIGARO ingestion
  └── produces sube_suts
        └── extract_domestic_block() (unchanged)
              └── build_matrices() (unchanged)
                    └── compute_sube() (unchanged)
                          └── estimate_elasticities() (unchanged)
                                └── prepare_sube_comparison() (unchanged)

One-call pipeline
  └── wraps import_suts / import_figaro + extract_domestic_block + build_matrices + compute_sube
  └── accepts path, cpa_map, ind_map, inputs as required arguments
  └── returns sube_results (same class as compute_sube output)

Batch processor
  └── wraps one-call pipeline or raw compute_sube across a list of paths/country-year vectors
  └── collects results via rbindlist on $summary and $tidy
  └── diagnostics aggregated across all runs

Paper replication verification
  └── requires real WIOD data in inst/references/ (already present, not bundled)
  └── calls full pipeline, compares multipliers against legacy script output
  └── tolerance: all.equal() with tolerance = 1e-6 on multiplier vectors
  └── comparison tables from prepare_sube_comparison() matched against paper Table 2 values
```

---

## Structural Notes on FIGARO SUT Format

Based on domain knowledge from the paper context and JRC documentation patterns (MEDIUM confidence — should be verified against actual FIGARO files before implementation):

- FIGARO publishes European inter-country supply and use tables; domestic blocks use NACE rev.2 64-industry classification
- File format: CSV, one file per table type (supply/use) per year, with country dimension in row/column headers
- Key difference from WIOD workbooks: FIGARO CSVs use explicit country-product row indices rather than WIOD's sheet-per-type layout; the `TYPE` column must be inferred from filename or a wrapper argument
- The REP/PAR domestic filter applies the same way once the long table is normalized, but the initial melt step differs because FIGARO columns represent industry codes directly (not named VAR codes requiring ind_map lookup in the same step)
- Industry and product codes differ from WIOD: FIGARO uses NACE rev.2 A64 labels; mapping tables (ind_map, cpa_map) will need FIGARO-specific variants
- CO2/emissions data may not be bundled with FIGARO tables; the `metrics` argument to `compute_sube()` should default gracefully when a metric column is absent

---

## Structural Notes on Paper Replication

Based on the existing `paper_tools.R` and `test-workflow.R` patterns:

- The paper compares Leontief multipliers (from `compute_sube()`) against SUBE OLS/pooled/between estimates (from `estimate_elasticities()`) across 43 countries × 22 product aggregates × 15 years
- Replication means: running the package end-to-end on actual WIOD 2016 data and checking that `result$summary` values match the legacy script's published Table 2 means/medians within floating-point tolerance
- Standard R approach: `testthat::skip_if()` + env-var-gated data path, `expect_equal(tolerance = 1e-6)` on scalar summaries, `all.equal()` on multiplier vectors
- The package already has `prepare_sube_comparison()` which produces the comparison structure; replication only needs a reference table of expected values (hardcoded or loaded from `inst/references/`) to check against
- A replication vignette (not a unit test) is the appropriate artifact: it documents the full run, loads real data with `system.file("references", ...)`, and knits only locally (add `eval = FALSE` or `skip_if_not(file.exists(...))`)

---

## Structural Notes on One-Call Pipeline

Based on the current five-step workflow and R package conventions:

- Signature pattern: `run_sube(path, cpa_map, ind_map, inputs, source = c("wiod", "figaro"), ...)` where `...` passes to internal functions
- Returns: the same `sube_results` object `compute_sube()` produces, so all downstream functions (`filter_sube()`, `plot_sube()`, `write_sube()`) work without changes
- Should NOT estimate elasticities by default — that requires separate `model_data` and is a user choice, not always part of the workflow
- Optionally: a `run_sube_full()` that also calls `estimate_elasticities()` and returns a named list of `sube_results` + `sube_models`

---

## Structural Notes on Batch Processing

Based on the existing `compute_sube()` country-year loop and paper scale (43 countries, 15 years):

- The existing `compute_sube()` already loops over all country-years in the matrix bundle — "batch" is about collecting results across multiple input *files* or *directory scans*, not adding a new loop inside compute
- Pattern: `batch_sube(paths, cpa_map, ind_map, inputs, ...)` — accepts a named list or directory of input files, calls the pipeline for each, returns a merged result
- Merged result: `list(summary = rbindlist(...), tidy = rbindlist(...), diagnostics = rbindlist(...))` with a `"sube_batch_results"` class that inherits `"sube_results"` so existing downstream functions still dispatch correctly
- Error handling: per-file errors should be captured as diagnostics rows (status = "error", message = condition$message) rather than stopping the whole batch — consistent with how `compute_sube()` handles singular matrices

---

## MVP Recommendation

For v1.1, prioritize in this order:

1. **FIGARO ingestion** — the core new data source; defines what the other features actually process
2. **Paper replication verification** — validates the existing pipeline is correct before adding complexity; a vignette-based approach with env-var gating is the minimum viable artifact
3. **One-call pipeline** — thin wrapper over existing functions; low implementation risk, high ergonomic value
4. **Batch processing** — builds directly on the one-call pipeline; straightforward once #3 exists

Defer: Auto-discovery of FIGARO country files from a directory (scan + infer country from filename) — useful but adds regex parsing complexity; can be added incrementally after the basic per-file importer works.

---

## Sources

- Codebase inspection: `/home/zenz/R/sube/R/import.R`, `compute.R`, `matrices.R`, `models.R`, `paper_tools.R`, `tests/testthat/test-workflow.R` — HIGH confidence for existing API contracts
- Paper text: `/home/zenz/R/sube/inst/references/paper.md` (Stehrer, Rueda-Cantuche, Amores, Zenz 2024) — HIGH confidence for WIOD data structure; MEDIUM confidence for FIGARO structural inference from JRC authorship context
- FIGARO format details: domain knowledge from paper context, not verified against live FIGARO files — MEDIUM confidence, flag for validation before implementation
- R package conventions (one-call, batch, replication patterns): standard testthat and CRAN patterns — HIGH confidence
