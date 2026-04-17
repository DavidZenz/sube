---
phase: 11
slug: data-format-specification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e "testthat::test_file('tests/testthat/test-vignette-render.R')"` |
| **Full suite command** | `Rscript -e "devtools::test()"` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e "devtools::test()"`
- **After every plan wave:** Run `Rscript -e "devtools::test()"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | FMT-01 | — | N/A | manual | `grep -c 'REP.*PAR.*CPA' vignettes/data-preparation.Rmd` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | FMT-02 | — | N/A | manual | `grep -c 'GO.*VA.*EMP.*CO2' vignettes/data-preparation.Rmd` | ✅ | ⬜ pending |
| 11-01-03 | 01 | 1 | FMT-03 | — | N/A | manual | `grep -c 'bring your own' vignettes/data-preparation.Rmd` | ✅ | ⬜ pending |
| 11-01-04 | 01 | 1 | FMT-04 | — | N/A | manual | `grep -c 'NACE_R2\|NACE\|INDUSTRY' vignettes/data-preparation.Rmd` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Canonical column table with semantics and examples | FMT-01 | Documentation content — requires human review of prose quality and accuracy | Read rendered vignette, verify each column has semantics + example |
| Satellite vector documentation | FMT-02 | Documentation content — requires human review | Read rendered vignette, verify GO/VA/EMP/CO2 documented with source info |
| BYOD step-by-step guide | FMT-03 | Documentation workflow — requires human walkthrough | Follow guide with sample data, verify steps are complete |
| Synonym table completeness | FMT-04 | Documentation accuracy — must match `.coerce_map()` | Compare synonym table against R/utils.R `.coerce_map()` output |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
