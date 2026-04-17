# Requirements: sube — v1.2

**Defined:** 2026-04-16
**Milestone:** v1.2 FIGARO Validation, Convenience & Tech Debt
**Core Value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

**Milestone Goal:** Prove the FIGARO pipeline works end-to-end on real data, deliver the long-promised one-call/batch convenience helpers, and clear the tech debt inherited from v1.1.

## v1.2 Requirements

Requirements for milestone v1.2. Each maps to roadmap phases.

### FIGARO End-to-End Validation

- [x] **FIG-E2E-01**: User can run a gated test (`SUBE_FIGARO_DIR`) that drives the real FIGARO 2023 flatfile through the full pipeline (`read_figaro → extract_domestic_block → build_matrices → compute_sube → estimate_elasticities`) for ~4 representative countries × 1 reference year, asserting (a) pipeline completes without error, (b) structural invariants hold (shapes, non-NULL core columns, elasticity signs sane), (c) digest of `model_data` matches a stored golden value (auto-captured on first green run). Skipped cleanly on CRAN/CI when the env var is unset.
- [x] **FIG-E2E-02**: Contract tests push the synthetic `inst/extdata/figaro-sample/` fixture through the downstream pipeline (`build_matrices → compute_sube → estimate_elasticities`) in a new `tests/testthat/test-figaro-pipeline.R`, runnable on every CRAN/CI build with no external data.
- [x] **FIG-E2E-03**: Standalone `vignettes/figaro-workflow.Rmd` (companion to `paper-replication.Rmd`, `eval = FALSE`) narrates the full researcher journey from downloading a FIGARO flatfile to final elasticity output.

### Convenience Helpers

- [x] **CONV-01**: User can call a single exported `run_sube_pipeline()` function that chains import → matrix → compute with arg pass-through and returns a single structured result object.
- [x] **CONV-02**: User can call an exported `batch_sube()` that loops `run_sube_pipeline()` over supplied country × year sets and returns collected results in a tidy structure.
- [x] **CONV-03**: `run_sube_pipeline()` and `batch_sube()` surface human-readable diagnostic warnings when rows are dropped by coercion, matrices are skipped due to missing data, or singular branches are hit — giving visibility into silent data-quality issues.

### Test Infrastructure

- [ ] **INFRA-01**: `tests/testthat/test-workflow.R:218` (legacy-wrapper subprocess test) passes cleanly under `R CMD check --as-cran`, either by threading `R_LIBS`/`.libPaths()` into the `Rscript` subprocess or by applying a principled check-time skip with documented rationale.
- [x] **INFRA-02**: `resolve_wiod_root()` is env-var-only: the `inst/extdata/wiod/` local fallback is removed entirely, and a parallel `resolve_figaro_root()` reads only `SUBE_FIGARO_DIR`. Unset env var → clean skip regardless of local dir presence. Ships with contract tests asserting guarded-skip and opt-in paths for both resolvers. (Revised during Phase 7 discuss from earlier `SUBE_WIOD_FALLBACK` opt-in wording — locked by CONTEXT.md D-7.7.)

### Validation Coverage

- [x] **NYQ-01**: A Nyquist-schema `*-VALIDATION.md` report exists for phase 5 (figaro-sut-ingestion), retroactively closing the v1.1 audit's `nyquist.overall: not_enforced` flag.
- [x] **NYQ-02**: A Nyquist-schema `*-VALIDATION.md` report exists for phase 6 (paper-replication-verification), retroactively closing the same audit flag.

## Future Requirements

Deferred to a later milestone. Tracked but not in current roadmap.

- **FIGARO SIOT support**: FIGARO product-by-product SIOT tables (only industry-by-industry SUTs scoped currently)
- **Auto-download helpers**: wrappers that fetch FIGARO/WIOD flatfiles on demand (currently excluded due to network/version constraints)
- **pkgdown search / site deployment polish**: pkgdown groups are wired; public site hosting and search tuning are not yet formalized

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Auto-downloading FIGARO/WIOD data | Network dependency, version drift, breaks R CMD check |
| Bundling real WIOD/FIGARO datasets | CRAN size limits, license restrictions |
| Zero-config pipeline hiding mapping tables | Mapping is a research decision, not a default |
| FIGARO SIOT (product-by-product) tables | Only industry-by-industry SUTs scoped |
| GUI/web/service wrapper around SUBE | Product is an R package for research workflows |
| Breaking changes to public `import_suts` / `build_matrices` / `compute_sube` APIs | CONV-* helpers layer on top; core surface stays backwards-compatible |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FIG-E2E-01 | Phase 7 | Satisfied |
| FIG-E2E-02 | Phase 7 | Satisfied |
| FIG-E2E-03 | Phase 7 | Satisfied |
| INFRA-02 | Phase 7 | Satisfied |
| CONV-01 | Phase 8 | Satisfied |
| CONV-02 | Phase 8 | Satisfied |
| CONV-03 | Phase 8 | Satisfied |
| INFRA-01 | Phase 9 | Pending |
| NYQ-01 | Phase 10 | Satisfied |
| NYQ-02 | Phase 10 | Satisfied |

**Coverage:**
- v1.2 requirements: 10 total
- Satisfied: 9 (FIG-E2E-01/02/03, INFRA-02, CONV-01/02/03, NYQ-01, NYQ-02)
- Pending: 1 (INFRA-01)
- Mapped to phases: 10 (100%)
- Unmapped: 0

**Phase rollup:**
- Phase 7 (FIGARO End-to-End Validation & Fallback Hardening): FIG-E2E-01, FIG-E2E-02, FIG-E2E-03, INFRA-02
- Phase 8 (Convenience Helpers): CONV-01, CONV-02, CONV-03
- Phase 9 (Test Infrastructure Tech Debt): INFRA-01
- Phase 10 (Retroactive Nyquist Validation): NYQ-01, NYQ-02

---
*Requirements defined: 2026-04-16; traceability filled by roadmapper 2026-04-16*
