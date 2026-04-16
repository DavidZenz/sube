# tests/testthat/helper-gated-data.R
# Shared fixtures and env-var resolvers for the gated data tests
# (paper-replication + FIGARO E2E). Renamed from helper-replication.R
# in Phase 7 (INFRA-02 / D-7.7). Do NOT source this file manually --
# testthat auto-loads helper-*.R.

# Resolve the WIOD root directory.
# D-7.7: env-var-only contract. No fallback to inst/extdata/wiod/.
# Returns "" when SUBE_WIOD_DIR is unset or points at a missing dir;
# callers should skip_if_not(nzchar(root)).
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}

# Resolve the FIGARO root directory. Parallel contract to
# resolve_wiod_root(): env-var-only, no fallback. Gates the FIG-E2E-01
# test introduced in 07-04-*.
resolve_figaro_root <- function() {
  env <- Sys.getenv("SUBE_FIGARO_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
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

# Derive cpa_map + ind_map from a character vector of CPA codes per D-7.1
# (section-letter equivalence via substr(code, 1, 1)).
# Returns list(cpa_map, ind_map) — note different column names on each so
# .coerce_map()'s NACE synonym routes them correctly (see Pitfall 5).
build_nace_section_map <- function(codes) {
  sections <- substr(codes, 1L, 1L)
  list(
    cpa_map = data.table::data.table(CPA = codes, CPAagg = sections),
    ind_map = data.table::data.table(NACE = codes, INDagg = sections)
  )
}

# Run the full FIGARO pipeline against the shipped synthetic fixture.
# Returns list(sut, domestic, bundle, result) — all intermediates preserved
# for FIG-E2E-02 structural assertions.
build_figaro_pipeline_fixture_from_synthetic <- function() {
  fixture_dir <- system.file("extdata", "figaro-sample", package = "sube")
  stopifnot(nzchar(fixture_dir))

  sut <- sube::read_figaro(fixture_dir, year = 2023L)
  domestic <- sube::extract_domestic_block(sut)

  # D-7.1: section-letter aggregation. Note: domestic$VAR includes FU_bas
  # (per read_figaro synth); the industry map should cover only the
  # non-FD VAR values. Intersect with domestic$CPA to ensure equivalence.
  codes <- sort(unique(c(domestic$CPA,
                         setdiff(domestic$VAR, "FU_BAS"))))
  maps <- build_nace_section_map(codes)

  # Aggregated industries from the section map: A, C, F, G.
  agg_inds <- sort(unique(maps$ind_map$INDagg))
  countries <- sort(unique(domestic$REP))

  # Synthetic inputs: GO/VA/EMP/CO2 with sane ratios per (country, aggregated industry).
  inputs <- data.table::CJ(YEAR = 2023L, REP = countries,
                           INDUSTRY = agg_inds, sorted = FALSE)
  inputs[, GO  := seq(100, by = 10, length.out = nrow(inputs))]
  inputs[, VA  := GO * 0.4]
  inputs[, EMP := GO * 0.1]
  inputs[, CO2 := GO * 0.05]

  bundle <- sube::build_matrices(domestic, maps$cpa_map, maps$ind_map)
  result <- sube::compute_sube(bundle, inputs,
                               metrics = c("GO", "VA", "EMP", "CO2"))

  list(sut = sut, domestic = domestic, bundle = bundle, result = result)
}

# Projection helper for golden snapshots (D-7.3, RESEARCH § Pattern 2).
# Drops $matrices (BLAS-sensitive floating-point noise; Pitfall 4) and
# projects to deterministic tabular fields. Drift in L surfaces through
# summary$GO (derived via colSums(L) in R/compute.R:93).
.snapshot_projection <- function(result) {
  list(
    summary       = result$summary[order(COUNTRY, CPAagg)],
    tidy_shape    = list(rows = nrow(result$tidy),
                         cols = sort(names(result$tidy))),
    diagnostics   = result$diagnostics[order(country, year)]
  )
}

# Sidecar loader for the opt-in elasticity path (D-7.2). Expected layout:
#   $SUBE_FIGARO_INPUTS_DIR/{country}_{year}.csv with cols INDUSTRY/GO/VA/EMP/CO2
# Returns NULL if any sidecar is missing or malformed — opt-in branch
# then silently skips rather than hard-erroring.
.load_figaro_inputs_sidecars <- function(inputs_dir, countries, year, bundle) {
  rows <- list()
  for (cc in countries) {
    f <- file.path(inputs_dir, sprintf("%s_%d.csv", cc, year))
    if (!file.exists(f)) return(NULL)
    dt <- data.table::fread(f)
    if (!all(c("INDUSTRY","GO","VA","EMP","CO2") %in% names(dt))) return(NULL)
    dt[, YEAR := year]
    dt[, REP  := cc]
    rows[[length(rows) + 1]] <- dt[, .(YEAR, REP, INDUSTRY, GO, VA, EMP, CO2)]
  }
  data.table::rbindlist(rows)
}

# Run the full FIGARO pipeline against a real Eurostat FIGARO root
# (SUBE_FIGARO_DIR). Default metrics = "GO" with synthesized
# GO = colSums(S) because real FIGARO has no VA/EMP/CO2 sidecars
# (A3 escalation, D-7.2). Opt-in elasticity branch activates when
# SUBE_FIGARO_INPUTS_DIR points at valid sidecars.
build_figaro_pipeline_fixture_from_real <- function(root,
                                                     countries = c("DE","FR","IT","NL"),
                                                     year = 2023L) {
  sut <- sube::read_figaro(path = root, year = year)

  sut_scoped <- sut[REP %in% countries]

  domestic <- sube::extract_domestic_block(sut_scoped)

  codes <- sort(unique(c(domestic$CPA,
                         setdiff(domestic$VAR, "FU_bas"))))
  maps <- build_nace_section_map(codes)

  bundle <- sube::build_matrices(domestic, maps$cpa_map, maps$ind_map)

  inputs <- data.table::rbindlist(lapply(names(bundle$matrices), function(nm) {
    b <- bundle$matrices[[nm]]
    go <- as.numeric(colSums(b$S))
    data.table::data.table(
      YEAR = b$year, REP = b$country, INDUSTRY = b$industries, GO = go
    )
  }))

  result <- sube::compute_sube(bundle, inputs, metrics = "GO")

  inputs_dir <- Sys.getenv("SUBE_FIGARO_INPUTS_DIR", unset = "")
  result_opt <- NULL
  if (nzchar(inputs_dir) && dir.exists(inputs_dir)) {
    inputs_full <- .load_figaro_inputs_sidecars(inputs_dir, countries, year, bundle)
    if (!is.null(inputs_full)) {
      result_opt <- sube::compute_sube(bundle, inputs_full,
                                       metrics = c("GO","VA","EMP","CO2"))
    }
  }

  list(sut = sut_scoped, domestic = domestic, bundle = bundle,
       result = result, result_opt = result_opt, inputs = inputs)
}
