#' ============================================================================
#' SUBE Paper Replication Script
#'
#' Replicates the WIOD-based multiplier and elasticity computation from the
#' original paper using the sube R package, then compares against the legacy
#' output stored in inst/extdata/wiod/Regression/final/.
#'
#' Requirements:
#'   - sube package installed (devtools::install())
#'   - WIOD data in inst/extdata/wiod/ (not shipped in tarball — gitignored)
#'   - Legacy final results in inst/extdata/wiod/Regression/final/
#'
#' Usage:
#'   Rscript inst/scripts/replicate_paper.R
#'   # or source interactively in RStudio
#' ============================================================================

library(sube)
library(data.table)
library(haven)

cat("=============================================================\n")
cat(" SUBE Paper Replication\n")
cat("=============================================================\n\n")

# ---------------------------------------------------------------------------
# Step 1: Import WIOD domestic SUTs (wide CSV → long format)
# ---------------------------------------------------------------------------
cat("Step 1: Importing WIOD domestic SUTs...\n")

sut_dir <- "inst/extdata/wiod/International SUTs domestic"
stopifnot(dir.exists(sut_dir))

csv_files <- list.files(sut_dir, pattern = "\\.csv$", full.names = TRUE)
cat(sprintf("  Found %d CSV files\n", length(csv_files)))

# The domestic CSVs are in wide format: REP, PAR, CPA, <industries>, ..., YEAR, TYPE
# We melt them to long format for the sube pipeline.
all_data <- rbindlist(lapply(csv_files, function(f) {
  dt <- fread(f)
  cn <- names(dt)
  id_cols <- intersect(c("REP", "PAR", "CPA", "YEAR", "TYPE"), cn)

  # Non-industry columns to exclude from melting
  exclude <- c(
    "REP", "PAR", "CPA", "YEAR", "TYPE",
    # Supply aggregates
    "DSUP_bas", "IMP", "SUP_bas", "ExpTTM", "ReEXP", "IntTTM",
    # Use aggregates and demand components
    "DUSE_bas", "FU_bas", "USE_bas",
    "INTC", "CONS_h", "CONS_np", "CONS_g", "CONS",
    "GFCF", "INVEN", "GCF", "EXP"
  )
  ind_cols <- setdiff(cn, exclude)

  long <- melt(dt, id.vars = id_cols, measure.vars = ind_cols,
               variable.name = "VAR", value.name = "VALUE")

  # Add FU_bas (final demand at basic prices) as separate rows
  if ("FU_bas" %in% cn) {
    fd <- dt[, c(id_cols, "FU_bas"), with = FALSE]
    fd[, VAR := "FU_bas"]
    setnames(fd, "FU_bas", "VALUE")
    long <- rbindlist(list(long, fd), use.names = TRUE, fill = TRUE)
  }
  long
}), fill = TRUE)

# Extract domestic block (REP == PAR)
domestic <- all_data[REP == PAR]

# IMPORTANT: uppercase VAR values — build_matrices() does toupper(final_demand_var)
# so "FU_bas" must become "FU_BAS" to match.
domestic[, VAR := toupper(as.character(VAR))]

class(domestic) <- c("sube_suts", class(domestic))

cat(sprintf("  Total domestic rows: %s\n", format(nrow(domestic), big.mark = ",")))
cat(sprintf("  Countries: %d, Years: %d, Types: %s\n",
            length(unique(domestic$REP)),
            length(unique(domestic$YEAR)),
            paste(sort(unique(domestic$TYPE)), collapse = "/")))
cat(sprintf("  FU_BAS rows: %s\n\n", format(nrow(domestic[VAR == "FU_BAS"]), big.mark = ",")))


# ---------------------------------------------------------------------------
# Step 2: Load correspondence tables (CPA × industry aggregation)
# ---------------------------------------------------------------------------
cat("Step 2: Loading correspondence tables...\n")

