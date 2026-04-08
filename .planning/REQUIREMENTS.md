# Requirements: sube

**Defined:** 2026-04-08
**Core Value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## v1 Requirements

### Workflow hardening

- [ ] **WF-01**: User can run the documented end-to-end sample workflow from shipped example data without external downloads
- [ ] **WF-02**: User can move from imported SUT data to domestic matrices and computed SUBE outputs through stable exported functions
- [ ] **WF-03**: User can access diagnostics and failure states when matrix inversion or required inputs are invalid

### Leontief and comparison outputs

- [ ] **COMP-01**: User can extract computed Leontief matrices in list, long, or wide form from a `sube_results` object
- [ ] **COMP-02**: User can prepare a comparison table that aligns Leontief and SUBE model outputs for selected measures and variables
- [ ] **COMP-03**: User can generate paper-style comparison plots by country, product, regression fit, and interval range from package objects
- [ ] **COMP-04**: User can export comparison-ready or summary outputs to CSV, RDS, or DTA without custom post-processing scripts

### Documentation and release

- [ ] **DOC-01**: User can find a consistent package narrative across README, vignettes, pkgdown, and NEWS
- [ ] **DOC-02**: User can identify which functions cover data preparation, computation, modeling, and comparison workflows from published docs
- [ ] **DOC-03**: Maintainer can run package checks and tests from the repository using the documented release workflow

### Migration and compatibility

- [ ] **MIG-01**: User coming from the historical script workflow can run a legacy wrapper script against local input files
- [ ] **MIG-02**: User can rely on shipped example data to understand required input contracts before using external research datasets

## v2 Requirements

### Future expansion

- **UX-01**: User can use higher-level helper wrappers that compose the full workflow into a single convenience call
- **INT-01**: User can export richer publication artifacts such as styled tables or report-ready bundles directly from package objects
- **METH-01**: User can extend the package with additional model families beyond OLS, pooled, and between estimators

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rebuilding the old numbered-script repository structure | The package-first architecture is already the validated product direction |
| Shipping large real-world SUT datasets in the repo | Package examples should stay lightweight and CRAN-friendly |
| Supporting non-R execution environments as first-class targets | Current users and tooling are centered on R package workflows |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WF-01 | Phase 1 | Complete |
| WF-02 | Phase 1 | Complete |
| WF-03 | Phase 1 | Complete |
| COMP-01 | Phase 2 | Pending |
| COMP-02 | Phase 2 | Pending |
| COMP-03 | Phase 2 | Pending |
| COMP-04 | Phase 2 | Pending |
| DOC-01 | Phase 3 | Pending |
| DOC-02 | Phase 3 | Pending |
| DOC-03 | Phase 4 | Pending |
| MIG-01 | Phase 4 | Pending |
| MIG-02 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after Phase 1 completion*
