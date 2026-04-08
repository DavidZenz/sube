# Phase 1 Research: Core Workflow Contracts

**Phase:** 1
**Date:** 2026-04-08
**Status:** Complete

## Objective

Research what must be true to plan Phase 1 well for a brownfield R package whose critical path is import -> matrix build -> compute -> reproducible example workflow.

## Repo Facts

- The current package surface is already established through exported functions in `R/import.R`, `R/matrices.R`, and `R/compute.R`.
- The sample workflow is documented in `vignettes/getting-started.Rmd` and partially asserted in `tests/testthat/test-workflow.R`.
- The code distinguishes between recoverable compute failures captured in `result$diagnostics$status` and hard input-contract failures raised via `stop()`.
- `AGENTS.md` is stale relative to the package-first repo layout, so plan decisions should follow source/tests/docs rather than that file's script-era narrative.

## Implementation Considerations

### 1. Contract boundaries should be explicit

The package already relies on a small set of public objects and classes:
- `sube_suts` / `sube_domestic_suts`
- `sube_matrices`
- `sube_results`

Phase 1 should strengthen these boundaries rather than add new concepts. The main risk is ambiguity about which failures should stop immediately versus which should be recorded in diagnostics.

### 2. The sample workflow is the best reproducibility anchor

The shipped sample data avoids external downloads and is already used by tests and vignettes. This makes it the right baseline for WF-01 and WF-02. Planning should therefore ensure at least one plan explicitly ties source contract updates to test and vignette verification.

### 3. Diagnostics need a clear taxonomy

`compute_sube()` already emits statuses like `singular_supply`, `singular_go`, `singular_leontief`, and `ok`, while other failures stop outright. Phase 1 should verify that:
- expected recoverable numeric failures stay in diagnostics
- malformed inputs still fail loudly
- tests cover both paths deliberately

### 4. Validation should stay lightweight

This is an R package with `testthat`, existing sample data, and a tarball-based release path. Validation should be based on:
- targeted workflow tests while iterating
- full `testthat` suite before phase completion
- release check path documented but not necessarily run on every task

## Recommended Plan Shape

Use three plans:
1. Import and matrix contract audit/hardening
2. Compute and diagnostics hardening
3. Reproducibility and workflow verification alignment

This split matches the source layout, keeps file ownership mostly separate, and gives Phase 1 a clean wave structure.

## Risks and Watchouts

- Tightening validation may break current examples if tests and docs are not updated in the same phase.
- Over-documenting Phase 1 would leak into the broader documentation-alignment phase; keep this phase centered on core workflow contracts.
- Avoid using README as the primary verification artifact in this phase; workflow tests and the getting-started vignette are stronger sources of truth.

## Validation Architecture

Phase 1 already has suitable infrastructure for Nyquist validation:
- framework: `testthat`
- quick checks: targeted workflow test file and focused `testthat` expectations
- full checks: repository `testthat` run, optionally followed by package build/check during phase verification
- sampling goal: every plan should have at least one automated verification command tied to the files it changes

## Research Conclusion

Phase 1 should harden the import-to-compute path by making object contracts, diagnostics, and sample-workflow verification mutually reinforcing. The best plan shape is three focused plans that separate import/matrix work, compute/diagnostics work, and reproducibility verification work.

## RESEARCH COMPLETE