cpa_map <- data.table(read_dta("inst/extdata/wiod/Correspondences/CorrespondenceCPA56.dta"))
ind_map <- data.table(read_dta("inst/extdata/wiod/Correspondences/CorrespondenceInd56.dta"))
setnames(cpa_map, "CPAagg", "CPA_AGG")
setnames(ind_map, "Indagg", "IND_AGG")

cat(sprintf("  cpa_map: 56 raw → %d aggregated products\n", length(unique(cpa_map$CPA_AGG))))
cat(sprintf("  ind_map: 56 raw → %d aggregated industries\n\n", length(unique(ind_map$IND_AGG))))


# ---------------------------------------------------------------------------
# Step 3: Build matrices (S, U per country-year + final demand)
# ---------------------------------------------------------------------------
cat("Step 3: Building matrices...\n")

matrices <- build_matrices(domestic, cpa_map, ind_map)

cat(sprintf("  Matrices: %d (country-year combinations)\n", length(matrices$matrices)))
cat(sprintf("  Final demand rows: %s\n", format(nrow(matrices$final_demand), big.mark = ",")))
cat(sprintf("  Aggregated products: %d, industries: %d\n\n",
            length(matrices$matrices[[1]]$products),
            length(matrices$matrices[[1]]$industries)))


# ---------------------------------------------------------------------------
# Step 4: Build aggregated inputs (GO, VA, EMP, CO2)
# ---------------------------------------------------------------------------
cat("Step 4: Loading and aggregating inputs...\n")

go_files <- list.files("inst/extdata/wiod/GOVAcur", pattern = "\\.dta$", full.names = TRUE)

inputs_list <- lapply(go_files, function(f) {
  dt <- data.table(read_dta(f))
  parts <- strsplit(tools::file_path_sans_ext(basename(f)), "_")[[1]]
  country <- parts[2]
  year <- as.integer(parts[3])

  emp_f <- file.path("inst/extdata/wiod/EMP", sprintf("EMP_%s_%d.dta", country, year))
  co2_f <- file.path("inst/extdata/wiod/CO2", sprintf("CO2_%s_%d.dta", country, year))
  if (!file.exists(emp_f) || !file.exists(co2_f)) return(NULL)

  emp_dt <- data.table(read_dta(emp_f))
  co2_dt <- data.table(read_dta(co2_f))

  # Raw inputs at 56-industry level

  raw <- data.table(
    YEAR = year, REP = country,
    INDUSTRY = ind_map$vars,
    IND_AGG = ind_map$IND_AGG,
    GO = dt$GO, VA = dt$VA,
    EMP = emp_dt$vEMP, CO2 = co2_dt$vCO2
  )

  # Aggregate to 22-industry level to match the correspondence tables
  raw[, .(GO = sum(GO), VA = sum(VA), EMP = sum(EMP), CO2 = sum(CO2)),
      by = .(YEAR, REP, INDUSTRY = IND_AGG)]
})
inputs <- rbindlist(inputs_list[!sapply(inputs_list, is.null)])

cat(sprintf("  Input rows: %s (%d countries × %d years × %d industries)\n",
            format(nrow(inputs), big.mark = ","),
            length(unique(inputs$REP)),
            length(unique(inputs$YEAR)),
            length(unique(inputs$INDUSTRY))))
cat("\n")


# ---------------------------------------------------------------------------
# Step 5: Compute SUBE multipliers and elasticities
# ---------------------------------------------------------------------------
cat("Step 5: Computing SUBE...\n")

results <- compute_sube(matrices, inputs)
sube <- results$summary

cat(sprintf("  Result rows: %s\n", format(nrow(sube), big.mark = ",")))
cat(sprintf("  Countries: %d, Years: %d, Products: %d\n",
            length(unique(sube$COUNTRY)),
            length(unique(sube$YEAR)),
            length(unique(sube$CPAagg))))
