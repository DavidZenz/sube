# sube

## What This Is

`sube` is an R package for supply-use based econometrics. It gives applied input-output researchers a package-first workflow that starts from supply and use tables, builds domestic matrices, computes Leontief-style benchmark multipliers, estimates SUBE regression models, and produces comparison-ready outputs and plots aligned with the companion paper.

## Core Value

Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## Requirements

### Validated

- ✓ Import WIOD-style workbooks and normalized CSV inputs into a standard long SUBE table — existing
- ✓ Extract domestic SUT blocks and build aggregated product-industry matrices by country and year — existing
- ✓ Compute Leontief-style multipliers, elasticities, diagnostics, and summary tables from prepared inputs — existing
- ✓ Estimate OLS, pooled, and between elasticity models through a stable package API — existing
- ✓ Filter, plot, and export tidy SUBE outputs and expose a legacy pipeline wrapper script — existing
- ✓ Generate paper-style Leontief versus SUBE comparison tables and plots from package objects — existing
- ✓ Reproducible import-to-compute sample workflow with explicit validation and diagnostics coverage — Phase 1

### Active

- [ ] Stabilize the explicit Leontief matrix extraction and comparison layer as a documented public workflow
- [ ] Keep the package documentation, vignettes, and pkgdown site aligned with the package-first architecture
- [ ] Keep a practical bridge for users migrating from the historical script workflow to package functions

### Out of Scope

- Reintroducing the archived script-first pipeline as the primary interface — the repo has already moved to a package-first design
- Bundling large external research datasets in the package — release artifacts should stay small and reproducible from shipped examples
- Building a non-R service, GUI, or web application around SUBE — the current product is an R package for research workflows

## Context

The repository already contains a released package skeleton (`Version: 0.1.2`), exported R functions, `testthat` coverage, vignettes, pkgdown configuration, and built package artifacts. The README and pkgdown config position `sube` as a general supply-use based econometrics package and a companion to the 2024 Stehrer et al. paper. A legacy wrapper script remains in `inst/scripts/run_legacy_pipeline.R` for compatibility, while historical paper material is intentionally kept out of the package bundle except for local reference material in `inst/references/`. The checked-in `AGENTS.md` still describes an older script-driven layout, so project planning should follow the current package structure rather than that stale description.

## Constraints

- **Tech stack**: R package targeting `R (>= 4.2.0)` with `data.table`, `ggplot2`, `openxlsx`, `haven`, and `plm` — the public API and tests already depend on this stack
- **Compatibility**: Public exported functions should remain side-effect-light and sample-data driven — the README, vignettes, and tests all assume reusable package functions
- **Release quality**: Changes should continue to pass tarball-based `R CMD check` and `testthat` workflows — CRAN notes and GitHub Actions are built around that expectation
- **Data footprint**: Only small example data should ship with the package — large historical inputs remain outside the package bundle
- **Documentation**: README, vignettes, pkgdown reference groups, and NEWS should describe the same workflow surface — current repo value depends on a coherent package story

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat `sube` as a brownfield package project, not a new script collection | The repo already has `DESCRIPTION`, exported functions, tests, vignettes, and release artifacts | ✓ Good |
| Use the package-first workflow as the canonical product surface | README, tests, and pkgdown all center on reusable functions rather than numbered scripts | ✓ Good |
| Keep legacy script support limited to a compatibility wrapper | `inst/scripts/run_legacy_pipeline.R` provides migration help without reopening the old architecture | Pending |
| Focus the next milestone on workflow hardening, documentation alignment, and release readiness | The current repo already implements the main workflow, so the next leverage is stabilization and clarity | ✓ Good |
| Treat diagnostics as part of the public reproducibility contract | Phase 1 showed users need explicit visibility into `result$diagnostics` for trustworthy workflow verification | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-08 after Phase 1 completion*
