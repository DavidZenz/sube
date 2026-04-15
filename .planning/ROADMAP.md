# Roadmap: sube

## Milestones

- ✅ **v1.0 Package Workflow Hardening** - Phases 1-4 (shipped 2026-04-08). See [v1.0-ROADMAP.md](.planning/milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Replication, FIGARO & Convenience** - Phases 5-6 (in progress)

## Phases

<details>
<summary>✅ v1.0 Package Workflow Hardening (Phases 1-4) - SHIPPED 2026-04-08</summary>

4 phases, 12 plans. Full record: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### 🚧 v1.1 Replication, FIGARO & Convenience (In Progress)

**Milestone Goal:** Prove the package reproduces the published paper exactly and add FIGARO SUT ingestion as a validated second data source.

- [ ] **Phase 5: FIGARO SUT Ingestion** - Import FIGARO industry-by-industry CSVs into the canonical sube_suts long table with tests
- [ ] **Phase 6: Paper Replication Verification** - Gated numerical reproduction of paper results with a step-by-step replication vignette

## Phase Details

### Phase 5: FIGARO SUT Ingestion
**Goal**: Researchers can import FIGARO industry-by-industry SUT CSV files into the same canonical long-format table produced by the WIOD importer
**Depends on**: Phase 4 (v1.0 package foundation)
**Requirements**: FIG-01, FIG-02, FIG-03, FIG-04
**Success Criteria** (what must be TRUE):
  1. User can call `read_figaro()` on a FIGARO SUT CSV file and receive a `sube_suts` long table with REP, PAR, CPA, VAR, VALUE, YEAR, TYPE columns
  2. Composite country-industry column labels are correctly split into separate REP, PAR, CPA, VAR fields with no silent corruption
  3. `.coerce_map()` accepts NACE and NACE_R2 column names without falling through to positional matching
  4. `R CMD check` passes with a `testthat` test suite that validates FIGARO import against a synthetic CSV fixture
**Plans**: TBD
**UI hint**: no

### Phase 6: Paper Replication Verification
**Goal**: Researchers can confirm that running the package end-to-end on the original WIOD data reproduces the published paper's numerical results
**Depends on**: Phase 5
**Requirements**: REP-01, REP-02
**Success Criteria** (what must be TRUE):
  1. Running the replication test with `SUBE_WIOD_DIR` set produces a pass, confirming numerical match within defined tolerance
  2. The replication test is automatically skipped in CI and on CRAN when `SUBE_WIOD_DIR` is absent
  3. A vignette documents the full reproduction workflow step-by-step and builds cleanly with `eval=FALSE`
**Plans**: 3 plans
  - [x] 06-01-replication-test-PLAN.md — Gated testthat suite (helper + 3 test_that blocks for W/SUP/USE matrices, AUS/DEU/USA/JPN × 2005)
  - [x] 06-02-filter-paper-outliers-export-PLAN.md — Export filter_paper_outliers() with variables/apply_bounds args, roxygen block, NAMESPACE + .Rd
  - [x] 06-03-replication-vignette-PLAN.md — 9-section paper-replication.Rmd, pkgdown group split, NEWS.md bullets, R CMD check --as-cran

## Progress

**Execution Order:**
Phases execute in numeric order: 5 → 6

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. FIGARO SUT Ingestion | v1.1 | 0/? | Not started | - |
| 6. Paper Replication Verification | v1.1 | 0/3 | Not started | - |
