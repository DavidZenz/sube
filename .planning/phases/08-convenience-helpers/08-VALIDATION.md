---
phase: 8
slug: convenience-helpers
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat edition 3 (R) |
| **Config file** | `DESCRIPTION` (Suggests: testthat), `tests/testthat/setup-sube.R` |
| **Quick run command** | `Rscript -e "devtools::test(filter = 'pipeline')"` |
| **Full suite command** | `Rscript -e "devtools::test()"` |
| **Estimated runtime** | ~25–40 seconds for `test-pipeline.R`; ~2–3 min full suite |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e "devtools::test(filter = 'pipeline')"`
- **After every plan wave:** Run `Rscript -e "devtools::test()"` (full suite must stay green — regression protection for the locked 4-step chain)
- **Before `/gsd-verify-work`:** Full suite + `R CMD check --no-manual` green
- **Max feedback latency:** 40 seconds (quick run)

---

## Per-Task Verification Map

Tasks below are filled by the planner. Row template:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01 | 01 | 1 | CONV-01 | — | N/A | unit | `Rscript -e "devtools::test(filter = 'pipeline')"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-pipeline.R` — new file, stub tests for CONV-01 / CONV-02 / CONV-03 covering:
  - Happy path `run_sube_pipeline()` on `sube_example_data()` fixture
  - FIGARO branch `run_sube_pipeline(source = "figaro", ...)` on `inst/extdata/figaro-sample/`
  - `estimate = TRUE` opt-in branch
  - `batch_sube()` success path (≥2 countries × 2 years)
  - Each of the 4 D-8.11 diagnostic categories produces the expected `$diagnostics` row
  - Resilient per-group error handling (D-8.7)
- [ ] `tests/testthat/helper-pipeline.R` (optional) — shared fixture builders; reuse `helper-gated-data.R::build_figaro_pipeline_fixture_from_synthetic()` where possible
- [ ] No new framework install needed — testthat 3 already on Suggests

*Test infrastructure exists; only per-phase stubs are missing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| pkgdown group placement renders correctly | D-8.13 | pkgdown build output is visual; automated check requires full `pkgdown::build_site()` which is slow | Run `pkgdown::build_site()` locally; verify `run_sube_pipeline` + `batch_sube` appear under "Data import and preparation" in reference section |
| `vignettes/pipeline-helpers.Rmd` knits under `R CMD check` | D-8.14 | Vignette eval happens in `R CMD check --as-cran` only; not part of `devtools::test()` | Run `R CMD check --as-cran` (or `devtools::check()`); confirm vignette builds without error |
| Summary `warning()` wording | D-8.10 | Wording is Claude's Discretion per CONTEXT.md; test only asserts presence and status-category counts, not exact prose | Review warning message after `run_sube_pipeline()` and `batch_sube()` calls on fixtures with known diagnostics; confirm status counts are named |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (stub `test-pipeline.R`)
- [ ] No watch-mode flags (testthat runs once)
- [ ] Feedback latency < 40 s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