cat(sprintf("  Columns: %s\n\n", paste(names(sube), collapse = ", ")))


# ---------------------------------------------------------------------------
# Step 6: Compare with legacy results
# ---------------------------------------------------------------------------
cat("=============================================================\n")
cat(" Comparison with legacy paper results\n")
cat("=============================================================\n\n")

leg_mult_file <- "inst/extdata/wiod/Regression/final/final_multipliers.csv"
leg_elas_file <- "inst/extdata/wiod/Regression/final/final_elasticities.csv"

if (!file.exists(leg_mult_file) || !file.exists(leg_elas_file)) {
  cat("WARNING: Legacy result files not found. Skipping comparison.\n")
  cat(sprintf("  Expected: %s\n  Expected: %s\n", leg_mult_file, leg_elas_file))
} else {

  # --- 6a: Multiplier comparison ---
  cat("--- Multiplier comparison (Leontief type) ---\n\n")

  leg_mult <- fread(leg_mult_file)
  leg_leo <- leg_mult[type == "leo"]

  # Average our per-year multipliers across years
  our_avg <- sube[, .(
    our_GO  = mean(GO,  na.rm = TRUE),
    our_VA  = mean(VA,  na.rm = TRUE),
    our_EMP = mean(EMP, na.rm = TRUE),
    our_CO2 = mean(CO2, na.rm = TRUE)
  ), by = .(COUNTRY, CPAagg)]

  # Reshape legacy to wide
  leg_wide <- dcast(leg_leo, COUNTRY + CPAagg ~ variable, value.var = "value")
  setnames(leg_wide, c("GO", "VA", "EMP", "CO2"),
           c("leg_GO", "leg_VA", "leg_EMP", "leg_CO2"))

  comp_mult <- merge(our_avg, leg_wide, by = c("COUNTRY", "CPAagg"))

  for (metric in c("GO", "VA", "EMP", "CO2")) {
    our_col <- paste0("our_", metric)
    leg_col <- paste0("leg_", metric)
    diff_col <- paste0("diff_", metric)
    pct_col <- paste0("pct_", metric)
    comp_mult[, (diff_col) := get(our_col) - get(leg_col)]
    comp_mult[, (pct_col) := 100 * (get(our_col) - get(leg_col)) / abs(get(leg_col))]
  }

  cat(sprintf("Matched country-product pairs: %d (of %d in our results)\n",
              nrow(comp_mult), nrow(our_avg)))
  cat(sprintf("Legacy excluded %d pairs (negative elasticities / outliers)\n\n",
              nrow(our_avg) - nrow(comp_mult)))

  cat("Overall multiplier accuracy:\n")
  cat(sprintf("  %-4s  mean|diff|=%.6f  max|diff|=%.6f  mean|%%|=%.2f%%  max|%%|=%.2f%%\n",
              "GO",
              mean(abs(comp_mult$diff_GO), na.rm = TRUE),
              max(abs(comp_mult$diff_GO), na.rm = TRUE),
              mean(abs(comp_mult$pct_GO), na.rm = TRUE),
              max(abs(comp_mult$pct_GO), na.rm = TRUE)))
  cat(sprintf("  %-4s  mean|diff|=%.6f  max|diff|=%.6f  mean|%%|=%.2f%%  max|%%|=%.2f%%\n",
              "VA",
              mean(abs(comp_mult$diff_VA), na.rm = TRUE),
              max(abs(comp_mult$diff_VA), na.rm = TRUE),
              mean(abs(comp_mult$pct_VA), na.rm = TRUE),
              max(abs(comp_mult$pct_VA), na.rm = TRUE)))
  cat(sprintf("  %-4s  mean|diff|=%.8f  max|diff|=%.8f  mean|%%|=%.2f%%  max|%%|=%.2f%%\n",
              "EMP",
              mean(abs(comp_mult$diff_EMP), na.rm = TRUE),
              max(abs(comp_mult$diff_EMP), na.rm = TRUE),
              mean(abs(comp_mult$pct_EMP), na.rm = TRUE),
              max(abs(comp_mult$pct_EMP), na.rm = TRUE)))
  cat(sprintf("  %-4s  mean|diff|=%.6f  max|diff|=%.6f  mean|%%|=%.2f%%  max|%%|=%.2f%%\n",
              "CO2",
              mean(abs(comp_mult$diff_CO2), na.rm = TRUE),
              max(abs(comp_mult$diff_CO2), na.rm = TRUE),
              mean(abs(comp_mult$pct_CO2), na.rm = TRUE),
              max(abs(comp_mult$pct_CO2), na.rm = TRUE)))

  cat("\nAUS detail (GO multiplier):\n")
  print(comp_mult[COUNTRY == "AUS",
                  .(CPAagg, our_GO, leg_GO, diff_GO,
                    pct_GO = round(pct_GO, 2))])

  # --- 6b: Elasticity comparison ---
  # Legacy order: average raw elasticities across years FIRST, then compute
  # shares on the averaged values. This matches 08_outlier_treatment.R which
  # drops the YEAR column and calls mean() on raw GOe/VAe/EMPe/CO2e, and
  # the final_elasticities.csv stores those averaged shares.
  # compute_sube() outputs raw elasticities (GOe = multiplier * FD), not
  # shares — the share normalization is a post-processing choice.
  cat("\n--- Elasticity comparison (Leontief type) ---\n\n")

  leg_elas <- fread(leg_elas_file)
  leg_elas_leo <- leg_elas[type == "leo"]

  # Match legacy order: average raw elasticities first, then normalize to shares
  our_elas_raw_avg <- sube[, .(
    avg_GOe  = mean(GOe,  na.rm = TRUE),
    avg_VAe  = mean(VAe,  na.rm = TRUE),
    avg_EMPe = mean(EMPe, na.rm = TRUE),
    avg_CO2e = mean(CO2e, na.rm = TRUE)
  ), by = .(COUNTRY, CPAagg)]

  # Compute shares on the averaged values (not per-year shares averaged)
  our_elas_totals <- our_elas_raw_avg[, .(
    total_GOe  = sum(avg_GOe,  na.rm = TRUE),
    total_VAe  = sum(avg_VAe,  na.rm = TRUE),
    total_EMPe = sum(avg_EMPe, na.rm = TRUE),
    total_CO2e = sum(avg_CO2e, na.rm = TRUE)
  ), by = .(COUNTRY)]

  our_elas_avg <- merge(our_elas_raw_avg, our_elas_totals, by = "COUNTRY")
  our_elas_avg[, our_GO_e  := fifelse(total_GOe  != 0, avg_GOe  / total_GOe,  0)]
  our_elas_avg[, our_VA_e  := fifelse(total_VAe  != 0, avg_VAe  / total_VAe,  0)]
  our_elas_avg[, our_EMP_e := fifelse(total_EMPe != 0, avg_EMPe / total_EMPe, 0)]
  our_elas_avg[, our_CO2_e := fifelse(total_CO2e != 0, avg_CO2e / total_CO2e, 0)]

  leg_elas_wide <- dcast(leg_elas_leo, COUNTRY + CPAagg ~ variable, value.var = "value")
  setnames(leg_elas_wide, c("GO", "VA", "EMP", "CO2"),
           c("leg_GO_e", "leg_VA_e", "leg_EMP_e", "leg_CO2_e"))

  comp_elas <- merge(our_elas_avg, leg_elas_wide, by = c("COUNTRY", "CPAagg"))

  for (metric in c("GO", "VA", "EMP", "CO2")) {
    our_col <- paste0("our_", metric, "_e")
    leg_col <- paste0("leg_", metric, "_e")
    diff_col <- paste0("diff_", metric, "_e")
    comp_elas[, (diff_col) := get(our_col) - get(leg_col)]
  }

  cat(sprintf("Matched country-product pairs: %d\n\n", nrow(comp_elas)))

  cat("Overall elasticity accuracy (absolute diff in share points):\n")
  for (metric in c("GO", "VA", "EMP", "CO2")) {
    diff_col <- paste0("diff_", metric, "_e")
    cat(sprintf("  %-4s  mean|diff|=%.6f  max|diff|=%.6f\n",
                metric,
                mean(abs(comp_elas[[diff_col]]), na.rm = TRUE),
                max(abs(comp_elas[[diff_col]]), na.rm = TRUE)))
  }

  cat("\nAUS detail (GO elasticity):\n")
  print(comp_elas[COUNTRY == "AUS",
                  .(CPAagg, our_GO_e = round(our_GO_e, 6),
                    leg_GO_e = round(leg_GO_e, 6),
                    diff = round(diff_GO_e, 6))])
}


