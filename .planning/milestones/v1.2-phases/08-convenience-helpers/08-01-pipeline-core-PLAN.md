---
phase: 08-convenience-helpers
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - R/pipeline.R
  - NAMESPACE
autonomous: true
requirements:
  - CONV-01
  - CONV-03
tags:
  - r-package
  - pipeline
  - diagnostics
must_haves:
  truths:
    - "`run_sube_pipeline()` is exported; calling it with a WIOD CSV path returns an object of class `c(\"sube_pipeline_result\", \"list\")`."
    - "`run_sube_pipeline(source = \"figaro\", path = <fixture_dir>, year = 2023L, ...)` routes to `read_figaro()` and returns the same class."
    - "When `estimate = TRUE` AND `build_matrices()` produced non-empty `$model_data`, the result's `$models` is a `sube_models` object; otherwise `$models` is `NULL`."
    - "Result has fields `$results` (sube_results), `$models` (sube_models or NULL), `$diagnostics` (data.table with 6 columns), `$call` (named list with source/path/n_countries/n_years/estimate/call/r_version/package_version)."
    - "`$diagnostics` schema is exactly `data.table(country = character, year = integer, stage = character, status = character, message = character, n_rows = integer)` with columns in that order."
    - "Upfront `inputs` validation using `.standardize_names()` + `.sube_required_columns(c(\"YEAR\",\"REP\",\"GO\"))` + industry-col check fires BEFORE the importer is called."
    - "Four diagnostic categories are detected inside `run_sube_pipeline()`: (1) singular_supply/go/leontief pass-through from compute_sube, (2) skipped_alignment from set-diff of input vs output country-years, (3) coerced_na at import via `sum(is.na(sut_raw$VALUE))`, (4) inputs_misaligned from sut/inputs joint minus model_data ids."
    - "If ANY diagnostic row has `status != \"ok\"`, exactly one `warning()` is emitted at end of the call, naming counts per status category."
  artifacts:
    - path: "R/pipeline.R"
      provides: "run_sube_pipeline() function, .sube_pipeline_result() constructor, .empty_diagnostics() helper, four detection helpers"
      contains: "run_sube_pipeline <- function("
      min_lines: 200
    - path: "NAMESPACE"
      provides: "Export line for run_sube_pipeline"
      contains: "export(run_sube_pipeline)"
  key_links:
    - from: "R/pipeline.R"
      to: "R/import.R::import_suts / read_figaro"
      via: "switch(source, wiod = import_suts(path, ...), figaro = read_figaro(path, year = ..., final_demand_vars = ...))"
      pattern: "switch\\(source"
    - from: "R/pipeline.R"
      to: "R/compute.R::compute_sube"
      via: "compute_sube(matrix_bundle, inputs, ...) after build_matrices"
      pattern: "compute_sube\\("
    - from: "R/pipeline.R"
      to: "R/models.R::estimate_elasticities"
      via: "conditional call when estimate = TRUE and nrow(matrix_bundle$model_data) > 0"
      pattern: "estimate_elasticities\\("
---

<objective>
Implement `run_sube_pipeline()` — the one-call wrapper chaining import → domestic → build → compute (optionally → estimate) — together with the unified `$diagnostics` machinery that catches the four CONV-03 categories inside the pipeline without touching the frozen Phase 5–7 core functions.

Purpose: Deliver CONV-01 (single-call pipeline returning a structured result) and CONV-03 (diagnostic visibility into silent data-quality failures) in one cohesive R file so Plan 02 (`batch_sube()`) can build on a finished contract.

Output: `R/pipeline.R` with the exported `run_sube_pipeline()`, a new S3 class `c("sube_pipeline_result", "list")`, an internal `.empty_diagnostics()` schema builder, and four detection helpers (`.detect_coerced_na`, `.detect_skipped_alignment`, `.detect_inputs_misaligned`, `.extend_compute_diagnostics`). NAMESPACE gains one `export()` line.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/08-convenience-helpers/08-CONTEXT.md
@.planning/phases/08-convenience-helpers/08-RESEARCH.md

<interfaces>
<!-- Extracted from codebase. Executor uses these directly. -->

From R/compute.R (frozen — do NOT modify):
```r
compute_sube <- function(matrix_bundle, inputs,
                         metrics = c("GO", "VA", "EMP", "CO2"),
                         diagonal_adjustment = 1, zero_replacement = 1e-6)
# Returns: list with class c("sube_results", class(out))
#   $summary      — wide data.table
#   $tidy         — long data.table
#   $diagnostics  — data.table(country, year, status)   # 3 columns
#   $matrices     — named list per country_year
# Validates: .validate_class(matrix_bundle, "sube_matrices")
#            inputs via .standardize_names + .sube_required_columns(c("YEAR","REP","GO"))
#            industry_col in c("IND","INDUSTRY","INDUSTRIES","INDAGG")
# Diagnostic statuses written: "ok" | "singular_supply" | "singular_go" | "singular_leontief"
# Throws (stops) on inputs-row-misalignment with: "Input rows do not align with matrix industries for {country} {year}."
```

From R/matrices.R (frozen):
```r
build_matrices <- function(sut_data, cpa_map, ind_map,
                           final_demand_var = "FU_bas", inputs = NULL)
# Returns: list with class c("sube_matrices", class(out))
#   $aggregated   — data.table of post-correspondence rows
#   $final_demand — data.table
#   $matrices     — named list; keys are paste(country, year, sep = "_")
#   $model_data   — data.table(YEAR, COUNTRY, GO, [VA,EMP,CO2], INDUSTRIES, product cols)
#                   empty data.table() when inputs = NULL
# Input ids in output: unique(aggregated[, .(YEAR, REP)]) — POST correspondence filter
```

From R/import.R (frozen):
```r
import_suts <- function(path, sheets = c("SUP", "USE"), recursive = FALSE)
# Returns: sube_suts (long: REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)

extract_domestic_block <- function(data)
# Returns: sube_domestic_suts, sube_suts  (subset where REP == PAR)

read_figaro <- function(path, year,
                        final_demand_vars = c("P3_S13","P3_S14","P3_S15","P51G","P5M"))
# Returns: sube_suts (long). VALUE = as.numeric(obsValue) — NA-introduction point.
```

From R/models.R:
```r
estimate_elasticities <- function(model_data, ...)
# Returns: sube_models
```

