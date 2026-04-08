# Phase 1: Core Workflow Contracts - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Source:** Orchestrator synthesis from brownfield repo state

<domain>
## Phase Boundary

Phase 1 covers the package contract from importing or loading supply-use data through matrix construction and `compute_sube()` output generation. The goal is to make the shipped example-data workflow explicit, reproducible, and robust to invalid inputs before any additional comparison-layer or documentation expansion work.

This phase does not expand the public surface into new modeling methods or comparison features. It hardens the current import, matrix, compute, and diagnostic behaviors that later phases depend on.
</domain>

<decisions>
## Implementation Decisions

### Workflow scope
- Treat the package-first API as the canonical product surface for this phase.
- Keep Phase 1 focused on `import_suts()`, `extract_domestic_block()`, `sube_example_data()`, `build_matrices()`, and `compute_sube()`.
- Use shipped sample data under `inst/extdata/sample/` as the reproducible baseline for workflow validation.

### Contract hardening
- Preserve existing exported function names and object classes unless a break is strictly required by a correctness issue.
- Prefer explicit input validation and deterministic diagnostics over silent recycling or partial failures.
- Make failure modes testable: missing columns, unsupported input layout, industry misalignment, singular matrix branches, and example-data workflow regressions should all have concrete expectations.

### Repo-specific constraints
- Follow the current package layout, not the stale script-oriented description in `AGENTS.md`.
- Keep changes side-effect-light and package-friendly; avoid reintroducing script-only flows as the main interface.
- Keep example-driven docs and tests aligned so the public workflow can be verified from a clean checkout.

### the agent's Discretion
- Whether hardening lands as stricter validation in existing functions, additional helper utilities, or both.
- Exact split between test coverage and vignette/example updates, as long as Phase 1 requirements stay covered.
- Whether sample workflow verification is best anchored in `testthat`, vignette code, or both.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Package contract
- `DESCRIPTION` — package dependencies, R version floor, and release metadata
- `README.md` — current public workflow and package framing
- `R/import.R` — import, domestic extraction, and sample data entry points
- `R/matrices.R` — matrix construction contract
- `R/compute.R` — compute and diagnostics contract
- `R/utils.R` — shared validation and coercion helpers

### Verification surfaces
- `tests/testthat.R` — test entry point
- `tests/testthat/test-workflow.R` — current workflow expectations
- `vignettes/getting-started.Rmd` — end-to-end sample workflow narrative
- `.github/workflows/R-CMD-check.yaml` — release-oriented check path

### Planning context
- `.planning/PROJECT.md` — project framing and constraints
- `.planning/REQUIREMENTS.md` — WF-01, WF-02, WF-03
- `.planning/ROADMAP.md` — Phase 1 goal and success criteria
- `.planning/STATE.md` — current project state
</canonical_refs>

<specifics>
## Specific Ideas

- Reconcile the README/vignette description of the sample workflow with the exact function contracts used in tests.
- Audit whether `build_matrices()` and `compute_sube()` produce clear, stable behavior when inputs are malformed or partially missing.
- Make diagnostic states observable enough that later comparison-layer work can rely on them.
</specifics>

<deferred>
## Deferred Ideas

- Comparison-layer stabilization and paper-style output hardening belong to Phase 2.
- Broader documentation alignment across README, vignettes, and pkgdown belongs to Phase 3.
- Legacy wrapper and release/migration cleanup belong to Phase 4.
</deferred>

---
*Phase: 01-core-workflow-contracts*
*Context gathered: 2026-04-08 via direct repo synthesis*
