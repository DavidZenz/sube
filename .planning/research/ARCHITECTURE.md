# Architecture Patterns

**Domain:** R package — supply-use based econometrics (sube v1.1)
**Researched:** 2026-04-08
**Confidence:** HIGH (based on full source read of all R/, tests, legacy scripts, and paper reference)

---

## Current Architecture (Baseline)

The package is organized as a linear, stage-gated pipeline with explicit S3 classes enforcing
stage ordering. Each stage validates its input class before proceeding, which prevents out-of-order
calls from silently producing garbage.

```
import_suts() / sube_example_data()
       |
       v  [class: sube_suts]
extract_domestic_block()
       |
       v  [class: sube_domestic_suts < sube_suts]
build_matrices()
       |
       v  [class: sube_matrices]
compute_sube()
       |
       v  [class: sube_results]
estimate_elasticities()          filter_sube() / plot_sube() / write_sube()
       |                                  ^
       v  [class: sube_models]            |
prepare_sube_comparison()  ------------>  |
plot_paper_comparison() / plot_paper_regression() / plot_paper_interval_ranges()
```

**Key invariant:** The canonical long-format SUBE table has exactly these columns:
`REP, PAR, CPA, VAR, VALUE, YEAR, TYPE`. Everything downstream depends on this contract.
Any new data source must produce this exact schema to enter the pipeline at `build_matrices()`.

### Source Files and Responsibilities

| File | Public Exports | Role |
|------|---------------|------|
| `R/import.R` | `import_suts()`, `extract_domestic_block()`, `sube_example_data()` | Data ingestion, class tagging |
| `R/matrices.R` | `build_matrices()` | Aggregation, matrix construction |
| `R/compute.R` | `compute_sube()` | Leontief inversion, multipliers, elasticities |
| `R/models.R` | `estimate_elasticities()` | OLS, pooled, between regressions |
| `R/filter_plot_export.R` | `filter_sube()`, `plot_sube()`, `write_sube()` | Output handling |
| `R/paper_tools.R` | `extract_leontief_matrices()`, `prepare_sube_comparison()`, `plot_paper_*()` | Paper-style comparison |
| `R/utils.R` | (none — internal) | Shared helpers, `.standardize_names()`, `.coerce_map()`, `.safe_solve()` |
| `R/globals.R` | (none) | data.table global variable declarations |
| `R/package.R` | (none) | Package-level doc |

---

## New Features and Their Integration Points

### Feature 1: FIGARO SUT Ingestion

**What it is:** FIGARO (Full International and Global Accounts for Research in input-Output
analysis) is Eurostat's multi-regional supply-use framework. It ships industry-by-industry
tables as large CSV files with a different column naming convention than WIOD. The goal is
a new importer that reads FIGARO files and emits the same `sube_suts` long-format table
that `import_suts()` produces.

**Integration point:** `R/import.R` — new exported function `read_figaro()` living alongside
`import_suts()`. It must exit with `class(out) <- c("sube_suts", class(out))` so the rest
of the pipeline sees no difference.

**FIGARO structural characteristics (from Eurostat documentation and format conventions):**
- Files are year-stamped CSVs, one file per year (e.g., `figaro_sut_2021.csv`)
- The matrix is wide: rows are industry-product combinations identified by compound codes
  (e.g., `AT_CPA_A01`, `AT_NACE_A`) rather than separate REP/CPA/VAR columns
- Column codes combine country ISO2 + `_CPA_` + product code for supply dimensions, and
  country ISO2 + `_NACE_` + industry code for use dimensions
- Final demand columns follow `{country}_FD_{category}` patterns
- Row identifiers encode both the reporting country and the product/industry, so parsing
  requires splitting on `_CPA_` vs `_NACE_` separators to recover REP, CPA, VAR fields
- Tables are multi-regional: domestic block extraction (`REP == PAR`) still applies, but
  "PAR" (the partner / column country) must be parsed from column headers

