# Roadmap: sube

## Milestones

- ✅ **v1.0 Package Workflow Hardening** - Phases 1-4 (shipped 2026-04-08). See [v1.0-ROADMAP.md](.planning/milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Replication, FIGARO & Convenience** - Phases 5-6 (shipped 2026-04-16). See [v1.1-ROADMAP.md](.planning/milestones/v1.1-ROADMAP.md)
- 🚧 **v1.2 FIGARO Validation, Convenience & Tech Debt** - Phases 7-10 (in progress)

## Phases

<details>
<summary>✅ v1.0 Package Workflow Hardening (Phases 1-4) - SHIPPED 2026-04-08</summary>

4 phases, 12 plans. Full record: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Replication, FIGARO & Convenience (Phases 5-6) - SHIPPED 2026-04-16</summary>

2 phases, 7 plans. Full record: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### 🚧 v1.2 FIGARO Validation, Convenience & Tech Debt (In Progress)

**Milestone Goal:** Prove the FIGARO pipeline works end-to-end on real data, deliver the long-promised one-call/batch convenience helpers, and clear the tech debt inherited from v1.1.

- [x] **Phase 7: FIGARO End-to-End Validation & Fallback Hardening** - Prove the FIGARO pipeline works on real data, on the synthetic fixture, and in docs — plus lock down the gated-env-var contract so local fallbacks never silently activate
- [x] **Phase 8: Convenience Helpers** - Deliver the long-deferred one-call pipeline, batch processor, and their diagnostic warnings layer
- [ ] **Phase 9: Test Infrastructure Tech Debt** - Fix the pre-existing `test-workflow.R:218` subprocess failure under `R CMD check --as-cran`
- [x] **Phase 10: Retroactive Nyquist Validation** - Back-fill Nyquist `*-VALIDATION.md` reports for phases 5 and 6 to close the v1.1 audit's `not_enforced` flag (completed 2026-04-17)

## Phase Details

### Phase 7: FIGARO End-to-End Validation & Fallback Hardening
**Goal**: Researchers can run the full FIGARO pipeline end-to-end on real data and on the shipped synthetic fixture, documented by a narrated vignette, with the gated-env-var contract hardened so no local fallback silently activates during development
**Depends on**: Phase 6 (v1.1 FIGARO ingestion + gated replication contract)
**Requirements**: FIG-E2E-01, FIG-E2E-02, FIG-E2E-03, INFRA-02
**Success Criteria** (what must be TRUE):
  1. User can set `SUBE_FIGARO_DIR` and run a gated test that drives a real FIGARO 2023 flatfile through `read_figaro → extract_domestic_block → build_matrices → compute_sube` (+ opt-in `estimate_elasticities` via `SUBE_FIGARO_INPUTS_DIR`) for DE/FR/IT/NL × 2023, with structural invariants (shapes, non-NULL core columns, sane elasticity signs) and a testthat golden snapshot on the deterministic projection of `compute_sube()` output both asserted
  2. On every CRAN/CI build, `tests/testthat/test-figaro-pipeline.R` pushes the extended synthetic `inst/extdata/figaro-sample/` fixture through `read_figaro → extract_domestic_block → build_matrices → compute_sube` with no external data and exits green
  3. A researcher reading `vignettes/figaro-workflow.Rmd` can trace the full journey from downloading a FIGARO flatfile to final elasticity output, including env-var gating and expected artifacts (vignette uses `eval = FALSE` and renders cleanly on pkgdown)
  4. When `SUBE_WIOD_DIR` is unset, `resolve_wiod_root()` returns `""` even when `inst/extdata/wiod/` exists on disk; parallel `resolve_figaro_root()` has the same env-var-only contract; a dedicated test file covers both resolvers across unset / fallback-present / valid-path / invalid-path branches
  5. Both gated tests (WIOD replication + FIGARO E2E) skip deterministically on CRAN/CI with the env vars unset, with skip messages simplified to `"SUBE_{WIOD,FIGARO}_DIR not set — ..."` (no fallback mention)
**Plans**: 5 plans
Plans:
- [x] 07-01-infra02-gated-data-contract-PLAN.md — Rename helper, remove WIOD fallback, add FIGARO resolver, ship INFRA-02 contract tests, update skip messages
- [x] 07-02-extend-synthetic-fixture-PLAN.md — Regenerate 8-CPA × 8-industry × 3-country synthetic fixture and update test-figaro.R value-baked assertions
- [x] 07-03-figaro-pipeline-synthetic-contract-PLAN.md — Add section-map + synthetic-pipeline helpers and FIG-E2E-02 contract test
- [x] 07-04-figaro-gated-e2e-snapshot-PLAN.md — Add real-data pipeline helper + snapshot projection + FIG-E2E-01 gated blocks (human-verify checkpoint for snapshot capture)
- [x] 07-05-figaro-vignette-docs-PLAN.md — Ship vignettes/figaro-workflow.Rmd, wire both it and paper-replication into _pkgdown.yml, add NEWS.md bullets

### Phase 8: Convenience Helpers
**Goal**: Researchers can run the full SUBE workflow through a single exported `run_sube_pipeline()` call or batch it across countries and years via `batch_sube()`, with visibility into silent data-quality issues through diagnostic warnings
**Depends on**: Phase 7
**Requirements**: CONV-01, CONV-02, CONV-03
**Success Criteria** (what must be TRUE):
  1. User can call a single exported `run_sube_pipeline()` function that chains import → matrix → compute with argument pass-through and returns one structured result object documenting the full pipeline output
  2. User can call an exported `batch_sube()` that loops `run_sube_pipeline()` over supplied country × year sets and returns collected results in a tidy structure suitable for downstream analysis
  3. When rows are dropped by coercion, matrices are skipped due to missing data, or singular branches are hit, `run_sube_pipeline()` and `batch_sube()` surface human-readable diagnostic warnings that pinpoint the country, year, and cause
  4. Both helpers are exported with roxygen docs, NAMESPACE entries, pkgdown group assignment, and testthat coverage exercising success paths, skip paths, and warning paths
**Plans**: 3 plans
Plans:
- [x] 08-01-pipeline-core-PLAN.md — Implement `run_sube_pipeline()` with `sube_pipeline_result` S3 class, unified 6-column `$diagnostics` schema, upfront `inputs` validation, all four CONV-03 detection helpers, and single-summary warning emission (CONV-01 + CONV-03 core)
- [x] 08-02-batch-sube-PLAN.md — Implement `batch_sube()` with `sube_batch_result` S3 class, copy-guarded maps/inputs, country × year splitter, per-group tryCatch resilience, and cross-group rbindlist merging with `group_key` (CONV-02 + CONV-03 batch scope)
- [x] 08-03-docs-vignette-PLAN.md — Regenerate man pages, update `_pkgdown.yml` (D-8.13 + D-8.14), add 3 NEWS.md bullets (D-8.15), ship `vignettes/pipeline-helpers.Rmd`, cross-link from `paper-replication.Rmd`/`figaro-workflow.Rmd`, run `R CMD check --no-manual --no-vignettes` clean

### Phase 9: Test Infrastructure Tech Debt
**Goal**: The pre-existing legacy-wrapper subprocess test in `tests/testthat/test-workflow.R:218` runs cleanly under `R CMD check --as-cran`, closing the last non-blocking tarball-check failure inherited from v1.1
**Depends on**: Phase 7 (shares the gated-test contract work)
**Requirements**: INFRA-01
**Success Criteria** (what must be TRUE):
  1. `R CMD check --as-cran` on the built tarball exits with zero test failures from `test-workflow.R:218` (either by threading `R_LIBS`/`.libPaths()` into the `Rscript` subprocess or by applying a principled check-time skip with documented rationale in the test file and NEWS entry)
  2. `devtools::test()` continues to run 102/102 green (no regressions in the non-subprocess path)
  3. The resolution strategy (fix vs. documented skip) is recorded in PROJECT.md Key Decisions and in an inline comment at the test site so future maintainers understand the trade-off
**Plans**: 1 plan
Plans:
- [x] 09-01-PLAN.md — Thread .libPaths() via R_LIBS into legacy-wrapper subprocess test and document resolution in PROJECT.md, NEWS.md, DESCRIPTION

### Phase 10: Retroactive Nyquist Validation
**Goal**: Phases 5 and 6 carry Nyquist-schema `*-VALIDATION.md` reports that retroactively close the v1.1 audit's `nyquist.overall: not_enforced` flag
**Depends on**: Nothing (pure retroactive documentation — can run in parallel with Phase 9)
**Requirements**: NYQ-01, NYQ-02
**Success Criteria** (what must be TRUE):
  1. A Nyquist-schema `*-VALIDATION.md` report exists in the phase 5 (figaro-sut-ingestion) planning directory, mapping shipped artifacts to the Nyquist validation schema
  2. A Nyquist-schema `*-VALIDATION.md` report exists in the phase 6 (paper-replication-verification) planning directory, mapping shipped artifacts to the Nyquist validation schema
  3. A follow-up audit against PROJECT.md / v1.1 closeout records no longer flags `nyquist.overall: not_enforced` for phases 5 or 6
**Plans**: 1 plan
Plans:
- [x] 10-01-PLAN.md — Create 10-VERIFICATION.md cross-referencing existing Nyquist artifacts, update REQUIREMENTS.md traceability for NYQ-01/NYQ-02

## Progress

**Execution Order:**
Phases execute in numeric order: 7 → 8 → 9 → 10 (Phase 10 may run in parallel with Phase 9 if capacity permits — no hard dependency between them).

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Core Workflow Contracts | v1.0 | 3/3 | Complete | 2026-04-08 |
| 2. Comparison Layer Stabilization | v1.0 | 3/3 | Complete | 2026-04-08 |
| 3. Documentation Alignment | v1.0 | 3/3 | Complete | 2026-04-08 |
| 4. Release, CI, and Migration Readiness | v1.0 | 3/3 | Complete | 2026-04-08 |
| 5. FIGARO SUT Ingestion | v1.1 | 4/4 | Complete | 2026-04-16 |
| 6. Paper Replication Verification | v1.1 | 3/3 | Complete | 2026-04-16 |
| 7. FIGARO End-to-End Validation & Fallback Hardening | v1.2 | 5/5 | Complete | 2026-04-17 |
| 8. Convenience Helpers | v1.2 | 3/3 | Complete | 2026-04-17 |
| 9. Test Infrastructure Tech Debt | v1.2 | 0/1 | Not started | - |
| 10. Retroactive Nyquist Validation | v1.2 | 1/1 | Complete    | 2026-04-17 |
