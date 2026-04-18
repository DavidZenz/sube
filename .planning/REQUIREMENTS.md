# Requirements: sube

**Defined:** 2026-04-17
**Core Value:** Researchers can run a reproducible end-to-end SUBE workflow in R without falling back to one-off scripts or undocumented paper code.

## v1.3 Requirements

Requirements for Documentation & pkgdown milestone. Each maps to roadmap phases.

### Data Format Specification

- [ ] **FMT-01**: User can find a clear definition of each canonical SUT column (REP, PAR, CPA, VAR, VALUE, YEAR, TYPE) with semantics and examples
- [ ] **FMT-02**: User can find documentation of the satellite vector input contract (GO, VA, EMP, CO2) — what they are, where they come from, that they are researcher-supplied
- [ ] **FMT-03**: User can follow a "bring your own data" guide to reshape non-WIOD/FIGARO supply-use data into the canonical long format
- [ ] **FMT-04**: User can discover that column names are flexible (e.g. INDUSTRY/NACE/NACE_R2 all accepted) with documented synonyms

### Vignette Improvements

- [x] **VIG-01**: All vignettes frame WIOD and FIGARO as example data sources, not as "the" data source — source-agnostic language throughout
- [x] **VIG-02**: Data-preparation vignette expanded with canonical format specification, column definitions, and worked examples
- [x] **VIG-03**: Narrative flow across all vignettes reviewed and improved for coherent reading order

### README

- [x] **DOC-01**: README refreshed with source-agnostic framing and clear statement that the package works with any SUT data in the canonical format

### pkgdown & Deployment

- [ ] **PKG-01**: GitHub Actions workflow deploys pkgdown site to GitHub Pages on push to master
- [ ] **PKG-02**: `_pkgdown.yml` reviewed and updated — article grouping, navbar, reference sections reflect the documentation narrative

## Future Requirements

None — this milestone completes the documentation surface.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New R code or exported functions | v1.0-v1.2 shipped all functionality; this milestone is documentation-only |
| Roxygen rewrites for existing functions | Function docs are adequate; focus is on vignettes and guides |
| CRAN submission | Separate concern; pkgdown site is the target documentation surface |
| Automated vignette eval with real data | Paper-replication and FIGARO vignettes must stay `eval = FALSE` (gated on researcher data) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FMT-01 | Phase 11 | Pending |
| FMT-02 | Phase 11 | Pending |
| FMT-03 | Phase 11 | Pending |
| FMT-04 | Phase 11 | Pending |
| VIG-01 | Phase 12 | Complete |
| VIG-02 | Phase 12 | Complete |
| VIG-03 | Phase 12 | Complete |
| DOC-01 | Phase 12 | Complete |
| PKG-01 | Phase 13 | Pending |
| PKG-02 | Phase 13 | Pending |

**Coverage:**
- v1.3 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 after roadmap creation*
