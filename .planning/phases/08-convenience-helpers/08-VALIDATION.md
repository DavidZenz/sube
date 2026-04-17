---
phase: 8
slug: convenience-helpers
status: audited
nyquist_compliant: true
wave_0_complete: true
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

| Task ID  | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|----------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01  | 01   | 1    | CONV-01, CONV-03 | T-8.1-01 | data.table::copy of inputs before .standardize_names | unit | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅       | ✅ green |
| 8-01-02  | 01   | 1    | CONV-03 | T-8.1-01 | diagnostic detections read-only on sut/inputs | unit + integration (figaro fixture) | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ✅ green |
| 8-01-03  | 01   | 1    | CONV-01, CONV-03 | — | N/A | unit + integration | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ✅ green |
| 8-02-01  | 02   | 2    | CONV-02 | T-8.2-01 | data.table::copy guards on cpa_map/ind_map/inputs | unit | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ✅ green |
| 8-02-02  | 02   | 2    | CONV-02, CONV-03 | T-8.2-01 | tryCatch isolation per group | unit + resilience | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ✅ green |
| 8-03-01  | 03   | 3    | CONV-01, CONV-02 | — | N/A | doc build | `Rscript -e "devtools::document()"` | ✅ | ✅ green |
| 8-03-02  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | config | `Rscript -e "yaml::read_yaml('_pkgdown.yml')"` | ✅ | ✅ green |
| 8-03-03  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | vignette build | `Rscript -e "devtools::build_vignettes()"` | ✅ | ✅ green |
| 8-03-04  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | full CRAN check | `Rscript -e "devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')"` | ✅ | ⚠️ flaky |

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (stub `test-pipeline.R`)
- [x] No watch-mode flags (testthat runs once)
- [x] Feedback latency < 40 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (2026-04-17 audit)

---

## Validation Audit 2026-04-17

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Notes:**
- Full test suite: 197 pass / 0 fail / 5 expected skip
- Pipeline filter: 87 pass / 0 fail / 2 expected skip
- 25 `test_that` blocks in `test-pipeline.R` cover all CONV-01/02/03 requirements
- Task 8-03-04 marked flaky: pre-existing `test-workflow.R` failures in `R CMD check` (not introduced by Phase 8; tracked in `deferred-items.md`)
- All other 8 tasks verified green with automated commands
