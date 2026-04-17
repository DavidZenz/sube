---
phase: 08-convenience-helpers
plan: 02
type: execute
wave: 2
depends_on:
  - 01
files_modified:
  - R/pipeline.R
  - NAMESPACE
autonomous: true
requirements:
  - CONV-02
  - CONV-03
tags:
  - r-package
  - batch
  - diagnostics
must_haves:
  truths:
    - "`batch_sube()` is exported and accepts a pre-imported `sube_suts` `sut_data`, `cpa_map`, `ind_map`, `inputs`, plus optional `countries`/`years`/`by`/`estimate`/`...`."
    - "`by` defaults to `\"country_year\"` (per D-8.8); other allowed values are `\"country\"` and `\"year\"`."
    - "Each group's slice is processed through a helper that calls `build_matrices` + `compute_sube` (optionally `estimate_elasticities`) and produces a `sube_pipeline_result` per group — wrapped in `tryCatch` so one group's failure does not abort the batch."
    - "Return object is `c(\"sube_batch_result\", \"list\")` with `$results` (named list of `sube_pipeline_result`), `$summary` (rbindlist of per-group `$results$summary`), `$tidy` (rbindlist of per-group `$results$tidy`), `$diagnostics` (rbindlist with added `group_key` column), and `$call` (provenance including `by`, `n_groups`, `n_errors`)."
    - "All three map/inputs tables are `data.table::copy()`-guarded at batch entry to avoid Pitfall 10 mutation-across-iterations."
    - "If ANY group's diagnostics contains `status != \"ok\"` OR any group errored, exactly one `warning()` is emitted at batch completion summarising counts (mirroring `run_sube_pipeline()`)."
  artifacts:
    - path: "R/pipeline.R"
      provides: "batch_sube() function, .batch_split() splitter, .batch_run_one() per-group wrapper, .emit_batch_warning() summary emitter"
      contains: "batch_sube <- function("
      min_lines: 350
    - path: "NAMESPACE"
      provides: "Export line for batch_sube"
      contains: "export(batch_sube)"
  key_links:
    - from: "R/pipeline.R::batch_sube"
      to: "R/pipeline.R::.batch_run_one (internal wrapping run_sube_pipeline semantics for pre-imported sut_data)"
      via: "tryCatch wrapper per group"
      pattern: "tryCatch\\("
    - from: "R/pipeline.R::batch_sube"
      to: "R/pipeline.R::.sube_pipeline_result (shared constructor from Plan 01)"
      via: "per-group result construction"
      pattern: "\\.sube_pipeline_result\\("
---

<objective>
Implement `batch_sube()` — the country × year batch processor — and the cross-group tidy merging that makes per-group results downstream-friendly. Reuses Plan 01's `.sube_pipeline_result()` constructor and all four detection helpers so the diagnostic contract is bit-identical at pipeline and batch scope.

Purpose: Deliver CONV-02 (looped pipeline over country × year groups returning tidy merged tables) and extend CONV-03 to batch scope (single summary warning, merged diagnostics with `group_key`).

Output: `batch_sube()` exported from `R/pipeline.R`, a new S3 class `c("sube_batch_result", "list")`, and three internal helpers (`.batch_split`, `.batch_run_one`, `.emit_batch_warning`). NAMESPACE gains one more `export()`.
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
@.planning/phases/08-convenience-helpers/08-01-pipeline-core-PLAN.md

<interfaces>
<!-- From Plan 01 output (R/pipeline.R); these are the contracts this plan consumes. -->

```r
# Internal, unexported (from Plan 01):
.empty_diagnostics <- function()
.sube_pipeline_result <- function(results, models, diagnostics, call_meta)
.detect_coerced_na <- function(sut_raw)
.detect_skipped_alignment <- function(sut, matrix_bundle)
.detect_inputs_misaligned <- function(sut, inputs, matrix_bundle)
.extend_compute_diagnostics <- function(compute_diag)
.emit_pipeline_warning <- function(diagnostics)
.validate_pipeline_inputs <- function(inputs)
```

Class contract:
```r
class(sube_pipeline_result) == c("sube_pipeline_result", "list")
names(sube_pipeline_result) == c("results", "models", "diagnostics", "call")
```

From R/import.R (frozen):
```r
# sube_suts class check: inherits(sut_data, "sube_suts")
# Required columns: REP, PAR, CPA, VAR, VALUE, YEAR, TYPE
extract_domestic_block(data)   # returns sube_domestic_suts, sube_suts
```