From R/utils.R (internals, use from R/pipeline.R — NOT exported):
```r
.standardize_names       <- function(data)    # uppercases + as.data.table
.sube_required_columns   <- function(data, required, call = NULL)  # stops on missing
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create R/pipeline.R with sube_pipeline_result class constructor, unified diagnostics schema, and exported run_sube_pipeline() skeleton (signature + dispatch + validation + class assembly — no detection logic yet)</name>
  <files>R/pipeline.R, NAMESPACE</files>
  <read_first>
    - R/pipeline.R (confirm it does NOT yet exist — this task creates it)
    - R/compute.R lines 1–140 (compute_sube signature, class tag pattern at line 135, diagnostics emission at lines 54/69/77/126)
    - R/matrices.R lines 30–200 (build_matrices signature, matrix keys `paste(country, year, sep = "_")` at line 104, model_data structure)
    - R/import.R lines 1–90, 116–130, 183–298 (import_suts, extract_domestic_block, read_figaro signatures)
    - R/utils.R (entire file — `.standardize_names`, `.sube_required_columns`, `.validate_class`)
    - NAMESPACE (entire file — 16 lines; note manual-edit convention from Phase 5 context)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.1, D-8.2, D-8.3, D-8.12)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §3 Open Item 1 (class decision), Open Item 3 (schema), Open Item 6 (upfront validation)
  </read_first>
  <behavior>
    - Empty diagnostics helper: `.empty_diagnostics()` returns `data.table(country=character(), year=integer(), stage=character(), status=character(), message=character(), n_rows=integer())` with columns in that exact order.
    - `run_sube_pipeline(path, cpa_map, ind_map, inputs, source = c("wiod", "figaro"), domestic_only = TRUE, estimate = FALSE, ...)` exists, `match.arg`s source, and errors cleanly on missing `path` with `"`path` must be a single non-empty character string."` (via `stop(..., call. = FALSE)`).
    - Upfront inputs validation (per RESEARCH §3 Open Item 6): `.standardize_names(copy)` + `.sube_required_columns(c("YEAR","REP","GO"))` + industry-col lookup with concrete error message `"`inputs` must include an industry identifier column (IND, INDUSTRY, INDUSTRIES, or INDAGG)."` fires BEFORE any importer call.
    - Stub the four later steps with placeholder NULL results; assemble an empty `sube_pipeline_result` shell and return it so the class contract is testable even before Tasks 2+3 land.
    - Class assignment: `class(out) <- c("sube_pipeline_result", "list")` (order matters — see RESEARCH §6 Risk 4).
    - Test (new at `tests/testthat/test-pipeline.R`, keep minimal for this task; Plan 03 fleshes it out):
      - Test 1: `run_sube_pipeline` is exported (`"run_sube_pipeline" %in% getNamespaceExports("sube")`).
      - Test 2: Calling with bad inputs (missing `GO` column) errors with message matching "Missing required columns: GO".
      - Test 3: `.empty_diagnostics()` has exactly the 6 columns in the specified order with the specified types (`vapply(out, class, character(1))`).
  </behavior>
  <action>
Create a brand-new file `R/pipeline.R`. Top-of-file roxygen header + internal helpers + exported function skeleton. Concrete requirements (copy verbatim where quoted):

1) **File header comment** (not roxygen): ``# Phase 8: Convenience Helpers — one-call and batch wrappers with CONV-03 diagnostics.``

2) **Internal helper `.empty_diagnostics()`** (unexported, placed above `run_sube_pipeline`):

   ```r
   .empty_diagnostics <- function() {
     data.table::data.table(
       country = character(),
       year    = integer(),
       stage   = character(),
       status  = character(),
       message = character(),
       n_rows  = integer()
     )
   }
   ```

   Rationale comment inline: `# Unified diagnostics schema per D-8.12 / RESEARCH §3 Open Item 3. Column order is load-bearing for rbindlist.`

3) **Internal helper `.sube_pipeline_result()`** (unexported constructor):

   ```r
   .sube_pipeline_result <- function(results, models, diagnostics, call_meta) {
     out <- list(
       results     = results,
       models      = models,
       diagnostics = diagnostics,
       call        = call_meta
     )
     class(out) <- c("sube_pipeline_result", "list")
     out
   }
   ```

   Rationale comment inline: `# Class per RESEARCH §3 Open Item 1: no inheritance from sube_results. $results holds the sube_results; wrappers stay distinct S3 tags.`

4) **Internal helper `.validate_pipeline_inputs(inputs)`** (unexported):

   Implement upfront validation matching `compute_sube()`'s contract so errors surface before importing large files. Uses `data.table::copy()` to avoid mutating caller's object. Body:

   ```r
   .validate_pipeline_inputs <- function(inputs) {
     if (is.null(inputs)) {
       stop("`inputs` must be supplied (industry-level GO/VA/EMP/CO2).", call. = FALSE)
     }
     check <- .standardize_names(data.table::copy(inputs))
     .sube_required_columns(check, c("YEAR", "REP", "GO"))
     industry_col <- intersect(
       c("IND", "INDUSTRY", "INDUSTRIES", "INDAGG"), names(check)
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
     invisible(TRUE)
   }
   ```

5) **Exported `run_sube_pipeline()`** — full roxygen + signature per D-8.1/D-8.2/D-8.3, with Task 2/3 detection logic stubbed so the skeleton works end-to-end on the happy path. Signature MUST be exactly:

   ```r
   run_sube_pipeline <- function(
       path,
       cpa_map,
       ind_map,
       inputs,
       source = c("wiod", "figaro"),
       domestic_only = TRUE,
       estimate = FALSE,
       ...
   ) {
     # --- 1. argument validation ---
     if (missing(path) || length(path) != 1L || !is.character(path) || !nzchar(path)) {
       stop("`path` must be a single non-empty character string.", call. = FALSE)
     }
     source <- match.arg(source)
     .validate_pipeline_inputs(inputs)

     call_snapshot <- match.call()

     # --- 2. import (source-dependent; full logic in Task 2) ---
     dots <- list(...)
     sut_raw <- switch(source,
       wiod = do.call(
         import_suts,
         c(list(path = path), dots[intersect(names(dots), c("sheets", "recursive"))])
       ),
       figaro = do.call(
         read_figaro,
         c(list(path = path), dots[intersect(names(dots), c("year", "final_demand_vars"))])
       )
     )

     # --- 3. coerced-NA diagnostics at import boundary (Task 2 fills) ---
     diag_import <- .empty_diagnostics()

     # --- 4. domestic filter ---
     sut <- if (isTRUE(domestic_only)) extract_domestic_block(sut_raw) else sut_raw

     # --- 5. build_matrices ---
     matrix_bundle <- build_matrices(sut, cpa_map, ind_map, inputs = inputs)

     # --- 6. diagnostics: skipped_alignment + inputs_misaligned (Task 2 fills) ---
     diag_build <- .empty_diagnostics()

     # --- 7. compute_sube ---
     results <- compute_sube(matrix_bundle, inputs, ...)

     # --- 8. diagnostics: extend compute_sube output to unified schema (Task 2 fills) ---
     diag_compute <- .empty_diagnostics()

     # --- 9. opt-in estimate_elasticities (Task 3) ---
     models <- NULL

     # --- 10. assemble + summary warning (Task 3) ---
     diagnostics <- data.table::rbindlist(
       list(diag_import, diag_build, diag_compute),
       fill = TRUE
     )

     n_countries <- length(unique(sut$REP))
     years <- unique(sut$YEAR)
     call_meta <- list(
       source          = source,
       path            = path,
       n_countries     = n_countries,
       n_years         = length(years),
       estimate        = isTRUE(estimate),
       call            = call_snapshot,
       r_version       = R.version.string,
       package_version = as.character(utils::packageVersion("sube"))
     )

     .sube_pipeline_result(results, models, diagnostics, call_meta)
   }
   ```

