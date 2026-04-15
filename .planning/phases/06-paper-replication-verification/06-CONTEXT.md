# Phase 6: Paper Replication Verification - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver two artefacts that make paper replication a first-class, verifiable
feature of the `sube` package:

1. A **gated testthat test** (`SUBE_WIOD_DIR` env var required) that confirms
   the package's end-to-end pipeline produces numerically identical raw
   supply, use, and net-supply matrices compared to the legacy paper output.
   Automatically skipped on CRAN and in CI when the env var is absent.

2. A **replication vignette** (`vignettes/paper-replication.Rmd`,
   `eval = FALSE`) that walks researchers through the full reproduction
   workflow step by step.

Out of scope: auto-downloading WIOD data, bundling WIOD data in the tarball,
replicating the IHS regression variants (`06_SUBE_ihs*.R`), replicating
paper figures via `plot_paper_*()`.

The replication work already done in `inst/scripts/replicate_paper.R`
(Leontief multipliers, OLS/pooled/between comparisons, 6-layer outlier
treatment) is reusable but does NOT define the test boundary — the test
verifies only what is bit-identical.

</domain>

<decisions>
## Implementation Decisions

### Test Scope and Tolerance

- **D-01: Gated test verifies exact matrix match only.** The test computes
  our raw 56×56 supply and use matrices, the net-supply regression matrix
  `W = t(SUP_agg − USE_agg)`, and compares each against the legacy
  intermediate files in
  `inst/extdata/wiod/Regression/data/*.csv` and
  `inst/extdata/wiod/International SUTs domestic/countries/matrices/`.
  Tolerance: `1e-6` absolute (floating-point noise only).
- **D-02: Leontief multipliers and regression coefficients are NOT test
  assertions.** Those diffs (~2.7% for Leontief after outlier treatment,
  4+ decimal for OLS) come from post-processing choices (averaging order,
  OLS-side filtering) and are correct within methodological variation.
  They belong in the vignette as illustrative comparisons, not as
  pass/fail gates. This keeps the test stable across minor numerical
  noise and future methodological refinements.
- **D-03: Test scope — sample countries and one year.** The test compares
  a representative subset (AUS, DEU, USA, JPN for 2005 — covering a small,
  large, diverse set of economies) rather than all 43 countries × 15 years.
  Full sweep is available as an interactive-only helper in the script. This
  keeps the test runtime under ~10 seconds on any reasonable hardware.

### Test Gating Mechanism

- **D-04: Test gates on `SUBE_WIOD_DIR` environment variable.** The variable
  points to a directory containing the WIOD subtree
  (`International SUTs domestic/`, `Correspondences/`, `GOVAcur/`, `EMP/`,
  `CO2/`, `Regression/data/`). The test helper resolves all file paths
  relative to this root.
- **D-05: `testthat::skip()` when the env var is unset or the directory
  does not exist.** Uses `testthat::skip_on_cran()` and
  `testthat::skip_if_not(nzchar(Sys.getenv("SUBE_WIOD_DIR")))` guards so
  the test is auto-skipped in the package tarball, on CRAN, and in the
  R CMD check workflow. Output of a skipped run must read cleanly (e.g.
  `SKIP (SUBE_WIOD_DIR not set — paper replication test skipped)`).
- **D-06: Local dev convenience.** Because the repo already contains
  `inst/extdata/wiod/` (gitignored), the test additionally falls back to
  that path when `SUBE_WIOD_DIR` is unset *and* the directory exists
  inside the package source tree. This only matters for interactive
  development — CRAN/CI never see this fallback because the directory is
  not in the tarball.

### Outlier Treatment Exposure

- **D-07: Export the existing `.apply_paper_filters()` helper as
  `filter_paper_outliers()`.** The current internal function in
  `R/paper_tools.R` already implements the six layers from
  `08_outlier_treatment.R`. Rename, export via roxygen `@export`, and
  document as "the exact exclusion rules used in the 2018 paper".
- **D-08: Function signature.**
  ```r
  filter_paper_outliers(data,
                        variables = c("GO", "VA", "EMP", "CO2"),
                        apply_bounds = TRUE)
  ```
  - `data`: a tidy comparison table (the shape returned by
    `prepare_sube_comparison()`, which is the existing consumer), or a
    SUBE results summary table with `COUNTRY, YEAR, CPAagg, GO, VA,
    EMP, CO2` columns.
  - `variables`: subset of metrics to filter on (CO2-absent cases use
    `variables = c("GO","VA","EMP")`).
  - `apply_bounds`: whether to apply layer 5 (GO ∈ [1,4], VA ∈ [0,1],
    EMP/CO2 ≥ 0) on raw multiplier columns. Defaults to TRUE.
- **D-09: Document provenance prominently.** The roxygen `@details` block
  must reference `08_outlier_treatment.R` lines 89-181 so users
  understand these are historical, paper-specific filters, not
  general-purpose quality rules. List the six layers explicitly in the
  man page.