From R/matrices.R / R/compute.R (frozen) — interfaces identical to Plan 01.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add batch_sube() signature, input validation, .batch_split() helper, and sube_batch_result class constructor. Happy-path loop stub (sequential, no merging yet)</name>
  <files>R/pipeline.R, NAMESPACE, tests/testthat/test-pipeline.R</files>
  <read_first>
    - R/pipeline.R (from Plan 01 — see all internal helpers and .sube_pipeline_result)
    - R/import.R lines 1–90, 116–130 (sube_suts class tags, extract_domestic_block behavior)
    - R/matrices.R lines 32–66 (build_matrices inputs shape; ids structure — YEAR int, REP char)
    - NAMESPACE (entire file; insertion point alphabetical)
    - tests/testthat/test-pipeline.R (exists from Plan 01 — will append)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.5, D-8.6, D-8.8)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §4 `data.table::copy()` placement (Pitfall 10)
  </read_first>
  <behavior>
    - `batch_sube(sut_data, cpa_map, ind_map, inputs, countries = NULL, years = NULL, by = c("country_year", "country", "year"), estimate = FALSE, ...)` exists, exports, `match.arg`s `by`, and validates `sut_data` via `.validate_class(sut_data, "sube_suts")` (re-using `R/utils.R`).
    - Top-of-function: `data.table::copy()` on all three of `cpa_map`, `ind_map`, `inputs` to prevent Pitfall 10 mutation-across-iterations.
    - `.batch_split(sut_data, countries, years, by)` helper returns a named list of (group_key, sut_slice, inputs_slice_ids) where `group_key` format depends on `by`: `"{REP}_{YEAR}"` (country_year), `"{REP}"` (country), `"{YEAR}"` (year).
    - Empty batch behavior: `batch_sube()` on `sut_data` filtered to zero rows returns a valid `sube_batch_result` with empty `$results`, empty-schema `$summary`/`$tidy`/`$diagnostics`, and `$call$n_groups = 0L`.
    - Test assertions: exported, accepts sube_suts, errors on non-sube_suts input, splits correctly into groups.
  </behavior>
  <action>
Append to `R/pipeline.R`. Do NOT touch Plan 01's existing functions.

1) **Internal splitter `.batch_split(sut_data, countries, years, by)`**:

   ```r
   .batch_split <- function(sut_data, countries, years, by) {
     dt <- data.table::as.data.table(sut_data)
     if (!is.null(countries)) dt <- dt[REP %in% countries]
     if (!is.null(years))     dt <- dt[YEAR %in% as.integer(years)]

     if (nrow(dt) == 0L) return(list())

     ids <- unique(dt[, .(REP = as.character(REP), YEAR = as.integer(YEAR))])

     group_keys <- switch(by,
       country_year = paste(ids$REP, ids$YEAR, sep = "_"),
       country      = unique(ids$REP),
       year         = as.character(unique(ids$YEAR))
     )

     lapply(group_keys, function(gk) {
       filt <- switch(by,
         country_year = {
           parts <- strsplit(gk, "_")[[1L]]
           rep_i <- parts[1L]; yr_i <- as.integer(parts[2L])
           dt[REP == rep_i & YEAR == yr_i]
         },
         country = dt[REP == gk],
         year    = dt[YEAR == as.integer(gk)]
       )
       # Preserve sube_suts / sube_domestic_suts class on the slice
       class(filt) <- class(sut_data)
       list(group_key = gk, sut = filt)
     })
   }
   ```

   Rationale comment: `# D-8.6 / D-8.8. Key format per group aligned with build_matrices() naming convention (REP_YEAR).`

2) **Internal constructor `.sube_batch_result()`**:

   ```r
   .sube_batch_result <- function(results, summary_dt, tidy_dt, diagnostics, call_meta) {
     out <- list(
       results     = results,
       summary     = summary_dt,
       tidy        = tidy_dt,
       diagnostics = diagnostics,
       call        = call_meta
     )
     class(out) <- c("sube_batch_result", "list")
     out
   }
   ```

   Rationale: `# D-8.6. Class vector order matches sube_pipeline_result pattern (RESEARCH §6 Risk 4).`