**Transformation required to reach the canonical schema:**
```
FIGARO wide CSV
  -> parse row labels -> REP, CPA (supply) or REP, VAR (use)
  -> parse column labels -> PAR, VAR (supply) or PAR, CPA (use)
  -> melt to long -> VALUE
  -> add YEAR (from filename or embedded metadata)
  -> add TYPE ("SUP" or "USE")
  -> output: REP, PAR, CPA, VAR, VALUE, YEAR, TYPE
```

**New file:** Add `read_figaro()` to `R/import.R` (or a new `R/figaro.R` if parsing logic
is substantial — prefer a separate file to keep `import.R` readable).

**Internal helpers needed:**
- `.parse_figaro_row()` — split compound row codes into REP + CPA or REP + IND
- `.parse_figaro_col()` — split compound column codes into PAR + VAR or PAR + CPA
- `.parse_figaro_year()` — extract year from filename (similar to existing `.parse_year_from_name()`)

**DESCRIPTION changes:** No new hard dependencies expected. If FIGARO files are gzipped,
`R.utils` would be needed; defer until format confirmed. `fread()` handles gzip natively.

**No existing functions need modification.** The canonical schema is the only contract.

---

### Feature 2: Paper Replication

**What it is:** Load real WIOD data, run the full package pipeline, and assert that the
numerical outputs match the legacy script results exactly (within floating-point tolerance).

**Integration point:** This is a *verification layer*, not a new feature of the public API.
It does not add new exported functions. It adds:

1. **A replication vignette** — `vignettes/paper-replication.Rmd` that documents the
   exact import-to-compute sequence matching the paper's Table 1, Table 3, and key figures.
   This vignette is marked `eval = FALSE` for CRAN/CI runs (real WIOD data cannot ship
   with the package) but executes in researcher workflows.

2. **A replication test file** — `tests/testthat/test-replication.R` that:
   - Skips if WIOD data is not found at a configurable path (`Sys.getenv("SUBE_WIOD_DIR")`)
   - Loads the WIOD data via `import_suts()`
   - Runs the full pipeline
   - Compares multiplier and elasticity tables to pre-computed reference fixtures stored
     in `inst/extdata/replication/` (small CSVs with known-good outputs)
   - Uses `expect_equal(..., tolerance = 1e-6)` for floating-point comparisons

**Paper output targets (from legacy scripts and 99_paper_tables.R):**
- `multiplier.csv` columns: `YEAR, REP, CPAagg, CPAnr, GO, VA, EMP, CO2, FD, GOe, VAe, EMPe, CO2e`
  — maps to `result$summary` from `compute_sube()`
- Comparison tables (leo vs. ols/pooled/between means and medians by variable) — maps to
  `prepare_sube_comparison()` output aggregated per the paper's filter rules
- `.apply_paper_filters()` is already implemented in `paper_tools.R` and encodes the
  exact country/product exclusion rules from the paper

**Existing functions that need verification but not modification:**
- `compute_sube()` — multiplier formula matches legacy `03_SUBE.R` (verified by reading both)
- `.apply_paper_filters()` — exclusion rules match `99_outlier_treatment_paper.R`
- `prepare_sube_comparison()` — aggregation logic matches `99_paper_tables.R`

**One gap to flag:** The legacy scripts write `CPAnr` (integer 1–22 product rank) as a column
in `multiplier.csv`. The current `compute_sube()` output does not include this rank column.
Replication comparison tables referencing row order rather than label may need `CPAnr` added
to `result$summary`, or the comparison test must join on `CPAagg` label only. Investigate
which the paper figures actually use — likely label-based, so this may be a non-issue.

---

### Feature 3: One-Call Pipeline

**What it is:** A single function, `run_sube_pipeline()`, that accepts a path (or pre-loaded
table), map files, and inputs, and returns the full `sube_results` object. Eliminates the
four-step import → extract → build → compute boilerplate for straightforward cases.

**Integration point:** New exported function, new file `R/pipeline.R`.

