# Roadmap: sube

## Milestones

- ✅ **v1.0 Package Workflow Hardening** - Phases 1-4 (shipped 2026-04-08). See [v1.0-ROADMAP.md](.planning/milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Replication, FIGARO & Convenience** - Phases 5-6 (shipped 2026-04-16). See [v1.1-ROADMAP.md](.planning/milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 FIGARO Validation, Convenience & Tech Debt** - Phases 7-10 (shipped 2026-04-17). See [v1.2-ROADMAP.md](.planning/milestones/v1.2-ROADMAP.md)
- 🚧 **v1.3 Documentation & pkgdown** - Phases 11-13 (in progress)

## Phases

<details>
<summary>✅ v1.0 Package Workflow Hardening (Phases 1-4) - SHIPPED 2026-04-08</summary>

4 phases, 12 plans. Full record: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Replication, FIGARO & Convenience (Phases 5-6) - SHIPPED 2026-04-16</summary>

2 phases, 7 plans. Full record: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 FIGARO Validation, Convenience & Tech Debt (Phases 7-10) - SHIPPED 2026-04-17</summary>

4 phases, 10 plans. Full record: `.planning/milestones/v1.2-ROADMAP.md`

</details>

### 🚧 v1.3 Documentation & pkgdown (In Progress)

**Milestone Goal:** Thorough, source-agnostic documentation with a live pkgdown site on GitHub Pages.

- [ ] **Phase 11: Data Format Specification** - Define canonical SUT column semantics, satellite vector contract, synonym flexibility, and BYOD guide
- [ ] **Phase 12: Vignette & README Refresh** - Apply source-agnostic framing throughout all vignettes, expand data-prep vignette, improve narrative flow, refresh README
- [ ] **Phase 13: pkgdown Deployment** - Deploy pkgdown site to GitHub Pages via GitHub Actions and align site structure with documentation narrative

## Phase Details

### Phase 11: Data Format Specification
**Goal**: Researchers can find authoritative documentation of the canonical long-format SUT contract — column semantics, satellite vector inputs, synonym flexibility, and a path for non-WIOD/FIGARO data
**Depends on**: Phase 10 (v1.2 complete)
**Requirements**: FMT-01, FMT-02, FMT-03, FMT-04
**Success Criteria** (what must be TRUE):
  1. User can read a definition of each canonical SUT column (REP, PAR, CPA, VAR, VALUE, YEAR, TYPE) with semantics and at least one concrete example per column
  2. User can find documentation of the satellite vector inputs (GO, VA, EMP, CO2) explaining what each is, where it comes from, and that it is researcher-supplied
  3. User can follow a step-by-step "bring your own data" guide to reshape arbitrary supply-use data into the canonical long format
  4. User can discover that column names are flexible (INDUSTRY, NACE, NACE_R2 all accepted) from a documented synonym table
**Plans:** 1 plan
Plans:
- [ ] 11-01-PLAN.md — Write canonical format spec, satellite vector contract, synonym table, and BYOD guide into data-preparation.Rmd

### Phase 12: Vignette & README Refresh
**Goal**: All vignettes and the README frame WIOD and FIGARO as two example data sources among many, the data-prep vignette is the authoritative format reference, and the narrative reads coherently from start to finish
**Depends on**: Phase 11
**Requirements**: VIG-01, VIG-02, VIG-03, DOC-01
**Success Criteria** (what must be TRUE):
  1. User reading any vignette sees WIOD and FIGARO described as example importers, not as "the" data source — no vignette assumes only WIOD or FIGARO data exists
  2. User reading the data-preparation vignette finds the canonical format specification (column definitions, satellite vector contract, worked reshape examples) from Phase 11 integrated into its narrative
  3. User reading the vignettes in sequence finds a coherent flow: data preparation → pipeline workflow → paper replication → FIGARO workflow → helpers
  4. User reading the README finds a source-agnostic description of what the package does and an explicit statement that any SUT data in the canonical format is supported
**Plans**: TBD
**UI hint**: yes

### Phase 13: pkgdown Deployment
**Goal**: A live pkgdown site is deployed to GitHub Pages on every push to master, with article grouping and navigation aligned to the documentation narrative
**Depends on**: Phase 12
**Requirements**: PKG-01, PKG-02
**Success Criteria** (what must be TRUE):
  1. Pushing to master triggers a GitHub Actions workflow that builds and deploys the pkgdown site to GitHub Pages without manual steps
  2. User visiting the pkgdown site finds articles grouped and ordered to reflect the documentation narrative established in Phase 12
  3. User visiting the pkgdown site finds reference sections and navbar consistent with current package exports and vignette titles
**Plans**: TBD

## Progress

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
| 9. Test Infrastructure Tech Debt | v1.2 | 1/1 | Complete | 2026-04-17 |
| 10. Retroactive Nyquist Validation | v1.2 | 1/1 | Complete | 2026-04-17 |
| 11. Data Format Specification | v1.3 | 0/1 | Planning | - |
| 12. Vignette & README Refresh | v1.3 | 0/? | Not started | - |
| 13. pkgdown Deployment | v1.3 | 0/? | Not started | - |