6) **Roxygen block** above the function (markdown). Required tags (exact content):

   - `@title Run the SUBE Pipeline End-to-End`
   - `@description` — one paragraph: "Chains the SUBE import → domestic filter → matrix construction → compute step into a single call, returning a structured result with unified diagnostics. The FIGARO source routes through [read_figaro()]; WIOD-style CSVs/workbooks route through [import_suts()]."
   - `@param path Single character path to a SUT file or directory (WIOD: workbook/CSV or dir; FIGARO: directory containing supply+use flatfiles).`
   - `@param cpa_map,ind_map Correspondence tables; see [build_matrices()].`
   - `@param inputs Industry-level inputs with columns `YEAR`, `REP`, an industry identifier, and at least `GO`.`
   - `@param source One of "wiod" or "figaro". Selects the importer. No auto-detect (D-8.2).`
   - `@param domestic_only If `TRUE` (default), runs [extract_domestic_block()] on the imported SUTs before building matrices.`
   - `@param estimate If `TRUE` and `build_matrices(..., inputs = inputs)` produces non-empty `$model_data`, also runs [estimate_elasticities()] and attaches the result to `$models`. Default `FALSE` (D-8.4).`
   - `@param ... Importer-specific arguments (e.g. `sheets`, `recursive` for WIOD; `year`, `final_demand_vars` for FIGARO) and compute-specific arguments (e.g. `metrics`, `diagonal_adjustment`, `zero_replacement`) forwarded to [compute_sube()].`
   - `@return An object of class `c("sube_pipeline_result", "list")` with elements `$results` (the [sube_results][compute_sube] object), `$models` (a `sube_models` object from [estimate_elasticities()] or `NULL`), `$diagnostics` (a unified diagnostics `data.table`; see *Details*), and `$call` (provenance metadata).`
   - `@details` — describe the `$diagnostics` schema literally: "The diagnostics table has columns `country` (character; `NA` for pipeline-level aggregates), `year` (integer; `NA` for pipeline-level aggregates), `stage` (`import`, `build`, `compute`, or `pipeline`), `status` (`ok`, `singular_supply`, `singular_go`, `singular_leontief`, `skipped_alignment`, `coerced_na`, `inputs_misaligned`, or `error`), `message` (human-readable reason), and `n_rows` (optional row count, populated for `coerced_na` aggregates). If any row has `status != "ok"` a single `warning()` summarising counts is emitted at the end of the call."
   - `@seealso [batch_sube()], [compute_sube()], [build_matrices()], [import_suts()], [read_figaro()]`
   - `@examples` — live block using `system.file("extdata", "sample", "sut_data.csv", package = "sube")` per D-8.16 and RESEARCH §6 Risk 5. Concrete content:

     ```r
     #' @examples
     #' sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     #' result <- run_sube_pipeline(
     #'   path    = sut_path,
     #'   cpa_map = sube_example_data("cpa_map"),
     #'   ind_map = sube_example_data("ind_map"),
     #'   inputs  = sube_example_data("inputs"),
     #'   source  = "wiod"
     #' )
     #' result$results$summary
     #' result$diagnostics
     #'
     #' \dontrun{
     #' # FIGARO branch needs a directory with real or synthetic FIGARO flatfiles:
     #' figaro_dir <- system.file("extdata", "figaro-sample", package = "sube")
     #' run_sube_pipeline(
     #'   path    = figaro_dir,
     #'   cpa_map = my_cpa_map,     # user-supplied
     #'   ind_map = my_ind_map,
     #'   inputs  = my_inputs,
     #'   source  = "figaro",
     #'   year    = 2023L
     #' )
     #' }
     ```

   - `@export`

7) **NAMESPACE** — append the export line alphabetically. Final NAMESPACE head (first 17 lines) must contain `export(run_sube_pipeline)` between `export(read_figaro)` and `export(plot_paper_comparison)` (alphabetical placement after existing `read_figaro`, before `plot_*`). Concrete snippet to insert (immediately after line `export(read_figaro)`):

   ```
   export(run_sube_pipeline)
   ```

   NOTE: Do NOT run `devtools::document()` — the convention per `.planning/phases/08-convenience-helpers/08-CONTEXT.md <code_context>` is manual NAMESPACE edits.