# ---------------------------------------------------------------------------
# Step 7: Apply legacy outlier treatment and re-compare
# ---------------------------------------------------------------------------
# The legacy pipeline (archive/legacy-scripts/07_neg_elasticities.R and
# 08_outlier_treatment.R) applies five layers of corrections before averaging
# multipliers and elasticities across years. The final_multipliers.csv and
# final_elasticities.csv files we compared against in Step 6 are the OUTPUT
# of this outlier treatment. To get a like-for-like comparison, we must apply
# the same filters to our per-year SUBE results before averaging.

cat("\n=============================================================\n")
cat(" Applying legacy outlier treatment\n")
cat("=============================================================\n\n")

# Start from our per-year results
filtered <- copy(sube)
n_start <- nrow(filtered)

# --- Layer 1: Drop entire countries ---
# 08_outlier_treatment.R lines 89-90: "drop Canada & Cyprus completely"
# Rationale: Canada has a known SUT compilation issue in WIOD that produces
# unstable Leontief inverses. Cyprus is too small and produces extreme
# multipliers in several products.
filtered <- filtered[!(COUNTRY %in% c("CAN", "CYP"))]
cat(sprintf("  Layer 1 (drop CAN, CYP):             %d rows dropped\n",
            n_start - nrow(filtered)))

