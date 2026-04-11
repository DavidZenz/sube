# sube (development version)

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
