# tests/testthat/test-replication.R
# REP-01: paper-replication numerical match test.
# Gated on SUBE_WIOD_DIR env var (or inst/extdata/wiod fallback).
# Skips cleanly on CRAN and when data is unavailable (per CONTEXT.md D-02/D-04/D-06).

# Memoised fixture loader: runs the expensive pipeline at most once per
# test-file invocation. Returns NULL when no data root is available so
# test_that blocks can skip rather than error.
.replication_bundle <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      root <- resolve_wiod_root()
      if (!nzchar(root)) return(NULL)
      cache <<- build_replication_fixtures(root)
    }
    cache
  }
})

# Aggregate columns stripped from the legacy wide CSVs so only the 56
# industry columns remain alongside CPA (cf. R/import.R wide-CSV branch).
.legacy_drop_cols <- c("REP", "PAR", "YEAR", "TYPE",
                       "DSUP_bas", "IMP", "SUP_bas",
                       "ExpTTM", "ReEXP", "IntTTM")

test_that("model_data W matrix matches legacy ground truth within 1e-6", {
  testthat::skip_on_cran()
  root <- resolve_wiod_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_WIOD_DIR not set - paper replication test skipped"
  )

  bundle <- .replication_bundle()
  testthat::skip_if(is.null(bundle), "replication fixture build failed")

  for (country in c("AUS", "DEU", "USA", "JPN")) {
    our <- bundle$model_data[COUNTRY == country & YEAR == 2005]
    testthat::expect_gt(nrow(our), 0, info = country)
    testthat::expect_equal(nrow(our), 56L, info = country)

    legacy <- data.table::fread(
      file.path(root, "Regression", "data", sprintf("%s_2005.csv", country))
    )

    data.table::setorder(our, INDUSTRIES)
    data.table::setorder(legacy, INDUSTRIES)

    testthat::expect_equal(our$INDUSTRIES, legacy$INDUSTRIES, info = country)

    for (p in sprintf("P%02d", 1:22)) {
      testthat::expect_equal(
        our[[p]], legacy[[p]],
        tolerance = 1e-6, info = paste(country, p)
      )
    }
  }
})

test_that("raw SUP cells match legacy wide CSV within 1e-6", {
  testthat::skip_on_cran()
  root <- resolve_wiod_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_WIOD_DIR not set - paper replication test skipped"
  )

  sut <- sube::import_suts(file.path(root, "International SUTs domestic"))
  raw_path <- file.path(root, "International SUTs domestic",
                        "Int_SUTs_domestic_SUP_2005_May18.csv")
  raw_all <- data.table::fread(raw_path)

  for (country in c("AUS", "DEU", "USA", "JPN")) {
    raw_wide <- raw_all[REP == country & PAR == country]
    raw_wide <- raw_wide[, setdiff(names(raw_wide), .legacy_drop_cols),
                         with = FALSE]
    # Defensive: legacy CPA may carry a "CPA_" prefix that our pipeline strips.
    raw_wide[, CPA := sub("^CPA_", "", CPA)]

    our_wide <- data.table::dcast(
      sut[REP == country & PAR == country & YEAR == 2005 &
            TYPE == "SUP" & VAR != "FU_BAS"],
      CPA ~ VAR, value.var = "VALUE", fill = 0
    )

    data.table::setorder(our_wide, CPA)
    data.table::setorder(raw_wide, CPA)

    testthat::expect_equal(our_wide$CPA, raw_wide$CPA, info = country)

    ind_cols <- setdiff(intersect(names(our_wide), names(raw_wide)), "CPA")
    for (col in ind_cols) {
      testthat::expect_equal(
        our_wide[[col]], raw_wide[[col]],
        tolerance = 1e-6, info = paste(country, "SUP", col)
      )
    }
  }
})

test_that("raw USE cells match legacy wide CSV within 1e-6", {
  testthat::skip_on_cran()
  root <- resolve_wiod_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_WIOD_DIR not set - paper replication test skipped"
  )

  sut <- sube::import_suts(file.path(root, "International SUTs domestic"))
  raw_path <- file.path(root, "International SUTs domestic",
                        "Int_SUTs_domestic_USE_2005_May18.csv")
  raw_all <- data.table::fread(raw_path)

  for (country in c("AUS", "DEU", "USA", "JPN")) {
    raw_wide <- raw_all[REP == country & PAR == country]
    raw_wide <- raw_wide[, setdiff(names(raw_wide), .legacy_drop_cols),
                         with = FALSE]
    raw_wide[, CPA := sub("^CPA_", "", CPA)]

    our_wide <- data.table::dcast(
      sut[REP == country & PAR == country & YEAR == 2005 &
            TYPE == "USE" & VAR != "FU_BAS"],
      CPA ~ VAR, value.var = "VALUE", fill = 0
    )

    data.table::setorder(our_wide, CPA)
    data.table::setorder(raw_wide, CPA)

    testthat::expect_equal(our_wide$CPA, raw_wide$CPA, info = country)

    ind_cols <- setdiff(intersect(names(our_wide), names(raw_wide)), "CPA")
    for (col in ind_cols) {
      testthat::expect_equal(
        our_wide[[col]], raw_wide[[col]],
        tolerance = 1e-6, info = paste(country, "USE", col)
      )
    }
  }
})
