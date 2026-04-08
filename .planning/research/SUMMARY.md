# Project Research Summary

**Project:** sube v1.1 — FIGARO ingestion, paper replication, convenience helpers
**Domain:** R econometrics package (supply-use based econometrics, input-output analysis)
**Researched:** 2026-04-08
**Confidence:** MEDIUM-HIGH (existing pipeline HIGH; FIGARO format MEDIUM — unverified against live files)

## Executive Summary

All four v1.1 features (FIGARO ingestion, paper replication, one-call pipeline, batch processing) can be built entirely on the existing stack — no new `Imports` dependencies needed. The defining architectural constraint is the canonical `sube_suts` long-format schema (`REP, PAR, CPA, VAR, VALUE, YEAR, TYPE`) — every new data source must converge to this schema before entering the existing pipeline, which then runs unchanged.

## Key Findings

### Stack

- **No new IMPORTS dependencies.** `data.table::fread()` reads FIGARO CSVs natively, `lapply`/`rbindlist` handle batch collection, `base::all.equal()` covers replication tolerance.
- Optional `waldo` in `Suggests:` for richer test diffs (already transitive via `testthat`).

### Features

**Table stakes:** FIGARO SUT ingestion → canonical `sube_suts`, paper replication (vignette + gated test), one-call pipeline, batch processor.

**Differentiators:** Unified output class from both WIOD and FIGARO, reproducible numerical replication vignette, named-list batch return.

**Anti-features:** Auto-downloading data, bundling real datasets, zero-config pipeline hiding mapping tables.

### Architecture

- `R/figaro.R` — `read_figaro()` with `.parse_figaro_row()`, `.parse_figaro_col()` internal helpers
- `R/pipeline.R` — `run_sube_pipeline()` and `batch_sube()`
- `tests/testthat/test-replication.R` — env-var-gated against `SUBE_WIOD_DIR`
- `vignettes/paper-replication.Rmd` — eval=FALSE for CRAN/CI
- **Zero existing exported functions need modification** (possible minor `.coerce_map()` synonym extension in `R/utils.R`)

### Critical Pitfalls

1. **FIGARO column layout mismatch** — composite labels encode REP/PAR/CPA/VAR; naive melt corrupts silently. Prevention: separate `read_figaro()` with dedicated parsers + synthetic fixture.
2. **Floating-point aggregation order** — `data.table` sums in key order vs legacy file order; differences at 10th-14th digit. Prevention: define `1e-6` tolerance before coding, canonical sort order.
3. **Pipeline swallows errors** — `build_matrices()` silently drops unmapped rows, `compute_sube()` silently skips singular matrices. Prevention: aggregate diagnostics, emit summary warning.
4. **NACE codes absent from `.coerce_map()`** — FIGARO column names fall through to fragile positional matching. Prevention: extend synonym list before writing importer.
5. **Batch memory** — full `$matrices` across ~880 country-years peaks at several GB. Prevention: `keep_matrices = FALSE` default.

## Recommended Phase Order

1. **FIGARO SUT Ingestion** — only feature with unverified external contract; format must be confirmed before code
2. **Paper Replication Verification** — validates core pipeline numerics before wrapping in convenience functions
3. **One-Call Pipeline** — thin composition; high ergonomic value, low risk
4. **Batch Processing** — loops the pipeline; last because it amplifies design mistakes in Phase 3

## Research Flags

- **Phase 1 needs research:** Download and inspect actual FIGARO CSV files before writing parsing code
- **Phases 2-4:** Standard R patterns, skip research

## Open Questions

- FIGARO exact column schema (compound label format, SUP/USE type encoding, year encoding)
- Whether `CPAnr` integer rank column is needed for paper table comparison joins
- WIOD data directory structure convention for `SUBE_WIOD_DIR` env var

---
*Research completed: 2026-04-08*
*Ready for roadmap: yes*
