---
phase: 12
slug: vignette-readme-refresh
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R CMD build + knitr (vignette compilation) |
| **Config file** | DESCRIPTION (VignetteBuilder: knitr) |
| **Quick run command** | `R CMD build . && echo "Vignettes OK"` |
| **Full suite command** | `R CMD build . && R CMD check --no-tests sube_*.tar.gz` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `R CMD build . && echo "Vignettes OK"`
- **After every plan wave:** Run `R CMD build . && R CMD check --no-tests sube_*.tar.gz`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | VIG-01 | — | N/A | build | `R CMD build .` | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | VIG-02 | — | N/A | build | `R CMD build .` | ✅ | ⬜ pending |
| 12-01-03 | 01 | 1 | VIG-03 | — | N/A | build | `R CMD build .` | ✅ | ⬜ pending |
| 12-01-04 | 01 | 1 | DOC-01 | — | N/A | manual | grep README.md | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Source-agnostic framing in each vignette | VIG-01 | Prose quality check | grep each vignette for "canonical format" or "any SUT data" framing sentence |
| Narrative coherence across vignette sequence | VIG-03 | Reading flow is subjective | Read vignettes in order: getting-started → package-design → data-preparation → modeling-and-outputs → paper-replication → figaro-workflow → pipeline-helpers |
| README source-agnostic description | DOC-01 | Prose content check | grep README.md for source-agnostic language and BYOD mention |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
