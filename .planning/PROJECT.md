# sube

## What This Is

`sube` is an R package for supply-use based econometrics. It gives applied input-output researchers a package-first workflow that starts from supply and use tables, builds domestic matrices, computes Leontief-style benchmark multipliers, estimates SUBE regression models, and produces comparison-ready outputs and plots aligned with the companion paper. The package imports both WIOD-style workbooks and FIGARO industry-by-industry SUT CSVs into the same canonical long-format table, and ships convenience helpers (`run_sube_pipeline()`, `batch_sube()`) for one-call and batch workflows with diagnostic warnings. Gated replication tests and narrated vignettes reproduce the paper's numerical results on researcher-supplied data.

## Core Value

Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## Current Milestone: v1.3 Documentation & pkgdown

**Goal:** Thorough, source-agnostic documentation with a live pkgdown site on GitHub Pages.

**Target features:**
- Rewrite/improve existing vignettes with proper data format specification (column semantics, canonical long-format contract, satellite vector inputs)
- Source-agnostic framing throughout — WIOD and FIGARO are just two built-in importers
- README refresh aligned with the documentation narrative
- pkgdown site deployed to GitHub Pages via GitHub Actions workflow
- "Bring your own data" guidance for researchers with non-WIOD/FIGARO sources

## Shipped Milestones

- **v1.0 Package Workflow Hardening** (2026-04-08) — Contractual import-to-compute workflow, stabilized comparison layer, aligned docs, hardened release path, legacy-wrapper migration bridge.
- **v1.1 Replication, FIGARO & Convenience** (2026-04-16) — FIGARO SUT ingestion (`read_figaro()` + synthetic fixture + NACE synonyms), gated paper replication test (`SUBE_WIOD_DIR`), exported `filter_paper_outliers()`, 9-section paper-replication vignette.
- **v1.2 FIGARO Validation, Convenience & Tech Debt** (2026-04-17) — FIGARO E2E validation (gated real-data test + synthetic CI contract), env-var-only resolver contract, `run_sube_pipeline()` + `batch_sube()` convenience helpers with diagnostic warnings, `test-workflow.R` subprocess fix, retroactive Nyquist validation for phases 5-6.

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
- ✓ FIGARO industry-by-industry SUT ingestion producing the standard long-format SUBE table — v1.1 (FIG-01..04)
- ✓ Paper replication with gated numerical match against legacy scripts using researcher-supplied WIOD data — v1.1 (REP-01, REP-02)
- ✓ **FIG-E2E-01**: Gated FIGARO pipeline test with structural invariants + golden-digest regression — v1.2
- ✓ **FIG-E2E-02**: Contract tests push synthetic fixture through full pipeline on every CI build — v1.2
- ✓ **FIG-E2E-03**: Standalone `figaro-workflow.Rmd` companion vignette — v1.2
- ✓ **INFRA-02**: Env-var-only resolver contract (no silent `inst/extdata/` fallback) — v1.2
- ✓ **CONV-01**: `run_sube_pipeline()` one-call wrapper — v1.2
- ✓ **CONV-02**: `batch_sube()` country/year batch processor — v1.2
- ✓ **CONV-03**: Pipeline diagnostic warnings for data-quality issues — v1.2
- ✓ **INFRA-01**: Legacy-wrapper subprocess test passes `R CMD check --as-cran` — v1.2
- ✓ **NYQ-01**: Retroactive Nyquist validation for phase 5 — v1.2
- ✓ **NYQ-02**: Retroactive Nyquist validation for phase 6 — v1.2

### Active

- ✓ Data format specification with canonical SUT column semantics, satellite vector contract, synonym table, and BYOD guide — Validated in Phase 11
- ✓ Source-agnostic framing throughout docs — WIOD and FIGARO as example importers — Validated in Phase 12
- ✓ README refresh — Validated in Phase 12
- [ ] pkgdown site deployed to GitHub Pages via GitHub Actions

### Out of Scope

- Reintroducing the archived script-first pipeline as the primary interface — the repo has already moved to a package-first design
- Bundling large external research datasets in the package — release artifacts should stay small and reproducible from shipped examples
- Building a non-R service, GUI, or web application around SUBE — the current product is an R package for research workflows
- Auto-downloading FIGARO/WIOD data — network dependency, version drift, breaks `R CMD check`
- Zero-config pipeline hiding mapping tables — mapping is a research decision, not a default
- FIGARO SIOT (product-by-product) tables — only industry-by-industry SUTs are scoped

## Context

