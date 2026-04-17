---
phase: 9
slug: test-infrastructure-tech-debt
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e "devtools::test(filter='workflow')"` |
| **Full suite command** | `Rscript -e "devtools::test()"` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e "devtools::test(filter='workflow')"`
- **After every plan wave:** Run `Rscript -e "devtools::test()"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | INFRA-01 | — | N/A | integration | `Rscript -e "devtools::test(filter='workflow')"` | ✅ | ⬜ pending |
| 09-01-02 | 01 | 1 | INFRA-01 | — | N/A | check | `R CMD build . && R CMD check --as-cran sube_*.tar.gz` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