3) **Exported `batch_sube()`** — signature + copy-guards + split + stub loop that just collects empty results. Full detection/compute wiring is Task 2.

   ```r
   batch_sube <- function(
       sut_data,
       cpa_map,
       ind_map,
       inputs,
       countries = NULL,
       years = NULL,
       by = c("country_year", "country", "year"),
       estimate = FALSE,
       ...
   ) {
     # --- 1. argument validation ---
     .validate_class(sut_data, "sube_suts")
     by <- match.arg(by)
     .validate_pipeline_inputs(inputs)

     call_snapshot <- match.call()

     # --- 2. copy-guards (Pitfall 10 / RESEARCH §4 data.table::copy placement) ---
     cpa_map <- data.table::copy(cpa_map)
     ind_map <- data.table::copy(ind_map)
     inputs  <- data.table::copy(inputs)

     # --- 3. split ---
     groups <- .batch_split(sut_data, countries, years, by)

     # --- 4. per-group loop (Task 2 fills with .batch_run_one) ---
     per_group <- list()
     n_errors  <- 0L

     # Stub: Task 2 replaces this empty loop with real per-group processing.

     # --- 5. assemble merged tables ---
     summary_dt     <- data.table::data.table()
     tidy_dt        <- data.table::data.table()
     diagnostics_dt <- .empty_diagnostics()
     diagnostics_dt[, group_key := character()]

     call_meta <- list(
       by              = by,
       n_groups        = length(groups),
       n_errors        = n_errors,
       estimate        = isTRUE(estimate),
       call            = call_snapshot,
       r_version       = R.version.string,
       package_version = as.character(utils::packageVersion("sube"))
     )

     .sube_batch_result(per_group, summary_dt, tidy_dt, diagnostics_dt, call_meta)
   }
   ```

4) **Roxygen for `batch_sube()`** (above the function). Required tags (exact content):

   - `@title Batch-Run the SUBE Pipeline Over Country × Year Groups`
   - `@description` — "Loops [run_sube_pipeline()]-style processing over a pre-imported `sube_suts` table grouped by country, year, or country-year. Each group produces a [sube_pipeline_result][run_sube_pipeline]; per-group results are preserved alongside merged tidy `\\$summary`, `\\$tidy`, and `\\$diagnostics` tables suitable for downstream analysis."
   - `@param sut_data A `sube_suts` object (from [import_suts()] or [read_figaro()]).`
   - `@param cpa_map,ind_map,inputs Correspondence tables and industry inputs; see [build_matrices()] and [compute_sube()].`
   - `@param countries Optional character vector of REP codes; defaults to all countries in `sut_data`.`
   - `@param years Optional integer vector of years; defaults to all years in `sut_data`.`
   - `@param by Grouping key; one of `"country_year"` (default, per D-8.8), `"country"`, or `"year"`.`
   - `@param estimate Forwarded per-group to the compute stage; see [run_sube_pipeline()] (D-8.4).`
   - `@param ... Forwarded per-group to `build_matrices()` and `compute_sube()`.`
   - `@return An object of class `c("sube_batch_result", "list")` with elements `\\$results` (named list of [sube_pipeline_result][run_sube_pipeline], one per group), `\\$summary` (rbindlist of per-group `\\$results\\$summary`), `\\$tidy` (rbindlist of per-group `\\$results\\$tidy`), `\\$diagnostics` (rbindlist of per-group `\\$diagnostics` with an added `group_key` column), and `\\$call` (provenance metadata including `by`, `n_groups`, `n_errors`).`
   - `@details` — "Per D-8.7, each group's processing is wrapped in `tryCatch`; a failing group appends a diagnostics row with `stage = \"pipeline\"`, `status = \"error\"` and the loop continues. A single summary `warning()` is emitted at the end if any group errored or produced non-`\"ok\"` diagnostics (per D-8.10)."
   - `@seealso [run_sube_pipeline()]`
   - `@examples` — live block using `sube_example_data()` and a synthetic second year (per D-8.16 / RESEARCH §4 `@examples` Runnable Budget):

     ```r
     #' @examples
     #' sut <- sube_example_data("sut_data")
     #' # Duplicate the sample to a second year so batch_sube has 2 groups to iterate:
     #' sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     #' sut_multi <- rbind(sut, sut2)
     #' class(sut_multi) <- c("sube_suts", class(sut_multi))
     #'
     #' inp <- sube_example_data("inputs")
     #' inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
     #' inp_multi <- rbind(inp, inp2)
     #'
     #' result <- batch_sube(
     #'   sut_data = sut_multi,
     #'   cpa_map  = sube_example_data("cpa_map"),
     #'   ind_map  = sube_example_data("ind_map"),
     #'   inputs   = inp_multi
     #' )
     #' result$summary
     #' result$diagnostics
     ```

   - `@export`