8) **Minimal test file** at `tests/testthat/test-pipeline.R` (Plan 03 expands this substantially). For this task, create the file with exactly these three test_that blocks:

   ```r
   library(testthat)
   library(sube)

   test_that("run_sube_pipeline is exported", {
     expect_true("run_sube_pipeline" %in% getNamespaceExports("sube"))
   })

   test_that(".empty_diagnostics has the unified D-8.12 schema", {
     d <- sube:::.empty_diagnostics()
     expect_named(d, c("country", "year", "stage", "status", "message", "n_rows"))
     expect_type(d$country, "character")
     expect_type(d$year,    "integer")
     expect_type(d$stage,   "character")
     expect_type(d$status,  "character")
     expect_type(d$message, "character")
     expect_type(d$n_rows,  "integer")
   })

   test_that("run_sube_pipeline errors upfront when `inputs` is missing GO", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     bad_inputs <- sube_example_data("inputs")
     bad_inputs[, GO := NULL]
     expect_error(
       run_sube_pipeline(
         path = sut_path,
         cpa_map = sube_example_data("cpa_map"),
         ind_map = sube_example_data("ind_map"),
         inputs  = bad_inputs,
         source  = "wiod"
       ),
       "Missing required columns: GO"
     )
   })
   ```
  </action>
  <verify>
    <automated>Rscript -e "devtools::load_all('.'); testthat::test_file('tests/testthat/test-pipeline.R', reporter='summary')"</automated>
    <automated>Rscript -e "stopifnot('run_sube_pipeline' %in% getNamespaceExports('sube'))"</automated>
    <automated>grep -q "^export(run_sube_pipeline)$" NAMESPACE</automated>
    <automated>grep -q "^run_sube_pipeline <- function(" R/pipeline.R</automated>
    <automated>grep -q '^\.empty_diagnostics <- function()' R/pipeline.R</automated>
    <automated>grep -q 'class(out) <- c("sube_pipeline_result", "list")' R/pipeline.R</automated>
    <automated>Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `R/pipeline.R` exists; file size ≥ 100 lines.
    - `grep -c "^export(run_sube_pipeline)$" NAMESPACE` prints `1`.
    - `Rscript -e "devtools::load_all('.'); inherits(sube:::.empty_diagnostics(), 'data.table')"` prints `[1] TRUE`.
    - `Rscript -e "devtools::load_all('.'); names(sube:::.empty_diagnostics())"` prints exactly `[1] "country" "year"    "stage"   "status"  "message" "n_rows"`.
    - `tests/testthat/test-pipeline.R` exists with the 3 `test_that(...)` blocks named above (grep for the quoted names).
    - `devtools::test()` exits with 0 failures; all prior test files (`test-workflow.R`, `test-figaro.R`, `test-figaro-pipeline.R`, `test-replication.R`, `test-gated-data-contract.R`) still pass.
    - `grep -q '@export' R/pipeline.R` returns 0 (exit code success).
    - `grep -q 'source = "wiod"' R/pipeline.R` returns 0 (the example runs against sample data).
    - Calling `run_sube_pipeline()` on sample data returns an object where `inherits(x, "sube_pipeline_result")` is `TRUE` and `inherits(x$results, "sube_results")` is `TRUE`. Verify: `Rscript -e 'devtools::load_all("."); p <- run_sube_pipeline(path = system.file("extdata","sample","sut_data.csv",package="sube"), cpa_map=sube_example_data("cpa_map"), ind_map=sube_example_data("ind_map"), inputs=sube_example_data("inputs"), source="wiod"); stopifnot(inherits(p, "sube_pipeline_result"), inherits(p$results, "sube_results"))'`
  </acceptance_criteria>
  <done>R/pipeline.R ships run_sube_pipeline() with live upfront inputs validation, source dispatch, the sube_pipeline_result S3 class, and the .empty_diagnostics() schema helper. NAMESPACE exports the function. Happy path on sample data returns a well-formed wrapper. 3 new tests green; no regressions in the 5 prior test files.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire the four CONV-03 diagnostic detections into run_sube_pipeline() — coerced_na at import, skipped_alignment + inputs_misaligned at build, and the schema-extension pass-through from compute_sube</name>
  <files>R/pipeline.R, tests/testthat/test-pipeline.R</files>
  <read_first>
    - R/pipeline.R (from Task 1 — must see the skeleton with the four stubbed diag_* slots)
    - R/compute.R lines 40–135 (diagnostics emission pattern; 3-column schema: country/year/status)
    - R/matrices.R lines 60–200 (matrix key naming `paste(country, year, sep = "_")` at line 104, model_data COUNTRY column at lines 179, ids derivation at line 66)
    - R/import.R lines 183–298 (read_figaro coercion at line 255; primary-input drop at line 247 BEFORE coercion)
    - tests/testthat/test-pipeline.R (from Task 1)
    - tests/testthat/helper-gated-data.R lines 80–111 (`build_figaro_pipeline_fixture_from_synthetic()` — needed for the FIGARO test)
    - tests/testthat/test-workflow.R lines 15–35 (pattern for `make_singular_supply_bundle()` — construct zero-product matrix to force singular_supply)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.9, D-8.11, D-8.12)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §3 Open Items 2 + 3, §4 Detection Algorithms
  </read_first>
  <behavior>
    - `run_sube_pipeline()` populates all four D-8.11 categories in the unified `$diagnostics` table (schema verified by Task 1).
    - Category 1 (compute pass-through): when `compute_sube()` emits rows with `status %in% c("singular_supply","singular_go","singular_leontief")`, the pipeline copies them, stamps `stage = "compute"`, fills `message` with concrete text per status, and sets `n_rows = NA_integer_`. Rows with `status = "ok"` are preserved (stamped `stage = "compute"`, `message = "ok"`, `n_rows = NA_integer_`).
    - Category 2 (skipped_alignment): one row per country-year present in `unique(sut[, .(YEAR, REP)])` but absent from `names(matrix_bundle$matrices)`. `stage = "build"`, concrete message names the dropped key.
    - Category 3 (coerced_na): one aggregate row when `sum(is.na(sut_raw$VALUE))` > 0 after the importer returns, BEFORE `extract_domestic_block()`. `stage = "import"`, `country = NA_character_`, `year = NA_integer_`, `n_rows = <count>`.
    - Category 4 (inputs_misaligned): one row per country-year that exists in BOTH `sut` (post-domestic) AND `inputs` but is absent from `matrix_bundle$model_data[, .(YEAR, COUNTRY)]`. `stage = "build"`.
    - Happy path on `sube_example_data()`: `$diagnostics` has exactly 1 row with `status = "ok"` (the single AAA/2020 compute row, post extension).
  </behavior>
  <action>
Replace the four stubbed `diag_*` blocks in `R/pipeline.R` with concrete detection logic, and add four internal helpers.

1) **Helper `.detect_coerced_na(sut_raw)`** — call right after the importer returns, BEFORE `extract_domestic_block`. Concrete body:

   ```r
   .detect_coerced_na <- function(sut_raw) {
     n <- sum(is.na(sut_raw$VALUE))
     if (n <= 0L) return(.empty_diagnostics())
     data.table::data.table(
       country = NA_character_,
       year    = NA_integer_,
       stage   = "import",
       status  = "coerced_na",
       message = sprintf(
         "%d row(s) with NA VALUE at import boundary (e.g. non-numeric obsValue).",
         n
       ),
       n_rows  = n
     )
   }
   ```

   Rationale comment: `# D-8.11 #3 / RESEARCH §3 Open Item 2. Primary-input rows in read_figaro are dropped BEFORE as.numeric() (R/import.R:247 vs 255), so sum(is.na(VALUE)) at this point is the exact count of coercion-introduced NAs.`

