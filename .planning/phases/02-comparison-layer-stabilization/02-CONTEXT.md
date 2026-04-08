# Phase 2: Comparison Layer Stabilization - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Source:** Orchestrator synthesis from brownfield repo state

<domain>
## Phase Boundary

Phase 2 covers the public comparison layer built on top of `sube_results` and `sube_models`. The goal is to make Leontief extraction, comparison-table preparation, paper-style plots, and export behavior reliable enough to use as a coherent research workflow without ad hoc reshaping scripts.

This phase does not introduce new model families or redesign the broader documentation architecture. It stabilizes the existing comparison helpers already exposed by the package so later documentation alignment can describe a trustworthy surface.
</domain>

<decisions>
## Implementation Decisions

### Workflow scope
- Treat `extract_leontief_matrices()`, `prepare_sube_comparison()`, `plot_paper_comparison()`, `plot_paper_regression()`, `plot_paper_interval_ranges()`, `filter_sube()`, `plot_sube()`, and `write_sube()` as the Phase 2 public contract.
- Keep the comparison workflow anchored to package objects produced by `compute_sube()` and `estimate_elasticities()`.
- Use shipped sample data and current workflow tests as the baseline for reproducible comparison examples.

### Contract stabilization
- Preserve exported function names and high-level return shapes unless correctness requires a narrowly scoped adjustment.
- Prefer explicit normalization of column names, measure/type handling, and export paths over relying on implicit data.table behavior.
- Make comparison-layer edge cases testable: alternate extraction formats, aggregate vs yearly comparison shapes, empty selections, interval/ribbon branches, and named-list export structure should all have concrete expectations.

### Repo-specific constraints
- Follow the package-first architecture already reflected in `R/`, `man/`, tests, and vignettes rather than the stale script-era guidance in `AGENTS.md`.
- Keep Phase 2 focused on comparison-layer stability, not a general documentation rewrite.
- Avoid introducing paper-specific glue code that bypasses the package API.

### the agent's Discretion
- Whether stabilization lands as stricter validation, output normalization, or tighter tests/examples.
- Exact split between `R/paper_tools.R` and `R/filter_plot_export.R`, as long as comparison preparation, plotting, and export remain coherent.
- Whether workflow examples are best reinforced in `tests/testthat/test-workflow.R`, `vignettes/modeling-and-outputs.Rmd`, or both.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Comparison-layer contract
- `R/paper_tools.R` — Leontief extraction, comparison shaping, and paper-style plotting helpers
- `R/filter_plot_export.R` — filtering, plotting, and export helpers for tidy SUBE outputs
- `R/utils.R` — shared normalization and validation helpers
- `R/compute.R` — source of `sube_results` objects consumed by the comparison layer
- `R/models.R` — source of `sube_models` objects consumed by comparison and interval helpers

### Verification and docs
- `tests/testthat/test-workflow.R` — current workflow and comparison smoke coverage
- `vignettes/modeling-and-outputs.Rmd` — current public narrative for filtering, comparison, and export
- `vignettes/getting-started.Rmd` — end-to-end sample workflow that now reaches into the comparison surface
- `README.md` — public quickstart framing for the comparison helpers

### Planning context
- `.planning/PROJECT.md` — project framing and constraints
- `.planning/REQUIREMENTS.md` — COMP-01, COMP-02, COMP-03, COMP-04
- `.planning/ROADMAP.md` — Phase 2 goal and success criteria
- `.planning/STATE.md` — current project state
</canonical_refs>

<specifics>
## Specific Ideas

- Pin the exact output structure for Leontief extraction in list, long, and wide formats so downstream code can rely on predictable columns and metadata.
- Verify that `prepare_sube_comparison()` produces a stable table across measure selection, variable filtering, year aggregation, and paper-filter application.
- Harden the plotting/export layer around empty or narrow selections, supported output formats, and named-list directory output conventions.
- Align tests and examples so the comparison story can be verified from a clean checkout without paper-only scripts.
</specifics>

<deferred>
## Deferred Ideas

- README/pkgdown/NEWS alignment across the whole package belongs to Phase 3.
- Release-command verification and legacy wrapper migration belong to Phase 4.
- Higher-level one-call workflow wrappers remain future expansion work.
</deferred>

---
*Phase: 02-comparison-layer-stabilization*
*Context gathered: 2026-04-08 via direct repo synthesis*
