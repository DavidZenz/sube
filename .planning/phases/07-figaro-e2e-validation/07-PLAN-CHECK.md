---
phase: 07-figaro-e2e-validation
checker: gsd-plan-checker
checked: 2026-04-15
verdict: PASS (with non-blocking findings)
plans_checked: 5
blockers: 0
warnings: 3
info: 4
---

# Phase 7 — Plan Check Verdict

## PLAN CHECK: PASS

Plans 07-01 through 07-05 collectively deliver FIG-E2E-01, FIG-E2E-02, FIG-E2E-03, and INFRA-02 per the phase goal. All 7 locked decisions (D-7.1..D-7.7) are honored. Wave structure is correct, file sets are disjoint within each wave, dependency graph is acyclic. All 18 tasks have automated verify commands. No scope creep.

Three non-blocking warnings and four informational notes are captured below for executor awareness. None require plan revision.

---

## Coverage Summary — Requirements to Plans

| Requirement | Covering Plan(s) | Task(s) | Verification |
|-------------|------------------|---------|--------------|
| FIG-E2E-01 | 07-04 | 1, 2, 3 (human-verify), 4 | Real-data gated test + snapshot + structural invariants + opt-in elasticity; env-unset skip ≥ 2 asserted |
| FIG-E2E-02 | 07-02 + 07-03 | 07-02/{1,2,3}; 07-03/{1,2,3} | Extended fixture regenerated; contract test green every build; 46 existing tests preserved |
| FIG-E2E-03 | 07-05 | 1, 2, 4 | Vignette with 9 sections + eval=FALSE + no Eurostat link; pkgdown builds |
| INFRA-02 | 07-01 + 07-05 task 3 | 07-01/{1,2,3,4}; 07-05/3 | Helper rename + env-var-only resolvers + contract test + NEWS.md BREAKING entry |

All 4 requirements covered. ✅

---

## D-7.1..D-7.7 Compliance (Context Compliance)

| Decision | Honored? | Where | Evidence |
|----------|----------|-------|----------|
| D-7.1 (NACE equivalence, one shared map) | ✅ | 07-03 Task 1 | `build_nace_section_map()` derives both `cpa_map` and `ind_map` via `substr(code, 1, 1)` |
| D-7.2 (compute_sube default, elasticity opt-in) | ✅ | 07-04 Task 1, 2 | Default `metrics = "GO"`; opt-in via `SUBE_FIGARO_INPUTS_DIR` with no snapshot on opt-in branch |
| D-7.3 (testthat snapshot) | ✅ | 07-04 Task 2 | `expect_snapshot_value(style = "serialize")` with projected fields (excludes `$matrices`) |
| D-7.4 (DE/FR/IT/NL × 2023) | ✅ | 07-04 Task 1 | Hardcoded `countries = c("DE","FR","IT","NL"), year = 2023L`; no env-var override |
| D-7.5 (8 CPAs × 3 countries fixture, ≤50 KB) | ✅ | 07-02 Task 1 | 8 real A*64 codes × 3 ISO-2 countries; verify enforces ≤50 KB |
| D-7.6 (standalone vignette, 9 sections, no Eurostat link) | ✅ | 07-05 Task 1 | verify command explicitly asserts `!any(grepl("ec.europa.eu\|eurostat", ...))` |
| D-7.7 (env-var-only, no fallback, NO opt-in flag) | ✅ | 07-01 Task 1, 3 | One-liner resolver matches D-7.7 code block exactly; no `SUBE_*_FALLBACK` flag introduced |

No decision contradicted. No deferred idea implemented (SIOT, auto-download, Eurostat citation, config-driven country/year are absent from all plans).

---

## Findings

### Warnings (non-blocking; fix if executor time permits)