5) **NAMESPACE** — insert `export(batch_sube)` in alphabetical order (at the very top, between the two `build_*` lines OR before `build_matrices` since `batch` < `build` alphabetically). Concrete snippet (the new first line of NAMESPACE):

   ```
   export(batch_sube)
   export(build_matrices)
   ```

6) **Append test_that blocks** to `tests/testthat/test-pipeline.R`:

   ```r
   test_that("batch_sube is exported", {
     expect_true("batch_sube" %in% getNamespaceExports("sube"))
   })

   test_that("batch_sube errors on non-sube_suts input (CONV-02 shape check)", {
     expect_error(
       batch_sube(
         sut_data = data.frame(x = 1),   # not sube_suts
         cpa_map  = sube_example_data("cpa_map"),
         ind_map  = sube_example_data("ind_map"),
         inputs   = sube_example_data("inputs")
       ),
       "Expected an object of class 'sube_suts'"
     )
   })

   test_that(".batch_split groups correctly by country_year (D-8.8 default)", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))
     groups <- sube:::.batch_split(sut_multi, NULL, NULL, "country_year")
     expect_equal(length(groups), 2L)
     expect_setequal(vapply(groups, function(g) g$group_key, character(1)),
                     c("AAA_2020", "AAA_2021"))
   })

   test_that(".batch_split groups correctly by country", {
     sut <- sube_example_data("sut_data")
     class(sut) <- c("sube_suts", class(sut))
     groups <- sube:::.batch_split(sut, NULL, NULL, "country")
     expect_equal(length(groups), 1L)
     expect_equal(groups[[1L]]$group_key, "AAA")
   })

   test_that(".batch_split groups correctly by year", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))
     groups <- sube:::.batch_split(sut_multi, NULL, NULL, "year")
     expect_equal(length(groups), 2L)
     expect_setequal(vapply(groups, function(g) g$group_key, character(1)),
                     c("2020", "2021"))
   })

   test_that("batch_sube with stub loop returns sube_batch_result with correct shape", {
     sut <- sube_example_data("sut_data")
     class(sut) <- c("sube_suts", class(sut))
     res <- batch_sube(
       sut_data = sut,
       cpa_map  = sube_example_data("cpa_map"),
       ind_map  = sube_example_data("ind_map"),
       inputs   = sube_example_data("inputs")
     )
     expect_s3_class(res, "sube_batch_result")
     expect_named(res, c("results", "summary", "tidy", "diagnostics", "call"))
     expect_named(res$call, c("by", "n_groups", "n_errors", "estimate",
                              "call", "r_version", "package_version"),
                  ignore.order = TRUE)
     expect_equal(res$call$by, "country_year")
   })
   ```
  </action>
  <verify>
    <automated>grep -q "^export(batch_sube)$" NAMESPACE</automated>
    <automated>grep -q "^batch_sube <- function(" R/pipeline.R</automated>
    <automated>grep -q "^\.batch_split <- function" R/pipeline.R</automated>
    <automated>grep -q "^\.sube_batch_result <- function" R/pipeline.R</automated>
    <automated>grep -q 'class(out) <- c("sube_batch_result", "list")' R/pipeline.R</automated>
    <automated>Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^export(batch_sube)$" NAMESPACE` prints `1`.
    - `grep -c "^batch_sube <- function(" R/pipeline.R` prints `1`.
    - `grep -c "^\.batch_split <- function" R/pipeline.R` prints `1`.
    - `R/pipeline.R` contains the exact string `data.table::copy(cpa_map)` and `data.table::copy(ind_map)` and `data.table::copy(inputs)`.
    - `Rscript -e 'devtools::load_all("."); res <- batch_sube(sut_data = {s <- sube_example_data("sut_data"); class(s) <- c("sube_suts", class(s)); s}, cpa_map = sube_example_data("cpa_map"), ind_map = sube_example_data("ind_map"), inputs = sube_example_data("inputs")); stopifnot(inherits(res, "sube_batch_result"))'` prints nothing and exits 0.
    - Test file grows by 6 test_that blocks. `grep -c "^test_that(" tests/testthat/test-pipeline.R` returns `>= 20`.
    - `devtools::test()` exits 0 — no regressions.
  </acceptance_criteria>
  <done>batch_sube() exported with full signature, roxygen docs, copy-guarded maps/inputs, sube_batch_result S3 class, and a working splitter. Stub loop returns a well-formed empty result shell. 6 new test_that blocks green.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Implement per-group processing (.batch_run_one), tryCatch resilience, cross-group rbindlist merging with group_key column, and the batch-level summary warning</name>
  <files>R/pipeline.R, tests/testthat/test-pipeline.R</files>
  <read_first>
    - R/pipeline.R (after Task 1 — has batch_sube stub + all Plan 01 helpers)
    - R/compute.R (compute_sube output shape: $summary/$tidy/$diagnostics/$matrices)
    - R/matrices.R lines 32–200 (build_matrices contract)
    - R/models.R lines 1–130 (estimate_elasticities)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.6, D-8.7, D-8.10)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §3 Open Item 3 (`rbindlist(..., fill = TRUE)`), §4 tryCatch Boundary, §6 Risk 2 (rbindlist unequal schemas)
  </read_first>
  <behavior>
    - `.batch_run_one(group, cpa_map, ind_map, inputs, estimate, dots)` processes a single group slice through build → compute → optional estimate → unified diagnostics, returning a `sube_pipeline_result`. If any error is raised, returns a special error-shaped `sube_pipeline_result` whose `$results`/`$models` are `NULL` and whose `$diagnostics` contains a `stage = "pipeline"`, `status = "error"` row.
    - `batch_sube()`'s loop wraps `.batch_run_one` in `tryCatch` — programming errors inside `.batch_run_one`'s own construction become diagnostics; data-quality errors are already caught by the helper internally.
    - Merged tables:
      - `$summary <- rbindlist(lapply(per_group, function(g) g$results$summary), fill = TRUE)` (when `g$results` is non-NULL; NULL results contribute empty).
      - `$tidy <- rbindlist(lapply(per_group, function(g) g$results$tidy), fill = TRUE)`.
      - `$diagnostics <- rbindlist(lapply(per_group, function(g) { d <- data.table::copy(g$diagnostics); d[, group_key := g$group_key]; d }), fill = TRUE)`.
      - `setcolorder(diagnostics, c("country", "year", "stage", "status", "message", "n_rows", "group_key"))`.
    - `$call$n_errors` counts groups whose diagnostics contain `status == "error"`.
    - Summary warning fires once when any group errored or any merged diagnostics row has `status != "ok"`. Wording: `"Batch completed with {n_errors} error(s) across {n_groups} group(s); issues: <comma-sep status:count>. See result$diagnostics for details."`
    - Happy path on 2-year duplicated sample: 2 groups, all ok, no warning, `nrow($summary) == 2 * nrow(single_group_summary)`.
    - Error-path test: force one group to error by supplying `inputs` missing one country-year's rows → that group's `status = "error"` row; other group still produces `$results`.
  </behavior>
  <action>
