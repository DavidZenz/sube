# Phase 9: Test Infrastructure Tech Debt - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the legacy-wrapper subprocess test (`test-workflow.R:218`) so it passes under `R CMD check --as-cran`. The test spawns `Rscript run_legacy_pipeline.R` via `system2()`, which calls `library(sube)` — this fails because the check-time temporary `.libPaths()` is not inherited by the child process.

</domain>

<decisions>
## Implementation Decisions

### Resolution Strategy
- **D-01:** Fix the subprocess by threading `.libPaths()` into the `Rscript` call via `R_LIBS` environment variable so the child process finds sube in the check-time temporary library. Do NOT use `skip_on_cran()` or any skip-based workaround.
- **D-02:** The fix must work cross-platform (Linux, macOS, Windows). No fallback to a documented skip if platform issues arise — invest the effort to make `R_LIBS` threading robust everywhere.

### Documentation
- **D-03:** Document the resolution in four places: (1) inline comment at the test site explaining the `.libPaths()` threading, (2) PROJECT.md Key Decisions entry, (3) NEWS.md bullet, (4) DESCRIPTION Note field mentioning that the legacy wrapper test requires `.libPaths()` threading.

### Regression Safety
- **D-04:** Verification requires both `devtools::test()` (all tests green, no regressions) AND `R CMD check --as-cran` on the built tarball (subprocess test passes). Both must succeed.

### Claude's Discretion
- Exact mechanism for passing `.libPaths()` to the subprocess (e.g., `R_LIBS` env var in `system2()` call, `callr::r()`, or wrapping the Rscript invocation)
- Whether to refactor the `system2()` call in-place or extract a helper for subprocess library threading

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Test infrastructure
- `tests/testthat/test-workflow.R` — The test file containing the failing subprocess test at line 218
- `inst/scripts/run_legacy_pipeline.R` — The legacy wrapper script invoked by the subprocess test

### Project context
- `.planning/ROADMAP.md` §Phase 9 — Phase goal, success criteria, and requirements
- `.planning/REQUIREMENTS.md` §INFRA-01 — Requirement definition
- `.planning/PROJECT.md` §Key Decisions — Where the resolution strategy must be recorded

### Prior phase patterns
- `tests/testthat/helper-gated-data.R` — Established gated-test pattern (env-var gate, clean skip) from Phase 7

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `helper-gated-data.R`: Established skip patterns for gated tests — but this phase explicitly avoids skip-based solutions (D-01)

### Established Patterns
- testthat3 `test_that()` conventions used across all test files
- `system2()` call pattern already in `test-workflow.R:240-245` — the fix modifies this call site
- `sube_example_data()` used to generate temp CSV fixtures for the subprocess

### Integration Points
- The only change is within `test-workflow.R` — no new files, no API changes
- `inst/scripts/run_legacy_pipeline.R` is read-only (no modifications needed — the script is correct, the test invocation is the problem)
- PROJECT.md, NEWS.md, DESCRIPTION are documentation-only updates

</code_context>

<specifics>
## Specific Ideas

No specific requirements — the fix is narrowly scoped to making the `system2()` Rscript subprocess inherit the correct `.libPaths()`.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 09-test-infrastructure-tech-debt*
*Context gathered: 2026-04-17*
