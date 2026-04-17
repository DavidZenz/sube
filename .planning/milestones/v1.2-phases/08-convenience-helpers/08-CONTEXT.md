---
phase: 08-convenience-helpers
milestone: v1.2
captured: 2026-04-16
---

# Phase 08 — Convenience Helpers: Context

Implementation decisions locked during discussion. Downstream agents (researcher,
planner) should treat these as non-negotiable unless explicitly marked "Claude's
Discretion" or "Open items".

<domain>
## Phase Boundary

Deliver three user-facing capabilities on top of the existing import → matrix →
compute pipeline:

1. **`run_sube_pipeline()`** — a one-call exported wrapper that chains
   `import_suts()` / `read_figaro()` → `extract_domestic_block()` →
   `build_matrices()` → `compute_sube()` for a single path, with argument
   pass-through and a structured return object (CONV-01).
2. **`batch_sube()`** — an exported looper over a pre-imported
   `sube_suts` table, grouped by country, year, or country-year, returning
   collected per-group results plus merged tidy tables (CONV-02).
3. **CONV-03 diagnostic warnings layer** — surface dropped/skipped/singular
   events at pipeline and batch scope via a unified structured
   `$diagnostics` table and a single summary `warning()` per run.

Out of scope:
- Modifying `import_suts()`, `read_figaro()`, `extract_domestic_block()`,
  `build_matrices()`, `compute_sube()`, or `estimate_elasticities()` public
  behavior (contracts frozen by Phase 5–7).
- Auto-download of FIGARO/WIOD data; zero-config mapping tables; parallel
  execution; directory auto-discovery.
- Reintroducing the archived script-first pipeline.

</domain>

<decisions>
## Implementation Decisions

### run_sube_pipeline() API

- **D-8.1** — **Path-only input.** Signature:
  ```r
  run_sube_pipeline(
    path,
    cpa_map,
    ind_map,
    inputs,
    source = c("wiod", "figaro"),
    domestic_only = TRUE,
    estimate = FALSE,
    ...   # importer-specific args (e.g. sheets for WIOD; year, final_demand_vars for FIGARO)
  )
  ```
  No `sut_data =` pre-loaded alternative. If a researcher already has a
  `sube_suts` in hand, they call the 4-step chain manually — it is 2 lines.
  Matches `.planning/research/ARCHITECTURE.md` and CONV-01 wording
  ("chains import → matrix → compute").

- **D-8.2** — **Explicit `source` argument.** `source = c("wiod", "figaro")`;
  no auto-detect. WIOD routes to `import_suts()`; FIGARO routes to
  `read_figaro()`. FIGARO needs `year` and `final_demand_vars` — these flow
  through `...` and must be validated before the importer is called (so the
  error message names which arg is missing for which `source`). A research
  pitfall (Pitfall 9 in `.planning/research/PITFALLS.md`) warns against
  "zero-config" auto-detect; we follow that advice.

- **D-8.3** — **Enriched `sube_pipeline_result` return class.** The pipeline
  returns a new class wrapping:
  - `$results` — the `sube_results` object from `compute_sube()` (same
    structure as today).
  - `$models` — `sube_models` from `estimate_elasticities()` iff
    `estimate = TRUE` and `model_data` is non-empty; else `NULL`.
  - `$diagnostics` — unified structured diagnostics table (schema below in
    D-8.12).
  - `$call` — provenance metadata: `source`, `path`, `n_countries`,
    `n_years`, `estimate`, call signature via `match.call()`, R + package
    version.
  Matches ROADMAP success criterion #1 ("one structured result object
  documenting the full pipeline output") and makes CONV-03 tests
  structural rather than condition-handler-dependent.

- **D-8.4** — **Opt-in `estimate = FALSE`.** The pipeline stops at
  `compute_sube()` by default. When `estimate = TRUE` AND
  `build_matrices(..., inputs = inputs)` produces non-empty `$model_data`,
  the pipeline additionally calls `estimate_elasticities()` and attaches
  its output to `$models`. Matches Phase 7 D-7.2 (snapshot the deepest
  deterministic contract; keep regression opt-in).

### batch_sube() API

