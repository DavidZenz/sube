---
phase: 3
slug: documentation-alignment
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-08
---

# Phase 3 — Validation Strategy

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

- **After every doc change set that mirrors runnable examples:** Run `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'`
- **After every plan wave:** Run `R -q -e 'testthat::test_dir("tests/testthat")'`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | DOC-01, DOC-02 | T-3-01 | README and vignette framing describe the same package workflow and function groupings | integration | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` | ✅ | ✅ green |
| 3-02-01 | 02 | 1 | DOC-01, DOC-02 | T-3-02 | pkgdown and package/reference surfaces expose the same workflow grouping users see in narrative docs | manual+unit | `R -q -e 'testthat::test_dir("tests/testthat")'` | ✅ | ✅ green |
| 3-03-01 | 03 | 2 | MIG-02, DOC-01 | T-3-03 | Example-data and input-contract guidance let new users infer required inputs from shipped examples without hidden assumptions | integration | `R -q -e 'testthat::test_dir("tests/testthat")'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-workflow.R` — stable sample-workflow contract baseline
- [x] `tests/testthat.R` — test runner already present
- [x] Documentation surfaces already exist and can be aligned without new infrastructure

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| pkgdown navigation and article grouping read coherently | DOC-01, DOC-02 | Site structure is configured in YAML and prose, not fully capturable by tests alone | Inspect `_pkgdown.yml` alongside README and vignette headings after edits |
| Example-data guidance is discoverable from docs alone | MIG-02 | This is primarily a documentation clarity check | Read README plus data-preparation/getting-started vignette flow as a new user would |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s for automated checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed on 2026-04-08