# --- Layer 2: Drop country-year combinations ---
# 08_outlier_treatment.R lines 94-95: "Belgium 2000-2008"
# Rationale: Belgium had a statistical break in SUT compilation methodology
# around 2009. The pre-2009 data produces inconsistent multipliers.
n_before <- nrow(filtered)
filtered <- filtered[!(COUNTRY == "BEL" & YEAR %in% 2000:2008)]
cat(sprintf("  Layer 2 (drop BEL 2000-2008):         %d rows dropped\n",
            n_before - nrow(filtered)))

# --- Layer 3: Drop specific country-product combinations ---
# 08_outlier_treatment.R lines 98-139. Each rule addresses a product that
# produces extreme or economically implausible multipliers in that country,
# typically because of SUT compilation artefacts, very small sectors, or
# missing intermediate consumption data.
n_before <- nrow(filtered)

# Belgium P14 (lines 99-100): real estate — distorted by imputed rents
filtered <- filtered[!(COUNTRY == "BEL" & CPAagg == "P14")]

# Brazil P11 (lines 102-103): transport equipment — volatile FDI-driven sector
filtered <- filtered[!(COUNTRY == "BRA" & CPAagg == "P11")]

# Denmark P04/P09 (lines 105-106): mining & construction — small sectors
filtered <- filtered[!(COUNTRY == "DNK" & CPAagg %in% c("P04", "P09"))]

# Finland P20 (lines 108-109): public administration — measurement artefact
filtered <- filtered[!(COUNTRY == "FIN" & CPAagg == "P20")]