**Proposed signature:**
```r
run_sube_pipeline(
  path,                          # passed to import_suts() or read_figaro()
  cpa_map,
  ind_map,
  inputs,
  source = c("wiod", "figaro"), # selects importer
  domestic_only = TRUE,         # whether to call extract_domestic_block()
  sheets = c("SUP", "USE"),     # passed to import_suts() for WIOD
  ...                            # passed to compute_sube()
)
```

**Return value:** `sube_results` object (same class as `compute_sube()` output). Callers who
want intermediate objects still use the individual functions; this is a convenience layer only.

**Existing functions called internally, not modified:**
- `import_suts()` or `read_figaro()` based on `source`
- `extract_domestic_block()` if `domestic_only = TRUE`
- `build_matrices()`
- `compute_sube()`

**FIGARO dependency:** `run_sube_pipeline()` should not be built until `read_figaro()` exists,
or the `source = "figaro"` branch must be stubbed with a clear error message.

**Test:** Add `test-pipeline.R` that calls `run_sube_pipeline()` on sample data and verifies
the result is identical to the manual four-step sequence.

---

### Feature 4: Batch Country/Year Processing

**What it is:** A function, `batch_sube()`, that loops over multiple countries and/or years,
calls `compute_sube()` for each slice, and returns a named list of `sube_results` objects or a
combined result. Targets the use case where a researcher has a multi-country, multi-year SUT
dataset and wants per-country or per-year results without writing their own `lapply` loop.

**Integration point:** New exported function, can live in `R/pipeline.R` alongside the
one-call pipeline, or in its own `R/batch.R`. Given that these two convenience functions are
closely related in purpose, `R/pipeline.R` is the right home for both.

**Proposed signature:**
```r
batch_sube(
  sut_data,      # pre-imported sube_suts table (already has YEAR and REP)
  cpa_map,
  ind_map,
  inputs,
  by = c("country", "year", "country_year"),  # grouping dimension
  ...            # passed to compute_sube()
)
```

**Return value:** Named list of `sube_results` objects keyed by `"{REP}"`, `"{YEAR}"`, or
`"{REP}_{YEAR}"` depending on `by`. Each element is a full `sube_results` so all downstream
functions (`filter_sube()`, `prepare_sube_comparison()`, etc.) work on each element.

**Existing functions called internally, not modified:**
- `extract_domestic_block()` per slice (already vectorized by country in `build_matrices()`,
  so this function may be called once on the full table before slicing)
- `build_matrices()` per slice
- `compute_sube()` per slice

**Design note:** `build_matrices()` already handles multiple country-year pairs in one call and
stores them as a list of matrices. `batch_sube()` does not replicate this; instead it splits
the `sut_data` into per-group subsets first, so each call produces independent `sube_results`
objects rather than one merged result. This gives the caller clean per-group objects to work
with rather than a merged result requiring re-splitting later.

**Alternative considered:** Accept a directory of files and auto-detect groups from filenames.
Rejected because `import_suts()` already handles directory inputs; `batch_sube()` should work
on already-imported data to avoid duplicating import logic.

---

## Component Boundaries After v1.1

```
R/import.R
  import_suts()          [EXISTING — no change]
  extract_domestic_block()[EXISTING — no change]
  sube_example_data()    [EXISTING — no change]
  read_figaro()          [NEW]

R/figaro.R (if parsing is complex, split from import.R)
  .parse_figaro_row()    [NEW internal]
  .parse_figaro_col()    [NEW internal]

R/matrices.R             [EXISTING — no change]
R/compute.R              [EXISTING — no change]
R/models.R               [EXISTING — no change]
R/filter_plot_export.R   [EXISTING — no change]

R/paper_tools.R          [EXISTING — possibly minor: CPAnr column question]
  extract_leontief_matrices()
  prepare_sube_comparison()
  plot_paper_comparison()
  plot_paper_regression()
  plot_paper_interval_ranges()

R/pipeline.R             [NEW]
  run_sube_pipeline()    [NEW]
  batch_sube()           [NEW]

R/utils.R                [EXISTING — add .parse_figaro_year() if needed]

tests/testthat/
  test-workflow.R        [EXISTING — no change]
  test-replication.R     [NEW — skips without WIOD_DIR env var]
  test-pipeline.R        [NEW]
  test-figaro.R          [NEW — uses synthetic minimal FIGARO-format CSV]

vignettes/
  paper-replication.Rmd  [NEW — eval=FALSE, researcher-facing]

inst/extdata/
  sample/                [EXISTING — no change]
  replication/           [NEW — small reference fixtures for test-replication.R]
  figaro-sample/         [NEW — tiny synthetic FIGARO CSV for test-figaro.R]
```

