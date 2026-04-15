---
phase: 06-paper-replication-verification
plan: 02
subsystem: api
tags: [r-package, roxygen2, namespace, data.table, paper-replication]

requires:
  - phase: 04-post-estimation-toolkit
    provides: prepare_sube_comparison + internal .apply_paper_filters
provides:
  - "Public filter_paper_outliers() function exporting the paper's six-layer outlier treatment"
  - "variables= and apply_bounds= arguments so downstream code can subset metrics or skip layer 5"
  - "CRAN-style man/filter_paper_outliers.Rd page"
affects: [06-03-replication-vignette, future paper-replication users]

tech-stack:
  added: []
  patterns:
    - "Internal helper promoted to @export with explicit argument surface"

key-files:
  created:
    - man/filter_paper_outliers.Rd
  modified:
    - R/paper_tools.R
    - NAMESPACE

key-decisions:
  - "Kept default variables=c('GO','VA','EMP','CO2') to preserve existing behaviour for all current call sites."
  - "apply_bounds defaults to TRUE so the legacy paper behaviour is the default; FALSE keeps multiplier outliers for diagnostics."
  - "Rewrote the Rd interval notation from \\link{1, 4} (auto-mangled by roxygen) to \\code{[1, 4]} so tools::checkRd passes."

patterns-established:
  - "Paper-specific filters live in R/paper_tools.R and are exported with a clear 'paper-specific, not general-purpose' warning in the roxygen description."

requirements-completed: [REP-01]

duration: 12min
completed: 2026-04-15
---

# Phase 06, Plan 02: filter_paper_outliers export Summary

**Exported the paper's six-layer outlier treatment as `filter_paper_outliers(data, variables, apply_bounds)` with a CRAN-style man page.**

## Performance

- **Duration:** ~12 min (executor) + orchestrator fixup
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Renamed internal `.apply_paper_filters` to public `filter_paper_outliers`, added roxygen documentation with @export.
- Added `variables=` and `apply_bounds=` arguments so callers can subset metrics and toggle multiplier-bounds layer.
- Updated two internal call sites (`prepare_sube_comparison`, `plot_paper_interval_ranges`) to use the exported name.
- Generated `man/filter_paper_outliers.Rd` and confirmed `tools::checkRd()` passes.

## Task Commits

1. **Task 1: export filter_paper_outliers** — `a1c7c64` (feat)
2. **Task 2: NAMESPACE + Rd** — `480d9c8` (docs)

## Files Created/Modified
- `R/paper_tools.R` — rename + roxygen block + call-site updates
- `NAMESPACE` — `export(filter_paper_outliers)`
- `man/filter_paper_outliers.Rd` — manual page (54 lines)

## Decisions Made
- Kept default `variables=c("GO","VA","EMP","CO2")` so existing behaviour is unchanged.
- Default `apply_bounds = TRUE` preserves paper behaviour; FALSE is a diagnostic escape hatch.

## Deviations from Plan
Roxygen auto-generated `\link{1, 4}` / `\link{0, 1}` in the Rd (it mis-parsed interval brackets). Orchestrator corrected these to `\code{[1, 4]}` / `\code{[0, 1]}` and committed the fix; `tools::checkRd()` then ran clean.

## Issues Encountered
- Executor agent encountered a permission denial editing the generated Rd file. Orchestrator applied the one-line fix, validated with `tools::checkRd`, and committed.
- Worktree was created from an older base (109c391) — orchestrator rebased onto 599d884 to pick up phase 6 planning docs so SUMMARY.md could be placed.

## Next Phase Readiness
- Public `filter_paper_outliers()` is ready to be used by the replication vignette (Plan 06-03).

---
*Phase: 06-paper-replication-verification*
*Completed: 2026-04-15*