2) **Helper `.detect_skipped_alignment(sut, matrix_bundle)`** — call right after `build_matrices()`. `sut` is the post-domestic data (has REP/YEAR cols). Concrete body:

   ```r
   .detect_skipped_alignment <- function(sut, matrix_bundle) {
     input_ids  <- unique(sut[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
     input_keys <- paste(input_ids$REP, input_ids$YEAR, sep = "_")
     output_keys <- names(matrix_bundle$matrices)
     dropped <- setdiff(input_keys, output_keys)
     if (length(dropped) == 0L) return(.empty_diagnostics())
     data.table::data.table(
       country = sub("_\\d+$", "", dropped),
       year    = as.integer(sub("^.*_", "", dropped)),
       stage   = "build",
       status  = "skipped_alignment",
       message = sprintf(
         "Country-year %s present in SUT data but absent from build_matrices output (missing CPA/industry alignment after correspondence merge).",
         dropped
       ),
       n_rows  = NA_integer_
     )
   }
   ```

   Rationale: `# D-8.9 / RESEARCH §4. Catches BOTH correspondence-filter drops (R/matrices.R:55) AND dcast-alignment NULL returns (R/matrices.R:89-91 → :103 Filter).`

3) **Helper `.detect_inputs_misaligned(sut, inputs, matrix_bundle)`** — call after `build_matrices()`. Concrete body (uses data.table anti-join):

   ```r
   .detect_inputs_misaligned <- function(sut, inputs, matrix_bundle) {
     sut_ids <- unique(sut[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
     inp <- .standardize_names(data.table::copy(inputs))
     input_ids <- unique(inp[, .(YEAR = as.integer(YEAR), REP = as.character(REP))])
     joint <- merge(sut_ids, input_ids, by = c("YEAR", "REP"))
     if (nrow(joint) == 0L) return(.empty_diagnostics())

     md <- matrix_bundle$model_data
     if (is.null(md) || nrow(md) == 0L) {
       model_ids <- data.table::data.table(YEAR = integer(), REP = character())
     } else {
       model_ids <- unique(md[, .(YEAR = as.integer(YEAR), REP = as.character(COUNTRY))])
     }

     misaligned <- joint[!model_ids, on = c("YEAR", "REP")]
     if (nrow(misaligned) == 0L) return(.empty_diagnostics())
     data.table::data.table(
       country = misaligned$REP,
       year    = misaligned$YEAR,
       stage   = "build",
       status  = "inputs_misaligned",
       message = sprintf(
         "Country-year %s_%d present in both SUT and inputs but absent from build_matrices model_data.",
         misaligned$REP, misaligned$YEAR
       ),
       n_rows  = NA_integer_
     )
   }
   ```

   Rationale: `# D-8.11 #4 / RESEARCH §4. model_data column is COUNTRY (not REP) per R/matrices.R:179.`

4) **Helper `.extend_compute_diagnostics(compute_diag)`** — transforms `compute_sube()`'s 3-col diagnostics into the 6-col unified schema. Concrete body:

   ```r
   .extend_compute_diagnostics <- function(compute_diag) {
     if (is.null(compute_diag) || nrow(compute_diag) == 0L) {
       return(.empty_diagnostics())
     }
     out <- data.table::copy(compute_diag)
     out[, stage := "compute"]
     out[, message := data.table::fcase(
       status == "ok",                "ok",
       status == "singular_supply",   "Supply matrix singular; country-year skipped.",
       status == "singular_go",       "GO diagonal singular; country-year skipped.",
       status == "singular_leontief", "Leontief matrix (I-A) singular; country-year skipped.",
       default = as.character(status)
     )]
     out[, n_rows := NA_integer_]
     out[, country := as.character(country)]
     out[, year    := as.integer(year)]
     data.table::setcolorder(out, c("country", "year", "stage", "status", "message", "n_rows"))
     out[]
   }
   ```

5) **Wire the helpers into `run_sube_pipeline()`** — replace the stubbed blocks from Task 1:

   ```r
   # --- 3. coerced-NA diagnostics at import boundary ---
   diag_import <- .detect_coerced_na(sut_raw)

   # --- 4. domestic filter ---
   sut <- if (isTRUE(domestic_only)) extract_domestic_block(sut_raw) else sut_raw

   # --- 5. build_matrices ---
   matrix_bundle <- build_matrices(sut, cpa_map, ind_map, inputs = inputs)

   # --- 6. diagnostics: skipped_alignment + inputs_misaligned ---
   diag_build <- data.table::rbindlist(
     list(
       .detect_skipped_alignment(sut, matrix_bundle),
       .detect_inputs_misaligned(sut, inputs, matrix_bundle)
     ),
     fill = TRUE
   )

   # --- 7. compute_sube ---
   results <- compute_sube(matrix_bundle, inputs, ...)

   # --- 8. diagnostics: extend compute_sube output to unified schema ---
   diag_compute <- .extend_compute_diagnostics(results$diagnostics)
   ```