---

## Data Flow Changes

**Before v1.1:**
```
WIOD xlsx/CSV  ->  import_suts()  ->  [sube_suts]  ->  extract_domestic_block()  ->  build_matrices()  ->  compute_sube()
```

**After v1.1:**
```
WIOD xlsx/CSV  ->  import_suts()  \
                                   ->  [sube_suts]  ->  extract_domestic_block()  ->  build_matrices()  ->  compute_sube()
FIGARO CSV     ->  read_figaro()  /

or via pipeline:
any source  ->  run_sube_pipeline(source = "wiod"/"figaro")  ->  [sube_results]

or via batch:
[sube_suts]  ->  batch_sube(by = "country")  ->  list of [sube_results]
```

The canonical `sube_suts` class is the convergence point. Everything upstream of it is
format-specific; everything downstream of it is format-agnostic.

---

## Suggested Build Order

Build order follows the dependency graph. Each feature unlocks the next.

| Order | Feature | Rationale |
|-------|---------|-----------|
| 1 | FIGARO ingestion (`read_figaro()`) | Independent of all other new features. Unlocks `run_sube_pipeline(source = "figaro")`. Establishes the second data-source path. |
| 2 | Paper replication verification | Requires only existing package functions plus real WIOD data. No new API. Establishes ground truth before adding convenience wrappers that could mask regressions. |
| 3 | One-call pipeline (`run_sube_pipeline()`) | Requires FIGARO ingestion to be done (or stubbed) so the `source` parameter is consistent. A pure composition of existing functions — low risk. |
| 4 | Batch processing (`batch_sube()`) | Requires the pipeline mental model to be settled. Builds on `run_sube_pipeline()` conceptually (even if not literally calling it). |

**Why replication before pipeline:** The pipeline wraps existing compute logic. If replication
reveals a numerical discrepancy, the fix is in `compute_sube()` or `build_matrices()` — core
functions that the pipeline then wraps. Fixing core functions after wrapping them adds friction.

**Why FIGARO first:** It is the only feature that adds a new external contract (the FIGARO
file format). Getting the format right and the class tagging correct establishes the pattern
that `run_sube_pipeline()` will depend on. If FIGARO parsing turns out to require a new
dependency or the format differs materially from expectations, that should be discovered before
pipeline code is written around it.

---

## Patterns to Follow

### Pattern: Format Adapter to Canonical Schema

Each data source gets its own import function that terminates by producing a correctly-classed
`sube_suts` `data.table` with exactly `REP, PAR, CPA, VAR, VALUE, YEAR, TYPE` columns.
No format-specific knowledge leaks past the import layer.

```r
read_figaro <- function(path, ...) {
  # ... format-specific parsing ...
  out <- data.table(REP = ..., PAR = ..., CPA = ..., VAR = ..., VALUE = ..., YEAR = ..., TYPE = ...)
  class(out) <- c("sube_suts", class(out))
  out[]
}
```

### Pattern: Composition Pipeline in Pipeline Functions

`run_sube_pipeline()` is a pure composition. It calls existing exported functions in sequence
and passes their results through. It does not duplicate logic.

```r
run_sube_pipeline <- function(path, cpa_map, ind_map, inputs, source = "wiod", domestic_only = TRUE, ...) {
  sut <- if (source == "figaro") read_figaro(path) else import_suts(path)
  if (domestic_only) sut <- extract_domestic_block(sut)
  bundle <- build_matrices(sut, cpa_map, ind_map)
  compute_sube(bundle, inputs, ...)
}
```