# Greece P09/P10 (lines 111-112): construction & trade — crisis-era distortions
filtered <- filtered[!(COUNTRY == "GRC" & CPAagg %in% c("P09", "P10"))]

# Croatia P05/P12/P18 (lines 114-115): energy, utilities, real estate — tiny economy
filtered <- filtered[!(COUNTRY == "HRV" & CPAagg %in% c("P05", "P12", "P18"))]

# Ireland P06 (lines 117-118): pharmaceuticals — transfer pricing distortion
filtered <- filtered[!(COUNTRY == "IRL" & CPAagg == "P06")]

# Luxembourg P04/P05/P06/P09/P12/P15/P17 (lines 120-121): 7 products —
# extremely small open economy, many sectors dominated by cross-border flows
filtered <- filtered[!(COUNTRY == "LUX" &
                         CPAagg %in% c("P04", "P05", "P06", "P09", "P12", "P15", "P17"))]

# Korea P11 (lines 123-124): transport equipment — chaebols distort I/O structure
filtered <- filtered[!(COUNTRY == "KOR" & CPAagg == "P11")]

# Mexico P19 (lines 126-127): education — public sector measurement issue
filtered <- filtered[!(COUNTRY == "MEX" & CPAagg == "P19")]

# Malta P08/P10/P15/P20 (lines 129-130): tiny island economy — 4 products unreliable
filtered <- filtered[!(COUNTRY == "MLT" & CPAagg %in% c("P08", "P10", "P15", "P20"))]

# Poland P15 (lines 132-133): transport — structural break during EU accession
filtered <- filtered[!(COUNTRY == "POL" & CPAagg == "P15")]

# Russia P20/P22 (lines 135-136): public admin & other services — data quality
filtered <- filtered[!(COUNTRY == "RUS" & CPAagg %in% c("P20", "P22"))]

# Slovenia P05/P19 (lines 138-139): energy & education — small-country artefacts
filtered <- filtered[!(COUNTRY == "SVN" & CPAagg %in% c("P05", "P19"))]

cat(sprintf("  Layer 3 (country-product exclusions):  %d rows dropped\n",
            n_before - nrow(filtered)))

# --- Layer 4: CO2 data availability ---
# 08_outlier_treatment.R lines 143-147. WIOD CO2 satellite accounts end in
# 2009, and three countries (Switzerland, Croatia, Norway) have no CO2 data
# at all in the WIOD release used for the paper. Dropping these avoids
# comparing CO2 multipliers/elasticities against missing data.
n_before <- nrow(filtered)

# Years after 2009 have no CO2 satellite data (line 143)
filtered <- filtered[!(YEAR > 2009)]

# Countries with no CO2 data at all (lines 146-147)
filtered <- filtered[!(COUNTRY %in% c("CHE", "HRV", "NOR"))]

cat(sprintf("  Layer 4 (CO2 gaps: >2009, CHE/HRV/NOR): %d rows dropped\n",
            n_before - nrow(filtered)))

# --- Layer 5: Multiplier bound filters ---
# 08_outlier_treatment.R lines 150-169. These are economic plausibility
# bounds. A GO multiplier outside [1, 4] indicates either a near-singular
# matrix (< 1, meaning intermediate consumption exceeds output — impossible
# in equilibrium) or an implausibly large ripple effect (> 4). VA must be
# in [0, 1] (value-added share of output). EMP and CO2 multipliers must
# be non-negative (negative means the sector "destroys" employment or
# emissions in response to demand — economically nonsensical).
n_before <- nrow(filtered)

# GO multiplier: must be in [1, 4] (lines 151-152)
filtered <- filtered[GO >= 1 & GO <= 4]

# VA multiplier: must be in [0, 1] (lines 156-157)
filtered <- filtered[VA >= 0 & VA <= 1]

# EMP multiplier: must be >= 0 (lines 161-162)
filtered <- filtered[EMP >= 0]