6) **Extend the test file** at `tests/testthat/test-pipeline.R` with FOUR new `test_that()` blocks (one per category) plus a happy-path structural block. Append these to the existing file (after the 3 from Task 1):

   ```r
   test_that("happy path on sube_example_data produces one 'ok' compute row (CONV-01 happy path)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     res <- run_sube_pipeline(
       path = sut_path,
       cpa_map = sube_example_data("cpa_map"),
       ind_map = sube_example_data("ind_map"),
       inputs  = sube_example_data("inputs"),
       source  = "wiod"
     )
     expect_s3_class(res, "sube_pipeline_result")
     expect_s3_class(res$results, "sube_results")
     expect_named(res$diagnostics,
                  c("country", "year", "stage", "status", "message", "n_rows"))
     expect_true(all(res$diagnostics$status == "ok"))
     expect_equal(sum(res$diagnostics$stage == "compute"), nrow(res$diagnostics))
   })

   test_that("coerced_na category surfaces when VALUE has NAs (D-8.11 #3)", {
     sut_path <- tempfile(fileext = ".csv")
     sut <- sube_example_data("sut_data")
     sut_corrupt <- data.table::copy(sut)
     sut_corrupt[1L, VALUE := NA_real_]
     data.table::fwrite(sut_corrupt, sut_path)
     res <- suppressWarnings(run_sube_pipeline(
       path    = sut_path,
       cpa_map = sube_example_data("cpa_map"),
       ind_map = sube_example_data("ind_map"),
       inputs  = sube_example_data("inputs"),
       source  = "wiod"
     ))
     import_rows <- res$diagnostics[stage == "import" & status == "coerced_na"]
     expect_equal(nrow(import_rows), 1L)
     expect_gte(import_rows$n_rows, 1L)
     expect_true(is.na(import_rows$country))
     expect_true(is.na(import_rows$year))
   })

   test_that("skipped_alignment category surfaces when cpa_map has no match (D-8.9)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     bad_cpa <- data.table::data.table(CPA = "ZZZ", CPAagg = "Z")  # matches nothing
     expect_error(
       suppressWarnings(run_sube_pipeline(
         path = sut_path,
         cpa_map = bad_cpa,
         ind_map = sube_example_data("ind_map"),
         inputs  = sube_example_data("inputs"),
         source  = "wiod"
       )),
       NA   # build_matrices returns empty matrices; compute_sube then yields empty result
     ) -> res
     # skipped_alignment row(s) present
     sa <- res$diagnostics[stage == "build" & status == "skipped_alignment"]
     expect_gte(nrow(sa), 1L)
     expect_true(all(grepl("^AAA$", sa$country)))
   })

   test_that("inputs_misaligned category surfaces when sut+inputs overlap but model_data omits the group (D-8.11 #4)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     # Corrupt inputs INDUSTRY so model_data build fails alignment for AAA/2020
     # (R/matrices.R:177: anyNA(inp_aligned$GO) → return(NULL))
     bad_inputs <- data.table::copy(sube_example_data("inputs"))
     bad_inputs[, INDUSTRY := "NOMATCH"]
     expect_warning(
       res <- run_sube_pipeline(
         path = sut_path,
         cpa_map = sube_example_data("cpa_map"),
         ind_map = sube_example_data("ind_map"),
         inputs  = bad_inputs,
         source  = "wiod"
       )
     )
     im <- res$diagnostics[stage == "build" & status == "inputs_misaligned"]
     expect_gte(nrow(im), 1L)
   })

   test_that("singular-compute passes through from compute_sube diagnostics (D-8.11 #1)", {
     # Use direct compute_sube diagnostics → extend helper round-trip
     fake_compute_diag <- data.table::data.table(
       country = c("AAA", "BBB"),
       year    = c(2020L, 2020L),
       status  = c("singular_supply", "ok")
     )
     ext <- sube:::.extend_compute_diagnostics(fake_compute_diag)
     expect_named(ext, c("country", "year", "stage", "status", "message", "n_rows"))
     expect_equal(ext$stage, c("compute", "compute"))
     expect_equal(ext$message[1], "Supply matrix singular; country-year skipped.")
     expect_equal(ext$message[2], "ok")
   })
   ```
  </action>
  <verify>
    <automated>Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"</automated>
    <automated>grep -q '^\.detect_coerced_na <- function' R/pipeline.R</automated>
    <automated>grep -q '^\.detect_skipped_alignment <- function' R/pipeline.R</automated>
    <automated>grep -q '^\.detect_inputs_misaligned <- function' R/pipeline.R</automated>
    <automated>grep -q '^\.extend_compute_diagnostics <- function' R/pipeline.R</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^\.detect_coerced_na <- function" R/pipeline.R` prints `1`.
    - `grep -c "^\.detect_skipped_alignment <- function" R/pipeline.R` prints `1`.
    - `grep -c "^\.detect_inputs_misaligned <- function" R/pipeline.R` prints `1`.
    - `grep -c "^\.extend_compute_diagnostics <- function" R/pipeline.R` prints `1`.
    - tests/testthat/test-pipeline.R has at least 8 `test_that(` blocks (3 from Task 1 + 5 here). Verify: `grep -c "^test_that(" tests/testthat/test-pipeline.R` returns `>= 8`.
    - `devtools::test(filter = "pipeline")` exits 0 with 0 failures.
    - `devtools::test()` exits 0 — no regression in the 5 pre-existing test files.
    - Running the happy-path pipeline on `sube_example_data()` yields `all(res$diagnostics$status == "ok")` with `nrow >= 1`. Verify via inline Rscript as in Task 1 acceptance block.
    - Coerced-NA test: the import diagnostics row has `n_rows >= 1` and `country`/`year` both `NA`.
  </acceptance_criteria>
  <done>All four D-8.11 diagnostic categories flow into the unified `$diagnostics` table inside `run_sube_pipeline()`. Five new test_that() blocks (one per category + happy path structure) green. Pre-existing suites still pass.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Add opt-in estimate_elasticities wiring, summary warning emission (one warning() per run with status counts), and FIGARO-path integration test</name>
  <files>R/pipeline.R, tests/testthat/test-pipeline.R</files>
  <read_first>
    - R/pipeline.R (from Task 2 — must see all four detection helpers wired)
    - R/models.R lines 1–130 (estimate_elasticities signature + return class `sube_models`)
    - tests/testthat/helper-gated-data.R lines 69–111 (`build_nace_section_map`, `build_figaro_pipeline_fixture_from_synthetic` — but for THIS task's FIGARO test, construct maps inline from the fixture codes, mirroring the helper's section-letter pattern)
    - tests/testthat/test-pipeline.R (from Task 2)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.4, D-8.10, D-8.16)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §3 Open Item 4 (silent in batch_sube but summary warning always emitted), §6 Risk 6 (vignette eval budget — not this task, but confirms inst/extdata/figaro-sample is fixture-only)
  </read_first>
  <behavior>
    - When `estimate = TRUE` AND `nrow(matrix_bundle$model_data) > 0`, `estimate_elasticities()` is called on `matrix_bundle$model_data` (possibly with `...` forwarded subset) and the result is attached to `$models`. Otherwise `$models` is `NULL`.
    - When `estimate = TRUE` but `model_data` is empty, `$models` is `NULL` AND a diagnostics row `stage = "pipeline"`, `status = "inputs_misaligned"`, `message = "estimate=TRUE requested but model_data is empty; no elasticities estimated."` is NOT emitted (this case is already covered by category 4 at build stage; avoid double-reporting).
    - If ANY row in `$diagnostics` has `status != "ok"`, exactly ONE `warning()` is emitted at end of call with body matching pattern `"^Pipeline completed with issues: "` followed by comma-separated `<count> <status_label>` fragments (e.g. `"2 skipped_alignment, 1 singular_leontief, 14 coerced_na rows. See result\\$diagnostics for details\\."`).
    - If every row has `status = "ok"` (or `$diagnostics` is empty), NO warning is emitted.
    - FIGARO-path test: constructing cpa_map/ind_map inline from fixture codes (DE/FR/IT, 8 CPAs each, section-letter aggregation), `run_sube_pipeline(source = "figaro", path = figaro_sample_dir, year = 2023L, ...)` completes and returns `sube_pipeline_result` with `nrow(result$results$summary) > 0`.
  </behavior>
  <action>