- **D-8.5** — **Pre-imported `sut_data` + filter args.** Signature:
  ```r
  batch_sube(
    sut_data,
    cpa_map,
    ind_map,
    inputs,
    countries = NULL,
    years = NULL,
    by = c("country_year", "country", "year"),
    estimate = FALSE,
    ...
  )
  ```
  `sut_data` must be a `sube_suts` (from `import_suts()` or `read_figaro()`).
  `countries`/`years` default to "all groups present in `sut_data`"; when
  set they filter before splitting. The batch operates on already-canonical
  data — no re-import per group. Researcher imports once (WIOD or FIGARO),
  then batches.

- **D-8.6** — **`sube_batch_result` return class with merged tidy tables.**
  Contents:
  - `$results` — named list of `sube_pipeline_result` objects, one per
    group. Key format: `"{REP}"`, `"{YEAR}"`, or `"{REP}_{YEAR}"` based on
    `by`.
  - `$summary` — `rbindlist` of each group's `$results$summary` (the wide
    compute_sube summary).
  - `$tidy` — `rbindlist` of each group's `$results$tidy`.
  - `$diagnostics` — `rbindlist` of each group's `$diagnostics`, with an
    added `group_key` column naming the batch key.
  - `$call` — provenance metadata as in D-8.3, plus `by`, `n_groups`,
    `n_errors`.
  The `$results` list preserves per-group objects (avoiding the merged-result
  anti-pattern in `.planning/research/ARCHITECTURE.md`); the `$summary` /
  `$tidy` / `$diagnostics` tables satisfy the ROADMAP's "tidy structure
  suitable for downstream analysis".

- **D-8.7** — **Resilient per-group error handling.** Each group's
  `run_sube_pipeline()` call is wrapped in `tryCatch`. On error, a
  diagnostics row with `stage = "pipeline"`, `status = "error"`,
  `message = conditionMessage(e)` is appended and the loop continues.
  One summary `warning()` at the end reports `n_errors` and the failing
  group keys. Mirrors the existing `compute_sube()` singular-matrix
  handling pattern.

- **D-8.8** — **`by = c("country_year", "country", "year")`, default
  `"country_year"`.** The default matches `compute_sube()`'s natural grouping
  (one matrix bundle per REP × YEAR). `by = "country"` collapses all years
  per country into one compute call; `by = "year"` collapses all countries
  per year. The research signature suggested `by = c("country", "year",
  "country_year")` — we keep those three options but flip the default so
  the most common researcher use case ("one result per country-year") is
  the no-arg path.

### CONV-03 Diagnostics

