---
phase: 2
slug: comparison-layer-stabilization
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-08
---

# Phase 2 — Validation Strategy

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
| 2-01-01 | 01 | 1 | COMP-01, COMP-02 | T-2-01 | Extraction and comparison helpers return explicit, stable structures instead of ambiguous table shapes | unit | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` | ✅ | ✅ green |
| 2-02-01 | 02 | 1 | COMP-03, COMP-04 | T-2-02 | Plot and export helpers either return predictable objects/paths or fail explicitly for unsupported shapes | unit | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` | ✅ | ✅ green |
| 2-03-01 | 03 | 2 | COMP-01, COMP-02, COMP-03, COMP-04 | T-2-03 | Public examples and workflow tests prove the comparison layer is reproducible from shipped package data | integration | `R -q -e 'testthat::test_dir("tests/testthat")'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-workflow.R` — existing comparison and export smoke coverage baseline
- [x] `tests/testthat.R` — test runner already present
- [x] `testthat` dependency already declared in `DESCRIPTION`

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | Phase 2 behaviors should remain automatable with shipped sample data and `testthat` | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed on 2026-04-08
