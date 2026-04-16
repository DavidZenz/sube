# scripts/build_figaro_sample.R
# Regenerates inst/extdata/figaro-sample/flatfile_eu-ic-*_sample.csv
# per Phase 7 D-7.5. Run from repo root: Rscript scripts/build_figaro_sample.R
# The output is committed to git; re-running should produce byte-identical CSVs.

library(data.table)

# --- Parameters (match 07-02-PLAN interfaces) -----------------------------
cpa_codes <- c("A01", "A03", "C10T12", "C13T15", "C26", "F", "G46", "G47")
countries  <- c("DE", "FR", "IT")
fd_codes   <- c("P3_S13", "P3_S14", "P3_S15", "P51G", "P5M")
fd_values  <- c(P3_S13 = 2, P3_S14 = 3, P3_S15 = 4, P51G = 5, P5M = 6)

# --- Helper: canonical row string for rowPi / colPi -----------------------
cpa_prefix <- function(code) paste0("CPA_", code)

# --- Supply rows (domestic for all countries + one inter-country per pair) ---
supply_rows <- list()
for (rep in countries) {
  for (i in seq_along(cpa_codes)) {
    cpa <- cpa_codes[i]
    for (j in seq_along(cpa_codes)) {
      ind <- cpa_codes[j]
      # Diagonal dominance: diag cell 1000, off-diag 10..80 (cycling by position)
      val <- if (i == j) 1000 else 10 * ((abs(i - j) %% 8) + 1)
      supply_rows[[length(supply_rows) + 1]] <- list(
        icsupRow        = paste(rep, cpa_prefix(cpa), sep = "_"),
        icsupCol        = paste(rep, ind, sep = "_"),
        refArea         = rep,
        rowPi           = cpa_prefix(cpa),
        counterpartArea = rep,
        colPi           = ind,
        obsValue        = val
      )
    }
  }
}
# Inter-country supply (one row per ordered pair, small values) --- ensures REP != PAR coverage
for (a_rep in countries) {
  for (a_par in setdiff(countries, a_rep)) {
    supply_rows[[length(supply_rows) + 1]] <- list(
      icsupRow        = paste(a_rep, cpa_prefix("A01"), sep = "_"),
      icsupCol        = paste(a_par, "A01", sep = "_"),
      refArea         = a_rep,
      rowPi           = cpa_prefix("A01"),
      counterpartArea = a_par,
      colPi           = "A01",
      obsValue        = 5
    )
  }
}

supply_dt <- rbindlist(supply_rows)
setcolorder(supply_dt,
  c("icsupRow", "icsupCol", "refArea", "rowPi", "counterpartArea", "colPi", "obsValue"))

# --- Use rows (domestic inter-industry + FD block + B2A3G + FIGW1) --------
use_rows <- list()
for (rep in countries) {
  for (i in seq_along(cpa_codes)) {
    cpa <- cpa_codes[i]
    for (j in seq_along(cpa_codes)) {
      ind <- cpa_codes[j]
      # Diagonal dominance (smaller scale than supply): diag 100, off-diag 1..8
      val <- if (i == j) 100 else ((abs(i - j) %% 8) + 1)
      use_rows[[length(use_rows) + 1]] <- list(
        icuseRow        = paste(rep, cpa_prefix(cpa), sep = "_"),
        icuseCol        = paste(rep, ind, sep = "_"),
        refArea         = rep,
        rowPi           = cpa_prefix(cpa),
        counterpartArea = rep,
        colPi           = ind,
        obsValue        = val
      )
    }
  }
}
# FD block: per (REP, CPA) x each of 5 FD codes, value from fd_values
for (rep in countries) {
  for (cpa in cpa_codes) {
    for (fd in fd_codes) {
      use_rows[[length(use_rows) + 1]] <- list(
        icuseRow        = paste(rep, cpa_prefix(cpa), sep = "_"),
        icuseCol        = paste(rep, fd, sep = "_"),
        refArea         = rep,
        rowPi           = cpa_prefix(cpa),
        counterpartArea = rep,
        colPi           = fd,
        obsValue        = fd_values[[fd]]
      )
    }
  }
}
# B2A3G primary-input row (1 per country x 1 CPA, small value -- dropped by read_figaro
# at import per D-19; but presence needed so line 98-99 of test-figaro.R stays meaningful
# and cannot regress to "vacuously true")
for (rep in countries) {
  use_rows[[length(use_rows) + 1]] <- list(
    icuseRow        = paste(rep, "B2A3G", sep = "_"),
    icuseCol        = paste(rep, "A01", sep = "_"),
    refArea         = rep,
    rowPi           = "B2A3G",
    counterpartArea = rep,
    colPi           = "A01",
    obsValue        = 50
  )
}
# FIGW1 row (rest-of-world) -- preserved per D-21. Use refArea = "FIGW1" for one row.
use_rows[[length(use_rows) + 1]] <- list(
  icuseRow        = paste("FIGW1", cpa_prefix("A01"), sep = "_"),
  icuseCol        = paste("DE", "A01", sep = "_"),
  refArea         = "FIGW1",
  rowPi           = cpa_prefix("A01"),
  counterpartArea = "DE",
  colPi           = "A01",
  obsValue        = 3
)

use_dt <- rbindlist(use_rows)
setcolorder(use_dt,
  c("icuseRow", "icuseCol", "refArea", "rowPi", "counterpartArea", "colPi", "obsValue"))

# --- Write CSVs (no quoting, no scientific notation for stable diffs) -----
out_dir <- file.path("inst", "extdata", "figaro-sample")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
fwrite(supply_dt, file.path(out_dir, "flatfile_eu-ic-supply_sample.csv"),
       quote = FALSE, scipen = 50)
fwrite(use_dt,    file.path(out_dir, "flatfile_eu-ic-use_sample.csv"),
       quote = FALSE, scipen = 50)

cat("Wrote:\n",
    "  supply rows:", nrow(supply_dt), "\n",
    "  use rows:   ", nrow(use_dt),    "\n",
    "  sizes (KB): ",
    round(file.size(file.path(out_dir, "flatfile_eu-ic-supply_sample.csv")) / 1024, 1),
    "+",
    round(file.size(file.path(out_dir, "flatfile_eu-ic-use_sample.csv"))    / 1024, 1),
    "\n")
