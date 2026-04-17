---
phase: 09-test-infrastructure-tech-debt
plan: "01"
subsystem: test-infrastructure
tags: [subprocess, R-CMD-check, library-path, testthat, legacy-wrapper]
dependency_graph:
  requires: []
  provides: [INFRA-01]
  affects: [tests/testthat/test-workflow.R]
tech_stack:
  added: []
  patterns: [R_LIBS env var threading via system2() env parameter]
key_files:
  created: []
  modified:
    - tests/testthat/test-workflow.R
    - .planning/PROJECT.md
    - NEWS.md
    - DESCRIPTION
decisions:
  - Thread .libPaths() via R_LIBS into legacy-wrapper subprocess test — zero-dependency cross-platform fix; no skip workarounds (D-01)
  - Document resolution in 4 locations: inline comment, PROJECT.md, NEWS.md, DESCRIPTION (D-03)
metrics:
  duration: ~15 minutes
  completed: 2026-04-17
  tasks_completed: 2
  files_modified: 4
---

# Phase 9 Plan 01: Legacy Wrapper Subprocess Fix (INFRA-01) Summary

**One-liner:** Fixed R CMD check subprocess failure by threading `.libPaths()` into child Rscript via `R_LIBS` env var and using full `R.home("bin")` path in `system2()` call.

## What Was Built

Resolved the pre-existing `test-workflow.R:218` failure under `R CMD check --as-cran`. The legacy-wrapper test spawns a child `Rscript` process via `system2()` to execute `inst/scripts/run_legacy_pipeline.R`, which calls `library(sube)`. Under `R CMD check --as-cran`, the harness installs the package into a temporary library and sets `R_LIBS` there, but the child process launched via `system2()` does not automatically inherit that path — it starts with the default library search list from the user profile. The fix passes `.libPaths()` explicitly as `R_LIBS` in the `env` parameter of `system2()`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Thread .libPaths() into subprocess via R_LIBS env var | 72fb095 | tests/testthat/test-workflow.R |
| 2 | Document resolution in PROJECT.md, NEWS.md, and DESCRIPTION | 13e903e | .planning/PROJECT.md, NEWS.md, DESCRIPTION |

## Verification Results

- `devtools::test(filter = "workflow")`: PASS (56/56, 0 failures)
- `devtools::test()` full suite: PASS (197/197 pass, 5 expected skips for gated replication tests)

## Deviations from Plan

- Used `file.path(R.home("bin"), "Rscript")` instead of `Sys.which("Rscript")` — R CMD check --as-cran rejects bare "Rscript" invocations per par. 1.6 of the Writing R Extensions manual. Discovered during human verification gate.

## Known Stubs

None.

## Threat Flags

None — test-only code path, no user-facing surface, no network access. `R_LIBS` value is derived from `.libPaths()` at test time (local filesystem paths only).

## Self-Check: PASSED

- `tests/testthat/test-workflow.R` — FOUND, contains `r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)` and `env    = paste0("R_LIBS=", r_libs)`
- `.planning/PROJECT.md` — FOUND, contains `Thread .libPaths() via R_LIBS`
- `NEWS.md` — FOUND, contains `R_LIBS environment variable (INFRA-01)`
- `DESCRIPTION` — FOUND, contains `threads .libPaths() via R_LIBS`
- Commit 72fb095 — FOUND
- Commit 13e903e — FOUND