### Vignette Scope

- **D-10: Vignette path and config.**
  `vignettes/paper-replication.Rmd` with `eval = FALSE` in the default
  knitr chunk options. No chunk evaluates WIOD data to keep CRAN builds
  fast and independent of external data. Inline `#> ...` comments show
  representative output captured from a real run.
- **D-11: Vignette structure — narrative + code, not exhaustive.** Mirror
  the structure of `inst/scripts/replicate_paper.R` as sections:
  1. What the paper replicates and why this vignette exists
  2. Obtaining the WIOD data (pointer to Eurostat, directory layout,
     `SUBE_WIOD_DIR` env var convention)
  3. Importing the domestic block (`import_suts()` + `extract_domestic_block()`)
  4. Aggregation via correspondence tables (CPA56, Ind56)
  5. Computing Leontief multipliers and elasticities (`compute_sube()`)
  6. Applying the paper's outlier treatment (`filter_paper_outliers()`)
  7. Running the regressions (`estimate_elasticities()`)
  8. Comparing with the legacy paper output and expected numerical match
  9. Running the gated test locally (`SUBE_WIOD_DIR=... R CMD check`)
- **D-12: Vignette does NOT include IHS variants or paper figures.** Those
  are explicitly deferred — a one-line note under a "Beyond this vignette"
  section points to `06_SUBE_ihs*.R` in `archive/legacy-scripts/` and the
  existing `plot_paper_comparison()` / `plot_paper_regression()` /
  `plot_paper_interval_ranges()` functions for users who want to go
  further.

### Script and Infrastructure Reuse

- **D-13: `inst/scripts/replicate_paper.R` stays as the reference
  runbook.** No migration into the package namespace. The script
  continues to be the place where the full comparison (including the
  illustrative Leontief and regression diffs) lives. The vignette
  references the script as the canonical full example, the test is a
  minimal subset.
- **D-14: The per-country legacy files under
  `inst/extdata/wiod/Regression/data/*.csv` are the ground-truth for the
  matrix comparison test** (same files we already verified bit-identical
  during replication). Test helper reads these directly, no transformation.

### Package Metadata

- **D-15: DESCRIPTION Version remains `0.1.2`** through Phase 6 (per
  Phase 5 D-23). The milestone v1.1 archive step bumps the version once.
- **D-16: Vignette dependency.** Vignettes already require `knitr` +
  `rmarkdown` — DESCRIPTION already lists them under `Suggests`. No new
  IMPORTS expected for Phase 6.
- **D-17: `NEWS.md` gets a Phase 6 entry** under the existing v1.1
  section: mention `filter_paper_outliers()` export and the new
  replication vignette. Keep the entry short (2-3 bullets).

### Claude's Discretion

- Exact wording of the `skip()` message and env-var documentation.
- Whether the test lives in a single file (`tests/testthat/test-replication.R`)
  or splits into matrix/regression subsections — size determines this,
  single file is the likely answer.
- Exact representative output shown as `#>` comments in the vignette
  (pick values from `AUS 2005` since that's what the existing script
  already uses for detail comparisons).
- Whether to add a one-liner `R CMD check` pre-commit check that the
  vignette still parses.
- pkgdown reference group for `filter_paper_outliers()` — put it with
  `compute_sube()` / `estimate_elasticities()` as a "Paper replication
  tools" group alongside the existing `plot_paper_*()` functions.

### Folded Todos

None (no matching todos in the backlog).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — Milestone goals, constraints, v1.1 scope
- `.planning/REQUIREMENTS.md` — REP-01, REP-02 acceptance criteria
- `.planning/ROADMAP.md` — Phase 6 goal and success criteria

### Prior-phase decisions still active
- `.planning/phases/05-figaro-sut-ingestion/05-CONTEXT.md` — Phase 5
  locked decisions; D-23 (no DESCRIPTION bump) carries through Phase 6.

### Existing code the implementation touches or mirrors
- `R/paper_tools.R` — `.apply_paper_filters()` (lines 109-146) to be
  renamed and exported; `prepare_sube_comparison()` shows the expected
  input shape; `extract_leontief_matrices()` is the canonical result-to-
  matrix extractor.
- `R/models.R` — `estimate_elasticities()` (already gained tryCatch for
  singular panels during replication work).
- `R/matrices.R` — `build_matrices()` with `inputs=` now returns
  `model_data` (net-supply regression matrix). Test relies on this.
- `R/import.R` — `import_suts()` wide-CSV branch (used by the test).
- `tests/testthat/test-workflow.R` — template for test style
  (`test_that()` blocks, error expectation patterns).
- `inst/scripts/replicate_paper.R` — reference runbook; test is a
  subset, vignette is the narrated version.
- `inst/scripts/README.md` — already documents the accuracy summary;
  update alongside the vignette if text drifts.

