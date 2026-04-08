# Requirements: sube

**Defined:** 2026-04-08
**Core Value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## v1.1 Requirements

Requirements for milestone v1.1. Each maps to roadmap phases.

### FIGARO Ingestion

- [ ] **FIG-01**: User can import FIGARO industry-by-industry SUT CSV files into a canonical `sube_suts` long table
- [ ] **FIG-02**: FIGARO importer correctly splits composite country-industry labels into REP, PAR, CPA, VAR fields
- [ ] **FIG-03**: `.coerce_map()` recognizes NACE and NACE_R2 column names for industry mapping
- [ ] **FIG-04**: Automated tests validate FIGARO import against a synthetic FIGARO-format CSV fixture

### Paper Replication

- [ ] **REP-01**: User can run a gated test that numerically reproduces paper results from WIOD data (skipped without `SUBE_WIOD_DIR`)
- [ ] **REP-02**: Replication vignette documents the full reproduction workflow step-by-step (eval=FALSE for CRAN/CI)

## Future Requirements

Deferred to a later milestone. Tracked but not in current roadmap.

### Convenience Helpers

- **CONV-01**: One-call pipeline function (`run_sube_pipeline()`) chaining import through compute
- **CONV-02**: Batch country/year processor (`batch_sube()`) with collected results
- **CONV-03**: Pipeline diagnostic warnings surfacing dropped rows and skipped matrices

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Auto-downloading FIGARO/WIOD data | Network dependency, version drift, breaks R CMD check |
| Bundling real WIOD/FIGARO datasets | CRAN size limits, license restrictions |
| Zero-config pipeline hiding mapping tables | Mapping is a research decision, not a default |
| FIGARO SIOT (product-by-product) tables | Only industry-by-industry SUTs scoped for v1.1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FIG-01 | Phase 5 | Pending |
| FIG-02 | Phase 5 | Pending |
| FIG-03 | Phase 5 | Pending |
| FIG-04 | Phase 5 | Pending |
| REP-01 | Phase 6 | Pending |
| REP-02 | Phase 6 | Pending |

**Coverage:**
- v1.1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after roadmap creation (all requirements mapped)*