- **D-8.9** — **Leave `build_matrices()` silent; catch in pipeline.** The
  pipeline detects dropped country-years by diffing input ids
  (`unique(sut_data[, .(YEAR, REP)])` post-`extract_domestic_block`) against
  the returned `$matrices` list names. Dropped slices become diagnostics
  rows with `stage = "build"`, `status = "skipped_alignment"`, `message` =
  concrete reason (e.g. "missing CPA/industry alignment after correspondence
  merge"). Zero risk of regressing the 46 FIGARO tests, the 3 gated
  replication tests, or the Phase 5–7 matrix contracts.

- **D-8.10** — **One summary `warning()` per run + structured table.**
  At the end of `run_sube_pipeline()` (or `batch_sube()`), if the unified
  `$diagnostics` table contains any rows with `status != "ok"`, emit ONE
  `warning()` call whose message summarises counts by status category:
  ```
  Pipeline completed with issues: 2 country-years skipped
  (missing alignment), 1 singular Leontief branch, 14 coerced-NA rows at
  import. See result$diagnostics for details.
  ```
  No per-country warning spam on 43 × 15 batches. Programmatic access is
  via the table; humans get one actionable summary.

- **D-8.11** — **Four diagnostic categories surfaced:**
  1. **Singular matrices** — pass-through from `compute_sube()`'s existing
     `singular_supply` / `singular_go` / `singular_leontief` statuses. No
     new code; pipeline just tags `stage = "compute"` on re-export.
  2. **Skipped country-years** — pipeline-level diff per D-8.9;
     `stage = "build"`, `status = "skipped_alignment"`.
  3. **Coerced-NA rows at import** — count rows where `as.numeric(VALUE)`
     produced `NA` before vs. after standardisation; surface as a
     pipeline-level aggregate row (`stage = "import"`,
     `status = "coerced_na"`, `country = NA`, `year = NA`, `n_rows =
     <count>`). Implementation detail for researcher phase: the cleanest
     hook is a thin wrapper around the importer call that compares
     `nrow(pre)` vs. `nrow(post[!is.na(VALUE)])`.
  4. **Input-metric alignment failures** — when `build_matrices(..., inputs
     = inputs)` returns empty `$model_data` rows for a country-year that is
     present in both the SUT data AND the `inputs` table, emit
     `stage = "build"`, `status = "inputs_misaligned"`. Detect by comparing
     input ids present in both tables vs. ids present in returned
     `model_data`.

- **D-8.12** — **Unified `$diagnostics` schema:**
  ```
  data.table(
    country  = character(),   # REP; NA for pipeline-level aggregates
    year     = integer(),     # YEAR;  NA for pipeline-level aggregates
    stage    = character(),   # one of: "import", "build", "compute", "pipeline"
    status   = character(),   # "ok" | "singular_supply" | "singular_go" |
                              # "singular_leontief" | "skipped_alignment" |
                              # "coerced_na" | "inputs_misaligned" | "error"
    message  = character(),   # one-line human-readable reason
    n_rows   = integer()      # optional; populated for "coerced_na" aggregate
  )
  ```
  Extends `compute_sube()`'s existing `diagnostics` table (which has
  `country`, `year`, `status`) by adding `stage`, `message`, and `n_rows`.
  `compute_sube()` itself is NOT modified — the pipeline constructs the
  extended schema by appending columns during assembly. In `batch_sube()`
  output, a further `group_key` column is added when diagnostics are
  merged across groups.

### Packaging & Docs

- **D-8.13** — **pkgdown: fold helpers into "Data import and preparation"
  group.** Overrides the "new group" recommendation because a researcher
  arriving via the pkgdown reference section with the question "I have
  data, how do I get results in one call?" looks at Data import first.
  Co-locating `run_sube_pipeline` + `batch_sube` with `import_suts` /
  `read_figaro` / `build_matrices` is the shortest path from question to
  answer. Updated group order:
  ```
  reference:
    - title: Data import and preparation
      contents:
        - import_suts
        - read_figaro
        - extract_domestic_block
        - sube_example_data
        - build_matrices
        - run_sube_pipeline   # NEW
        - batch_sube          # NEW
  ```