1) **Internal helper `.batch_run_one(group, cpa_map, ind_map, inputs, estimate, dots)`**:

   ```r
   .batch_run_one <- function(group, cpa_map, ind_map, inputs, estimate, dots) {
     gk  <- group$group_key
     sut <- group$sut

     # data-quality issues are caught here; caller's tryCatch is a safety net.
     tryCatch({
       # Diagnostics containers — seeded with coerced_na on the slice.
       diag_import <- .detect_coerced_na(sut)

       matrix_bundle <- do.call(
         build_matrices,
         c(list(sut_data = sut, cpa_map = cpa_map, ind_map = ind_map,
                inputs = inputs),
           dots[intersect(names(dots), c("final_demand_var"))])
       )

       diag_build <- data.table::rbindlist(
         list(
           .detect_skipped_alignment(sut, matrix_bundle),
           .detect_inputs_misaligned(sut, inputs, matrix_bundle)
         ),
         fill = TRUE
       )

       results <- do.call(
         compute_sube,
         c(list(matrix_bundle = matrix_bundle, inputs = inputs),
           dots[intersect(names(dots),
                          c("metrics", "diagonal_adjustment", "zero_replacement"))])
       )

       diag_compute <- .extend_compute_diagnostics(results$diagnostics)

       models <- NULL
       if (isTRUE(estimate) && nrow(matrix_bundle$model_data) > 0L) {
         models <- estimate_elasticities(matrix_bundle$model_data)
       }

       diagnostics <- data.table::rbindlist(
         list(diag_import, diag_build, diag_compute),
         fill = TRUE
       )
       data.table::setcolorder(
         diagnostics,
         c("country", "year", "stage", "status", "message", "n_rows")
       )

       call_meta <- list(
         source          = NA_character_,   # batch mode: no importer dispatch
         path            = NA_character_,
         n_countries     = length(unique(sut$REP)),
         n_years         = length(unique(sut$YEAR)),
         estimate        = isTRUE(estimate),
         group_key       = gk,
         r_version       = R.version.string,
         package_version = as.character(utils::packageVersion("sube"))
       )

       res <- .sube_pipeline_result(results, models, diagnostics, call_meta)
       list(group_key = gk, pipeline_result = res, errored = FALSE)
     },
     error = function(e) {
       err_diag <- data.table::data.table(
         country = NA_character_,
         year    = NA_integer_,
         stage   = "pipeline",
         status  = "error",
         message = conditionMessage(e),
         n_rows  = NA_integer_
       )
       call_meta <- list(
         source = NA_character_, path = NA_character_,
         n_countries = NA_integer_, n_years = NA_integer_,
         estimate = isTRUE(estimate),
         group_key = gk,
         r_version = R.version.string,
         package_version = as.character(utils::packageVersion("sube"))
       )
       res <- .sube_pipeline_result(NULL, NULL, err_diag, call_meta)
       list(group_key = gk, pipeline_result = res, errored = TRUE)
     })
   }
   ```

   Rationale: `# D-8.7. tryCatch boundary here — see RESEARCH §4 "tryCatch Boundary". Any stage error becomes one diagnostic row; the loop continues.`

