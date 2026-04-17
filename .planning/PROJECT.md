# sube

## What This Is

`sube` is an R package for supply-use based econometrics. It gives applied input-output researchers a package-first workflow that starts from supply and use tables, builds domestic matrices, computes Leontief-style benchmark multipliers, estimates SUBE regression models, and produces comparison-ready outputs and plots aligned with the companion paper. As of v1.1 the package imports both WIOD-style workbooks and FIGARO industry-by-industry SUT CSVs into the same canonical long-format table, and ships a gated replication test plus a narrated vignette that reproduce the paper's numerical results on researcher-supplied WIOD data.

## Core Value

Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## Shipped Milestones

- **v1.0 Package Workflow Hardening** (2026-04-08) — Contractual import-to-compute workflow, stabilized comparison layer, aligned docs, hardened release path, legacy-wrapper migration bridge.
- **v1.1 Replication, FIGARO & Convenience** (2026-04-16) — FIGARO SUT ingestion (`read_figaro()` + synthetic fixture + NACE synonyms), gated paper replication test (`SUBE_WIOD_DIR`), exported `filter_paper_outliers()`, 9-section paper-replication vignette.

## Current Milestone: v1.2 FIGARO Validation, Convenience & Tech Debt

**Goal:** Prove the FIGARO pipeline works end-to-end on real data, deliver the long-promised one-call/batch convenience helpers, and clear the tech debt inherited from v1.1.

**Target features:**
- **FIGARO end-to-end validation** — gated `SUBE_FIGARO_DIR` real-data test with structural invariants + golden-digest regression; contract tests pushing the synthetic `figaro-sample` fixture through the full pipeline; standalone `figaro-workflow.Rmd` companion vignette.
- **Convenience helpers** — `run_sube_pipeline()` (one-call import → compute), `batch_sube()` (country/year batch), and pipeline diagnostic warnings for dropped rows / skipped matrices / singular branches.
- **Test-infrastructure tech debt** — fix `test-workflow.R:218` legacy-wrapper subprocess failure under `R CMD check --as-cran`; require explicit `SUBE_WIOD_FALLBACK` opt-in so `devtools::load_all` stops silently picking up `inst/extdata/wiod/`.
- **Retroactive Nyquist validation** — back-fill Nyquist `*-VALIDATION.md` reports for phases 5 and 6 (closes v1.1 audit's `not_enforced` flag).

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
- ✓ **FIG-E2E-01**: Gated FIGARO pipeline test (`SUBE_FIGARO_DIR`) drives real 2023 flatfile through full pipeline with structural invariants + golden-digest regression — v1.2 Phase 7
- ✓ **FIG-E2E-02**: Contract tests push synthetic `figaro-sample` fixture through full pipeline (new `test-figaro-pipeline.R`) — v1.2 Phase 7
- ✓ **FIG-E2E-03**: Standalone `vignettes/figaro-workflow.Rmd` companion to paper-replication vignette (`eval=FALSE`) — v1.2 Phase 7
- ✓ **INFRA-02**: `resolve_wiod_root()` is env-var-only (no `inst/extdata/wiod/` fallback); parallel `resolve_figaro_root()` added — v1.2 Phase 7 (D-7.7 tightened from "opt-in" to "no fallback")

### Active (v1.2)

- ✓ **CONV-01**: `run_sube_pipeline()` — one-call wrapper chaining import → matrix → compute — v1.2 Phase 8
- ✓ **CONV-02**: `batch_sube()` — country/year batch processor returning collected results — v1.2 Phase 8
- ✓ **CONV-03**: Pipeline diagnostic warnings for dropped rows, skipped matrices, singular branches — v1.2 Phase 8
- [ ] **INFRA-01**: `test-workflow.R:218` legacy-wrapper subprocess test passes under `R CMD check --as-cran`
- [ ] **NYQ-01**: Retroactive Nyquist `*-VALIDATION.md` for phase 5 (figaro-sut-ingestion)
- [ ] **NYQ-02**: Retroactive Nyquist `*-VALIDATION.md` for phase 6 (paper-replication-verification)

### Out of Scope

- Reintroducing the archived script-first pipeline as the primary interface — the repo has already moved to a package-first design
- Bundling large external research datasets in the package — release artifacts should stay small and reproducible from shipped examples
- Building a non-R service, GUI, or web application around SUBE — the current product is an R package for research workflows
- Auto-downloading FIGARO/WIOD data — network dependency, version drift, breaks `R CMD check`
- Zero-config pipeline hiding mapping tables — mapping is a research decision, not a default
- FIGARO SIOT (product-by-product) tables — only industry-by-industry SUTs are scoped

## Context

The repository has a validated package-first maintenance path: exported R functions covering import (WIOD + FIGARO), matrix building, compute, diagnostics, Leontief extraction, comparison shaping, paper-style plotting, outlier filtering, and export. `testthat` coverage runs green (102/102 under `devtools::test()`; 46/46 FIGARO; 3 gated replication blocks skip cleanly on CRAN). pkgdown groups cover Data import, Matrix building, Compute, Elasticity models, Diagnostics, Paper replication tools, and Legacy migration. `R-CMD-check` GitHub Actions workflow is hardened; `.Rbuildignore` keeps planning artifacts and `inst/extdata/wiod/` out of the CRAN tarball. Historical paper material remains outside the package bundle except for local reference material in `inst/references/` and synthetic fixtures in `inst/extdata/`.

Two documented non-blocking tech-debt items survive v1.1 closeout: (1) pre-existing `test-workflow.R:218` legacy-wrapper subprocess failure under `R CMD check --as-cran`, and (2) known ~4.4% methodological divergence when `devtools::load_all` triggers the local WIOD fallback. Both are candidates for v1.2 follow-up. Phase 8 shipped `run_sube_pipeline()` and `batch_sube()` with unified `$diagnostics` data.table (6-column schema) and four detection helpers. `testthat` coverage: 197 pass / 0 fail / 5 gated skips.

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

<details>
<summary>Previous milestone cycles</summary>

### After v1.0 milestone start

Document was seeded with initial v1.0 brownfield hardening scope and constraints.

### After v1.1 milestone start

Document tracked v1.1 active requirements (paper replication, FIGARO ingestion, pipeline helper, batch helper). Pipeline and batch helpers were deferred to a future milestone at closeout — no CNV- requirements were authored.

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
*Last updated: 2026-04-17 after v1.2 Phase 8 completion (CONV-01/02/03 validated — run_sube_pipeline + batch_sube + diagnostics shipped)*
