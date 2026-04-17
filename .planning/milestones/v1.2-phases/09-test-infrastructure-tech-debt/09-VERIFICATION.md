---
phase: 09-test-infrastructure-tech-debt
verified: 2026-04-17T00:00:00Z
status: human_needed
score: 2/4 must-haves verified programmatically (2 require human run)
overrides_applied: 0
human_verification:
  - test: "Run devtools::test() and confirm zero failures"
    expected: "All tests pass (197+ pass, 0 fail, 5 expected skips for gated replication tests per SUMMARY)"
    why_human: "Cannot invoke devtools::test() in a static grep-only verification pass — requires a live R session with sube installed"
  - test: "Build tarball and run R CMD check --as-cran"
    expected: "Zero test failures from test-workflow.R:218 in check output"
    why_human: "Definitive gate per PLAN verification section — requires R CMD build + R CMD check --as-cran; cannot be replicated statically"
---

# Phase 9: Test Infrastructure Tech Debt — Verification Report

**Phase Goal:** The pre-existing legacy-wrapper subprocess test in `tests/testthat/test-workflow.R:218` runs cleanly under `R CMD check --as-cran`, closing the last non-blocking tarball-check failure inherited from v1.1
**Verified:** 2026-04-17
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | R CMD check --as-cran on the built tarball produces zero test failures from test-workflow.R | ? UNCERTAIN — human needed | Code fix is in place (R_LIBS threading implemented at lines 244, 251); definitive confirmation requires running R CMD check --as-cran on the built tarball |
| 2 | devtools::test() runs all tests green with no regressions | ? UNCERTAIN — human needed | SUMMARY claims 197/197 pass (0 fail, 5 expected skips); cannot confirm without a live R session |
| 3 | The system2() call at test-workflow.R passes R_LIBS to the child Rscript process | ✓ VERIFIED | Line 244: `r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)`; line 251: `env    = paste0("R_LIBS=", r_libs)` inside system2() call block; inline comment at lines 240-243 explains the rationale |
| 4 | The resolution strategy is documented in PROJECT.md, NEWS.md, DESCRIPTION, and an inline comment | ✓ VERIFIED | All four locations confirmed: inline comment lines 240-243 (test-workflow.R); Key Decisions row line 94 (PROJECT.md); changelog bullet lines 69-74 (NEWS.md); Description field lines 13-14 (DESCRIPTION) |

**Score:** 2/4 truths verified programmatically; 2 require human confirmation

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/testthat/test-workflow.R` | Fixed subprocess invocation with R_LIBS threading | ✓ VERIFIED | 260 lines; contains `r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)` at line 244 and `env = paste0("R_LIBS=", r_libs)` at line 251; `expect_null(attr(status, "status"))` assertion at line 254 unchanged |
| `.planning/PROJECT.md` | Key Decisions entry for INFRA-01 resolution | ✓ VERIFIED | Line 94 contains `Thread .libPaths() via R_LIBS into legacy-wrapper subprocess test (INFRA-01)` with full rationale and `Good (v1.2)` outcome |
| `NEWS.md` | Changelog entry for subprocess fix | ✓ VERIFIED | Lines 69-74 contain INFRA-01 bullet: "Fixed the legacy-wrapper subprocess test ... via the `R_LIBS` environment variable (INFRA-01)" |
| `DESCRIPTION` | Note about legacy wrapper test .libPaths() threading | ✓ VERIFIED | Lines 13-14: "The legacy wrapper test threads .libPaths() via R_LIBS to support R CMD check environments." No standalone `Note:` field present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `tests/testthat/test-workflow.R` | `inst/scripts/run_legacy_pipeline.R` | system2() subprocess invocation with R_LIBS env | ✓ WIRED | Line 244 constructs r_libs from .libPaths(); line 251 passes env=paste0("R_LIBS=", r_libs) to system2(); target script exists (903 bytes) and calls library(sube) at its line 11, confirming why R_LIBS threading is necessary |

### Data-Flow Trace (Level 4)

Not applicable — the modified artifact is a test file, not a data-rendering component. No state variables flow to user-visible rendering.

### Behavioral Spot-Checks

Step 7b skipped for the devtools::test() and R CMD check gates — both require a live R session and cannot be verified statically. The structural fix (env parameter wiring) is confirmed by code inspection.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| system2() env parameter wired | `grep -n "env.*paste0.*R_LIBS" test-workflow.R` | Line 251: `env    = paste0("R_LIBS=", r_libs)` | ✓ PASS |
| r_libs variable constructed from .libPaths() | `grep -n "r_libs.*libPaths\|libPaths.*r_libs" test-workflow.R` | Line 244: `r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)` | ✓ PASS |
| Legacy script target exists and uses library(sube) | `ls inst/scripts/run_legacy_pipeline.R` + grep | Script exists (903 bytes); `library(sube)` at its line 11 | ✓ PASS |
| No standalone Note: field in DESCRIPTION | `grep "^Note:" DESCRIPTION` | No match | ✓ PASS |
| Assertion unchanged | `grep "expect_null(attr(status" test-workflow.R` | Line 254: unchanged | ✓ PASS |
| devtools::test() full suite | Requires live R session | Not run | ? SKIP |
| R CMD check --as-cran | Requires tarball build | Not run | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| INFRA-01 | 09-01-PLAN.md | `test-workflow.R:218` passes under `R CMD check --as-cran` by threading R_LIBS into subprocess | IMPLEMENTATION COMPLETE — human confirmation pending | R_LIBS threading code verified in test-workflow.R lines 240-251; target script confirmed to call library(sube); documentation in all 4 required locations |

**REQUIREMENTS.md checkbox state:** INFRA-01 is still marked `[ ]` in REQUIREMENTS.md. This is a stale documentation state — the code fix has been implemented and committed (commit `38f4788`). The checkbox should be updated to `[x]` during phase transition, but this is not a code gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | None found | — | All four modified files are clean |

### Human Verification Required

#### 1. Full Test Suite — devtools::test()

**Test:** In an R session with `sube` installed (or via `devtools::load_all()`), run `devtools::test()`.
**Expected:** All tests pass (197 pass, 0 failures, 5 gated skips for replication tests that require SUBE_WIOD_DIR / SUBE_FIGARO_DIR). The SUMMARY records these numbers from the executor's run.
**Why human:** Cannot invoke devtools::test() in a static verification pass; requires a live R session.

#### 2. R CMD Check --as-cran Gate

**Test:** Build the tarball (`R CMD build .`) and run `R CMD check --as-cran sube_*.tar.gz`. Review the test output section for any failures from test-workflow.R.
**Expected:** Zero test failures from test-workflow.R:218. The subprocess test invokes `run_legacy_pipeline.R` and the `expect_null(attr(status, "status"))` assertion passes because the child Rscript now finds the `sube` package via the threaded R_LIBS env var.
**Why human:** Definitive verification gate per the PLAN; requires building a tarball from the current source tree and running the full CRAN check harness — not achievable by static analysis.

### Gaps Summary

No programmatic gaps identified. All code changes are present and correctly implemented. Two must-haves (R CMD check outcome and devtools::test() count) cannot be verified without running R, which is the normal state for an R package verification. The SUMMARY documents the executor's runtime results (197/197 pass, 0 fail).

The REQUIREMENTS.md INFRA-01 checkbox remains `[ ]` — this stale state should be updated to `[x]` during the phase transition step, but it does not represent a missing implementation.

---

_Verified: 2026-04-17_
_Verifier: Claude (gsd-verifier)_
