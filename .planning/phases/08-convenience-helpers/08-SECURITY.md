---
phase: 08
slug: convenience-helpers
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-17
---

# Phase 08 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| user-supplied `path` → filesystem | Researcher passes local path to `run_sube_pipeline()` | File path string; guarded by `import_suts()`/`read_figaro()` (`file.exists`/`dir.exists`) |
| user-supplied `inputs`/`cpa_map`/`ind_map` → data.table mutation | `setnames()`/`.standardize_names()` mutate by reference | data.table objects; mitigated by `data.table::copy()` at entry |
| user-supplied `sut_data` → `batch_sube()` pipeline | Class-guarded via `.validate_class(sut_data, "sube_suts")` | data.table with required columns |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-8.1-01 | T (Tampering) | data.table mutation of user `inputs` in `run_sube_pipeline()` | mitigate | `data.table::copy(inputs)` at R/pipeline.R:75,156 before `.standardize_names()` | closed |
| T-8.1-02 | T (Tampering) | `path` arg to filesystem | accept | Already guarded by `import_suts()`/`read_figaro()` path validation | closed |
| T-8.1-03 | D (Denial of service) | Large data input | accept | In-process library; user controls input size | closed |
| T-8.1-04 | I (Information disclosure) | `$call` contains `match.call()` | accept | Standard provenance pattern; path-like strings already user-supplied | closed |
| T-8.1-05 | R (Repudiation) | N/A | accept | Not applicable to library APIs | closed |
| T-8.1-06 | E (Elevation of privilege) | N/A | accept | No privilege boundaries in an in-process R library | closed |
| T-8.2-01 | T (Tampering) | data.table mutation of shared `cpa_map`/`ind_map`/`inputs` in `batch_sube()` | mitigate | `data.table::copy()` at R/pipeline.R:658-660 before per-group loop | closed |
| T-8.2-02 | D (Denial of service) | n_countries x n_years memory blowup | accept | User-controlled scope; documented in batch_sube() docs | closed |
| T-8.2-03 | I (Information disclosure) | `$call$call` records match.call() | accept | Standard provenance pattern | closed |
| T-8.2-04 | S/R/E | N/A | accept | Library API, in-process only; no auth/privilege boundaries | closed |
| T-8.3-01 | All | Documentation surface (Plan 03) | accept | Pure text/YAML/Rd changes; no new attack surface | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-8.1-02 | Path validation delegated to existing `import_suts()`/`read_figaro()` guards | orchestrator | 2026-04-17 |
| AR-02 | T-8.1-03, T-8.2-02 | Memory is user-controlled in R library context | orchestrator | 2026-04-17 |
| AR-03 | T-8.1-04, T-8.2-03 | match.call() provenance is standard R practice | orchestrator | 2026-04-17 |
| AR-04 | T-8.1-05, T-8.1-06, T-8.2-04, T-8.3-01 | STRIDE categories N/A for in-process R library | orchestrator | 2026-04-17 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 11 | 11 | 0 | gsd-execute-phase orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter
