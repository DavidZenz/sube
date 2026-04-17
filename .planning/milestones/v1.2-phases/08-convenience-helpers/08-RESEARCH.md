# Phase 8: Convenience Helpers — Research

**Researched:** 2026-04-16
**Domain:** R S3 API wrappers, data.table batch processing, diagnostic instrumentation
**Confidence:** HIGH

---

## 1. Goal Clarification

This research supports the planner in laying out concrete tasks for Phase 8.
The implementation decisions are already locked in CONTEXT.md (D-8.1 through
D-8.16). What the planner needs is: exact file-and-line anchors in the existing
codebase, resolved answers to the six open items from CONTEXT.md, concrete code
patterns for the detection algorithms, and a Nyquist validation map so a
VALIDATION.md can be derived.

This document does NOT re-examine locked decisions. Every recommendation is
constrained by the CONTEXT.md decisions or is filling a gap those decisions
left explicitly open.

---

## 2. Codebase Anchor Map

All line numbers verified against HEAD as of 2026-04-16.

| Symbol | File | Line(s) | Notes |
|--------|------|---------|-------|
| `compute_sube()` signature | `R/compute.R` | 17–22 | `matrix_bundle, inputs, metrics, diagonal_adjustment, zero_replacement` |
| `compute_sube()` diagnostics table | `R/compute.R` | 54, 69, 77, 126 | writes `data.table(country, year, status)` per iteration |
| `compute_sube()` class assignment | `R/compute.R` | 135 | `class(out) <- c("sube_results", class(out))` |
| `compute_sube()` inputs validation | `R/compute.R` | 24–31 | `.standardize_names`, `.sube_required_columns`, industry col lookup |
| `compute_sube()` deep-fail on bad inputs | `R/compute.R` | 58–62 | stops with `"Input rows do not align..."` if inputs shape wrong after join |
| `build_matrices()` signature | `R/matrices.R` | 32–33 | `sut_data, cpa_map, ind_map, final_demand_var, inputs` |
| `build_matrices()` ids derivation | `R/matrices.R` | 66 | `ids <- unique(aggregated[, .(YEAR, REP)])` |
| `build_matrices()` matrix naming | `R/matrices.R` | 104 | `paste(x$country, x$year, sep = "_")` → `"REP_YEAR"` |
| `build_matrices()` NULL-filtered matrices | `R/matrices.R` | 103 | `Filter(Negate(is.null), matrices)` — silently drops NULL bundles |
| `build_matrices()` model_data | `R/matrices.R` | 120–190 | empty `data.table()` when inputs=NULL; NULL per group on alignment failure (lines 136, 139, 157, 177) |
| `import_suts()` signature | `R/import.R` | 25 | `path, sheets, recursive` |
| `extract_domestic_block()` | `R/import.R` | 116–122 | `data[REP == PAR]`; assigns `sube_domestic_suts` + `sube_suts` class |
| `read_figaro()` signature | `R/import.R` | 183–184 | `path, year, final_demand_vars` |
| `read_figaro()` primary-input drop | `R/import.R` | 247 | `dt[startsWith(rowPi, "CPA_")]` — drops non-CPA rows BEFORE `as.numeric(obsValue)` coercion |
| `read_figaro()` VALUE coercion | `R/import.R` | 255 | `VALUE = as.numeric(dt$obsValue)` — the NA-introduction point |
| `read_figaro()` final-demand aggregation | `R/import.R` | 270–284 | FD codes summed with `sum(VALUE, na.rm = TRUE)` per `(REP,PAR,CPA)` |
| `sube_example_data()` | `R/import.R` | 302–309 | loads `sut_data/cpa_map/ind_map/inputs/model_data` from `inst/extdata/sample/` |
| `.standardize_names()` | `R/utils.R` | 17–21 | upcases all column names; converts to data.table |
| `.sube_required_columns()` | `R/utils.R` | 1–9 | errors with `"Missing required columns: ..."` |
| `.validate_class()` | `R/utils.R` | 87–91 | `inherits(x, expected)` check |
| `filter_sube()` class check | `R/filter_plot_export.R` | 39, 43 | `.standardize_names(data)` + `.sube_required_columns()` — NO `UseMethod`, NO `inherits` on `sube_results` |
| `plot_sube()` class check | `R/filter_plot_export.R` | 89 | same: `.standardize_names` only, no class guard |
| `write_sube()` class check | `R/filter_plot_export.R` | 154 | checks `is.data.frame` / `is.data.table` / named list — no `sube_*` class check |
| `extract_leontief_matrices()` | `R/paper_tools.R` | 32 | `.validate_class(results, "sube_results")` — HARD class gate |
| `prepare_sube_comparison()` | `R/paper_tools.R` | 204 | `.validate_class(leontief, "sube_results")` — HARD class gate |
| `estimate_elasticities()` class | `R/models.R` | 121 | `class(out) <- c("sube_models", class(out))` |
| `_pkgdown.yml` reference section | `_pkgdown.yml` | 10–35 | "Data import and preparation" group at lines 11–17; five entries currently |
| `_pkgdown.yml` articles section | `_pkgdown.yml` | 36–56 | six article groups; "Modeling, Comparison, and Outputs" at line 43 |
| NAMESPACE current exports | `NAMESPACE` | 1–16 | 16 export() lines; no S3method() lines |
| test conventions (testthat 3) | `tests/testthat/test-workflow.R` | 1–252 | `library(testthat)`, `library(sube)`, one `test_that()` per behaviour |
| FIGARO pipeline test style | `tests/testthat/test-figaro-pipeline.R` | 1–106 | memoised fixture, gated skip, `expect_s3_class`, structural invariants |
| figaro-sample fixture files | `inst/extdata/figaro-sample/` | — | TWO files only: `flatfile_eu-ic-supply_sample.csv`, `flatfile_eu-ic-use_sample.csv` |
| figaro-sample countries | fixture | — | DE, FR, IT (3 countries × 8 CPA codes each) |
| figaro-sample FD codes | fixture | — | P3_S13, P3_S14, P3_S15, P51G, P5M present (120 rows matched) |
| sube_example_data fixture | `inst/extdata/sample/` | — | `sut_data.csv`: 1 country (AAA), 2 products, 2 industries, 1 year (2020); `inputs.csv`: 2 industry rows |
| test helper (fixture builders) | `tests/testthat/helper-gated-data.R` | 80–111 | `build_figaro_pipeline_fixture_from_synthetic()` — builds cpa_map/ind_map inline, NOT loaded from sample/ |

---

## 3. Resolutions for the 6 Open Items

### Open Item 1: Class Inheritance for Dispatch

**Evidence:**

`filter_sube()`, `plot_sube()`, and `write_sube()` in `R/filter_plot_export.R`
have NO `UseMethod()` dispatch and NO `inherits()` / `.validate_class()` guard
on a `sube_results` class. They accept any `data.frame` / `data.table` with the
right columns. The entry points are:

- `filter_sube()` line 39: `.standardize_names(data)` — converts anything to
  data.table with uppercased names, then column-checks via `.sube_required_columns`
- `plot_sube()` line 89: same pattern
- `write_sube()` line 154: `is.data.frame(data) || data.table::is.data.table(data)`

Two functions in `R/paper_tools.R` DO have hard class gates:

- `extract_leontief_matrices()` line 32: `.validate_class(results, "sube_results")`
- `prepare_sube_comparison()` line 204: `.validate_class(leontief, "sube_results")`

`compute_sube()` line 23: `.validate_class(matrix_bundle, "sube_matrices")`.

**RECOMMENDATION: Do NOT inherit `sube_results` on `sube_pipeline_result` /
`sube_batch_result`.**

Rationale:

1. `filter_sube`, `plot_sube`, `write_sube` require only column shape, not class
   tag — passing `result$tidy` or `result$results$tidy` works today and will
   continue to work. Inheritance adds zero dispatch value for these three.

2. The two functions that DO class-gate (`extract_leontief_matrices`,
   `prepare_sube_comparison`) accept a `sube_results` representing the COMPUTE
   output — i.e., `result$results` (the inner object), not the pipeline wrapper.
   If `sube_pipeline_result` inherited `sube_results`, a researcher passing the
   pipeline wrapper to `extract_leontief_matrices()` would pass the class check
   but then fail when the function tries to access `results$tidy` (which does not
   exist at the wrapper level — the wrapper has `$results$tidy`). This is a
   worse failure mode than the honest class-mismatch error.

3. The S3 class hierarchy `c("sube_pipeline_result", "list")` and
   `c("sube_batch_result", "list")` is correct — these are distinct result
   shapes, not subclasses of compute output.

4. The `$results` field inside `sube_pipeline_result` IS a `sube_results` object
   and passes to `extract_leontief_matrices(result$results)` cleanly.

**Downstream action for planner:** `R/pipeline.R` constructors assign:
```r
class(out) <- c("sube_pipeline_result", "list")
class(out) <- c("sube_batch_result", "list")
```
NAMESPACE gets `export(run_sube_pipeline)` + `export(batch_sube)` plus optional
`S3method(print, sube_pipeline_result)` / `S3method(print, sube_batch_result)`.

---

### Open Item 2: Coerced-NA Row Counting Hook (D-8.11 #3)

**Evidence:**

In `read_figaro()` (`R/import.R`):

1. Line 247: `dt <- dt[startsWith(rowPi, "CPA_")]` — primary-input rows are
   dropped BEFORE the `as.numeric()` call. These rows are SNA value-added blocks,
   not products. They are structural drops, not coercion-induced NA rows.

