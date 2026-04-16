# Requirements: sube — v1.2

**Defined:** 2026-04-16
**Milestone:** v1.2 FIGARO Validation, Convenience & Tech Debt
**Core Value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

**Milestone Goal:** Prove the FIGARO pipeline works end-to-end on real data, deliver the long-promised one-call/batch convenience helpers, and clear the tech debt inherited from v1.1.

## v1.2 Requirements

Requirements for milestone v1.2. Each maps to roadmap phases.

### FIGARO End-to-End Validation

- [ ] **FIG-E2E-01**: User can run a gated test (`SUBE_FIGARO_DIR`) that drives the real FIGARO 2023 flatfile through the full pipeline (`read_figaro → extract_domestic_block → build_matrices → compute_sube → estimate_elasticities`) for ~4 representative countries × 1 reference year, asserting (a) pipeline completes without error, (b) structural invariants hold (shapes, non-NULL core columns, elasticity signs sane), (c) digest of `model_data` matches a stored golden value (auto-captured on first green run). Skipped cleanly on CRAN/CI when the env var is unset.
- [ ] **FIG-E2E-02**: Contract tests push the synthetic `inst/extdata/figaro-sample/` fixture through the downstream pipeline (`build_matrices → compute_sube → estimate_elasticities`) in a new `tests/testthat/test-figaro-pipeline.R`, runnable on every CRAN/CI build with no external data.
- [ ] **FIG-E2E-03**: Standalone `vignettes/figaro-workflow.Rmd` (companion to `paper-replication.Rmd`, `eval = FALSE`) narrates the full researcher journey from downloading a FIGARO flatfile to final elasticity output.

### Convenience Helpers

- [ ] **CONV-01**: User can call a single exported `run_sube_pipeline()` function that chains import → matrix → compute with arg pass-through and returns a single structured result object.
- [ ] **CONV-02**: User can call an exported `batch_sube()` that loops `run_sube_pipeline()` over supplied country × year sets and returns collected results in a tidy structure.
- [ ] **CONV-03**: `run_sube_pipeline()` and `batch_sube()` surface human-readable diagnostic warnings when rows are dropped by coercion, matrices are skipped due to missing data, or singular branches are hit — giving visibility into silent data-quality issues.

### Test Infrastructure

- [ ] **INFRA-01**: `tests/testthat/test-workflow.R:218` (legacy-wrapper subprocess test) passes cleanly under `R CMD check --as-cran`, either by threading `R_LIBS`/`.libPaths()` into the `Rscript` subprocess or by applying a principled check-time skip with documented rationale.
- [ ] **INFRA-02**: `resolve_wiod_root()` requires an explicit `SUBE_WIOD_FALLBACK` opt-in env var before picking up `inst/extdata/wiod/` under `devtools::load_all`; by default, unset `SUBE_WIOD_DIR` → clean skip even when the local fallback directory exists. Ships with a test asserting both the guarded skip and the opt-in path.

### Validation Coverage

- [ ] **NYQ-01**: A Nyquist-schema `*-VALIDATION.md` report exists for phase 5 (figaro-sut-ingestion), retroactively closing the v1.1 audit's `nyquist.overall: not_enforced` flag.
- [ ] **NYQ-02**: A Nyquist-schema `*-VALIDATION.md` report exists for phase 6 (paper-replication-verification), retroactively closing the same audit flag.

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

Which phases cover which requirements. Filled by roadmapper.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FIG-E2E-01 | TBD | Pending |
| FIG-E2E-02 | TBD | Pending |
| FIG-E2E-03 | TBD | Pending |
| CONV-01 | TBD | Pending |
| CONV-02 | TBD | Pending |
| CONV-03 | TBD | Pending |
| INFRA-01 | TBD | Pending |
| INFRA-02 | TBD | Pending |
| NYQ-01 | TBD | Pending |
| NYQ-02 | TBD | Pending |

**Coverage:**
- v1.2 requirements: 10 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 10

---
*Requirements defined: 2026-04-16*
