# sube

## What This Is

`sube` is an R package for supply-use based econometrics. It gives applied input-output researchers a package-first workflow that starts from supply and use tables, builds domestic matrices, computes Leontief-style benchmark multipliers, estimates SUBE regression models, and produces comparison-ready outputs and plots aligned with the companion paper.

## Core Value

Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## Current State

Milestone `v1.0` is shipped. The package now has a verified package-first workflow from sample-data import through comparison outputs, aligned public documentation, a clean tarball-based release path, and a documented compatibility wrapper for script-era users.

## Next Milestone Goals

- Define the next milestone scope from the archived v2 ideas in the v1 requirements archive.
- Decide whether the next focus is higher-level workflow convenience helpers, richer publication/export artifacts, or additional model families.
- Rebuild `.planning/REQUIREMENTS.md` from scratch for the next milestone instead of carrying forward stale scope.

## Requirements

### Validated

- ✓ Import WIOD-style workbooks and normalized CSV inputs into a standard long SUBE table — existing
- ✓ Extract domestic SUT blocks and build aggregated product-industry matrices by country and year — existing
- ✓ Compute Leontief-style multipliers, elasticities, diagnostics, and summary tables from prepared inputs — existing
- ✓ Estimate OLS, pooled, and between elasticity models through a stable package API — existing
- ✓ Filter, plot, and export tidy SUBE outputs and expose a legacy pipeline wrapper script — existing
- ✓ Generate paper-style Leontief versus SUBE comparison tables and plots from package objects — existing
- ✓ Reproducible import-to-compute sample workflow with explicit validation and diagnostics coverage — v1.0
- ✓ Explicit Leontief extraction, comparison-table, plot, and export workflow validated from shipped package objects — v1.0
- ✓ README, vignettes, pkgdown, and release-facing docs aligned to the package-first workflow and sample-data contract — v1.0
- ✓ Keep a practical bridge for users migrating from the historical script workflow to package functions — v1.0
- ✓ Harden GitHub Actions and release-check automation around the documented package workflow — v1.0

### Active

- None currently. Define the next milestone with `/gsd-new-milestone`.

### Out of Scope

- Reintroducing the archived script-first pipeline as the primary interface — the repo has already moved to a package-first design
- Bundling large external research datasets in the package — release artifacts should stay small and reproducible from shipped examples
- Building a non-R service, GUI, or web application around SUBE — the current product is an R package for research workflows

## Context

The repository now has a validated package-first maintenance path: exported R functions, `testthat` coverage, vignettes, pkgdown configuration, a hardened `R-CMD-check` workflow, clean tarball-based release verification, and archived milestone records under `.planning/milestones/`. Historical paper material remains outside the package bundle except for local reference material in `inst/references/`.

## Constraints

- **Tech stack**: R package targeting `R (>= 4.2.0)` with `data.table`, `ggplot2`, `openxlsx`, `haven`, and `plm`
- **Compatibility**: Public exported functions should remain side-effect-light and sample-data driven
- **Release quality**: Changes should continue to pass tarball-based `R CMD check` and `testthat` workflows
- **Data footprint**: Only small example data should ship with the package
- **Documentation**: README, vignettes, pkgdown reference groups, and NEWS should describe the same workflow surface

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat `sube` as a brownfield package project, not a new script collection | The repo already has `DESCRIPTION`, exported functions, tests, vignettes, and release artifacts | ✓ Good |
| Use the package-first workflow as the canonical product surface | README, tests, and pkgdown all center on reusable functions rather than numbered scripts | ✓ Good |
| Keep legacy script support limited to a compatibility wrapper | `inst/scripts/run_legacy_pipeline.R` provides migration help without reopening the old architecture | ✓ Good |
| Treat diagnostics and comparison/export semantics as explicit public contracts | Later phases relied on these behaviors as stable workflow surfaces | ✓ Good |
| Exclude `.planning/` from source builds so release artifacts stay clean | Tarball checks should validate the package, not local planning metadata | ✓ Good |

---
*Last updated: 2026-04-08 after v1.0 milestone archive*