# CO2 multiplier: must be >= 0 (lines 166-167)
filtered <- filtered[CO2 >= 0]

cat(sprintf("  Layer 5 (multiplier bounds):           %d rows dropped\n",
            n_before - nrow(filtered)))

# --- Layer 6: Negative elasticity filter ---
# 08_outlier_treatment.R line 181. Any row where ANY of the four Leontief
# raw elasticities (GOe, VAe, EMPe, CO2e) is negative gets dropped. The
# legacy checks the raw values (multiplier * FD), not shares. A negative
# raw elasticity means that an increase in final demand for this product
# would decrease total output (or VA/EMP/CO2) — economically implausible.
n_before <- nrow(filtered)

# Drop rows with any negative raw elasticity (line 181)
# Note: the legacy checks GOe.leo < 0, not the share — raw values.
filtered <- filtered[GOe >= 0 & VAe >= 0 & EMPe >= 0 & CO2e >= 0]

cat(sprintf("  Layer 6 (negative elasticities):       %d rows dropped\n",
            n_before - nrow(filtered)))

cat(sprintf("\n  Surviving rows: %d of %d (%.1f%% retained)\n\n",
            nrow(filtered), n_start,
            100 * nrow(filtered) / n_start))


# ---------------------------------------------------------------------------
# Step 8: Average filtered results and compare with legacy
# ---------------------------------------------------------------------------
cat("=============================================================\n")
cat(" Filtered comparison with legacy paper results\n")
cat("=============================================================\n\n")

# --- 8a: Multiplier comparison (filtered) ---
cat("--- Multiplier comparison (filtered, Leontief) ---\n\n")

our_avg_f <- filtered[, .(
  our_GO  = mean(GO,  na.rm = TRUE),
  our_VA  = mean(VA,  na.rm = TRUE),
  our_EMP = mean(EMP, na.rm = TRUE),
  our_CO2 = mean(CO2, na.rm = TRUE)
), by = .(COUNTRY, CPAagg)]

comp_mult_f <- merge(our_avg_f, leg_wide, by = c("COUNTRY", "CPAagg"))
for (metric in c("GO", "VA", "EMP", "CO2")) {
  our_col <- paste0("our_", metric)
  leg_col <- paste0("leg_", metric)
  comp_mult_f[, paste0("diff_", metric) := get(our_col) - get(leg_col)]
  comp_mult_f[, paste0("pct_", metric) := 100 * (get(our_col) - get(leg_col)) / abs(get(leg_col))]
}

cat(sprintf("Matched pairs: %d\n\n", nrow(comp_mult_f)))

cat("Overall multiplier accuracy (after outlier treatment):\n")
for (metric in c("GO", "VA", "EMP", "CO2")) {
  diff_col <- paste0("diff_", metric)
  pct_col <- paste0("pct_", metric)
  fmt <- if (metric == "EMP") "%.8f" else "%.6f"
  cat(sprintf("  %-4s  mean|diff|=%s  max|diff|=%s  mean|%%|=%.2f%%  max|%%|=%.2f%%\n",
              metric,
              sprintf(fmt, mean(abs(comp_mult_f[[diff_col]]), na.rm = TRUE)),
              sprintf(fmt, max(abs(comp_mult_f[[diff_col]]), na.rm = TRUE)),
              mean(abs(comp_mult_f[[pct_col]]), na.rm = TRUE),
              max(abs(comp_mult_f[[pct_col]]), na.rm = TRUE)))
}

cat("\nAUS detail (GO multiplier, filtered):\n")
print(comp_mult_f[COUNTRY == "AUS",
                  .(CPAagg, our_GO, leg_GO,
                    diff = round(diff_GO, 6),
                    pct  = round(pct_GO, 2))])

# --- 8b: Elasticity comparison (filtered) ---
# Same legacy order as Step 6b: average raw elasticities first, then normalize
# to shares on the averaged values.
cat("\n--- Elasticity comparison (filtered, Leontief) ---\n\n")

