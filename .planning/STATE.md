---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: FIGARO Validation, Convenience & Tech Debt
status: defining_requirements
stopped_at: Milestone v1.2 started — requirements defined, roadmap pending
last_updated: "2026-04-16T00:00:00.000Z"
last_activity: 2026-04-16 -- Milestone v1.2 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16 for v1.2)

**Core value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.
**Current focus:** v1.2 — FIGARO Validation, Convenience & Tech Debt (defining requirements → roadmap)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-16 -- Milestone v1.2 started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 19 (v1.0: 12; v1.1: 7)
- Total phases shipped: 6 (v1.0: 1-4; v1.1: 5-6)

**By Milestone:**

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 | 1-4 | 12 | 2026-04-08 |
| v1.1 | 5-6 | 7 | 2026-04-16 |
| v1.2 | 7-? | TBD | in progress |

**Recent Trend:**

- Last milestone: v1.1 Replication, FIGARO & Convenience (2 phases, 7 plans, 8 days)
- Trend: Steady cadence; FIGARO ingestion + paper replication delivered on plan

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions carried into v1.2:

- FIGARO ingestion modeled as parallel canonical importer (`read_figaro()`), not polymorphic `import_suts()` branch
- `CPA_` prefix stripped and FD columns aggregated to `FU_bas` at FIGARO import time
- Paper replication gated on `SUBE_WIOD_DIR`; `.Rbuildignore` excludes `inst/extdata/wiod/` so CRAN/CI skip deterministically
- v1.2 will parallel the gate pattern for FIGARO (`SUBE_FIGARO_DIR`) — CRAN/CI skip, researcher runs locally

### Pending Todos

Writing REQUIREMENTS.md with 10 REQ-IDs across 4 categories:
- FIGARO End-to-End Validation (FIG-E2E-01..03)
- Convenience Helpers (CONV-01..03)
- Test Infrastructure (INFRA-01, INFRA-02)
- Validation Coverage (NYQ-01, NYQ-02)

Roadmap: to be spawned via gsd-roadmapper, continuing numbering from Phase 7.

### Blockers/Concerns

None blocking; v1.2 explicitly addresses the tech debt from v1.1.

## Session Continuity

Last session: 2026-04-16
Stopped at: Milestone v1.2 started — requirements defined, roadmap pending
Resume file: .planning/REQUIREMENTS.md (then ROADMAP.md)