**W1. RESEARCH.md `## Open Questions` section lacks `(RESOLVED)` suffix (Dimension 11)**
- File: `.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md:738`
- Impact: Documentation annotation. All three questions *are* substantively resolved by the plans:
  - Q1 (year 2023 vs 2019) → Resolved: CONTEXT.md D-7.4 updated to 2023; plans hardcode `year = 2023L`.
  - Q2 (real vs abstract fixture codes) → Resolved: plan 07-02 uses `DE/FR/IT`.
  - Q3 (snapshot on synthetic path) → Resolved as "No" (researcher recommended Yes; plans follow D-7.3's "snapshot on gated only"). Defensible.
- Fix (optional): rename section heading to `## Open Questions (RESOLVED)` and add inline `RESOLVED: ...` markers to each question before executor pickup. Not a blocker because all questions have concrete resolutions visible in CONTEXT.md + plan tasks.

**W2. REQUIREMENTS.md INFRA-02 wording disagrees with locked D-7.7**
- File: `.planning/REQUIREMENTS.md:28`
- REQUIREMENTS.md text: "`resolve_wiod_root()` requires an explicit `SUBE_WIOD_FALLBACK` opt-in env var before picking up `inst/extdata/wiod/` …"
- D-7.7 (locked): **no fallback at all**, not even via an opt-in env var. The REQUIREMENTS.md wording is stale (predates the /gsd-discuss-phase 7 discussion that refined INFRA-02).
- Plans correctly follow D-7.7, not the stale REQUIREMENTS.md text. ROADMAP.md success criterion #4 + #5 also match D-7.7 (no fallback mention).
- Fix (optional, post-execution): update REQUIREMENTS.md line 28 to match D-7.7 when this phase ships. A roadmapper responsibility, not a planner/executor one.

**W3. Plan 07-02 task 1 uses a hardcoded expected FU_bas total (`nrow=24L, sum=480`) that is derivable only from the generator's value scheme**
- File: `07-02-extend-synthetic-fixture-PLAN.md:308-309, 373-377`
- Math verified correct: 3 countries × 8 CPAs × (2+3+4+5+6) FD values = 24 FU_bas rows × 20 = 480.
- Risk: if executor tweaks FD values to stay under the 50 KB budget, test-figaro.R line 119 assertion (`sum = 480`) becomes wrong. Planner flagged this in the plan prose but did not make the value dependency explicit to the executor.
- Fix (optional): executor should re-derive `sum(fu_rows$VALUE)` from the actual generated fixture before hardcoding into test, not blindly use 480.

### Informational Notes

**I1. Wave structure differs slightly from user's additional-context stated plan**
- User's prompt said "Wave 1: 07-01, 07-02, 07-05 (parallel)". Actual frontmatter: **Wave 1: 07-01, 07-02** and **Wave 2: 07-03, 07-05**.
- 07-05 declares `depends_on: ["07-01", "07-02"]`. These are soft dependencies (vignette copy-paste example in section 3 references the extended synthetic fixture from 07-02; NEWS.md INFRA-02 bullet in 07-05 task 3 references the helper rename from 07-01). The dependencies are valid for correctness and don't parallelize.
- The orchestrator should understand that 07-03 and 07-05 run in parallel inside Wave 2.

**I2. 07-04 checkpoint task 3 is blocking and requires local SUBE_FIGARO_DIR**
- Correctly declared `autonomous: false` and `type: checkpoint:human-verify gate="blocking"`.
- Executor will halt at this task; researcher captures the initial snapshot on local 873 MB flatfile, commits `tests/testthat/_snaps/figaro-pipeline/`, replies `approved` to resume.
- No fix needed — this is the correct pattern for data-gated snapshot capture.

**I3. 07-01 helper rename (`git mv helper-replication.R helper-gated-data.R`) + `test-replication.R` skip-message edit land in the same plan**
- Task 1 does the `git mv`. Task 2 edits the 3 occurrences of the skip-message in `test-replication.R`. Both tasks in plan 07-01. Testthat auto-discovers `helper-*.R` so the rename is runtime-transparent. ✅
- User flagged this dependency; it is correctly handled.

**I4. `build_figaro_pipeline_fixture_from_synthetic()` (plan 07-03) and `build_figaro_pipeline_fixture_from_real()` (plan 07-04) both call `build_nace_section_map()` (also plan 07-03)**
- 07-04's `depends_on: ["07-01", "07-02", "07-03"]` correctly reflects this. Without 07-03 the rename in 07-01 is insufficient for 07-04's helper to source correctly. ✅

---

## Dimension Summary (per gsd-plan-checker methodology)

| Dimension | Status | Notes |
|-----------|--------|-------|
| 1. Requirement Coverage | PASS | All 4 requirements (FIG-E2E-01..03, INFRA-02) mapped to tasks |
| 2. Task Completeness | PASS | 18/18 tasks have files + action + verify + done (checkpoint task 07-04/3 has proper checkpoint shape) |
| 3. Dependency Correctness | PASS | Acyclic DAG: 07-01,07-02 (W1) → 07-03,07-05 (W2) → 07-04 (W3) |
| 4. Key Links Planned | PASS | All must_haves.key_links wiring (helper → resolver, test → helper, vignette → fixture, pkgdown → vignette) covered by explicit task actions |
| 5. Scope Sanity | PASS | Plans sized 3-4 tasks each; 07-04 is 4 tasks (one is human-verify, not code); files per plan 3-5; well within budget |
| 6. Verification Derivation | PASS | must_haves.truths are user-observable (e.g. "researcher can run gated test", "synthetic fixture pipeline completes"); no implementation-only truths |
| 7. Context Compliance | PASS | D-7.1..D-7.7 all honored; no deferred-idea leakage |
| 7b. Scope Reduction Detection | PASS | No "v1 / future enhancement / static for now / hardcoded placeholder" language found. D-7.2's opt-in elasticity branch is *real opt-in* (plan 07-04 fully implements it), not a stub. |
| 8. Nyquist Compliance | PASS | VALIDATION.md present with 18 per-task rows; all tasks have `<automated>` commands; sampling continuity OK (no 3 consecutive non-verified tasks); Wave 0 artifacts all referenced; no watch-mode flags; feedback latency ~20-60s; `nyquist_compliant: true` set |
| 9. Cross-Plan Data Contracts | PASS | `helper-gated-data.R` is append-only across 07-01 (creates), 07-03 (appends), 07-04 (appends); `test-figaro-pipeline.R` append-only across 07-03 (creates) and 07-04 (appends). No conflicting transforms. |
| 10. CLAUDE.md Compliance | SKIPPED | No `./CLAUDE.md` in repo root |
| 11. Research Resolution | WARNING | `## Open Questions` section exists without `(RESOLVED)` suffix; all 3 questions substantively resolved but not annotated (see W1) |

---

## Final Verdict

**PLAN CHECK: PASS**

All five plans collectively deliver the phase goal. Waves are safe to parallelize. Dependencies are correct. No scope creep. No locked-decision contradictions. No deferred-idea leakage. All 18 tasks have automated verification. Execute with confidence.

Three warnings (W1 doc annotation, W2 upstream REQUIREMENTS.md staleness, W3 hardcoded FD total) are advisory — they don't block execution but the executor should be aware of W3 during 07-02 task 2.

**Recommended next step:** `/gsd-execute-phase 7` (or invoke the orchestrator against this verdict to start Wave 1 execution of 07-01 + 07-02 in parallel).
