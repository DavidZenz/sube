---
phase: 6
slug: paper-replication-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat (edition 3) |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e 'devtools::test(filter = "replication")'` |
| **Full suite command** | `Rscript -e 'devtools::test()'` |
| **Gated run (REP-01 match)** | `SUBE_WIOD_DIR=/path/to/wiod Rscript -e 'devtools::test(filter = "replication")'` |
| **Vignette build** | `Rscript -e 'devtools::build_vignettes()'` |
| **Estimated runtime** | ~10 s (gated); <1 s (ungated, skips) |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e 'devtools::test(filter = "replication")'` (skips cleanly when env var unset — near-instant feedback)
- **After every plan wave:** Run `Rscript -e 'devtools::test()'` full suite + `devtools::build_vignettes()`
- **Before `/gsd-verify-work`:** `SUBE_WIOD_DIR=... R CMD check --as-cran` must be green
- **Max feedback latency:** ~10 s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | REP-01 | — | N/A | integration (gated) | `SUBE_WIOD_DIR=... Rscript -e 'devtools::test(filter = "replication")'` | ❌ W0 (`tests/testthat/test-replication.R`) | ⬜ pending |
| 6-01-02 | 01 | 1 | REP-01 | — | N/A | integration (gated) | same | ❌ W0 (same file) | ⬜ pending |
| 6-01-03 | 01 | 1 | REP-01 | — | N/A | unit | `Rscript -e 'devtools::test(filter = "replication")'` (env unset) | ❌ W0 | ⬜ pending |
| 6-02-01 | 02 | 1 | REP-01 | — | N/A | unit | `Rscript -e 'devtools::test(filter = "paper")'` | ✅ existing | ⬜ pending |
| 6-03-01 | 03 | 2 | REP-02 | — | N/A | build | `Rscript -e 'devtools::build_vignettes()'` | ❌ W0 (`vignettes/paper-replication.Rmd`) | ⬜ pending |
| 6-03-02 | 03 | 2 | REP-02 | — | N/A | full check | `R CMD check --as-cran sube_0.1.2.tar.gz` | ✅ harness | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs are illustrative placeholders — planner will finalize task numbering when writing PLAN.md files.*

---

## Wave 0 Requirements

- [ ] `tests/testthat/helper-replication.R` — fixture builder (`resolve_wiod_root()`, `build_replication_fixtures()`) lifted from `inst/scripts/replicate_paper.R`
- [ ] `tests/testthat/test-replication.R` — three `test_that()` blocks: (1) `model_data` ≡ legacy W, (2) raw SUP ≡ legacy, (3) raw USE ≡ legacy
- [ ] `vignettes/paper-replication.Rmd` — 9-section narrative with `eval = FALSE`
- [ ] `R/paper_tools.R` — rename `.apply_paper_filters()` → `filter_paper_outliers()`, add `@export`, refactor body to honour `variables` + `apply_bounds` per D-08
- [ ] `NAMESPACE` — append `export(filter_paper_outliers)` (hand-edit per Phase 5 D-23)
- [ ] `man/filter_paper_outliers.Rd` — roxygen-generated man page
- [ ] `_pkgdown.yml` — new "Paper replication tools" group
- [ ] `NEWS.md` — 2-3 bullets under v1.1 section

*Testthat framework already installed — no framework bootstrap needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Vignette prose reads clearly and mirrors `replicate_paper.R` section order | REP-02 | Narrative quality cannot be asserted via code | Reviewer reads rendered HTML of `paper-replication.html` after `build_vignettes()`; confirms 9 sections (per D-11), representative `#> ...` output present in sections 3–8, "Beyond this vignette" pointer at end (D-12) |
| `SUBE_WIOD_DIR` skip message reads cleanly in interactive sessions | REP-01 SC-2 | Exact wording is Claude's discretion (per CONTEXT.md "Claude's Discretion") | Run `Rscript -e 'devtools::test(filter = "replication")'` without env var; confirm output contains a single clear SKIP line |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10 s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
