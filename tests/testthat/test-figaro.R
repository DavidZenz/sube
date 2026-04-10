library(testthat)
library(sube)

figaro_fixture_dir <- function() {
  path <- system.file("extdata", "figaro-sample", package = "sube")
  if (!nzchar(path)) {
    skip("figaro-sample fixture not installed; run devtools::load_all() or install package")
  }
  path
}

make_tiny_figaro_maps <- function() {
  # Minimal mapping tables for the FIG-04 integration chain.
  # Matches the fixture's CPA/NACE codes from Task 1/Task 2.
  cpa_map <- data.table::data.table(
    CPA = c("P01", "P02", "P03"),
    CPAagg = c("PX", "PX", "PY")
  )
  ind_map <- data.table::data.table(
    NACE = c("I01", "I02", "I03"),  # deliberately uses "NACE" to also exercise FIG-03
    INDagg = c("IX", "IX", "IY")
  )
  inputs <- data.table::data.table(
    YEAR = 2023L,
    REP = c("REP1", "REP1", "REP2", "REP2"),
    INDUSTRY = c("IX", "IY", "IX", "IY"),
    GO = c(100, 80, 90, 70),
    VA = c(40, 30, 35, 25),
    EMP = c(10, 8, 9, 7),
    CO2 = c(5, 4, 4.5, 3.5)
  )
  list(cpa_map = cpa_map, ind_map = ind_map, inputs = inputs)
}

