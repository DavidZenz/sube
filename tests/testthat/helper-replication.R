# tests/testthat/helper-replication.R
# Shared fixtures for the paper-replication test. Lifted from
# inst/scripts/replicate_paper.R steps 1-4 + 9a. Do NOT source this file
# manually -- testthat auto-loads helper-*.R.

# Resolve the WIOD root directory. Priority:
#   1) SUBE_WIOD_DIR env var (researcher-set, per CONTEXT.md D-04)
#   2) system.file("extdata", "wiod", package = "sube") local-dev fallback (D-06)
#   3) "" (empty) -> caller should skip_if_not(nzchar(root))
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) return(env)
  fallback <- system.file("extdata", "wiod", package = "sube")
  if (nzchar(fallback) && dir.exists(fallback)) return(fallback)
  ""
}

# Build the bundle the test asserts against. Runs the full pipeline once;
# test_that blocks reuse the returned bundle via a memoised closure in
# the test file. Returns the list from build_matrices(..., inputs = inputs_raw)
# -- in particular $model_data.
build_replication_fixtures <- function(root, countries = c("AUS", "DEU", "USA", "JPN"),
                                       year = 2005L) {
  sut_dir <- file.path(root, "International SUTs domestic")
  sut <- sube::import_suts(sut_dir)
  domestic <- sube::extract_domestic_block(sut)

  cpa_map <- data.table::data.table(haven::read_dta(
    file.path(root, "Correspondences", "CorrespondenceCPA56.dta")))
  ind_map <- data.table::data.table(haven::read_dta(
    file.path(root, "Correspondences", "CorrespondenceInd56.dta")))
  data.table::setnames(cpa_map, "CPAagg", "CPA_AGG")
  data.table::setnames(ind_map, "Indagg", "IND_AGG")

  ind_codes_raw <- ind_map$vars

  go_files <- list.files(file.path(root, "GOVAcur"),
                         pattern = "\\.dta$", full.names = TRUE)
  inputs_raw <- data.table::rbindlist(Filter(Negate(is.null), lapply(go_files, function(f) {
    parts <- strsplit(tools::file_path_sans_ext(basename(f)), "_")[[1]]
    cc <- parts[2]
    yr <- suppressWarnings(as.integer(parts[3]))
    if (is.na(yr)) return(NULL)
    emp_f <- file.path(root, "EMP", sprintf("EMP_%s_%d.dta", cc, yr))
    co2_f <- file.path(root, "CO2", sprintf("CO2_%s_%d.dta", cc, yr))
    if (!file.exists(emp_f) || !file.exists(co2_f)) return(NULL)
    dt <- data.table::data.table(haven::read_dta(f))
    emp_dt <- data.table::data.table(haven::read_dta(emp_f))
    co2_dt <- data.table::data.table(haven::read_dta(co2_f))
    data.table::data.table(
      YEAR = yr, REP = cc, INDUSTRY = ind_codes_raw,
      GO = dt$GO, VA = dt$VA, EMP = emp_dt$vEMP, CO2 = co2_dt$vCO2
    )
  })))

  sube::build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)
}
