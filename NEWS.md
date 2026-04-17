# sube (development version)

- Added `run_sube_pipeline()`, a one-call wrapper that chains
  `import_suts()` or `read_figaro()` → `extract_domestic_block()` →
  `build_matrices()` → `compute_sube()` (with opt-in
  `estimate_elasticities()`) for a single SUT path. Returns a structured
  `sube_pipeline_result` object carrying `$results`, `$models`,
  `$diagnostics`, and `$call` provenance. See
  `vignette("pipeline-helpers")`.
- Added `batch_sube()`, which loops the convenience pipeline over a
  pre-imported `sube_suts` table grouped by country, year, or
  country-year (default `by = "country_year"`), returning per-group
  results alongside merged tidy `$summary`, `$tidy`, and `$diagnostics`
  tables suitable for downstream analysis. Per-group errors never abort
  the batch. See `vignette("pipeline-helpers")`.
- Added the unified pipeline diagnostics layer: `run_sube_pipeline()`
  and `batch_sube()` surface four categories of silent data-quality
  issues — coerced-NA rows at import, country-years dropped by
  correspondence-map alignment, singular matrix branches from
  `compute_sube()`, and input-metric misalignments from
  `build_matrices()` model-data — through a unified `$diagnostics`
  `data.table` and a single summary `warning()` per run.
- **BREAKING (development contract, INFRA-02):** `resolve_wiod_root()` no
  longer falls back to `inst/extdata/wiod/` when `SUBE_WIOD_DIR` is unset.
  The gated replication test now skips cleanly in that case instead of
  silently using locally-mounted data (which previously caused a known
  ~4.4% multiplier divergence). Introduced `resolve_figaro_root()` with
  the same env-var-only contract (`SUBE_FIGARO_DIR`). Test helper
  renamed `tests/testthat/helper-replication.R` →
  `tests/testthat/helper-gated-data.R`.
- Added end-to-end FIGARO validation coverage: a gated real-data test
  (`SUBE_FIGARO_DIR`, DE/FR/IT/NL × 2023) with a testthat golden snapshot,
  a synthetic-fixture contract test running on every CRAN build, and a
  new `figaro-workflow` vignette narrating the full pipeline from
  flatfile to multipliers. The shipped synthetic fixture under
  `inst/extdata/figaro-sample/` is extended to 8 real FIGARO A*64 codes
  × 3 countries to exercise a non-degenerate Leontief inversion on every
  build.
- Added `read_figaro()` for importing Eurostat FIGARO industry-by-industry
  supply and use flat-format CSV files into the canonical `sube_suts` long
  table. The importer auto-pairs one supply and one use file from a
  directory, strips the `CPA_` prefix from product codes, filters SNA
  primary-input rows (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`,
  `OP_NRES`), and aggregates the five FIGARO final-demand codes
  (`P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M`) into a single
  `VAR = "FU_bas"` row per `(REP, PAR, CPA)` so the output feeds
  `build_matrices()` unchanged. `FIGW1` (FIGARO rest-of-world 1) is
  preserved as a real country code.
- Extended `.coerce_map()` to recognize `NACE` and `NACE_R2` as synonyms
  for the industry-identifier column, so FIGARO-derived `ind_map` tables
  route correctly through `build_matrices()` without falling through to
  positional matching.
- Added `inst/extdata/figaro-sample/` with a synthetic 2-country FIGARO
  fixture and `tests/testthat/test-figaro.R` covering the new importer
  end-to-end.
- Exported `filter_paper_outliers()` (formerly internal `.apply_paper_filters()`)
  with `variables` and `apply_bounds` arguments so researchers can apply the
  paper's six-layer outlier treatment directly to SUBE comparison or results
  tables. See `?filter_paper_outliers` for the full rule list with citations
  to `archive/legacy-scripts/08_outlier_treatment.R:89-181`.
- Added the `paper-replication` vignette: a nine-section walkthrough of the
  end-to-end reproduction of the 2018 paper's raw supply, use, and
  net-supply matrices from WIOD data. Builds with `eval = FALSE` so it
  renders cleanly on CRAN.
- Added the gated `tests/testthat/test-replication.R` suite (requires
  `SUBE_WIOD_DIR`; auto-skipped on CRAN and in CI) which asserts bit-level
  equality against the legacy paper ground-truth matrices for AUS, DEU,
  USA, and JPN in 2005.
- Fixed the legacy-wrapper subprocess test (`test-workflow.R`) to pass under
  `R CMD check --as-cran` by threading `.libPaths()` into the child `Rscript`
  process via the `R_LIBS` environment variable (INFRA-01). Previously, the
  subprocess could not find `sube` because `R CMD check` installs to a
  temporary library not on the child's default search path.

# sube 0.1.2

- Added explicit Leontief matrix extraction in list, long, and wide formats.
- Added paper-style comparison, plotting, and export helpers around package objects.
- Tightened the package-first documentation story around the stabilized workflow surface.
- Aligned the local release path with GitHub Actions and kept the legacy wrapper as a documented compatibility bridge.

# sube 0.1.1

- Bumped the development version for the next documentation-focused pass.
- Next release direction: reframe the README around supply-use based
  econometrics more generally and position `sube` as a companion package to
  the Stehrer et al. paper.

# sube 0.1.0

- Converted the repository into a package-first layout with a stable exported
  workflow API.
- Made `plm` a required dependency for pooled and between model estimation.
- Added CRAN-oriented metadata, release notes, and documentation scaffolding.
- Added sample-data-driven vignettes and `pkgdown` configuration.
- Moved legacy paper scripts into a local ignored archive instead of packaging
  them.
