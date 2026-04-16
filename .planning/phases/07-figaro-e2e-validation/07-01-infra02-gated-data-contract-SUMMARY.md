---
phase: 07-figaro-e2e-validation
plan: "01"
name: infra02-gated-data-contract
subsystem: tests/testthat
tags:
  - testing
  - infrastructure
  - gated-data
  - INFRA-02
dependency_graph:
  requires: []
  provides:
    - resolve_wiod_root (env-var-only, D-7.7)
    - resolve_figaro_root (env-var-only, D-7.7)
    - test-gated-data-contract.R (INFRA-02 contract tests)
  affects:
    - tests/testthat/test-replication.R (skip messages)
    - downstream plans in phase 07 that gate on resolve_figaro_root()
tech_stack:
  added: []
  patterns:
    - env-var-only resolver pattern (D-7.7)
    - base-R with_env() scoping helper (no withr dependency)
key_files:
  created:
    - tests/testthat/test-gated-data-contract.R
  modified:
    - tests/testthat/helper-gated-data.R (renamed from helper-replication.R via git mv)
    - tests/testthat/test-replication.R (skip message text only)
decisions:
  - "Used do.call(Sys.setenv, ...) in with_env() helper because Sys.setenv requires named character args, not a named list — base-R list approach from plan template needed adjustment"
  - "Kept build_replication_fixtures() in helper-gated-data.R unchanged; rename only affects file path, not function signatures"
metrics:
  duration: "~4 minutes"
  completed_date: "2026-04-16"
  tasks_completed: 4
  files_modified: 3
  files_created: 1
---

# Phase 07 Plan 01: infra02-gated-data-contract Summary

**One-liner:** Env-var-only WIOD/FIGARO resolver contract (D-7.7) via helper rename, resolve_figaro_root() addition, and 8-block INFRA-02 regression guard test.

## What Was Built

Closed the INFRA-02 silent-fallback gap identified in the v1.1 audit. The helper file was renamed from `helper-replication.R` to `helper-gated-data.R` (tracked via `git mv`), `resolve_wiod_root()` was replaced with a one-liner that never falls back to `inst/extdata/wiod/`, a parallel `resolve_figaro_root()` was added reading `SUBE_FIGARO_DIR`, and `test-gated-data-contract.R` was created with 8 `test_that` blocks covering both resolvers across all four behavioral branches. The three skip messages in `test-replication.R` were shortened to drop the now-obsolete "inst/extdata/wiod/ absent" phrase.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rename helper, replace resolve_wiod_root(), add resolve_figaro_root() | c552d14 | tests/testthat/helper-gated-data.R (renamed from helper-replication.R) |
| 2 | Update test-replication.R skip messages | 567557b | tests/testthat/test-replication.R |
| 3 (TDD RED) | Add failing INFRA-02 contract tests | f866f40 | tests/testthat/test-gated-data-contract.R |
| 3 (TDD GREEN) | Fix with_env() and pass all tests | 55b9b40 | tests/testthat/test-gated-data-contract.R |
| 4 | Full suite smoke test (verification only) | 9eebc04 | (no file writes) |

## Verification Results

- `devtools::test(filter = "gated-data-contract")`: 6 PASS, 2 SKIP (fallback dir absent — holds vacuously per D-7.7), 0 FAIL
- `devtools::test()` full suite: 108 PASS, 5 SKIP, 0 FAIL, 0 ERROR
- `devtools::check(cran = FALSE, vignettes = FALSE)`: 0 errors, 4 warnings, 2 notes — identical to v1.1 pre-change baseline (no regressions introduced)
- `git log --follow tests/testthat/helper-gated-data.R`: rename from `helper-replication.R` tracked

## Success Criteria Check

- [x] `tests/testthat/helper-replication.R` no longer exists
- [x] `tests/testthat/helper-gated-data.R` exists with both resolvers + `build_replication_fixtures()`
- [x] `resolve_wiod_root()` body is the D-7.7 one-liner; no `system.file()` fallback branch
- [x] `resolve_figaro_root()` exists with identical one-liner shape reading `SUBE_FIGARO_DIR`
- [x] `test-replication.R` skip messages drop the `inst/extdata/wiod/ absent` phrase (3 occurrences updated)
- [x] `test-gated-data-contract.R` exists with 8 test_that blocks (6 pass, 2 skip on this install)
- [x] `devtools::test()` full-suite zero failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `with_env()` Sys.setenv call pattern**
- **Found during:** Task 3 TDD GREEN — tests errored with "all arguments must be named"
- **Issue:** Plan template used `Sys.setenv(setNames(list(value), key))` which fails because `Sys.setenv` requires named character arguments passed directly, not a named list
- **Fix:** Changed to `do.call(Sys.setenv, setNames(list(as.character(value)), key))` for both set and restore paths
- **Files modified:** tests/testthat/test-gated-data-contract.R
- **Commit:** 55b9b40

## Known Stubs

None — all resolvers are fully wired; no placeholder data or TODO patterns introduced.

## Threat Flags

None — this plan modifies test infrastructure only. No new network endpoints, auth paths, file access patterns outside the test suite, or schema changes introduced.

## Self-Check: PASSED

- [x] tests/testthat/helper-gated-data.R exists
- [x] tests/testthat/test-gated-data-contract.R exists
- [x] tests/testthat/test-replication.R modified (3 skip messages updated)
- [x] helper-replication.R absent
- [x] Commits c552d14, 567557b, f866f40, 55b9b40, 9eebc04 exist in git log