test_that("read_figaro returns a sube_suts object with canonical columns (FIG-01)", {
  dir <- figaro_fixture_dir()
  out <- read_figaro(dir, year = 2023)

  expect_s3_class(out, "sube_suts")
  expect_s3_class(out, "data.table")
  expect_true(all(c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE") %in% names(out)))
  expect_type(out$REP, "character")
  expect_type(out$PAR, "character")
  expect_type(out$CPA, "character")
  expect_type(out$VAR, "character")
  expect_type(out$VALUE, "double")
  expect_true(is.integer(out$YEAR) || is.numeric(out$YEAR))
  expect_type(out$TYPE, "character")
  expect_setequal(unique(out$TYPE), c("SUP", "USE"))
  expect_true(all(out$YEAR == 2023L))
})

test_that("read_figaro hard-errors on missing or invalid year (FIG-01, D-08)", {
  dir <- figaro_fixture_dir()
  expect_error(read_figaro(dir))  # missing year
  expect_error(read_figaro(dir, year = "twenty-three"))
  expect_error(read_figaro(dir, year = 20.5))
  expect_error(read_figaro(dir, year = c(2022, 2023)))
})

test_that("read_figaro hard-errors on missing path, zero files, or ambiguous files (FIG-01, D-11)", {
  expect_error(read_figaro("/nonexistent/figaro/dir", year = 2023))

  empty_dir <- file.path(tempdir(), "sube-figaro-empty")
  dir.create(empty_dir, showWarnings = FALSE)
  expect_error(read_figaro(empty_dir, year = 2023))

  ambiguous_dir <- file.path(tempdir(), "sube-figaro-ambig")
  dir.create(ambiguous_dir, showWarnings = FALSE)
  file.copy(
    list.files(figaro_fixture_dir(), full.names = TRUE),
    ambiguous_dir,
    overwrite = TRUE
  )
  # Create a second supply file to induce ambiguity
  file.copy(
    file.path(figaro_fixture_dir(), "flatfile_eu-ic-supply_sample.csv"),
    file.path(ambiguous_dir, "flatfile_eu-ic-supply_duplicate.csv")
  )
  expect_error(read_figaro(ambiguous_dir, year = 2023))
})

test_that("read_figaro strips CPA_ prefix and preserves inter-country rows (FIG-02, D-06, D-10)", {
  dir <- figaro_fixture_dir()
  out <- read_figaro(dir, year = 2023)

  expect_true(all(!startsWith(out$CPA, "CPA_")))
  expect_true(all(out$CPA %in% c("P01", "P02", "P03")))

  # Inter-country rows preserved (REP != PAR)
  expect_true(any(out$REP != out$PAR))
})

test_that("read_figaro filters primary-input rows with non-CPA rowPi (FIG-02, D-19)", {
  dir <- figaro_fixture_dir()
  out <- read_figaro(dir, year = 2023)

  expect_false("B2A3G" %in% out$CPA)
  expect_false("W2" %in% out$REP)
  expect_false("W2" %in% out$PAR)
  # Every remaining CPA code must have come from CPA_-prefixed rowPi
  expect_true(all(out$CPA %in% c("P01", "P02", "P03")))
})

test_that("read_figaro aggregates five FD codes into VAR = 'FU_bas' (FIG-02, D-20)", {
  dir <- figaro_fixture_dir()
  out <- read_figaro(dir, year = 2023)

  use_rows <- out[TYPE == "USE"]
  expect_true("FU_bas" %in% use_rows$VAR)
  # Original FD codes should NOT appear in output
  expect_false(any(c("P3_S13", "P3_S14", "P3_S15", "P51G", "P5M") %in% out$VAR))

  # Fixture: 2 countries × 3 CPA × (2+3+4+5+6)=20 per (REP,CPA)
  # Plan 02 aggregates over counterpart (FD rows have counterpart = refArea)
  # so expect 6 FU_bas rows totaling 6 * 20 = 120
  fu_rows <- use_rows[VAR == "FU_bas"]
  expect_equal(nrow(fu_rows), 6L)
  expect_equal(sum(fu_rows$VALUE), 120)
})

test_that("read_figaro preserves FIGW1 rows (FIG-02, D-21)", {
  dir <- figaro_fixture_dir()
  out <- read_figaro(dir, year = 2023)

  expect_true("FIGW1" %in% out$REP)
})

test_that("final_demand_vars arg validates membership and overrides aggregation set (FIG-02, D-20, D-22)", {
  dir <- figaro_fixture_dir()
  # Unknown code -> hard error
  expect_error(read_figaro(dir, year = 2023, final_demand_vars = "BOGUS"))

  # Subset aggregation yields smaller FU_bas total
  out_full <- read_figaro(dir, year = 2023)
  out_subset <- read_figaro(
    dir, year = 2023,
    final_demand_vars = c("P3_S14")
  )
  expect_lt(
    sum(out_subset[VAR == "FU_bas"]$VALUE),
    sum(out_full[VAR == "FU_bas"]$VALUE)
  )
})

test_that(".coerce_map routes NACE and NACE_R2 column names to VAR (FIG-03, D-16)", {
  sut <- sube_example_data("sut_data")
  cpa_map <- sube_example_data("cpa_map")

  # Use a NACE-named ind_map instead of VARS-named one
  nace_map <- data.table::data.table(
    NACE = c("I1", "I2"),
    INDagg = c("I01", "I02")
  )
  expect_silent(bundle_nace <- build_matrices(sut, cpa_map, nace_map))
  expect_s3_class(bundle_nace, "sube_matrices")
  expect_true(length(bundle_nace$matrices) > 0)

  # Same test with NACE_R2
  nace_r2_map <- data.table::data.table(
    NACE_R2 = c("I1", "I2"),
    INDagg = c("I01", "I02")
  )
  expect_silent(bundle_nace_r2 <- build_matrices(sut, cpa_map, nace_r2_map))
  expect_s3_class(bundle_nace_r2, "sube_matrices")
})

test_that("figaro-sample fixture directory is reachable via system.file (FIG-04)", {
  dir <- system.file("extdata", "figaro-sample", package = "sube")
  expect_true(nzchar(dir))
  expect_true(file.exists(file.path(dir, "flatfile_eu-ic-supply_sample.csv")))
  expect_true(file.exists(file.path(dir, "flatfile_eu-ic-use_sample.csv")))
})

test_that("read_figaro output flows through extract_domestic_block -> build_matrices -> compute_sube (FIG-04)", {
  dir <- figaro_fixture_dir()
  sut <- read_figaro(dir, year = 2023)

  domestic <- extract_domestic_block(sut)
  expect_s3_class(domestic, "sube_domestic_suts")
  expect_true(all(domestic$REP == domestic$PAR))

  maps <- make_tiny_figaro_maps()
  bundle <- build_matrices(domestic, maps$cpa_map, maps$ind_map)
  expect_s3_class(bundle, "sube_matrices")

  result <- compute_sube(bundle, maps$inputs)
  expect_s3_class(result, "sube_results")
  expect_true(nrow(result$summary) >= 1)
})