### Pattern: Skip-Guard for External Data Tests

Replication tests that require external WIOD data use an env-var guard so CI stays green.

```r
test_that("paper replication matches", {
  wiod_dir <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  skip_if(nzchar(wiod_dir) == FALSE, "SUBE_WIOD_DIR not set — skipping replication")
  # ...
})
```

---

## Anti-Patterns to Avoid

### Anti-Pattern: Diverging Canonical Schemas

**What:** Letting `read_figaro()` return a slightly different column set (e.g., adding a
`SOURCE` column or using `INDUSTRY` instead of `VAR`).
**Why bad:** `build_matrices()` calls `.sube_required_columns()` and would error; workarounds
would proliferate through `build_matrices()` and make it format-aware.
**Instead:** Transform fully to the canonical schema inside the import function. Add metadata
as an attribute if needed: `attr(out, "source") <- "figaro"`.

### Anti-Pattern: Pipeline Function With Conditional Logic for Data Shape

**What:** `run_sube_pipeline()` inspecting the data and branching based on column names to
handle format differences.
**Why bad:** The format adapter pattern already handles this. Adding shape-inspection in the
pipeline layer means format knowledge is in two places.
**Instead:** By the time data reaches `run_sube_pipeline()`, it is already canonical. All
branching is at the importer level.

### Anti-Pattern: Batch Function That Returns a Merged Single Result

**What:** `batch_sube()` calling `rbindlist()` on all results into one big table.
**Why bad:** Destroys per-group `sube_results` structure. Callers who want per-group
diagnostics or per-group `matrices` lists cannot recover them from a merged table.
**Instead:** Return a named list of `sube_results` objects. Callers can bind the `$summary`
or `$tidy` sub-tables themselves using `rbindlist(lapply(batch, `[[`, "summary"))`.

### Anti-Pattern: Shipping WIOD Data With the Package

**What:** Adding WIOD Excel files to `inst/extdata/` to make replication tests always run.
**Why bad:** WIOD release 2016 is ~300 MB. Package tarball limit is 5 MB. R CMD check would
fail. The license also prohibits redistribution without attribution.
**Instead:** Keep replication data external. Use env-var skip guards and tiny synthetic
fixtures for fast CI validation of format parsing.

---

## Scalability Considerations

These are primarily research workflow concerns, not production scale, but worth noting.

| Concern | Single-country run | Full WIOD (44 countries × 15 years) | FIGARO (full release) |
|---------|---------------------|-------------------------------------|-----------------------|
| Memory | Negligible | ~2–4 GB for all matrices in-memory | ~4–8 GB (larger coverage) |
| `build_matrices()` | Fast | ~30s on modern hardware | Similar or longer |
| `batch_sube()` | N/A | Sequential lapply is fine | Same |
| Parallelism | Not needed | Not needed for research use | Not needed |

No parallelism infrastructure is warranted for this milestone. `batch_sube()` should use a
plain `lapply` loop with informative progress messages via `message()`.

---

## Sources

- Full read of `R/import.R`, `R/matrices.R`, `R/compute.R`, `R/models.R`,
  `R/filter_plot_export.R`, `R/paper_tools.R`, `R/utils.R` (2026-04-08)
- Full read of `archive/legacy-scripts/01_read_SUTs.R`, `03_SUBE.R`, `99_paper_tables.R`
- Full read of `tests/testthat/test-workflow.R` and `inst/scripts/run_legacy_pipeline.R`
- `inst/references/paper.md` — paper methodology, Table 1 product aggregates, filter rules
- `NAMESPACE` — current exports contract
- `DESCRIPTION` — current dependency list
- FIGARO format: structural inference from Eurostat's multi-regional SUT documentation
  conventions (compound `{country}_{CPA/NACE}_{code}` column naming). Web access was not
  available during this research session; FIGARO-specific column naming should be verified
  against actual downloaded files before implementing `.parse_figaro_row()` / `.parse_figaro_col()`.
  Confidence on FIGARO internal format: MEDIUM (structural pattern inferred, not verified from live docs).