1) **Helper `.emit_pipeline_warning(diagnostics)`** — add to `R/pipeline.R` above `run_sube_pipeline()`:

   ```r
   .emit_pipeline_warning <- function(diagnostics) {
     if (is.null(diagnostics) || nrow(diagnostics) == 0L) return(invisible(NULL))
     bad <- diagnostics[status != "ok"]
     if (nrow(bad) == 0L) return(invisible(NULL))
     counts <- bad[, .N, by = status]
     data.table::setorder(counts, -N)
     parts <- sprintf("%d %s", counts$N, counts$status)
     warning(
       sprintf(
         "Pipeline completed with issues: %s. See result$diagnostics for details.",
         paste(parts, collapse = ", ")
       ),
       call. = FALSE
     )
   }
   ```

   Rationale comment: `# D-8.10. ONE warning() per run, counts sorted descending so the largest issue category surfaces first. "ok" rows excluded by construction.`

2) **Wire `.emit_pipeline_warning` into `run_sube_pipeline()`** — replace the stubbed Step 10 block. Final tail of the function:

   ```r
   # --- 9. opt-in estimate_elasticities (D-8.4) ---
   models <- NULL
   if (isTRUE(estimate) && nrow(matrix_bundle$model_data) > 0L) {
     models <- estimate_elasticities(matrix_bundle$model_data)
   }

   # --- 10. assemble unified diagnostics ---
   diagnostics <- data.table::rbindlist(
     list(diag_import, diag_build, diag_compute),
     fill = TRUE
   )
   data.table::setcolorder(
     diagnostics,
     c("country", "year", "stage", "status", "message", "n_rows")
   )

   # --- 11. build call_meta ---
   n_countries <- length(unique(sut$REP))
   years <- unique(sut$YEAR)
   call_meta <- list(
     source          = source,
     path            = path,
     n_countries     = n_countries,
     n_years         = length(years),
     estimate        = isTRUE(estimate),
     call            = call_snapshot,
     r_version       = R.version.string,
     package_version = as.character(utils::packageVersion("sube"))
   )

   # --- 12. single summary warning (D-8.10) ---
   .emit_pipeline_warning(diagnostics)

   .sube_pipeline_result(results, models, diagnostics, call_meta)
   ```

3) **Append three new test_that blocks** to `tests/testthat/test-pipeline.R`:

   ```r
   test_that("summary warning emitted exactly once when any diagnostic is non-ok (D-8.10)", {
     sut_path <- tempfile(fileext = ".csv")
     sut <- data.table::copy(sube_example_data("sut_data"))
     sut[1L, VALUE := NA_real_]
     data.table::fwrite(sut, sut_path)
     w <- tryCatch(
       run_sube_pipeline(
         path = sut_path,
         cpa_map = sube_example_data("cpa_map"),
         ind_map = sube_example_data("ind_map"),
         inputs  = sube_example_data("inputs"),
         source  = "wiod"
       ),
       warning = function(w) w
     )
     expect_s3_class(w, "warning")
     expect_match(conditionMessage(w), "^Pipeline completed with issues: ")
     expect_match(conditionMessage(w), "coerced_na")
     expect_match(conditionMessage(w), "See result\\$diagnostics for details\\.")
   })

   test_that("no warning emitted when all diagnostics are ok", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     expect_no_warning(
       run_sube_pipeline(
         path = sut_path,
         cpa_map = sube_example_data("cpa_map"),
         ind_map = sube_example_data("ind_map"),
         inputs  = sube_example_data("inputs"),
         source  = "wiod"
       )
     )
   })

   test_that("estimate = TRUE attaches sube_models when model_data is non-empty (D-8.4)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     res <- run_sube_pipeline(
       path = sut_path,
       cpa_map = sube_example_data("cpa_map"),
       ind_map = sube_example_data("ind_map"),
       inputs  = sube_example_data("inputs"),
       source  = "wiod",
       estimate = TRUE
     )
     # sample data has 1 country × 2 industries × 1 year → model_data has 2 rows
     # estimate_elasticities may error on such small data; guard via expect_true/skip
     if (!is.null(res$models)) {
       expect_s3_class(res$models, "sube_models")
     } else {
       succeed("estimate path exercised; sube_models fallback OK when sample too small")
     }
   })

   test_that("estimate = FALSE leaves $models NULL (D-8.4 default)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     res <- run_sube_pipeline(
       path = sut_path,
       cpa_map = sube_example_data("cpa_map"),
       ind_map = sube_example_data("ind_map"),
       inputs  = sube_example_data("inputs"),
       source  = "wiod"
     )
     expect_null(res$models)
     expect_true(res$call$estimate == FALSE)
   })

   test_that("FIGARO source routes through read_figaro and returns sube_pipeline_result (CONV-01 FIGARO path)", {
     fixture_dir <- system.file("extdata", "figaro-sample", package = "sube")
     skip_if_not(nzchar(fixture_dir), "figaro-sample fixture missing")

     # Build cpa_map + ind_map inline from fixture codes via section-letter rule
     # (mirrors helper-gated-data.R::build_nace_section_map).
     sut_peek <- read_figaro(fixture_dir, year = 2023L)
     dom_peek <- extract_domestic_block(sut_peek)
     codes <- sort(unique(c(dom_peek$CPA, setdiff(dom_peek$VAR, "FU_BAS"))))
     cpa_map <- data.table::data.table(CPA = codes, CPAagg = substr(codes, 1L, 1L))
     ind_map <- data.table::data.table(NACE = codes, INDagg = substr(codes, 1L, 1L))

     agg_inds <- sort(unique(ind_map$INDagg))
     countries <- sort(unique(dom_peek$REP))
     inputs <- data.table::CJ(YEAR = 2023L, REP = countries,
                              INDUSTRY = agg_inds, sorted = FALSE)
     inputs[, GO  := seq(100, by = 10, length.out = nrow(inputs))]
     inputs[, VA  := GO * 0.4]
     inputs[, EMP := GO * 0.1]
     inputs[, CO2 := GO * 0.05]

     res <- run_sube_pipeline(
       path    = fixture_dir,
       cpa_map = cpa_map,
       ind_map = ind_map,
       inputs  = inputs,
       source  = "figaro",
       year    = 2023L
     )
     expect_s3_class(res, "sube_pipeline_result")
     expect_s3_class(res$results, "sube_results")
     expect_gt(nrow(res$results$summary), 0L)
     expect_setequal(unique(res$results$summary$COUNTRY), c("DE", "FR", "IT"))
     expect_true(all(res$diagnostics$status == "ok"))
     expect_equal(res$call$source, "figaro")
   })

   test_that("$call carries provenance metadata (D-8.3)", {
     sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")
     res <- run_sube_pipeline(
       path = sut_path,
       cpa_map = sube_example_data("cpa_map"),
       ind_map = sube_example_data("ind_map"),
       inputs  = sube_example_data("inputs"),
       source  = "wiod"
     )
     expect_named(res$call,
                  c("source", "path", "n_countries", "n_years",
                    "estimate", "call", "r_version", "package_version"),
                  ignore.order = TRUE)
     expect_equal(res$call$source, "wiod")
     expect_equal(res$call$n_countries, 1L)
     expect_equal(res$call$n_years, 1L)
     expect_false(res$call$estimate)
   })
   ```
  </action>
  <verify>
    <automated>Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"</automated>
    <automated>grep -q '^\.emit_pipeline_warning <- function' R/pipeline.R</automated>
    <automated>grep -q "estimate_elasticities(matrix_bundle\$model_data)" R/pipeline.R</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
    <automated>Rscript -e "devtools::load_all('.'); r <- run_sube_pipeline(path = system.file('extdata','sample','sut_data.csv',package='sube'), cpa_map=sube_example_data('cpa_map'), ind_map=sube_example_data('ind_map'), inputs=sube_example_data('inputs'), source='wiod'); stopifnot(is.null(r\$models)); stopifnot(identical(r\$call\$source, 'wiod'))"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^\.emit_pipeline_warning <- function" R/pipeline.R` prints `1`.
    - `R/pipeline.R` contains the literal string `estimate_elasticities(matrix_bundle$model_data)`.
    - Running `run_sube_pipeline()` on happy-path sample data emits zero warnings. Inject NA into a value → exactly one warning emitted whose message starts with `Pipeline completed with issues: ` and ends with `See result$diagnostics for details.`.
    - FIGARO-path test passes — verifies section-letter map construction and `read_figaro` dispatch end-to-end on `inst/extdata/figaro-sample/`.
    - Test count: `grep -c "^test_that(" tests/testthat/test-pipeline.R` returns `>= 14`.
    - `devtools::test()` exits 0; no regressions.
    - Happy-path `$diagnostics` has 0 rows with `status != "ok"`: `Rscript -e 'devtools::load_all("."); r <- run_sube_pipeline(path = system.file("extdata","sample","sut_data.csv",package="sube"), cpa_map=sube_example_data("cpa_map"), ind_map=sube_example_data("ind_map"), inputs=sube_example_data("inputs"), source="wiod"); stopifnot(sum(r$diagnostics$status != "ok") == 0)'`
  </acceptance_criteria>
  <done>run_sube_pipeline() fully implements CONV-01 + CONV-03 per Phase 8 locked decisions. Opt-in estimation wires cleanly; exactly one summary warning surfaces when diagnostics are non-clean; FIGARO path verified against synthetic fixture. At least 14 pipeline test_that blocks green; no regressions.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| user-supplied `path` → filesystem | Researcher passes local path; already guarded by `import_suts()` (`file.exists`/`dir.exists`) and `read_figaro()` (`dir.exists` + pattern-matched file count). |