2) **Internal helper `.emit_batch_warning(diagnostics, n_errors, n_groups)`**:

   ```r
   .emit_batch_warning <- function(diagnostics, n_errors, n_groups) {
     if (is.null(diagnostics) || nrow(diagnostics) == 0L) {
       if (n_errors == 0L) return(invisible(NULL))
     }
     bad <- diagnostics[status != "ok"]
     if (nrow(bad) == 0L && n_errors == 0L) return(invisible(NULL))
     counts <- bad[, .N, by = status]
     data.table::setorder(counts, -N)
     parts <- if (nrow(counts) > 0L) {
       sprintf("%d %s", counts$N, counts$status)
     } else character(0)
     warning(
       sprintf(
         "Batch completed with %d error(s) across %d group(s); issues: %s. See result$diagnostics for details.",
         n_errors, n_groups,
         if (length(parts) > 0L) paste(parts, collapse = ", ") else "none"
       ),
       call. = FALSE
     )
   }
   ```

3) **Replace the stub loop in `batch_sube()`** (Task 1's Step 4 + Step 5):

   ```r
     # --- 4. per-group loop ---
     dots <- list(...)
     processed <- lapply(groups, function(g) {
       .batch_run_one(g, cpa_map, ind_map, inputs, estimate, dots)
     })

     per_group <- setNames(
       lapply(processed, function(p) p$pipeline_result),
       vapply(processed, function(p) p$group_key, character(1))
     )
     n_errors <- sum(vapply(processed, function(p) isTRUE(p$errored), logical(1)))

     # --- 5. assemble merged tables (D-8.6) ---
     summary_dt <- data.table::rbindlist(
       lapply(per_group, function(r) {
         if (is.null(r$results)) data.table::data.table() else r$results$summary
       }),
       fill = TRUE
     )
     tidy_dt <- data.table::rbindlist(
       lapply(per_group, function(r) {
         if (is.null(r$results)) data.table::data.table() else r$results$tidy
       }),
       fill = TRUE
     )
     diagnostics_dt <- data.table::rbindlist(
       lapply(names(per_group), function(gk) {
         d <- data.table::copy(per_group[[gk]]$diagnostics)
         if (nrow(d) == 0L) {
           return(.empty_diagnostics()[, group_key := character()])
         }
         d[, group_key := gk]
         d
       }),
       fill = TRUE
     )
     if (nrow(diagnostics_dt) > 0L) {
       data.table::setcolorder(
         diagnostics_dt,
         c("country", "year", "stage", "status", "message", "n_rows", "group_key")
       )
     }

     call_meta <- list(
       by              = by,
       n_groups        = length(groups),
       n_errors        = n_errors,
       estimate        = isTRUE(estimate),
       call            = call_snapshot,
       r_version       = R.version.string,
       package_version = as.character(utils::packageVersion("sube"))
     )

     # --- 6. summary warning (D-8.10) ---
     .emit_batch_warning(diagnostics_dt, n_errors, length(groups))

     .sube_batch_result(per_group, summary_dt, tidy_dt, diagnostics_dt, call_meta)
   ```

4) **Append tests** to `tests/testthat/test-pipeline.R`:

   ```r
   test_that("batch_sube happy path on 2-year duplicate produces merged tables (CONV-02)", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))

     inp <- sube_example_data("inputs")
     inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
     inp_multi <- rbind(inp, inp2)

     res <- batch_sube(
       sut_data = sut_multi,
       cpa_map  = sube_example_data("cpa_map"),
       ind_map  = sube_example_data("ind_map"),
       inputs   = inp_multi
     )
     expect_s3_class(res, "sube_batch_result")
     expect_equal(length(res$results), 2L)
     expect_named(res$results, c("AAA_2020", "AAA_2021"), ignore.order = TRUE)
     expect_true(all(vapply(res$results, inherits, logical(1),
                            "sube_pipeline_result")))
     expect_gte(nrow(res$summary), 2L)
     expect_gte(nrow(res$tidy), 2L)
     expect_true("group_key" %in% names(res$diagnostics))
     expect_true(all(res$diagnostics$status == "ok"))
     expect_equal(res$call$n_groups, 2L)
     expect_equal(res$call$n_errors, 0L)
   })

   test_that("batch_sube is resilient to per-group error (D-8.7)", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))

     # Force group AAA_2021 to error: supply inputs with 2020 only.
     inp_broken <- sube_example_data("inputs")   # YEAR = 2020 only

     res <- suppressWarnings(batch_sube(
       sut_data = sut_multi,
       cpa_map  = sube_example_data("cpa_map"),
       ind_map  = sube_example_data("ind_map"),
       inputs   = inp_broken
     ))
     expect_s3_class(res, "sube_batch_result")
     expect_equal(length(res$results), 2L)
     # AAA_2020 succeeds, AAA_2021 fails
     expect_equal(res$call$n_errors, 1L)
     errs <- res$diagnostics[status == "error"]
     expect_gte(nrow(errs), 1L)
     expect_true("AAA_2021" %in% errs$group_key)
   })

   test_that("batch_sube summary warning fires once and names errors (D-8.10)", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))
     inp_broken <- sube_example_data("inputs")

     w <- tryCatch(
       batch_sube(
         sut_data = sut_multi,
         cpa_map  = sube_example_data("cpa_map"),
         ind_map  = sube_example_data("ind_map"),
         inputs   = inp_broken
       ),
       warning = function(w) w
     )
     expect_s3_class(w, "warning")
     expect_match(conditionMessage(w), "^Batch completed with 1 error\\(s\\)")
     expect_match(conditionMessage(w), "2 group\\(s\\)")
     expect_match(conditionMessage(w), "See result\\$diagnostics for details\\.")
   })

   test_that("batch_sube merged $diagnostics has group_key column with correct values", {
     sut <- sube_example_data("sut_data")
     sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
     sut_multi <- rbind(sut, sut2)
     class(sut_multi) <- c("sube_suts", class(sut_multi))
     inp <- sube_example_data("inputs")
     inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
     inp_multi <- rbind(inp, inp2)

     res <- batch_sube(
       sut_data = sut_multi,
       cpa_map  = sube_example_data("cpa_map"),
       ind_map  = sube_example_data("ind_map"),
       inputs   = inp_multi
     )
     expect_named(res$diagnostics,
                  c("country", "year", "stage", "status", "message",
                    "n_rows", "group_key"))
     expect_setequal(unique(res$diagnostics$group_key),
                     c("AAA_2020", "AAA_2021"))
   })

   test_that("batch_sube caller's cpa_map is not mutated (Pitfall 10)", {
     sut <- sube_example_data("sut_data")
     class(sut) <- c("sube_suts", class(sut))
     cpa <- sube_example_data("cpa_map")
     pre_names <- names(cpa)
     batch_sube(
       sut_data = sut,
       cpa_map  = cpa,
       ind_map  = sube_example_data("ind_map"),
       inputs   = sube_example_data("inputs")
     )
     expect_equal(names(cpa), pre_names)
   })
   ```
  </action>
  <verify>
    <automated>grep -q "^\.batch_run_one <- function" R/pipeline.R</automated>
    <automated>grep -q "^\.emit_batch_warning <- function" R/pipeline.R</automated>
    <automated>grep -q 'setcolorder(.*"group_key"' R/pipeline.R</automated>
    <automated>Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^\.batch_run_one <- function" R/pipeline.R` prints `1`.
    - `grep -c "^\.emit_batch_warning <- function" R/pipeline.R` prints `1`.
    - Merged `$diagnostics` column order verified: last column MUST be `group_key`. Run: `Rscript -e 'devtools::load_all("."); sut <- sube_example_data("sut_data"); sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]; sm <- rbind(sut, sut2); class(sm) <- c("sube_suts", class(sm)); inp <- sube_example_data("inputs"); inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]; im <- rbind(inp, inp2); r <- batch_sube(sm, sube_example_data("cpa_map"), sube_example_data("ind_map"), im); stopifnot(identical(names(r$diagnostics), c("country","year","stage","status","message","n_rows","group_key")))'`
    - Error-path test green: `AAA_2021` appears in `res$diagnostics[status == "error"]$group_key`.
    - `res$call$n_errors == 1` when one group fails.
    - Pitfall 10 test green: caller's `cpa_map` column names unchanged after batch.
    - Test count: `grep -c "^test_that(" tests/testthat/test-pipeline.R` returns `>= 25`.
    - `devtools::test()` exits 0 — no regressions in the 5 pre-existing test files.
  </acceptance_criteria>
  <done>batch_sube() fully implements CONV-02 + CONV-03 at batch scope per Phase 8 locked decisions. Per-group tryCatch resilience, merged tidy tables with group_key, and a single summary warning all landed. 5+ new test_that blocks green (2-year happy path, error resilience, warning wording, diagnostics schema, Pitfall 10). No regressions.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| user-supplied `sut_data` (already a `sube_suts`) → pipeline | Class-guarded via `.validate_class(sut_data, "sube_suts")`. Required-column check inside build_matrices still applies per group. |
