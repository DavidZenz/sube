# Phase 4 Research: Release, CI, and Migration Readiness

**Phase:** 4
**Date:** 2026-04-08
**Status:** Complete

## Objective

Research what must be true to plan Phase 4 well for a package that already has a working API and aligned docs, but still needs a hardened release path, clearer CI assumptions, and a validated migration bridge.

## Repo Facts

- The repository already has a GitHub Actions workflow at `.github/workflows/R-CMD-check.yaml`, but it is minimal: Ubuntu and macOS only, no explicit concurrency controls, and only the core `r-lib/actions` package-check path.
- The README documents tarball-oriented release checks, but local and CI guidance are still fairly thin and not explicitly tied together.
- The legacy wrapper `inst/scripts/run_legacy_pipeline.R` is intentionally small and routes directly into package functions, which is good for migration scope but means its assumptions should be pinned and documented clearly.
- `AGENTS.md` remains stale and script-oriented, which creates a lingering release-facing contradiction even after the Phase 3 doc alignment work.

## Implementation Considerations

### 1. Release and CI should describe the same path

DOC-03 and CI-01 are closely linked. The highest-value Phase 4 work is to make the documented local release flow and the GitHub Actions flow mirror each other enough that maintainers are not debugging two different systems.

### 2. CI hardening should improve signal, not just add matrix breadth

The current workflow is serviceable, but hardening should focus on maintenance value: up-to-date assumptions, clearer failure surfaces, and practical coverage. Adding complexity without improving signal would be low-value.

### 3. The legacy wrapper is a migration bridge, not a second product

`run_legacy_pipeline.R` already maps cleanly onto package functions. Phase 4 should verify that path, document its required arguments and outputs, and keep it intentionally narrow. The goal is compatibility, not reopening the script-first architecture.

### 4. Stale guidance is part of release risk

If repo guidance still implies an outdated structure or future scope that no longer matches reality, that is a release and maintenance problem. Phase 4 should explicitly close those contradictions.

## Recommended Plan Shape

Use three plans:
1. Harden GitHub Actions and local release-check workflow assumptions
2. Audit and document the legacy wrapper migration path
3. Update stale project guidance and release-facing notes that still contradict the package-first repo

This matches the roadmap and keeps execution split between CI/release mechanics, migration verification, and remaining stale guidance cleanup.

## Risks and Watchouts

- CI changes can fail for environmental reasons unrelated to repo logic; Phase 4 should prefer pragmatic hardening over ambitious workflow expansion.
- The local environment still lacks `gh` on `PATH`, so execution may need to rely on static workflow inspection rather than live Actions queries.
- Wrapper validation should avoid introducing new mandatory dependencies or side effects beyond the current package path.

## Validation Architecture

Phase 4 should combine automated checks with documented/manual verification:
- framework: `testthat` for workflow regression protection
- local release commands: `R CMD build .` and `R CMD check <tarball> --no-manual` where feasible
- CI validation: static inspection of `.github/workflows/R-CMD-check.yaml`, plus any runnable local analogs of the workflow
- migration validation: execute or simulate the legacy wrapper path against shipped example-style inputs when feasible

## Research Conclusion

Phase 4 should finish the milestone by tightening the release and CI path around the already-validated package workflow and by keeping the legacy wrapper as a documented compatibility bridge. The right plan shape is CI/release hardening first, migration-path validation second, and stale release/project guidance cleanup last.

## RESEARCH COMPLETE
