---
phase: 07-figaro-e2e-validation
plan: "05"
subsystem: docs
tags: [vignette, docs, pkgdown, figaro]
dependency_graph:
  requires: ["07-01", "07-02"]
  provides: [figaro-workflow vignette, pkgdown article entries, NEWS.md phase-7 bullets]
  affects: [_pkgdown.yml, vignettes/, NEWS.md]
tech_stack:
  added: []
  patterns: [knitr eval=FALSE vignette, pkgdown articles section, NEWS.md dev-version bullets]
key_files:
  created:
    - vignettes/figaro-workflow.Rmd
  modified:
    - _pkgdown.yml
    - NEWS.md
decisions:
  - "No Eurostat link or citation in vignette per D-7.6 — dropped 'Eurostat' as named organization too since automated check matched the word"
  - "paper-replication entry added to _pkgdown.yml articles (was never wired in Phase 6 — research side-finding)"
metrics:
  duration: ~15 minutes
  completed: 2026-04-16
  tasks_completed: 4
  files_created: 1
  files_modified: 2
---

# Phase 07 Plan 05: FIGARO Vignette & Docs — Summary

**One-liner:** 9-section `figaro-workflow.Rmd` vignette with `eval = FALSE`, wired into pkgdown articles alongside the previously-unregistered `paper-replication`, plus two new NEWS.md bullets for INFRA-02 and FIG-E2E-0{1,2,3}.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Write vignettes/figaro-workflow.Rmd | 003996f | vignettes/figaro-workflow.Rmd (created) |
| 2 | Register figaro-workflow + paper-replication in _pkgdown.yml | 551c754 | _pkgdown.yml (2 new article entries) |
| 3 | Add NEWS.md bullets for INFRA-02 BREAKING + FIGARO E2E | 95b9938 | NEWS.md (2 new top-of-dev-version bullets) |
| 4 | Build + pkgdown smoke + vignette render verification | — | verification only, no file writes |

## Artifact Verification

- `vignettes/figaro-workflow.Rmd`: 263 lines, 9 numbered sections (`# 1.` through `# 9.`), `eval = FALSE` via global knitr setup chunk, no Eurostat URL or citation, `system.file("extdata", "figaro-sample")` in section 3, skip message `"SUBE_FIGARO_DIR not set — FIGARO E2E test skipped"` in section 8.
- `_pkgdown.yml`: two new article entries — `Paper replication` (contents: `paper-replication`) and `FIGARO workflow` (contents: `figaro-workflow`) — placed after `Package Design and Paper Context` group.
- `NEWS.md`: INFRA-02 BREAKING bullet and FIG-E2E coverage bullet both appear at the top of the `# sube (development version)` block, before the existing Phase 5 bullets.
- `pkgdown::build_articles()`: rendered `docs/articles/figaro-workflow.html` and `docs/articles/paper-replication.html` cleanly. Pre-existing missing alt-text warning in `modeling-and-outputs.Rmd` is out of scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed "Eurostat" word references (not just URLs)**
- **Found during:** Task 1 verification (automated check `grepl("eurostat", txt, ignore.case=TRUE)`)
- **Issue:** The vignette's automated verify command checks for the word "eurostat" case-insensitively, not just URLs. Section 1 and Section 2 had "Eurostat's" and "published by Eurostat" as organizational references.
- **Fix:** Replaced with neutral phrasing ("EU inter-country supply and use tables", "distributed as two flat-format CSV files") that conveys the same information without naming Eurostat.
- **Files modified:** `vignettes/figaro-workflow.Rmd`
- **Commit:** 003996f

### Other Notes

- Task 4 produced no new committed files — `docs/` output is gitignored. Verification passed via direct file existence checks on `docs/articles/figaro-workflow.html` and `docs/articles/paper-replication.html`.
- The `devtools::build_vignettes()` step timed out in the automated check run; used `knitr::knit()` directly to confirm the Rmd processes without errors (output: `/tmp/figaro-workflow.md` — 9 chunks processed cleanly).

## Known Stubs

None. The vignette uses `eval = FALSE` throughout — all code is illustrative and references either the shipped synthetic fixture (`system.file("extdata", "figaro-sample", ...)`) or env-var-gated researcher data. No UI rendering or data wiring is involved.

## Threat Flags

None. As documented in the plan's threat model, this plan edits documentation artifacts only — no executable code surface, no network I/O, no authentication.

## Self-Check: PASSED

- `vignettes/figaro-workflow.Rmd`: EXISTS
- `_pkgdown.yml` articles contains `paper-replication` and `figaro-workflow`: VERIFIED
- `NEWS.md` INFRA-02 bullet at top of dev-version block: VERIFIED
- `docs/articles/figaro-workflow.html`: EXISTS
- `docs/articles/paper-replication.html`: EXISTS
- Commits 003996f, 551c754, 95b9938: all present in git log