### Legacy artefacts (read-only ground truth)
- `archive/legacy-scripts/05_SUBE_regress.R` lines 28-55 — origin of
  the net-supply matrix `W = t(SUP_agg − USE_agg)` used for regressions.
- `archive/legacy-scripts/08_outlier_treatment.R` lines 89-181 — the
  six-layer exclusion rules `filter_paper_outliers()` must codify.
- `inst/extdata/wiod/Regression/data/*.csv` — per-country legacy net-
  supply matrices (ground truth for the matrix test).
- `inst/extdata/wiod/International SUTs domestic/countries/matrices/` —
  raw S/U matrix files (ground truth, cross-check).

### Package docs to update
- `_pkgdown.yml` — add `filter_paper_outliers` to the paper-replication
  reference group.
- `NEWS.md` — v1.1 section entry.
- `DESCRIPTION` — no change expected.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.apply_paper_filters()` (`R/paper_tools.R:109`) — full six-layer
  implementation; just needs rename, `@export`, and a roxygen block.
- `prepare_sube_comparison()` (`R/paper_tools.R:150`) — already consumes
  `.apply_paper_filters()`; no change needed beyond the rename.
- `inst/scripts/replicate_paper.R` — working end-to-end pipeline; the
  test can reuse the same input-loading helpers verbatim (lift the
  `inputs_raw_list` builder into a test helper).
- `testthat::skip_on_cran()` and `testthat::skip_if_not()` — standard
  R-pkg gating pattern.

### Established Patterns
- testthat edition 3, one `test_that()` block per behaviour group.
- Fixtures live in `inst/extdata/` (never in `tests/testthat/fixtures/`);
  test accesses them via `system.file()` or, in this phase, via
  `Sys.getenv("SUBE_WIOD_DIR")`.
- Roxygen2 documentation; NAMESPACE is edited manually (Phase 5
  confirmed roxygen does not regenerate it in this project).
- Vignettes already exist in `vignettes/` (`getting-started.Rmd`,
  `data-preparation.Rmd`, `modeling-and-outputs.Rmd`); follow their
  YAML header and chunk-option conventions.

### Integration Points
- `R/paper_tools.R` — rename + export.
- `NAMESPACE` — add `export(filter_paper_outliers)`.
- `man/filter_paper_outliers.Rd` — new roxygen-generated man page.
- `tests/testthat/test-replication.R` — new test file.
- `vignettes/paper-replication.Rmd` — new vignette file.
- `_pkgdown.yml` — reference group update.
- `NEWS.md` — v1.1 entry.

### Non-Integration Points (locked)
- `R/compute.R`, `R/matrices.R`, `R/import.R`, `R/models.R`,
  `R/filter_plot_export.R` — no functional changes expected. Any fix
  surfaced during Phase 6 testing would be an out-of-scope regression.
- `DESCRIPTION` Version — stays at `0.1.2` (D-15, per Phase 5 D-23).
- `DESCRIPTION` Imports — no new dependencies.

</code_context>

<specifics>
## Specific Ideas

- The matrix-identity test is strictly stronger than any multiplier or
  coefficient test: if the raw matrices match bit-for-bit, every
  downstream number is deterministically derivable. Framing the test
  this way sidesteps the averaging-order / filter-interaction issues
  we found during replication, without weakening the claim that the
  pipeline reproduces the paper.
- `AUS 2005` is the natural detail example for the vignette because
  `inst/extdata/wiod/Regression/data/AUS_2005.csv` is already the file
  we verified exactly during replication; users can follow the same
  comparison at home.
- Representative country sample (AUS, DEU, USA, JPN) spans: Australia
  (paper's diagnostic default), Germany (large EU economy), USA
  (largest economy, different SNA vintage), Japan (different region,
  large economy). This covers edge cases without iterating all 43.
- The script's "Step 9" regression section already demonstrates that
  OLS matches to 4+ decimal places for significant terms — the vignette
  will quote these numbers rather than reproduce the computation
  (eval=FALSE).

</specifics>

<deferred>
## Deferred Ideas

- **IHS regression variants** — the `06_SUBE_ihs*.R`,
  `06_SUBE_lin-ihs*.R`, `06_SUBE_ihs-lin*.R` transformations are
  deliberately out of scope for Phase 6. Mentioned in the vignette's
  "Beyond this vignette" section as a pointer for users.
- **Paper figure replication** — `plot_paper_comparison()`,
  `plot_paper_regression()`, `plot_paper_interval_ranges()` already
  exist as functions. Not tested or vignetted in Phase 6. Could be a
  follow-up milestone.
- **FIGARO replication target** — once a FIGARO reference computation
  exists, Phase 6's pattern can be reused. Out of scope until a target
  is published.
- **A `run_sube_pipeline()` one-call wrapper** — explicitly deferred
  in REQUIREMENTS.md as CONV-01; not part of v1.1.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 6 scope.

</deferred>

---

*Phase: 06-paper-replication-verification*
*Context gathered: 2026-04-15*
