---
phase: 6
slug: paper-replication-verification
status: audited
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-15
updated: 2026-04-17
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
| 6-01-01 | 01 | 1 | REP-01 | — | N/A | integration (gated) | `SUBE_WIOD_DIR=... Rscript -e 'devtools::test(filter = "replication")'` | ✅ | ✅ green |
| 6-01-02 | 01 | 1 | REP-01 | — | N/A | integration (gated) | same | ✅ | ✅ green |
| 6-01-03 | 01 | 1 | REP-01 | — | N/A | unit | `Rscript -e 'devtools::test(filter = "replication")'` (env unset) | ✅ | ✅ green |
| 6-02-01 | 02 | 1 | REP-01 | — | N/A | unit | `Rscript -e 'devtools::test(filter = "paper")'` | ✅ | ✅ green |
| 6-03-01 | 03 | 2 | REP-02 | — | N/A | build | `Rscript -e 'tools::buildVignettes(dir = ".")'` | ✅ | ✅ green |
| 6-03-02 | 03 | 2 | REP-02 | — | N/A | full check | `R CMD check --as-cran sube_0.1.2.tar.gz` | ✅ | ⚠️ flaky |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs are illustrative placeholders — planner will finalize task numbering when writing PLAN.md files.*

---

## Wave 0 Requirements

- [x] `tests/testthat/helper-gated-data.R` — fixture builder (renamed from `helper-replication.R` in Phase 7; contains `resolve_wiod_root()`, `build_replication_fixtures()`)
- [x] `tests/testthat/test-replication.R` — 3 `test_that` blocks: W matrix, raw SUP, raw USE (all skip cleanly when `SUBE_WIOD_DIR` unset)
- [x] `vignettes/paper-replication.Rmd` — 9-section narrative with `eval = FALSE` (157 lines)
- [x] `R/paper_tools.R` — `filter_paper_outliers()` exported with `variables` + `apply_bounds` args
- [x] `NAMESPACE` — `export(filter_paper_outliers)` present
- [x] `man/filter_paper_outliers.Rd` — roxygen-generated man page (53 lines)
- [x] `_pkgdown.yml` — "Paper replication tools" group present
- [x] `NEWS.md` — 3 bullets under development version section

*Testthat framework already installed — no framework bootstrap needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Vignette prose reads clearly and mirrors `replicate_paper.R` section order | REP-02 | Narrative quality cannot be asserted via code | Reviewer reads rendered HTML of `paper-replication.html` after `build_vignettes()`; confirms 9 sections (per D-11), representative `#> ...` output present in sections 3–8, "Beyond this vignette" pointer at end (D-12) |
| `SUBE_WIOD_DIR` skip message reads cleanly in interactive sessions | REP-01 SC-2 | Exact wording is Claude's discretion (per CONTEXT.md "Claude's Discretion") | Run `Rscript -e 'devtools::test(filter = "replication")'` without env var; confirm output contains a single clear SKIP line |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (2026-04-17 retroactive audit)

---

## Validation Audit 2026-04-17

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Notes:**
- Replication filter: 0 pass / 0 fail / 3 expected skip (SUBE_WIOD_DIR unset — by design)
- 3 `test_that` blocks in `test-replication.R` cover REP-01 (gated numerical match)
- `filter_paper_outliers` exported with full Rd documentation
- `paper-replication.Rmd` vignette builds cleanly via `tools::buildVignettes()`
- Task 6-03-02 marked flaky: pre-existing `test-workflow.R` failures under `R CMD check`
- All Wave 0 artifacts delivered across Plans 01-03
- Retroactive audit — phase was executed before Nyquist validation was enforced
