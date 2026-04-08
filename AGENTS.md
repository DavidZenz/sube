# Repository Guidelines

## Project Structure & Module Organization
This repository is a package-first R project. Core package code lives in `R/`, generated help pages in `man/`, long-form documentation in `vignettes/`, and CI in `.github/workflows/`. The main workflow surface is the exported API: `import_suts()`, `extract_domestic_block()`, `build_matrices()`, `compute_sube()`, `estimate_elasticities()`, `prepare_sube_comparison()`, and the plotting/export helpers. A narrow compatibility bridge for script-era users remains at `inst/scripts/run_legacy_pipeline.R`, but it is not the primary interface.

## Build, Test, and Development Commands
Run the maintained local check path from the repository root with:

```bash
R -q -e 'testthat::test_dir("tests/testthat")'
R CMD build .
R CMD check sube_0.1.2.tar.gz --no-manual
```

This mirrors the GitHub Actions `R-CMD-check` workflow. For focused iteration, run the main workflow regression file with:

```bash
R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'
```

If you need the compatibility bridge, invoke:

```bash
Rscript inst/scripts/run_legacy_pipeline.R <sut_path> <cpa_map.csv> <ind_map.csv> <inputs.csv> [output_dir]
```

## Coding Style & Naming Conventions
Use 2-space indentation and keep functions side-effect-light unless file writing is explicit. Follow the existing package naming patterns: snake_case for objects, descriptive helper names, and roxygen-backed function documentation for public APIs. Prefer relative paths inside the repo. Treat historical absolute paths like `W:/...` and `D://...` as technical debt and do not introduce new ones.

## Testing Guidelines
`testthat` is the automated baseline. Before committing, rerun `tests/testthat/test-workflow.R` for touched workflow surfaces and the full `tests/testthat/` suite for release-facing changes. If you touch CI, wrapper, or vignette-evaluated examples, also confirm `R CMD build .` still succeeds. Treat the shipped example data as the canonical reproducibility baseline for tests and docs.

## Commit & Pull Request Guidelines
Use short imperative commit subjects under 72 characters, for example `Harden R-CMD-check workflow` or `Clarify legacy wrapper usage`. Pull requests should state which workflow surfaces changed, whether CI or release behavior changed, and whether migration guidance or wrapper behavior was affected. Include the commands you ran when the change is release- or CI-facing.

## Data & Configuration Notes
Do not commit large generated datasets unless explicitly required. Keep the package bundle lightweight and sample-data-driven. When changing CI, release instructions, or migration guidance, make sure README, `AGENTS.md`, and `.github/workflows/R-CMD-check.yaml` stay aligned.
