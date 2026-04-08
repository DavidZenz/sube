---
phase: 1
slug: core-workflow-contracts
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-08
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` |
| **Full suite command** | `R -q -e 'testthat::test_dir("tests/testthat")'` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'`
- **After every plan wave:** Run `R -q -e 'testthat::test_dir("tests/testthat")'`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | WF-02 | T-1-01 | Invalid import or mapping shapes fail explicitly instead of silently coercing bad data | unit | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` | ✅ | ✅ green |
| 1-02-01 | 02 | 1 | WF-03 | T-1-02 | Compute failures either emit stable diagnostics or stop with explicit contract errors | unit | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` | ✅ | ✅ green |
| 1-03-01 | 03 | 2 | WF-01 | T-1-03 | Shipped example workflow remains runnable from documented entry points | integration | `R -q -e 'testthat::test_dir("tests/testthat")'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-workflow.R` — existing workflow coverage baseline
- [x] `tests/testthat.R` — test runner already present
- [x] `testthat` dependency already declared in `DESCRIPTION`

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All Phase 1 behaviors should be automatable with example data and `testthat` | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed on 2026-04-08