- **D-8.14** — **New `vignettes/pipeline-helpers.Rmd` + cross-links.** Ship
  a standalone vignette that knits on CRAN (`eval = TRUE`) using
  `sube_example_data()`. Structure (draft — planner may adjust):
  1. When to reach for the convenience helpers vs. the 4-step chain
  2. `run_sube_pipeline()` on the sample data with `source = "wiod"`
  3. Inspecting `$results`, `$diagnostics`, `$call`
  4. Switching to FIGARO: the `source = "figaro"` path (example code,
     `eval = FALSE` block because it needs a real flatfile)
  5. `batch_sube()` over multiple country-years, inspecting
     `$summary` / `$diagnostics`
  6. Turning on `estimate = TRUE` for end-to-end including elasticities
  7. Reading the diagnostic warnings: categories, what they mean
  Register in `_pkgdown.yml` articles (between "Modeling, Comparison, and
  Outputs" and "Package Design and Paper Context"). Add a short side-note
  to `paper-replication.Rmd` and `figaro-workflow.Rmd`:
  > "For a one-call equivalent, see
  > [`run_sube_pipeline()`](../reference/run_sube_pipeline.html)."

- **D-8.15** — **Three NEWS.md bullets under v1.2 development version:**
  1. `run_sube_pipeline()` — name the function, its purpose ("one-call
     chain from path through multipliers"), point to the new vignette.
  2. `batch_sube()` — name the function, explain country × year grouping,
     point to the vignette.
  3. Pipeline diagnostics — describe the unified `$diagnostics` table and
     the single summary `warning()`; name the four surfaced categories.
  Matches Phase 5/6/7 NEWS verbosity.

- **D-8.16** — **Live roxygen `@examples`.** Both `run_sube_pipeline()` and
  `batch_sube()` ship `@examples` blocks that run on CRAN using
  `sube_example_data()` (same pattern as `build_matrices()` /
  `compute_sube()` today). The FIGARO branch of `run_sube_pipeline()` gets
  a separate `\dontrun{}` block because `read_figaro()` needs a real
  flatfile.

### Claude's Discretion

- Exact wording of the summary `warning()` message (must name status
  counts; length reasonable on multi-country batches).
- Whether `sube_pipeline_result` / `sube_batch_result` inherit from
  `sube_results` for dispatch on `filter_sube()` / `plot_sube()` /
  `write_sube()`. FEATURES.md suggests inheriting; planner decides after
  inspecting existing `UseMethod` / class checks. If inherit is chosen,
  the `$results` field is redundant for dispatch but kept for explicit
  access.
- Whether `batch_sube()` emits a `message()` per group while iterating
  (progress reporting) or stays silent until the summary warning.
  Research architecture said "informative progress messages via
  `message()`" — planner decides based on expected runtime (likely
  silent for small batches, `message()` per group for batches > 5).
- File layout: one `R/pipeline.R` holding both functions (research
  default), or split into `R/pipeline.R` + `R/batch.R`. Single file is
  fine unless the combined size exceeds ~250 lines.
- Unit test file naming: `tests/testthat/test-pipeline.R` (research
  default) — likely sufficient for both functions given the existing
  per-file convention.

### Folded Todos

None identified. No pending todos referenced CONV-01, CONV-02, or CONV-03.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — v1.2 goals, active CONV-* requirements, Key
  Decisions table (including Phase 5–7 decisions that constrain Phase 8).
- `.planning/REQUIREMENTS.md` — CONV-01, CONV-02, CONV-03 acceptance
  criteria; Out of Scope table (auto-download, zero-config, API breaking
  changes).
- `.planning/ROADMAP.md` — Phase 8 goal, success criteria, dependencies.

### Prior-phase decisions still active
- `.planning/phases/05-figaro-sut-ingestion/05-CONTEXT.md` — Phase 5
  locked decisions; `read_figaro()` signature contract.
- `.planning/phases/06-paper-replication-verification/06-CONTEXT.md` —
  Phase 6 locked decisions; gated-test pattern, `filter_paper_outliers()`.
- `.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md` — Phase 7
  locked decisions; D-7.2 (elasticity opt-in), D-7.7 (env-var-only
  resolver), golden-snapshot pattern.

### Pre-existing research (from v1.1 planning; still largely current)
- `.planning/research/ARCHITECTURE.md` §149-229 — proposed signatures for
  `run_sube_pipeline()` and `batch_sube()`. Phase 8 decisions refine
  several points (return shape D-8.3 enriches the plain `sube_results`
  suggested there; default `by` D-8.8 flips to `country_year`).
- `.planning/research/FEATURES.md` §104-123 — structural notes on one-call
  pipeline and batch processing; merged-result class suggestion informed
  D-8.6.
- `.planning/research/PITFALLS.md` §154-162 — Pitfall 9 (no zero-config
  maps) drives D-8.1 / D-8.2.
- `.planning/research/PITFALLS.md` §170-178 — Pitfall 10 (data.table by-ref
  mutation in batch loop) — researcher phase must verify `data.table::copy()`
  usage in `batch_sube()`.

### Existing code the implementation touches or mirrors
- `R/compute.R:17` — `compute_sube()` signature; already-present
  diagnostics table that D-8.12 extends.
- `R/matrices.R:32` — `build_matrices()` signature; D-8.9 detects dropped
  slices by diffing input ids vs. returned `$matrices` list names.
- `R/import.R:25` — `import_suts()` (WIOD path).
- `R/import.R:116` — `extract_domestic_block()` (optional depending on
  `domestic_only` D-8.1).
- `R/import.R:183` — `read_figaro()` (FIGARO path); frozen API.
- `R/models.R:22` — `estimate_elasticities()` (opt-in D-8.4).
- `R/filter_plot_export.R` — `filter_sube()`, `plot_sube()`, `write_sube()`
  (dispatch target; inherit-from-`sube_results` question is Claude's
  Discretion).
- `R/paper_tools.R:197` — `prepare_sube_comparison()` (dispatch target).

### Test style and fixtures
- `tests/testthat/test-workflow.R` — testthat3 `test_that()` conventions,
  error-expectation patterns.
- `tests/testthat/test-figaro-pipeline.R` — existing 4-step chain
  contract test against the extended synthetic fixture; `batch_sube()`
  and `run_sube_pipeline()` tests should mirror its style.
- `inst/extdata/sample/` — `sube_example_data()` fixtures for live
  `@examples` and the new vignette.
- `inst/extdata/figaro-sample/` — extended synthetic FIGARO fixture
  (Phase 7 D-7.5) for FIGARO-path tests; used via `system.file()`.

### Package docs to update
- `NAMESPACE` — `export(run_sube_pipeline)` + `export(batch_sube)` (+
  optional `S3method(print, sube_pipeline_result)` /
  `S3method(print, sube_batch_result)` per planner's dispatch decision).
- `_pkgdown.yml` — Data import group (D-8.13) + articles entry (D-8.14).
- `NEWS.md` — three bullets (D-8.15).
- `DESCRIPTION` — no new Imports expected.
- `vignettes/pipeline-helpers.Rmd` — new file (D-8.14).
- `vignettes/paper-replication.Rmd`, `vignettes/figaro-workflow.Rmd` —
  one-liner side-note each pointing to the new helpers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `compute_sube()` diagnostics machinery — already writes per-country-year
  `status` rows for singular branches. D-8.11 / D-8.12 layer additional
  categories on top without modifying `compute_sube()`.
- `sube_example_data()` (`R/import.R:302`) — loads all five sample
  artefacts by name. Drives live `@examples` + the new vignette.
- `.standardize_names()`, `.sube_required_columns()` (`R/utils.R`) — reuse
  for `sut_data` validation in `batch_sube()`.
- `testthat::expect_warning()` alongside structural asserts on
  `result$diagnostics` — lets us pin both the condition-handler surface
  AND the structured contract.

### Established Patterns
- testthat edition 3, one `test_that()` per behaviour group.
- S3 dispatch via `class(out) <- c("<new_class>", class(out))` at the end
  of the constructor (consistent with `sube_results`, `sube_matrices`,
  `sube_suts`).
- `roxygen2` docs; NAMESPACE is edited manually (Phase 5 confirmed).
- Vignettes live in `vignettes/`; default knitr opts at top of each file;
  `eval = TRUE` only when the chunk runs on `sube_example_data()`.
- Single-file module home (`R/compute.R`, `R/matrices.R`, …) unless size
  forces a split.

### Integration Points
- `R/pipeline.R` — new file with both helpers (D-8.5, default research
  layout).
- `NAMESPACE` — two new `export()` lines.
- `tests/testthat/test-pipeline.R` — new file covering:
  success-path `run_sube_pipeline()` on `sube_example_data()`,
  FIGARO-branch success on `inst/extdata/figaro-sample/`,
  opt-in `estimate = TRUE` path,
  `batch_sube()` over ≥2 countries × 2 years,
  each of the four diagnostic categories (D-8.11) produces the expected
  `$diagnostics` row,
  resilient per-group error handling (D-8.7) — force one group to error
  and assert the batch still returns.
- `_pkgdown.yml` — reference + articles updates (D-8.13, D-8.14).
- `NEWS.md` — three bullets (D-8.15).
- `vignettes/pipeline-helpers.Rmd` — new file (D-8.14).
- `vignettes/paper-replication.Rmd`, `vignettes/figaro-workflow.Rmd` —
  side-note lines.

### Non-Integration Points (locked)
- `R/import.R`, `R/matrices.R`, `R/compute.R`, `R/models.R`,
  `R/filter_plot_export.R`, `R/paper_tools.R` — no functional changes.
  D-8.9 + D-8.11 keep all CONV-03 detection inside the new `R/pipeline.R`.
- `DESCRIPTION` Version — still `0.1.2` until milestone close.
- `DESCRIPTION` Imports — no new deps.
- Tests covering the 4-step chain directly (`test-workflow.R`,
  `test-figaro.R`, `test-figaro-pipeline.R`, `test-replication.R`) —
  must continue passing unchanged.

</code_context>

<specifics>
## Specific Ideas

- CONV-03 is strongest when the `$diagnostics` table is programmatically
  queryable AND a single summary `warning()` narrates the issues. The two
  are redundant on purpose: programmatic for tests, the warning for
  interactive console use.
- The pkgdown placement override (D-8.13) is about the researcher's entry
  path, not taxonomic purity. A new researcher asks "how do I go from
  data to multipliers" — the answer starts at "Data import and
  preparation", so the one-call helper should be visible there.
- `estimate = FALSE` is the default (D-8.4) because Phase 7's FIGARO
  gated test locked the "snapshot the deterministic compute output; keep
  regression opt-in" pattern. Phase 8 stays consistent.
- The four-category diagnostics (D-8.11) fill the current visibility
  gaps: singular branches were the only category surfaced pre-v1.2;
  dropped country-years, coerced-NA rows, and input-metric misalignments
  all existed silently. This phase is the first chance researchers get
  to see them without reading `build_matrices()` source.

</specifics>

<deferred>
## Deferred Ideas

- **Parallel batch execution** — `future.apply` or similar for large
  country-year sweeps. Research flagged no parallelism needed at current
  scale; research use cases complete in minutes sequentially. Defer to a
  later milestone if researcher workflows demand it.
- **Directory-based batch** (`batch_sube(paths, source, ...)`) — v1.1
  research rejected this because `import_suts()` / `read_figaro()`
  already handle directories; `batch_sube()` operates on canonical data.
  Keep deferred.
- **Auto-detect `source` from file extension** — rejected above
  (D-8.2). Revisit if user feedback shows explicit `source` is a friction
  point; not in v1.2.
- **`run_sube_full()` wrapper** that always runs elasticities — rejected
  in favour of opt-in `estimate = TRUE` on the single helper.
- **Progress reporting via `message()` per group in `batch_sube()`** —
  Claude's Discretion (planner decides based on typical batch size); not
  locked.
- **Inheritance from `sube_results` for dispatch** — Claude's Discretion;
  planner decides after inspecting `filter_sube()` / `plot_sube()` /
  `write_sube()` class checks.
- **`build_matrices()` emitting its own diagnostics** — deliberately
  deferred (D-8.9) to keep Phase 5–7 contracts frozen. Could become
  Phase 11+ refactor if the pipeline-level diffing proves noisy.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 8 scope.

</deferred>

## Open items for researcher / planner phase

Things the researcher (or planner, if `workflow.research = false`) should
settle before task breakdown:

1. Whether `sube_pipeline_result` and `sube_batch_result` inherit from
   `sube_results` (Claude's Discretion D-8 above). Read
   `R/filter_plot_export.R` and `R/paper_tools.R` for any `UseMethod()`
   / `inherits()` calls before deciding.
2. Concrete hook for "coerced-NA rows at import" counting (D-8.11 #3) —
   simplest is a wrapper that records `nrow(pre)` and
   `nrow(post[!is.na(VALUE)])`; verify this does not double-count rows
   the importers already drop (e.g. FIGARO primary-input rows in
   `read_figaro()`).
3. Final exact schema and column types for the unified `$diagnostics`
   table (D-8.12). The sketch above is a starting point; planner should
   confirm column order and NA-handling for pipeline-level aggregate
   rows.
4. Whether `batch_sube()` emits `message()` per group (progress) or
   stays silent. Planner's call based on expected batch size.
5. Test file layout: one `tests/testthat/test-pipeline.R` vs. splitting
   into `test-pipeline.R` + `test-batch.R`. Default to one file; split
   only if > ~300 lines.
6. Whether `run_sube_pipeline()` should validate `inputs` upfront (fail
   fast with "inputs argument missing required columns: ...") rather
   than letting `compute_sube()` error deep in the chain. Early
   validation improves error quality; planner decides.

## Next step

`/gsd-plan-phase 8` (research will run first if `workflow.research = true`
— currently yes per Phase 7 default, so expect RESEARCH.md before PLAN.md).
