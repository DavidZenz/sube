# Phase 4: Release, CI, and Migration Readiness - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Source:** Orchestrator synthesis from brownfield repo state

<domain>
## Phase Boundary

Phase 4 covers the release-facing maintenance surfaces around the package-first workflow: local build and check instructions, GitHub Actions reliability, the legacy wrapper script, and any remaining stale project guidance that still conflicts with the current repo structure.

This phase does not add new workflow features or broaden the package scope. It verifies that the current package can be released and maintained with a documented CI path while preserving a minimal migration bridge for script-era users.
</domain>

<decisions>
## Implementation Decisions

### Workflow scope
- Treat local build/check instructions, `.github/workflows/R-CMD-check.yaml`, `inst/scripts/run_legacy_pipeline.R`, and release-facing guidance as the primary Phase 4 surfaces.
- Keep GitHub Actions hardening explicit in this phase rather than folding it into documentation-only work.
- Preserve the package-first API as the canonical product surface while retaining the legacy wrapper only as a compatibility bridge.

### Release and CI strategy
- Prefer documented, reproducible local commands that match the CI path as closely as practical.
- Harden Actions assumptions around package checks, dependency setup, and signal quality before adding complexity.
- Keep CI edits scoped to the documented package check flow; avoid unrelated workflow expansion unless it materially improves the release path.

### Migration strategy
- Keep the legacy wrapper narrow: accept local inputs, route into package functions, and document exactly what it expects.
- Avoid reviving the historical script tree as a primary workflow.
- Treat stale script-first or future-scope guidance as a release risk that should be removed or corrected.

### Repo-specific constraints
- The local shell still does not expose `gh` on `PATH`, so planning should not assume live Actions inspection during execution.
- `AGENTS.md` remains stale relative to the package structure and may need either correction or explicit deprioritization in project guidance.
- Keep the release path CRAN-friendly and tarball-oriented, consistent with the current README and workflow metadata.

### the agent's Discretion
- Whether CI hardening lands as matrix adjustments, workflow metadata, cache/concurrency controls, or improved failure/reporting behavior.
- Exact split between code, workflow YAML, wrapper documentation, and release-note/project-guidance edits.
- Whether package metadata or project docs need a narrow refresh to align with the final release/CI path.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Release and CI surfaces
- `.github/workflows/R-CMD-check.yaml` — current package check automation path
- `README.md` — current local release/check instructions
- `DESCRIPTION` — package metadata, dependencies, and versioning surface
- `NEWS.md` — release-facing narrative
- `.planning/ROADMAP.md` — Phase 4 goal and success criteria
- `.planning/REQUIREMENTS.md` — DOC-03, CI-01, MIG-01

### Migration surface
- `inst/scripts/run_legacy_pipeline.R` — legacy wrapper entry point
- `R/import.R` — wrapper import dependency
- `R/matrices.R` — wrapper matrix-build dependency
- `R/compute.R` — wrapper compute dependency
- `R/filter_plot_export.R` — wrapper export dependency

### Validation and planning context
- `tests/testthat.R` — test runner
- `tests/testthat/test-workflow.R` — stable workflow regression surface
- `.planning/PROJECT.md` — project framing and constraints
- `.planning/STATE.md` — current state and blockers
</canonical_refs>

<specifics>
## Specific Ideas

- Verify that the README release commands, local test commands, and GitHub Actions workflow describe the same package-check path.
- Harden the Actions workflow around current maintenance expectations such as clearer matrix coverage, concurrency/cancel behavior, or improved failure visibility.
- Audit the legacy wrapper for input assumptions, output behavior, and minimal documentation needed for migration users.
- Remove or correct any stale repo/project guidance that still implies script-first maintenance or outdated release scope.
</specifics>

<deferred>
## Deferred Ideas

- New feature work beyond release, CI, and migration hardening is out of scope.
- Broad documentation redesign beyond what is necessary for release-facing correctness was handled in Phase 3.
- Richer publication bundles or new wrappers remain future expansion work.
</deferred>

---
*Phase: 04-release-ci-and-migration-readiness*
*Context gathered: 2026-04-08 via direct repo synthesis*