Shipped v1.2 with 197 pass / 0 fail / 5 gated skips in testthat. Tech stack: R (>= 4.2.0) with `data.table`, `ggplot2`, `openxlsx`, `haven`, and `plm`. Exported functions cover import (WIOD + FIGARO), matrix building, compute, diagnostics, Leontief extraction, comparison shaping, paper-style plotting, outlier filtering, export, and convenience pipeline/batch helpers. Three narrated vignettes (`paper-replication.Rmd`, `figaro-workflow.Rmd`, `pipeline-helpers.Rmd`) all with `eval = FALSE`. pkgdown groups: Data import, Matrix building, Compute, Elasticity models, Diagnostics, Paper replication tools, Pipeline helpers, Legacy migration. GitHub Actions CI hardened; `.Rbuildignore` excludes planning artifacts and researcher data directories.

All v1.1 tech debt resolved: `test-workflow.R:218` subprocess failure fixed via `R_LIBS` threading; WIOD/FIGARO resolvers are env-var-only (no silent fallback). Nyquist validation reports retroactively added for phases 5 and 6.

## Constraints

- **Tech stack**: R package targeting `R (>= 4.2.0)` with `data.table`, `ggplot2`, `openxlsx`, `haven`, and `plm`
- **Compatibility**: Public exported functions should remain side-effect-light and sample-data driven
- **Release quality**: Changes should continue to pass tarball-based `R CMD check` and `testthat` workflows
- **Data footprint**: Only small example data should ship with the package; real WIOD/FIGARO datasets stay out of the tarball via `.Rbuildignore`
- **Documentation**: README, vignettes, pkgdown reference groups, and NEWS should describe the same workflow surface
- **Replication contract**: Paper reproduction is gated on `SUBE_WIOD_DIR` — never shipped, never bundled; CRAN/CI skip deterministically

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat `sube` as a brownfield package project, not a new script collection | The repo already has `DESCRIPTION`, exported functions, tests, vignettes, and release artifacts | ✓ Good |
| Use the package-first workflow as the canonical product surface | README, tests, and pkgdown all center on reusable functions rather than numbered scripts | ✓ Good |
| Keep legacy script support limited to a compatibility wrapper | `inst/scripts/run_legacy_pipeline.R` provides migration help without reopening the old architecture | ✓ Good |
| Treat diagnostics and comparison/export semantics as explicit public contracts | Later phases relied on these behaviors as stable workflow surfaces | ✓ Good |
| Exclude `.planning/` from source builds so release artifacts stay clean | Tarball checks should validate the package, not local planning metadata | ✓ Good |
| Model FIGARO ingestion as a parallel canonical importer (`read_figaro()`) rather than an `import_suts()` branch | Composite-label parsing and CPA-prefix stripping live in one focused function; keeps WIOD path untouched | ✓ Good (v1.1) |
| Strip `CPA_` prefix and aggregate FD columns to `FU_bas` at FIGARO import time | Downstream code never has to distinguish raw vs. stripped product codes or FIGARO vs. WIOD FD conventions | ✓ Good (v1.1) |
| Gate replication on `SUBE_WIOD_DIR`; exclude `inst/extdata/wiod/` from tarball | CRAN/CI skip deterministically; researchers reproduce locally with their own data | ✓ Good (v1.1) |
| Defer v1.1's "Convenience" scope (pipeline, batch helpers) to v1.2 rather than back-filling CNV-requirements | No CNV- requirements were defined during planning; shipped convenience-shaped work landed under FIG-/REP- IDs | ✓ Good (v1.1) |
| Thread `.libPaths()` via `R_LIBS` into legacy-wrapper subprocess test (INFRA-01) | `R CMD check --as-cran` isolates the package in a temp library that `system2()` children don't inherit; passing `R_LIBS` from `.libPaths()` is the zero-dependency cross-platform fix | ✓ Good (v1.2) |
| Env-var-only resolver contract (INFRA-02): remove all local fallbacks | Prevents silent activation of researcher data during `devtools::load_all` — explicit opt-in via env var only | ✓ Good (v1.2) |
| Accept existing Nyquist VALIDATION.md artifacts as-is for Phase 10 | Artifacts were comprehensive with full audit sections; regeneration would add no value | ✓ Good (v1.2) |

<details>
<summary>Previous milestone cycles</summary>

### After v1.0 milestone start

Document was seeded with initial v1.0 brownfield hardening scope and constraints.

### After v1.1 milestone start

Document tracked v1.1 active requirements (paper replication, FIGARO ingestion, pipeline helper, batch helper). Pipeline and batch helpers were deferred to a future milestone at closeout — no CNV- requirements were authored.

### After v1.2 milestone start

Document tracked v1.2 active requirements: FIGARO E2E validation (FIG-E2E-01/02/03), convenience helpers (CONV-01/02/03), test infrastructure (INFRA-01/02), and Nyquist validation (NYQ-01/02). All 10 requirements satisfied at milestone close.

</details>

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Archive previous milestone's active content under `<details>`

---
*Last updated: 2026-04-18 after Phase 12 completion*