2. Line 255: `VALUE = as.numeric(dt$obsValue)` — this is the single location
   where `as.numeric()` coercion happens in `read_figaro()`. NAs can only be
   introduced here if `obsValue` contains non-numeric strings (e.g. `":"` which
   is Eurostat's null marker).

3. Lines 270–284: Final-demand aggregation uses `sum(VALUE, na.rm = TRUE)` —
   coerced NAs are silently absorbed here (they contribute 0). So coerced NAs in
   FD rows are already partially hidden.

In `import_suts()` (`R/import.R`): there is no explicit `as.numeric(VALUE)` call
during import. The VALUE column inherits the numeric type from `fread()` or from
the workbook. The WIOD path does not introduce coercion NAs in a measurable way.

**Where `as.numeric(VALUE)` appears in `build_matrices()` (`R/matrices.R`):**
Lines 60, 144, 147: `sum(as.numeric(VALUE), na.rm = TRUE)` — these coercions
happen AFTER import on already-canonical data. They silently absorb NAs from
any non-numeric VALUE strings that `import_suts()` might have passed through.
These are the secondary NA-introduction points.

**RECOMMENDATION — Hook placement and measurement technique:**

The cleanest hook is a thin wrapper around the importer call inside
`run_sube_pipeline()` that counts NAs produced by `as.numeric(obsValue)` during
`read_figaro()`, and a separate count for `import_suts()` output.

For FIGARO:
```r
# Before calling read_figaro():
sut_raw <- read_figaro(path, year = year, ...)  # already coerces obsValue

# read_figaro() returns a sube_suts; VALUE column is already as.numeric()
# Count NAs in the returned VALUE column — these are all from obsValue coercion
# (primary-input rows were dropped before coercion, so no double-count):
n_coerced_na <- sum(is.na(sut_raw$VALUE))
```

For WIOD (`import_suts()`): check `sum(is.na(sut_raw$VALUE))` post-import.
`import_suts()` does not call `as.numeric(VALUE)` explicitly; NAs originate
from workbook cells that `readWorkbook()` returns as NA. The count is still valid
as "rows with NA VALUE at import boundary".

The diagnostic row is a pipeline-level aggregate (no per-country breakdown at
import stage because the importer handles all countries together):

```r
if (n_coerced_na > 0L) {
  diag_import <- data.table(
    country = NA_character_,
    year    = NA_integer_,
    stage   = "import",
    status  = "coerced_na",
    message = sprintf("%d row(s) with NA VALUE after as.numeric() coercion at import", n_coerced_na),
    n_rows  = n_coerced_na
  )
}
```

**Double-counting avoidance:** Primary-input rows in FIGARO are dropped at line
247 BEFORE `as.numeric()` at line 255 — so they are never in the data when we
count `sum(is.na(VALUE))`. The `na.rm = TRUE` in `build_matrices()` absorbs them
silently, but since we count BEFORE `build_matrices()`, there is no
double-counting. The measurement is: `sum(is.na(sut_raw$VALUE))` after the
importer returns, before any further pipeline steps.

---

### Open Item 3: Final `$diagnostics` Schema and NA Handling

**Evidence:** `compute_sube()` emits `data.table(country, year, status)` at
lines 54, 69, 77, 126. Column order: `country`, `year`, `status`.

The pipeline must extend this to the D-8.12 schema without modifying
`compute_sube()`. The extension happens by appending columns on the compute
diagnostics when assembling the unified table.

**CONFIRMED schema and column order:**

```r
data.table(
  country = character(),   # REP; NA_character_ for pipeline-level aggregates
  year    = integer(),     # YEAR; NA_integer_  for pipeline-level aggregates
  stage   = character(),   # "import" | "build" | "compute" | "pipeline"
  status  = character(),   # see allowed values below
  message = character(),   # one-line human-readable reason
  n_rows  = integer()      # NA_integer_ except for "coerced_na" aggregate rows
)
```

Column order rationale: `country` + `year` first (match compute output; sort
keys for humans); `stage` + `status` second (the diagnostic taxonomy); `message`
third (human text); `n_rows` last (optional numeric, mostly NA).

**Allowed `status` values (character, NOT factor):**

`"ok"`, `"singular_supply"`, `"singular_go"`, `"singular_leontief"`,
`"skipped_alignment"`, `"coerced_na"`, `"inputs_misaligned"`, `"error"`

Use free-form `character` (not `factor`) because:
- `rbindlist` on factor columns requires matching levels or `fill = TRUE` with
  level coercion; character avoids silent level-mismatch bugs across batch groups
- Test assertions `expect_equal(diag$status, "ok")` work on character without
  level bookkeeping
- Adding a new status in a future phase does not require an enum update

**NA handling for pipeline-level aggregate rows:**

`rbindlist` on a mix of rows with `country = NA_character_` and rows with
country codes works correctly — `data.table::rbindlist` treats NA values as
valid data entries in character columns. Verified pattern from `compute_sube()`
itself: it already rbindlists diagnostics that may have been built from different
country-year iterations. The `fill = TRUE` parameter handles any column-set
mismatches.

The `n_rows` column: use `NA_integer_` for all non-`coerced_na` rows (not 0,
because 0 would imply "checked and found nothing" while NA means "this metric
does not apply to this category"). Use `integer()` as the column type (not
`numeric`) to match the existing convention in `compute_sube()` where `year` is
integer.

**Assembling compute-stage rows from compute_sube output:**

```r
compute_diag <- data.table::copy(result$diagnostics)  # has: country, year, status
compute_diag[, stage   := "compute"]
compute_diag[, message := fcase(
  status == "singular_supply",   "Supply matrix singular; country-year skipped",
  status == "singular_go",       "GO diagonal singular; country-year skipped",
  status == "singular_leontief", "Leontief matrix (I-A) singular; country-year skipped",
  status == "ok",                "ok",
  default = status
)]
compute_diag[, n_rows := NA_integer_]
```

---

### Open Item 4: Progress Reporting in `batch_sube()`

**Evidence:** No `message()` or `cli::*` calls exist anywhere in
`R/compute.R`, `R/matrices.R`, `R/import.R`. The codebase convention is
**silent** — all user-visible communication is via `stop()` / `warning()`.

`compute_sube()` iterates over potentially many country-year bundles inside its
`for` loop (lines 45–127) without emitting any progress messages. The pattern is:
compute, accumulate, warn at the end if needed.

The FIGARO synthetic fixture runs DE/FR/IT × 1 year = 3 groups. The example data
has AAA × 1 year = 1 group. Estimated runtime for a single `run_sube_pipeline()`
call on the sample data: < 0.5 seconds.

**RECOMMENDATION: Silent until summary warning. No `message()` per group.**

Rationale:
- Package convention is uniformly silent; introducing `message()` in the batch
  function breaks this convention.
- Typical researcher use case at current scale: 40–50 countries × 5–10 years =
  200–500 groups; each group completes in well under 1 second; total batch is
  seconds to minutes. Progress spam at 500 messages would fill the console.
- The summary `warning()` at the end (D-8.10) provides sufficient feedback.
- If future scale demands progress bars, the `cli` package can be added later
  without breaking any API.

**Planner action:** Document the silence explicitly in the `batch_sube()` roxygen
`@details`. No `message()` calls in the loop.

---

### Open Item 5: Test File Layout

**Evidence:**

Current test file sizes:
- `test-workflow.R`: 252 lines
- `test-figaro-pipeline.R`: 106 lines

File convention: one test file per module. `test-workflow.R` covers
`import_suts`, `extract_domestic_block`, `build_matrices`, `compute_sube`,
`filter_sube`, `plot_sube`, `write_sube`, `estimate_elasticities` — the full
workflow — in 252 lines.

`test-pipeline.R` will need to cover:
- `run_sube_pipeline()` success on `sube_example_data()` (WIOD path)
- `run_sube_pipeline()` success on figaro-sample (FIGARO path)
- `run_sube_pipeline()` with `estimate = TRUE`
- `batch_sube()` over multiple groups
- All four diagnostic categories (D-8.11)
- Per-group error resilience (D-8.7)

Estimate: ~10 `test_that()` blocks × ~20–30 lines each = 200–300 lines. This
stays under the 300-line threshold.

**RECOMMENDATION: One file — `tests/testthat/test-pipeline.R`.**

Split into `test-pipeline.R` + `test-batch.R` only if the combined file exceeds
~300 lines after drafting. The expected size is 220–280 lines, so single file is
correct. Mirror the `test-figaro-pipeline.R` style: helper functions at top,
`test_that()` blocks below.

---

### Open Item 6: Upfront `inputs` Validation

**Evidence:**

`compute_sube()` validates `inputs` at lines 24–31:
```r
inputs <- .standardize_names(inputs)
.sube_required_columns(inputs, c("YEAR", "REP", "GO"))

industry_col <- intersect(c("IND", "INDUSTRY", "INDUSTRIES", "INDAGG"), names(inputs))
if (length(industry_col) == 0L) {
  stop("`inputs` must include an industry identifier column.", call. = FALSE)
}
```

This runs before the matrix loop and provides a clear error message for missing
required columns. The LATE failure (line 58–62) is the alignment check:
```r
input_rows <- inputs[YEAR == year & REP == country]
input_rows <- input_rows[match(bundle$industries, INDUSTRY)]
if (nrow(input_rows) != length(bundle$industries) || anyNA(input_rows$INDUSTRY)) {
  stop(sprintf("Input rows do not align with matrix industries for %s %s.", country, year), call. = FALSE)
}
```

This fails per-country-year deep inside the loop — and it stops completely (not
a diagnostic row). This is the bad-UX failure mode.

In `run_sube_pipeline()`, the `inputs` argument is passed to BOTH
`build_matrices()` (optional, for model_data) and `compute_sube()`. A shape
problem in `inputs` will cause `compute_sube()` to stop at line 58–62 after
the full import and matrix build have already run.

**RECOMMENDATION: Add upfront `inputs` validation in `run_sube_pipeline()`.**

Reuse `.standardize_names()` and `.sube_required_columns()` (already available
as package internals):

```r
# In run_sube_pipeline(), before calling any importer:
if (!is.null(inputs)) {
  inputs_check <- .standardize_names(inputs)
  .sube_required_columns(inputs_check, c("YEAR", "REP", "GO"),
    call = FALSE)  # propagate clean error
  industry_col <- intersect(
    c("IND", "INDUSTRY", "INDUSTRIES", "INDAGG"), names(inputs_check)
  )
  if (length(industry_col) == 0L) {
    stop(
      paste0(
        "`inputs` must include an industry identifier column ",
        "(IND, INDUSTRY, INDUSTRIES, or INDAGG)."
      ),
      call. = FALSE
    )
  }
}
```

This matches the exact same validation `compute_sube()` does, runs before the
pipeline starts, and gives the researcher a named-column error before spending
time importing potentially large files.

Note: `inputs` is required in `run_sube_pipeline()` (not optional), so the
`!is.null` guard is for `batch_sube()` compatibility only — treat it as always
present in the pipeline context.

---

## 4. Additional Planner Musts

### Detection Algorithm for D-8.9 (Dropped Country-Years)

Matrix names in `build_matrices()` output use `paste(country, year, sep = "_")`
(verified at `R/matrices.R:104`). The ids table is derived from
`unique(aggregated[, .(YEAR, REP)])` (line 66), where `aggregated` is the
post-merge, post-filter data that survived the CPA and industry correspondence
joins.

**Critical distinction:** `aggregated` is already the filtered set — rows that
did not match `cpa_map` or `ind_map` are dropped at line 55:
`tagged[!is.na(CPAagg) & !is.na(INDagg)]`. So the ids in `build_matrices()` are
already post-correspondence-filter. The country-years present in
`unique(sut_data[, .(YEAR, REP)])` (pre-filter) may be larger than
`unique(aggregated[, .(YEAR, REP)])`.

The detection diff should compare:

```r
# Input ids: from sut_data AFTER extract_domestic_block, BEFORE build_matrices
input_ids <- unique(sut_data[, .(YEAR, REP)])
input_keys <- paste(input_ids$REP, input_ids$YEAR, sep = "_")

# Output ids: from the returned matrices list
output_keys <- names(matrix_bundle$matrices)

# Dropped keys
dropped_keys <- setdiff(input_keys, output_keys)
```

For each `dropped_key`, construct a diagnostics row:
```r
data.table(
  country = sub("_\\d+$", "", dropped_key),   # extract REP
  year    = as.integer(sub("^[^_]+_", "", dropped_key)),  # extract YEAR
  stage   = "build",
  status  = "skipped_alignment",
  message = sprintf(
    "Country-year %s present in SUT data but absent from build_matrices output (missing CPA/industry alignment after correspondence merge)",
    dropped_key
  ),
  n_rows  = NA_integer_
)
```

**Key naming convention confirmed:** `build_matrices()` ALWAYS formats keys as
`"{REP}_{YEAR}"` regardless of the `by` grouping argument (which belongs to
`batch_sube()`, not `build_matrices()`). This is consistent with the `ids`
derivation on line 66 and the naming on line 104.

**NULL filtering in build_matrices:** `Filter(Negate(is.null), matrices)` at
line 103 silently drops bundles where the dcast + alignment step returned NULL
(line 89–91: `anyNA(sup$CPAagg) || anyNA(use$CPAagg)`). These are ALSO dropped
country-years. The diff on `names(matrix_bundle$matrices)` vs. `input_keys`
catches ALL of them — both the correspondence-filter drops AND the dcast-alignment
NULLs.

---

### Detection Algorithm for D-8.11 #4 (`inputs_misaligned`)

The condition is: country-year present in BOTH `sut_data` (after
`extract_domestic_block`) AND `inputs` — but absent from `build_matrices()` output
`$model_data`.

Note that `model_data` is built inside `build_matrices()` only when `inputs != NULL`
(line 122). The model_data section uses `ids` (same post-correspondence-filter
ids) and returns NULL per group at lines 136 or 139 (empty inputs or empty SUB)
and at line 177 (anyNA(inp_aligned$GO)). The final `model_data` omits NULLs.

```r
# After build_matrices() with inputs != NULL:
sut_ids   <- unique(sut_data[, .(YEAR, REP)])
input_ids <- unique(inputs[, .(YEAR, REP)])

# Country-years in BOTH sut_data AND inputs
joint_ids <- merge(sut_ids, input_ids, by = c("YEAR", "REP"))

# Country-years present in model_data
if (nrow(matrix_bundle$model_data) > 0L) {
  model_ids <- unique(matrix_bundle$model_data[, .(YEAR, COUNTRY)])
  setnames(model_ids, "COUNTRY", "REP")
} else {
  model_ids <- data.table(YEAR = integer(), REP = character())
}

# Country-years present in joint but absent from model_data
misaligned <- anti_join(joint_ids, model_ids, by = c("YEAR", "REP"))
# or in data.table:
misaligned <- joint_ids[!model_ids, on = c("YEAR", "REP")]
```

Each misaligned row gets a `stage = "build"`, `status = "inputs_misaligned"`
diagnostic row.

---

### `tryCatch` Boundary for D-8.7

The `tryCatch` in `batch_sube()` wraps the **full `run_sube_pipeline()` call**
for each group, not individual pipeline stages. This is the right boundary
because:

1. `run_sube_pipeline()` is the complete unit of work per group; partial
   completions cannot be meaningfully assembled.
2. Catching at the full-call level means any error from any stage (import,
   build, compute) becomes a diagnostics row.

Pattern:
```r
group_result <- tryCatch(
  run_sube_pipeline(
    sut_data = group_slice,
    cpa_map  = cpa_map,
    ind_map  = ind_map,
    inputs   = group_inputs,
    ...
  ),
  error = function(e) {
    list(
      error_key = group_key,
      diagnostics = data.table(
        country = NA_character_,
        year    = NA_integer_,
        stage   = "pipeline",
        status  = "error",
        message = conditionMessage(e),
        n_rows  = NA_integer_
      )
    )
  }
)
```

**What should bubble up vs. become a diagnostic row:**

- Bubble up (re-throw): programming errors — wrong argument types, missing
  required columns in `sut_data` (these are caller mistakes, not data-quality
  issues). Validate `sut_data` shape BEFORE the loop, stop there.
- Diagnostic row: data-quality failures — singular matrices, alignment failures,
  unexpected numeric content. These are per-group issues, not caller mistakes.

In practice: validate `sut_data` class + required columns and `by` argument
BEFORE the loop, stop fast. Put `tryCatch` only around the per-group pipeline
call.

---

### `data.table::copy()` Placement (Pitfall 10)

**Verified risk locations:**

1. **`inputs` passed into `compute_sube()` per group:** `compute_sube()` calls
   `inputs <- .standardize_names(inputs)` at line 24, which reassigns the LOCAL
   variable (it calls `.as_data_table(data)` which uses `as.data.table()`, not
   `setDT()` on the original). BUT `.standardize_names()` calls `setnames(out, ...)` in-place. If `inputs` is already a data.table, `as.data.table(x)` returns the same object — `setnames` then modifies the original. **This is the live risk.** The outer loop passes the same `inputs` data.table to each group's pipeline call; if `setnames` mutates column names (e.g., uppercasing `go` → `GO`), the second iteration receives an already-uppercased version, which is benign but masked. More dangerous: if `setnames` renames `INDUSTRY` to something else per Pitfall 10 pattern.

2. **`sut_data` sliced per group:** If the batch function does
   `group_slice <- sut_data[REP %in% group_countries]`, this is a copy in
   data.table (subset returns new data.table). No copy needed here.

3. **`cpa_map` and `ind_map` inside `build_matrices()`:** `build_matrices()` calls
   `.coerce_map()` which calls `.standardize_names()` — same mutation risk on the
   map objects.

**RECOMMENDED copy() placement:**

```r
# At the top of batch_sube(), before the loop:
inputs   <- data.table::copy(.standardize_names(inputs))
cpa_map  <- data.table::copy(.standardize_names(cpa_map))
ind_map  <- data.table::copy(.standardize_names(ind_map))
```

Pre-normalizing and copying once outside the loop is safer than copying inside
the per-group call. Inside `run_sube_pipeline()`, the same pre-normalization
should happen for `inputs`, `cpa_map`, `ind_map` at function entry before
passing to the four-step chain.

---

### pkgdown Article Ordering (D-8.14)

Current `_pkgdown.yml` articles section (lines 36–56):
```yaml
articles:
  - title: Workflow Start Here
    navbar: Get started
    contents:
      - getting-started
  - title: Inputs and Preparation
    contents:
      - data-preparation
  - title: Modeling, Comparison, and Outputs
    contents:
      - modeling-and-outputs
  - title: Package Design and Paper Context
    contents:
      - package-design
  - title: Paper replication
    contents:
      - paper-replication
  - title: FIGARO workflow
    contents:
      - figaro-workflow
```

D-8.14 specifies: insert the new article "between 'Modeling, Comparison, and
Outputs' and 'Package Design and Paper Context'".

**Exact YAML snippet to insert after `modeling-and-outputs` group:**

```yaml
  - title: Pipeline Helpers
    contents:
      - pipeline-helpers
```

Result after insertion:
```yaml
articles:
  - title: Workflow Start Here
    navbar: Get started
    contents:
      - getting-started
  - title: Inputs and Preparation
    contents:
      - data-preparation
  - title: Modeling, Comparison, and Outputs
    contents:
      - modeling-and-outputs
  - title: Pipeline Helpers
    contents:
      - pipeline-helpers
  - title: Package Design and Paper Context
    contents:
      - package-design
  - title: Paper replication
    contents:
      - paper-replication
  - title: FIGARO workflow
    contents:
      - figaro-workflow
```

The reference section edit for D-8.13 adds two entries to the existing "Data
import and preparation" group (lines 11–17). Exact snippet:

```yaml
  - title: Data import and preparation
    contents:
      - import_suts
      - read_figaro
      - extract_domestic_block
      - sube_example_data
      - build_matrices
      - run_sube_pipeline
      - batch_sube
```

---

### `@examples` Runnable Budget

**Verification of `sube_example_data()` coverage:**

`sube_example_data("sut_data")` returns the long-format table at
`inst/extdata/sample/sut_data.csv`:
- 1 country (AAA), year 2020, 2 products (P1, P2), 2 industries (I1, I2)
- Already in long format with REP == PAR (already domestic) — confirmed by
  reading the CSV: all rows have `REP=AAA, PAR=AAA`

The four-step chain on this data works:
```r
sut  <- import_suts(system.file("extdata", "sample", "sut_data.csv", package="sube"))
dom  <- extract_domestic_block(sut)
mat  <- build_matrices(dom,
          sube_example_data("cpa_map"),
          sube_example_data("ind_map"))
res  <- compute_sube(mat, sube_example_data("inputs"))
```

This is verified by `test-workflow.R`'s passing tests.

**`run_sube_pipeline()` on `sube_example_data()`:**

The WIOD branch needs a `path` to a SUT file (D-8.1 is path-only). The sample
CSV is at `inst/extdata/sample/sut_data.csv`. A live `@examples` block can use:

```r
path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
result <- run_sube_pipeline(
  path    = path,
  cpa_map = sube_example_data("cpa_map"),
  ind_map = sube_example_data("ind_map"),
  inputs  = sube_example_data("inputs"),
  source  = "wiod"
)
```

This completes the full `import → domestic → build → compute` chain on example
data. The `domestic_only = TRUE` default calls `extract_domestic_block()`; since
the sample data is already domestic (REP == PAR throughout), this is a no-op
subset that still returns the right class.

**`batch_sube()` on `sube_example_data()`:**

The sample `sut_data` has only 1 country (AAA) × 1 year (2020). A live
`@examples` block can demonstrate `batch_sube()` on this single-group case. For
a multi-group example that actually batches, duplicate-year the sample data:

```r
sut <- sube_example_data("sut_data")
# For @examples, add a second year to show multi-group behavior
sut2 <- data.table::copy(sut)
sut2[, YEAR := 2021L]
sut_multi <- rbind(sut, sut2)
# Also need an inputs row for 2021
inp <- sube_example_data("inputs")
inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
inp_multi <- rbind(inp, inp2)
result <- batch_sube(sut_multi, sube_example_data("cpa_map"),
                     sube_example_data("ind_map"), inp_multi)
```

This avoids external data and runs in < 1 second.

---

### FIGARO-Path Runnable Test

**Verification of `inst/extdata/figaro-sample/` completeness:**

Contents: exactly TWO files:
- `flatfile_eu-ic-supply_sample.csv` — has required columns `refArea, rowPi,
  counterpartArea, colPi, obsValue`; 3 countries (DE, FR, IT); 8 CPA codes each
- `flatfile_eu-ic-use_sample.csv` — same schema; includes all 5 FD codes
  (P3_S13, P3_S14, P3_S15, P51G, P5M) — confirmed 120 matching rows

**The fixture does NOT include cpa_map, ind_map, or inputs.**

`build_figaro_pipeline_fixture_from_synthetic()` in `helper-gated-data.R`
(lines 80–111) builds these inline from the CPA codes present in the fixture data,
using section-letter aggregation. A `run_sube_pipeline(source = "figaro", ...)` test
must do the same or use pre-built maps. The test in `test-pipeline.R` should
mirror this helper.

**Conclusion:** `inst/extdata/figaro-sample/` has sufficient files for
`read_figaro(path = fixture_dir, year = 2023L)` to complete. The downstream
`extract_domestic_block → build_matrices → compute_sube` steps need externally
supplied `cpa_map`, `ind_map`, and `inputs` (as the existing test helper
constructs inline).

For a `run_sube_pipeline(source = "figaro", ...)` CRAN-safe test, the test file
must construct `cpa_map` and `ind_map` inline (section-letter pattern from the
fixture codes) and synthesize an `inputs` table — identical to
`build_figaro_pipeline_fixture_from_synthetic()`. The test helper in
`helper-gated-data.R` already exists for this purpose; `test-pipeline.R` can
call `build_figaro_pipeline_fixture_from_synthetic()` directly or inline the
equivalent logic.

---

## 5. Validation Architecture (Nyquist)

**Nyquist validation is enabled** (`workflow.nyquist_validation: true` in
`.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3 (edition 3) |
| Config file | `tests/testthat.R` (standard) |
| Quick run command | `testthat::test_file("tests/testthat/test-pipeline.R")` |
| Full suite command | `devtools::test()` or `R CMD check` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File | Automated Command | Notes |
|--------|----------|-----------|------|-------------------|-------|
| CONV-01 | `run_sube_pipeline()` returns `sube_pipeline_result` on sample data (WIOD) | unit | `test-pipeline.R` | `testthat::test_file(...)` | Must use `sube_example_data()` |
| CONV-01 | `run_sube_pipeline()` returns `sube_pipeline_result` on figaro-sample (FIGARO) | integration | `test-pipeline.R` | `testthat::test_file(...)` | Uses `build_figaro_pipeline_fixture_from_synthetic()` pattern |
| CONV-01 | `run_sube_pipeline()` with `estimate = TRUE` produces `$models` | unit | `test-pipeline.R` | `testthat::test_file(...)` | Uses `sube_example_data("model_data")` path |
| CONV-01 | `run_sube_pipeline()` upfront validation errors on bad `inputs` | unit | `test-pipeline.R` | `testthat::test_file(...)` | `expect_error(run_sube_pipeline(..., inputs = bad))` |
| CONV-02 | `batch_sube()` returns `sube_batch_result` on multi-year sample | unit | `test-pipeline.R` | `testthat::test_file(...)` | Duplicate year in sample data |
| CONV-02 | `batch_sube()` merges `$summary`, `$tidy`, `$diagnostics` across groups | contract | `test-pipeline.R` | `testthat::test_file(...)` | Assert `nrow($summary) >= 2` |
| CONV-02 | `batch_sube()` per-group error keeps loop going (D-8.7) | resilience | `test-pipeline.R` | `testthat::test_file(...)` | Force one group to error with bad inputs |
| CONV-03 | Diagnostic category: singular matrices pass-through | unit | `test-pipeline.R` | `testthat::test_file(...)` | Use `make_singular_supply_bundle()` pattern from `test-workflow.R:18` |
| CONV-03 | Diagnostic category: skipped country-year (D-8.9) | unit | `test-pipeline.R` | `testthat::test_file(...)` | Supply sut_data with country whose CPA codes have no cpa_map match |
| CONV-03 | Diagnostic category: coerced-NA at import (D-8.11 #3) | unit | `test-pipeline.R` | `testthat::test_file(...)` | Inject non-numeric VALUE into sample data |
| CONV-03 | Diagnostic category: inputs_misaligned (D-8.11 #4) | unit | `test-pipeline.R` | `testthat::test_file(...)` | Supply inputs with country present in sut but absent in build_matrices model_data |
| CONV-03 | Summary `warning()` emitted when diagnostics has non-ok rows | unit | `test-pipeline.R` | `testthat::test_file(...)` | `expect_warning(run_sube_pipeline(...))` |
| CONV-03 | No `warning()` emitted when all diagnostics are ok | unit | `test-pipeline.R` | `testthat::test_file(...)` | `expect_no_warning(run_sube_pipeline(...))` |

### 8 Nyquist Dimensions

**1. Happy-Path Validation**
- `run_sube_pipeline()` on `sube_example_data()` (WIOD, `source = "wiod"`):
  asserts `inherits(result, "sube_pipeline_result")`, `is.null(result$models)`,
  `nrow(result$diagnostics) > 0`, `all(result$diagnostics$status == "ok")`,
  `nrow(result$results$summary) > 0`, `!is.null(result$call)`
- `run_sube_pipeline()` on `inst/extdata/figaro-sample/` (FIGARO,
  `source = "figaro"`): same assertions + `nrow(result$results$summary)` covers
  DE, FR, IT
- `batch_sube()` on 2-year sample: asserts `inherits(result, "sube_batch_result")`,
  `length(result$results) == 2`, `nrow(result$summary) >= 2`, `nrow(result$tidy) > 0`

**2. Boundary Validation**
- Empty results when sut_data has no valid country-years after correspondence
  filter: pipeline must return zero-row `$results$summary` and a diagnostics row
  with `status = "skipped_alignment"`, not stop()
- Single-group batch: `batch_sube()` with one country-year must return
  `$results` list of length 1 and merged tables with correct dimensions
- All-groups-error batch: `batch_sube()` where every group fails in `tryCatch`
  must return a result (not stop()), with `$diagnostics` containing `n_errors`
  equal to number of groups and `$summary` / `$tidy` as empty data.tables

**3. Contract Validation (Return Shape)**
- `$diagnostics` column names: `expect_named(result$diagnostics, c("country", "year", "stage", "status", "message", "n_rows"))` (order matters for `rbindlist`)
- `$diagnostics` column types: `country` = character, `year` = integer, `stage` = character, `status` = character, `message` = character, `n_rows` = integer
- `$call` fields: `source`, `path`, `n_countries`, `n_years`, `estimate` all present
- `sube_batch_result$diagnostics` has `group_key` column in addition to base schema
- `batch_sube()` `$summary` has same columns as `compute_sube()$summary`

**4. Diagnostic Category Coverage**
- Each D-8.11 category gets a dedicated `test_that()` block that (a) produces
  the category, (b) asserts the correct `stage` + `status` values, (c) asserts
  `warning()` is emitted at the end. One test per category, four tests total.

**5. Regression Protection**
- `test-workflow.R`, `test-figaro-pipeline.R`, `test-figaro.R`,
  `test-replication.R`, `test-gated-data-contract.R` must all pass unchanged
  after Phase 8 is merged. The CI gate is `devtools::test()` green.
- Specifically: `compute_sube()` diagnostics table schema (`country`, `year`,
  `status`) remains unchanged (D-8.12 extends it without modifying compute.R).

**6. Resilience Validation**
- One group forced to error (e.g., `inputs` missing the group's `REP`):
  `batch_sube()` returns normally (no stop()), the failing group appears in
  `$diagnostics` with `stage = "pipeline"`, `status = "error"`, the error
  message is the original condition message, and `$call$n_errors == 1`.
- Summary `warning()` message names the failing group key.

**7. Integration Validation**
Since `sube_pipeline_result` does NOT inherit `sube_results`, integration tests
verify the explicit access path:
- `extract_leontief_matrices(result$results)` — must pass class check (result$results is sube_results)
- `prepare_sube_comparison(result$results, ...)` — same
- `filter_sube(result$results$tidy)` — must work (column-based, no class check)
- Inheritance is NOT tested (the decision is no-inheritance)

**8. Vignette Knit Validation**
- `vignettes/pipeline-helpers.Rmd` must knit under `R CMD check` with
  `eval = TRUE` chunks using only `sube_example_data()` data.
- Chunks for the FIGARO path and `\dontrun{}` blocks must be wrapped in
  `eval = FALSE` (per D-8.16 and D-8.14).
- Validation: `devtools::build_vignettes()` exits without error; the knitted
  HTML appears in `doc/`.

### Wave 0 Gaps

- [ ] `tests/testthat/test-pipeline.R` — new file, covers all 13 test cases above
- [ ] `vignettes/pipeline-helpers.Rmd` — new file (must knit cleanly)
- [ ] `R/pipeline.R` — new file (the implementation itself)
- [ ] No new test framework required; testthat 3 already installed

---

## 6. Risks and Pitfalls

### Risk 1: `data.table::copy()` in Batch Loop

**Described above (Open Item 4 / Additional Must).** The pattern:
```r
inputs <- .standardize_names(inputs)  # in compute_sube()
```
calls `as.data.table(x)` which returns the SAME object if already a data.table.
Then `setnames(out, names(out), toupper(names(out)))` modifies it in-place.
On the first iteration this is benign. On subsequent iterations with already-uppercased
names it is also benign. But any `setnames()` that changes a column name (not just
case) would persist. The safe path is `data.table::copy()` at the top of
`batch_sube()` on all shared mutable inputs.

**Severity:** Medium. Data.table mutation is subtle; the manifestation (second
group getting wrong column names) produces a hard-to-debug error mid-batch.

### Risk 2: `rbindlist` on Diagnostics with Unequal Schemas

In `batch_sube()`, the `$diagnostics` from each group may have different sets of
rows (some groups have `coerced_na` rows, some do not). `rbindlist(..., fill = TRUE)`
handles this correctly — missing columns are filled with NA. **Use `fill = TRUE`
everywhere in diagnostics rbindlist.**

For `n_rows`: groups without `coerced_na` rows will have `n_rows = NA_integer_`
throughout. When `rbindlist(fill = TRUE)` combines a group that has `n_rows = 5L`
with a group that has no `n_rows` column, the missing column becomes `NA` (not
an error) IF the column was declared as `integer()` in the schema. **Declare the
empty diagnostics table with explicit column types** to avoid type coercion on
first `rbindlist`.

```r
# Template empty diagnostics table with correct types:
.empty_diagnostics <- function() {
  data.table(
    country = character(),
    year    = integer(),
    stage   = character(),
    status  = character(),
    message = character(),
    n_rows  = integer()
  )
}
```

### Risk 3: NA in `year` Column after `rbindlist`

`rbindlist` on diagnostics where some rows have `year = NA_integer_` (pipeline-level
aggregates) and others have `year = 2020L` (compute-stage rows) is safe — integer
NAs are valid in data.table. Test the combined table with
`expect_type(result$diagnostics$year, "integer")`.

### Risk 4: Class Assignment Ordering

`compute_sube()` uses `class(out) <- c("sube_results", class(out))` which prepends
to the existing class vector (line 135). The pipeline constructors must do the same:
`class(out) <- c("sube_pipeline_result", "list")` (not `c("list", "sube_pipeline_result")`).
`inherits(x, "sube_pipeline_result")` checks the FIRST class match; reversing the
order would break future S3 dispatch if any method is ever added.

### Risk 5: `sube_example_data()` Is Not Path-Based

`run_sube_pipeline()` accepts a `path` argument and calls `import_suts()` (or
`read_figaro()`), NOT `sube_example_data()`. The sample `sut_data.csv` IS a valid
`import_suts()` input (it is in long CSV format). For `@examples`, use:
```r
path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
```
NOT `sube_example_data("sut_data")`. This is a subtle distinction — the example
data loader returns an in-memory data.table, while `run_sube_pipeline()` expects
a file path.

### Risk 6: Vignette Eval Budget

`sube_example_data()` has only 1 country × 2 products × 2 industries × 1 year.
`build_matrices()` produces 1 matrix bundle. `compute_sube()` runs in
milliseconds. The vignette's `eval = TRUE` chunks are within CRAN budget.

For the `batch_sube()` vignette section showing multiple groups, the 2-year trick
(duplicate sample data with YEAR=2021) works but produces artificial results.
The vignette should note this is illustrative. Alternatively, the FIGARO-sample
fixture (3 countries × 1 year) can be used for `batch_sube()` with
`source = "figaro"` — but `batch_sube()` operates on a pre-imported `sube_suts`,
not a path, so the vignette would call `read_figaro()` first, then `batch_sube()`.
The FIGARO path in the vignette should be `eval = FALSE` per D-8.14.

### Risk 7: `compute_sube()` Stops on Input-Alignment Error

Currently `compute_sube()` calls `stop()` (not a diagnostic row) when inputs do
not align with matrix industries (line 58–62). If `batch_sube()` relies on
`run_sube_pipeline()` to call `compute_sube()`, and `compute_sube()` stops, the
`tryCatch` in `batch_sube()` will catch it as a group-level error (correct
behavior per D-8.7). The pipeline-level inputs validation (Open Item 6) fires
before `build_matrices()` and `compute_sube()` are called, preventing this for
outright missing columns, but NOT for row-level misalignment (where the right
columns exist but the values do not match). The `tryCatch` boundary is the safety
net for this case.

---

## 7. Open Questions for the Planner

**Fully resolved — none that block task breakdown.**

Three items are planner preferences that research cannot settle, but all have
default recommendations:

1. **`domestic_only = TRUE` default in `run_sube_pipeline()` for FIGARO path.**
   `read_figaro()` returns MULTI-country data (all trading partners). If
   `domestic_only = TRUE`, `extract_domestic_block()` filters to REP == PAR, which
   is correct for domestic-production analysis. But for some FIGARO use cases a
   researcher might want the full international table. D-8.1 sets
   `domestic_only = TRUE` as the default — this is correct and locked. The
   planner should verify the vignette clarifies what "domestic" means for FIGARO.

2. **`group_key` column in `batch_sube()` `$diagnostics`** (D-8.6). The D-8.6
   spec says "a further `group_key` column is added when diagnostics are merged."
   The planner should decide whether this column is added to ALL rows (including
   pipeline-level aggregate rows from each group) or only to non-aggregate rows.
   Recommendation: add to ALL rows with `group_key = NA_character_` for pipeline-
   level aggregates (consistent with `country = NA` convention), and `group_key =
   "{REP}_{YEAR}"` (or the by-key) for all other rows.

3. **Whether to expose `run_sube_pipeline()` in `batch_sube()` as a dependency.**
   D-8.7 says each group's `run_sube_pipeline()` call is wrapped in `tryCatch` —
   implying `batch_sube()` calls `run_sube_pipeline()` per group. The alternative
   is to call the 4-step chain directly in `batch_sube()` without going through
   `run_sube_pipeline()`. The CONTEXT.md phrasing "each group's
   `run_sube_pipeline()` call is wrapped in `tryCatch`" strongly implies the
   former. This is a planner confirmation of a locked decision, not a new question.

---

## Sources

### Primary (HIGH confidence — codebase inspection)

All findings are based on direct codebase inspection via the Read tool at the
file:line references listed in Section 2. No external sources were needed or
consulted, as the phase operates entirely on the existing codebase.

- `R/compute.R` — diagnostics table schema, class assignment, inputs validation
- `R/matrices.R` — matrix naming, ids derivation, NULL filtering, model_data path
- `R/import.R` — read_figaro coercion point, primary-input drop ordering
- `R/filter_plot_export.R` — confirmed absence of UseMethod / class guards
- `R/paper_tools.R` — confirmed presence of .validate_class(sube_results)
- `R/utils.R` — .validate_class, .standardize_names, .sube_required_columns
- `tests/testthat/helper-gated-data.R` — figaro-sample usage pattern
- `inst/extdata/figaro-sample/` — file inventory, FD code presence
- `inst/extdata/sample/sut_data.csv` — single-country structure
- `_pkgdown.yml` — exact current YAML structure

### Confidence

| Area | Level | Reason |
|------|-------|--------|
| Class dispatch resolution | HIGH | Direct code inspection; no UseMethod found |
| Coerced-NA counting hook | HIGH | Traced exact line of as.numeric() in read_figaro() |
| Diagnostics schema | HIGH | Extended from verified compute_sube() schema |
| Progress reporting | HIGH | Confirmed zero message() calls in pipeline; package convention |
| Test file layout | HIGH | Counted lines in analogous files |
| Inputs validation | HIGH | Traced exact validation code in compute_sube() |
| data.table copy risk | HIGH | Traced .standardize_names() implementation |
| figaro-sample completeness | HIGH | Listed files, grepped for FD codes |
| pkgdown YAML | HIGH | Read exact current YAML; insertion point is unambiguous |

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (stable codebase; expires if Phase 8 contracts change)
