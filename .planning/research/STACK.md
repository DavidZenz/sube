# Technology Stack

**Project:** sube v1.1 — FIGARO ingestion, paper replication, convenience helpers
**Researched:** 2026-04-08
**Scope:** Additions/changes only. Existing v1.0 stack (data.table, openxlsx, haven, plm, broom, ggplot2, ggrepel) is NOT re-evaluated.

---

## Verdict: No New Import Dependencies

All four new features can be built on the existing dependency set. The risk of adding dependencies to a research package is high (CRAN policy, user environments, tarball size). Each candidate was evaluated against what the existing stack already provides.

---

## Recommended Stack Additions

### None for IMPORTS

| Category | Decision | Rationale |
|----------|----------|-----------|
| FIGARO CSV reading | `data.table::fread()` (already imported) | FIGARO distributes industry-by-industry SUTs as plain or gzipped CSV. `fread` handles `.csv` and `.csv.gz` natively with no extra dependency. |
| Pipeline orchestration | No new library — pure R function composition | `sube_pipeline()` is a thin wrapper that calls `import_suts()` → `build_matrices()` → `compute_sube()` in sequence. No framework needed. |
| Batch processing | No new library — `lapply`/`rbindlist` (data.table, already imported) | Collecting per-country-year results is a standard `lapply` over a grid then `rbindlist`. Already used internally. |
| Numerical comparison for replication | No new library — `all.equal()` from base R | Exact numerical matching against legacy script outputs uses `all.equal()` with a tolerance. No new dependency. |

### SUGGESTS additions (test/vignette only)

| Package | Purpose | Why Suggests not Imports |
|---------|---------|--------------------------|
| `waldo` | Richer diff output in replication tests | Only needed in `testthat` replication tests; not part of user-facing API. Users never call it directly. |

`waldo` is already a transitive dependency of `testthat` in many environments, so it is effectively free. If CRAN submission is a goal, omit it and use `testthat::expect_equal()` directly — `all.equal()` tolerance wrapping is sufficient.

---

## FIGARO Format: What the Ingestion Function Must Handle

FIGARO (Full International and Global Accounts for Research in Input-Output Analysis) is published by Eurostat. Based on the data format documentation (MEDIUM confidence — from known Eurostat FIGARO release structure):

| Characteristic | WIOD (existing) | FIGARO |
|---------------|----------------|--------|
| File format | `.xlsx` workbook, multiple sheets | `.csv` or `.csv.gz`, one matrix per file |
| Table type | Supply + Use as separate sheets | Industry-by-industry (symmetric IO, or SUT) |
| Country coding | 2-letter ISO + `ROW` | `CC_` prefix + country code (e.g. `AT_`) |
| Dimension labeling | Row=product, Col=industry | Row label encodes country+industry, Col=country+industry |
| Year encoding | In file name (e.g. `wiot00`) | In file name (e.g. `figaro_2020_`) |
| Value units | Million USD | Million EUR |

**Implication for implementation:** The `import_figaro()` function needs its own parser — it cannot reuse `.parse_year_from_name()` and the WIOD sheet-melt logic as-is. It should produce the same output schema (`REP`, `PAR`, `CPA`, `VAR`, `VALUE`, `YEAR`, `TYPE`) so downstream functions remain unchanged.

---

## Integration Points

### Where new code plugs in

```
R/import_figaro.R      — new file; exports import_figaro()
R/pipeline.R           — new file; exports sube_pipeline()
R/batch.R              — new file; exports sube_batch()
R/import.R             — no changes needed (FIGARO gets its own function)
R/compute.R            — no changes needed
R/matrices.R           — no changes needed
tests/testthat/        — replication tests comparing package output to legacy
                         script snapshots (numerical tolerance via all.equal)
```

### What must NOT change

- Public function signatures: `import_suts()`, `build_matrices()`, `compute_sube()`, `estimate_sube()`, `compare_sube()` — downstream user code depends on these.
- Output schemas: `sube_suts`, `sube_domestic_suts`, `sube_matrices`, `sube_results` S3 classes — downstream print/plot methods depend on these.
- `DESCRIPTION` `Imports:` field — do not add packages here unless essential.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| FIGARO file reading | `fread` (data.table) | `readr::read_csv` | Adds a dependency; data.table is already imported and faster for wide matrices |
| FIGARO file reading | `fread` (data.table) | `arrow::read_csv_arrow` | Arrow is heavyweight; FIGARO files are not Parquet; no benefit |
| Batch orchestration | `lapply` + `rbindlist` | `purrr::map` + `dplyr::bind_rows` | Adds tidyverse dependencies; data.table already covers this |
| Batch orchestration | `lapply` + `rbindlist` | `parallel::mclapply` | Parallelism adds complexity and platform inconsistency; IO-bound anyway; out of scope |
| Replication diff display | base `all.equal` | `waldo` | `waldo` is optional; `all.equal` is sufficient for numeric tolerance checks |
| Pipeline function | thin R wrapper | `targets` workflow | Way too heavy for a single convenience function; out of scope |

---

## Installation

No new installation step. The existing `DESCRIPTION` `Imports:` covers all new code.

If `waldo` is added to `Suggests:`:

```r
# Already present in most test environments via testthat; explicit:
install.packages("waldo")
```

---

## Confidence Assessment

| Claim | Confidence | Source |
|-------|------------|--------|
| FIGARO distributed as CSV/CSV.GZ | MEDIUM | Known Eurostat FIGARO release pattern; not verified against live download in this session |
| `fread` handles gzipped CSV | HIGH | data.table documentation, well-established feature |
| `waldo` is a testthat transitive dep | MEDIUM | True for recent testthat versions, but not guaranteed in all envs |
| No new IMPORTS needed | HIGH | All four features use only function composition and base R |
| FIGARO uses country-prefixed row/col labels | MEDIUM | Standard Eurostat multi-country IO convention; verify against actual file download |

---

## Open Questions for Implementation Phase

1. **Exact FIGARO column schema** — confirm country+industry row label format from a real downloaded file before writing the parser. The `import_figaro()` function's reshape logic depends on this.
2. **SUP vs USE sheet equivalents in FIGARO** — FIGARO industry-by-industry tables may require different TYPE assignment logic than the WIOD SUP/USE sheet split. Clarify before writing the function.
3. **Replication data location** — the full WIOD dataset is not shipped with the package (`inst/references/` only has the paper). The replication test needs a documented path convention for the user's local WIOD data.