| user-supplied `cpa_map`/`ind_map`/`inputs` → per-group `build_matrices()`/`compute_sube()` | Pitfall 10 — data.table mutation risk. Mitigated by `data.table::copy()` at batch entry (Task 1). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8.2-01 | T (Tampering) | cpa_map/ind_map/inputs mutation across iterations | mitigate | `data.table::copy()` on all three at batch entry (Task 1 Step 3). Test in Task 2 verifies caller's `cpa_map` names unchanged after call. |
| T-8.2-02 | D (Denial of service) | Unbounded batch size | accept | Research notes sequential batches complete in minutes at researcher scale (~200-500 groups). No parallelism requested (CONTEXT.md Deferred). |
| T-8.2-03 | I (Information disclosure) | `$call$call` records match.call() | accept | Standard provenance pattern; equivalent to compute_sube's output contents. Path-like strings already user-supplied. |
| T-8.2-04 | Remaining categories (S/R/E) | N/A | accept | Library API, in-process only; no auth/privilege boundaries. ASVS L1 N/A. |

Security surface is minimal (ASVS L1). The only mitigated threat is Pitfall 10 data.table mutation.
</threat_model>

<verification>
- `Rscript -e "devtools::test(filter = 'pipeline', stop_on_failure = TRUE)"` — 0 failures.
- `Rscript -e "devtools::test(stop_on_failure = TRUE)"` — 0 failures (no regression).
- `grep -q "^export(batch_sube)$" NAMESPACE` — exits 0.
- Happy-path 2-year batch: `$results` has 2 groups, `$diagnostics` merged with `group_key` column, `$call$n_errors == 0`.
- Error-path: one group's `$results` is NULL but the batch still returns and `$call$n_errors == 1`.
</verification>

<success_criteria>
1. `batch_sube()` exported; signature matches D-8.5; `by` default is `"country_year"` (D-8.8).
2. Returns `c("sube_batch_result", "list")` with `$results` (named list of `sube_pipeline_result`), `$summary`/`$tidy`/`$diagnostics` (rbindlist), and `$call` (provenance with `by`, `n_groups`, `n_errors`).
3. `$diagnostics` has the unified 6-column schema plus `group_key` as the 7th column (CONV-03 batch scope).
4. tryCatch per group — no error aborts the batch (D-8.7).
5. Single summary warning when any group errored or produced non-ok diagnostics (D-8.10).
6. Pitfall 10 mutation test green — caller's maps survive intact.
7. No regressions in the 5 prior test files.
</success_criteria>

<output>
After completion, create `.planning/phases/08-convenience-helpers/08-02-SUMMARY.md`.
</output>
