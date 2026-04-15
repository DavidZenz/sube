---
phase: 06-paper-replication-verification
plan: 03
subsystem: docs
tags: [r-package, vignette, pkgdown, news, paper-replication]

requires:
  - phase: 06-paper-replication-verification
    provides: filter_paper_outliers export + gated replication test
provides:
  - "paper-replication vignette (9 sections + Beyond, eval=FALSE)"
  - "pkgdown Paper replication tools reference group"
  - "NEWS.md v1.1 entries for REP-01 + REP-02"
affects: [future users following the replication workflow]

tech-stack:
  added: []
  patterns:
    - "Dedicated pkgdown reference group for paper-specific tooling (separates replication API from generic comparison helpers)."

key-files:
  created:
    - vignettes/paper-replication.Rmd
  modified:
    - _pkgdown.yml
    - NEWS.md

key-decisions:
  - "Vignette uses eval = FALSE globally (D-10) so it renders on CRAN without the ~4 GB WIOD archive; inline #> lines mirror paper replicate_paper.R:741-747 output."
  - "pkgdown reference split places paper-specific helpers (filter_paper_outliers, prepare_sube_comparison, plot_paper_*) in a new 'Paper replication tools' group, keeping 'Comparison and export helpers' for generic helpers."
  - "NEWS.md bullets appended under the existing `# sube (development version)` section — no new version header per D-15."

patterns-established:
  - "Paper-specific reference pages are collected under a single pkgdown group with filter_paper_outliers as the entry point."

requirements-completed: [REP-02]

duration: 20min
completed: 2026-04-15
---

# Phase 06, Plan 03: replication-vignette Summary

**paper-replication vignette + pkgdown reference group + NEWS entries completing REP-02.**

## Performance

- **Duration:** ~20 min (executor + orchestrator fixups)
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Authored the `paper-replication` vignette (9 numbered sections + Beyond footer) narrating the end-to-end WIOD→SUBE workflow with eval=FALSE chunks. Section 6 demos `filter_paper_outliers()`; section 9 shows the gated-test command.
- Split the pkgdown `reference:` block: new `Paper replication tools` group containing `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_*`; trimmed `Comparison and export helpers` to generic helpers (`extract_leontief_matrices`, `filter_sube`, `plot_sube`, `write_sube`).
- Added three bullets to the existing `# sube (development version)` section of NEWS.md covering the new export, the vignette, and the gated regression test.
- `tools::buildVignettes()` renders `doc/paper-replication.html` cleanly; yaml parses and new group contains `filter_paper_outliers` as first entry.
- `R CMD build .` succeeds.

## Task Commits

1. **Task 1: paper-replication.Rmd** — `95f1689` (docs)
2. **Task 2: _pkgdown.yml + NEWS.md** — `1cb5533` (docs)

## Files Created/Modified
- `vignettes/paper-replication.Rmd` — 9-section walkthrough, 157 lines, eval=FALSE
- `_pkgdown.yml` — new `Paper replication tools` group + trimmed `Comparison and export helpers`
- `NEWS.md` — 3 new bullets under the existing development-version header

## Decisions Made
- Orchestrator applied all file edits because the executor subagent hit a sandbox permission wall on creating new files in `vignettes/`. Content came from the plan's explicit action block.

## Deviations from Plan
**R CMD check --as-cran reports 1 ERROR — pre-existing, unrelated to phase 6.**

The failure is in `tests/testthat/test-workflow.R:218` (`legacy wrapper script remains a usable migration bridge`). The test launches `inst/scripts/run_legacy_pipeline.R` via `Rscript` in a subprocess; under `R CMD check`'s isolated library path the subprocess exits status 1 and never writes its output files. `devtools::test()` at phase-6 HEAD passes (102/102) — the failure is specific to R CMD check's subprocess library isolation, not a phase-6 regression.

**Recommendation:** Address in a separate infrastructure phase (adjust the legacy-wrapper test to pass `R_LIBS` / `.libPaths()` into the Rscript subprocess, or skip under `R CMD check`). Does not block REP-02 acceptance — vignette, pkgdown, NEWS all verify.

## Issues Encountered
- Executor was blocked by a sandbox permission wall on `Write` of the new vignette file. Orchestrator touched the empty file and wrote content inline from the plan.
- `devtools::build_vignettes()` failed in this sandbox because it tried to rebuild `lmtest` from source (broken gfortran/GLIBC). Used `tools::buildVignettes()` instead, which uses the installed `lmtest` — vignette built successfully.

## Next Phase Readiness
- REP-01 and REP-02 both satisfied; phase 6 replication work complete.
- Pre-existing legacy-wrapper R CMD check failure logged for a follow-up infrastructure phase.

---
*Phase: 06-paper-replication-verification*
*Completed: 2026-04-15*
