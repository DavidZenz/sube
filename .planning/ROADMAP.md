# Roadmap: sube

## Overview

This roadmap assumes the core SUBE package workflow already exists and has basic validation through tests, docs, and release metadata. The next milestone is about turning that existing surface into a tighter brownfield package story: harden the core contracts, stabilize the Leontief comparison layer, align the documentation surfaces, and preserve a clear migration path plus release checks.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Core Workflow Contracts** - Confirm and harden the import-to-compute package contracts around shipped examples and diagnostics
- [ ] **Phase 2: Comparison Layer Stabilization** - Stabilize Leontief extraction, comparison shaping, and export/plot outputs as a coherent public workflow
- [ ] **Phase 3: Documentation Alignment** - Make README, vignettes, and pkgdown tell the same package-first story and input contract
- [ ] **Phase 4: Release and Migration Readiness** - Preserve legacy entry points and verify the package passes documented release checks

## Phase Details

### Phase 1: Core Workflow Contracts
**Goal**: Ensure the package's sample-data-driven import, matrix, compute, and diagnostics flow is explicit, tested, and ready for downstream comparison tooling.
**Depends on**: Nothing (first phase)
**Requirements**: [WF-01, WF-02, WF-03]
**Success Criteria** (what must be TRUE):
  1. Users can run the sample workflow from shipped example data using exported functions only.
  2. Invalid or incomplete inputs surface clear diagnostics instead of opaque failures.
  3. The package contract from `import_suts()` through `compute_sube()` is documented and covered by verification.
**Plans**: 3 plans

Plans:
- [x] 01-01: Audit the current import, matrix, and compute contracts against tests and examples
- [x] 01-02: Fill validation or diagnostics gaps in the core workflow
- [x] 01-03: Refresh examples/tests so the core workflow is reproducible from a clean checkout

### Phase 2: Comparison Layer Stabilization
**Goal**: Make the Leontief extraction and paper-style comparison surface reliable, documented, and export-friendly for research use.
**Depends on**: Phase 1
**Requirements**: [COMP-01, COMP-02, COMP-03, COMP-04]
**Success Criteria** (what must be TRUE):
  1. Users can extract Leontief matrices from `sube_results` in the advertised formats.
  2. Users can prepare comparison tables and generate paper-style plots without custom glue code.
  3. Comparison outputs can be exported in supported formats with predictable file structure.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Verify and normalize comparison data structures and extraction helpers
- [ ] 02-02: Harden plotting and export workflows for paper-style outputs
- [ ] 02-03: Add or refine tests and examples around the comparison layer

### Phase 3: Documentation Alignment
**Goal**: Align README, vignettes, pkgdown navigation, and input guidance with the real package workflow and comparison story.
**Depends on**: Phase 2
**Requirements**: [DOC-01, DOC-02, MIG-02]
**Success Criteria** (what must be TRUE):
  1. The public docs describe the same workflow stages and function groupings.
  2. Users can discover required inputs and example data paths from the documentation alone.
  3. The package website clearly distinguishes core workflow steps from paper-context references.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Reconcile README and vignette framing with the brownfield package architecture
- [ ] 03-02: Align pkgdown navigation and reference groups with the documented workflow
- [ ] 03-03: Tighten example-data and input-contract guidance for new users

### Phase 4: Release and Migration Readiness
**Goal**: Keep the package releasable while preserving a minimal migration path from the historical script workflow.
**Depends on**: Phase 3
**Requirements**: [DOC-03, MIG-01]
**Success Criteria** (what must be TRUE):
  1. Maintainers can run the documented build, check, and test flow successfully.
  2. Legacy users still have a working wrapper path into the package workflow with documented inputs.
  3. Release notes and project instructions reflect the current package structure rather than stale script-first assumptions.
**Plans**: 3 plans

Plans:
- [ ] 04-01: Verify release commands, CI assumptions, and local check instructions
- [ ] 04-02: Audit and document the legacy wrapper script and migration path
- [ ] 04-03: Update stale project guidance and release notes where they contradict the package-first repo

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Workflow Contracts | 3/3 | Complete | 2026-04-08 |
| 2. Comparison Layer Stabilization | 0/3 | Not started | - |
| 3. Documentation Alignment | 0/3 | Not started | - |
| 4. Release and Migration Readiness | 0/3 | Not started | - |