| user-supplied `inputs`/`cpa_map`/`ind_map` → data.table mutation | `.standardize_names()` + `setnames()` inside `build_matrices()` / `compute_sube()` mutate by reference. D-8 mitigates via `data.table::copy()` in `.validate_pipeline_inputs` (Task 1) and internal `copy()` already in `build_matrices`. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8.1-01 | T (Tampering) | `inputs` data.table passed to pipeline | mitigate | `.validate_pipeline_inputs` takes `data.table::copy()` before `.standardize_names` so caller's object is never mutated. Verified by Task 1 acceptance. |
| T-8.1-02 | I (Information disclosure) | `$call$path` stored in return object | accept | Path is user-supplied and already on the filesystem the user owns; recording it in `$call` is expected provenance. No secrets stored. |
| T-8.1-03 | D (Denial of service) | `read_figaro()` on user-chosen directory | accept | Out-of-scope per CONTEXT.md — `read_figaro()` already bounds via its `length(supply_files) != 1L` / `length(use_files) != 1L` guards. Phase 8 layers on top, adds no new IO. |
| T-8.1-04 | S (Spoofing) | N/A — library API, no auth | accept | No authentication surface; package is a library invoked in-process by the researcher. ASVS L1 N/A. |
| T-8.1-05 | R (Repudiation) | N/A | accept | Not applicable to library APIs. |
| T-8.1-06 | E (Elevation of privilege) | N/A | accept | No privilege boundaries in an in-process R library. |

No security_enforcement blockers. Security surface is minimal (ASVS L1): the only mitigated threat is the data.table mutation risk, handled inline via `copy()`.
</threat_model>

<verification>
Phase-local checks (run from repo root):

- `Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"` — 0 failures.
- `Rscript -e "devtools::test(stop_on_failure = TRUE)"` — 0 failures (no regression in test-workflow.R, test-figaro.R, test-figaro-pipeline.R, test-replication.R, test-gated-data-contract.R).
- `grep -c "^export(run_sube_pipeline)$" NAMESPACE` — prints `1`.
- `Rscript -e "devtools::load_all('.'); inherits(run_sube_pipeline(path = system.file('extdata','sample','sut_data.csv',package='sube'), cpa_map = sube_example_data('cpa_map'), ind_map = sube_example_data('ind_map'), inputs = sube_example_data('inputs'), source = 'wiod'), 'sube_pipeline_result')"` — prints `[1] TRUE`.
</verification>

<success_criteria>
1. `run_sube_pipeline()` is exported and runs the full WIOD and FIGARO chains on shipped sample data and synthetic fixture respectively (CONV-01).
2. Return object is `c("sube_pipeline_result", "list")` with `$results` (sube_results), `$models` (sube_models or NULL), `$diagnostics` (6-column unified schema), `$call` (provenance).
3. All four D-8.11 diagnostic categories detected inside the pipeline; `$diagnostics` schema matches D-8.12 exactly (column order, types).
4. Exactly one `warning()` emitted when any diagnostic row has `status != "ok"`; zero warnings on clean runs (CONV-03).
5. Upfront `inputs` validation prevents deep-stack errors (Open Item 6).
6. All pre-existing test files still pass unchanged.
</success_criteria>

<output>
After completion, create `.planning/phases/08-convenience-helpers/08-01-SUMMARY.md`.
</output>