our_elas_raw_avg_f <- filtered[, .(
  avg_GOe  = mean(GOe,  na.rm = TRUE),
  avg_VAe  = mean(VAe,  na.rm = TRUE),
  avg_EMPe = mean(EMPe, na.rm = TRUE),
  avg_CO2e = mean(CO2e, na.rm = TRUE)
), by = .(COUNTRY, CPAagg)]

our_elas_totals_f <- our_elas_raw_avg_f[, .(
  total_GOe  = sum(avg_GOe,  na.rm = TRUE),
  total_VAe  = sum(avg_VAe,  na.rm = TRUE),
  total_EMPe = sum(avg_EMPe, na.rm = TRUE),
  total_CO2e = sum(avg_CO2e, na.rm = TRUE)
), by = .(COUNTRY)]

our_elas_avg_f <- merge(our_elas_raw_avg_f, our_elas_totals_f, by = "COUNTRY")
our_elas_avg_f[, our_GO_e  := fifelse(total_GOe  != 0, avg_GOe  / total_GOe,  0)]
our_elas_avg_f[, our_VA_e  := fifelse(total_VAe  != 0, avg_VAe  / total_VAe,  0)]
our_elas_avg_f[, our_EMP_e := fifelse(total_EMPe != 0, avg_EMPe / total_EMPe, 0)]
our_elas_avg_f[, our_CO2_e := fifelse(total_CO2e != 0, avg_CO2e / total_CO2e, 0)]

comp_elas_f <- merge(our_elas_avg_f, leg_elas_wide, by = c("COUNTRY", "CPAagg"))
for (metric in c("GO", "VA", "EMP", "CO2")) {
  our_col <- paste0("our_", metric, "_e")
  leg_col <- paste0("leg_", metric, "_e")
  comp_elas_f[, paste0("diff_", metric, "_e") := get(our_col) - get(leg_col)]
}

cat(sprintf("Matched pairs: %d\n\n", nrow(comp_elas_f)))

cat("Overall elasticity accuracy (filtered, share points):\n")
for (metric in c("GO", "VA", "EMP", "CO2")) {
  diff_col <- paste0("diff_", metric, "_e")
  cat(sprintf("  %-4s  mean|diff|=%.6f  max|diff|=%.6f\n",
              metric,
              mean(abs(comp_elas_f[[diff_col]]), na.rm = TRUE),
              max(abs(comp_elas_f[[diff_col]]), na.rm = TRUE)))
}

cat("\nAUS detail (GO elasticity, filtered):\n")
print(comp_elas_f[COUNTRY == "AUS",
                  .(CPAagg,
                    our    = round(our_GO_e, 6),
                    legacy = round(leg_GO_e, 6),
                    diff   = round(diff_GO_e, 6))])


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat("\n=============================================================\n")
cat(" Replication complete\n")
cat("=============================================================\n\n")

cat("Pipeline:  import → domestic block → build_matrices → compute_sube\n")
cat("Outliers:  6 layers from 08_outlier_treatment.R applied\n\n")

cat("Remaining differences (if any) may stem from:\n")
cat("  1. The legacy Leontief multipliers in final_multipliers.csv may have\n")
cat("     been post-processed further (e.g. renormalized after dropping rows).\n")
cat("  2. Minor floating-point differences from 56→22 aggregation order.\n")
cat("  3. Rows dropped by the legacy OLS-side filter (p-value >= 0.05 in\n")
cat("     07_neg_elasticities.R) that also exclude Leontief rows via the\n")
cat("     merge in 08_outlier_treatment.R — we only filter Leontief bounds.\n")
cat("\nNext steps:\n")
cat("  - Compare regression estimates (OLS, pooled, between) via\n")
cat("    estimate_elasticities()\n")
cat("  - Replicate the paper's figures using plot_paper_comparison() etc.\n")
