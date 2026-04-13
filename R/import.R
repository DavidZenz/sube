#' Import Supply-Use Tables
#'
#' `import_suts()` reads either WIOD-style Excel workbooks or pre-normalized
#' CSV files and returns a long table with standard SUBE columns.
#'
#' `extract_domestic_block()` filters an imported table to the domestic block
#' (`REP == PAR`).
#'
#' `sube_example_data()` loads tiny example inputs shipped in
#' `inst/extdata/sample`.
#'
#' @param path Path to a workbook, a directory of workbooks, a normalized CSV,
#'   or a directory of normalized CSV files.
#' @param sheets Sheet names to import from workbooks.
#' @param recursive Whether to scan subdirectories when `path` is a directory.
#' @param data Imported SUT data.
#' @param name Name of the example dataset. One of `"sut_data"`, `"cpa_map"`,
#'   `"ind_map"`, `"inputs"`, or `"model_data"`.
#'
#' @return `import_suts()` returns an object of class `c("sube_suts",
#'   "data.table", "data.frame")`. `extract_domestic_block()` returns an object
#'   of class `c("sube_domestic_suts", "sube_suts", "data.table",
#'   "data.frame")`. `sube_example_data()` returns a `data.table`.
#' @export
import_suts <- function(path, sheets = c("SUP", "USE"), recursive = FALSE) {
  if (!dir.exists(path) && !file.exists(path)) {
    stop("`path` does not exist.", call. = FALSE)
  }

  if (dir.exists(path)) {
    files <- list.files(path, pattern = "\\.(xlsx|csv)$", full.names = TRUE, recursive = recursive)
  } else {
    files <- path
  }

  if (length(files) == 0L) {
    stop("No supported input files were found.", call. = FALSE)
  }

  tables <- lapply(files, function(file_name) {
    if (grepl("\\.csv$", file_name, ignore.case = TRUE)) {
      data <- .standardize_names(fread(file_name))
      canonical <- c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE")

      if (all(canonical %in% names(data))) {
        # Already in long format — use directly
        return(data[, canonical, with = FALSE])
      }

      # Wide format: has REP, PAR, CPA, YEAR, TYPE but industry codes as
      # columns instead of a VAR/VALUE pair. Melt industry columns to long.
      wide_id <- c("REP", "PAR", "CPA", "YEAR", "TYPE")
      if (!all(wide_id %in% names(data))) {
        warning(sprintf(
          "Skipping %s — not a recognized SUT format (missing: %s).",
          basename(file_name),
          paste(setdiff(wide_id, names(data)), collapse = ", ")
        ), call. = FALSE)
        return(NULL)
      }

      # Non-industry columns to exclude from melting (known WIOD aggregates)
      known_agg <- c(
        "DSUP_BAS", "IMP", "SUP_BAS", "EXPTTM", "REEXP", "INTTTM",
        "DUSE_BAS", "FU_BAS", "USE_BAS",
        "INTC", "CONS_H", "CONS_NP", "CONS_G", "CONS",
        "GFCF", "INVEN", "GCF", "EXP"
      )
      ind_cols <- setdiff(names(data), c(wide_id, known_agg))

      long <- melt(data, id.vars = wide_id, measure.vars = ind_cols,
                   variable.name = "VAR", value.name = "VALUE")
      long[, VAR := as.character(VAR)]

      # Append FU_BAS as separate rows if present (final demand at basic prices)
      if ("FU_BAS" %in% names(data)) {
        fd <- data[, c(wide_id, "FU_BAS"), with = FALSE]
        fd[, VAR := "FU_BAS"]
        setnames(fd, "FU_BAS", "VALUE")
        long <- rbindlist(list(long, fd), use.names = TRUE, fill = TRUE)
      }

      return(long[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)])
    }

    wb <- loadWorkbook(file_name)
    available <- intersect(sheets, wb$sheet_names)
    if (length(available) == 0L) {
      stop(sprintf("No matching sheets found in %s.", basename(file_name)), call. = FALSE)
    }

    year <- .parse_year_from_name(file_name)
    rbindlist(lapply(available, function(sheet_name) {
      raw <- .standardize_names(readWorkbook(wb, sheet = sheet_name))
      .sube_required_columns(raw, c("REP", "PAR", "CPA"))
      id_cols <- c("REP", "PAR", "CPA")
      long <- melt(raw, id.vars = id_cols, variable.name = "VAR", value.name = "VALUE")
      long[, YEAR := year]
      long[, TYPE := toupper(sheet_name)]
      long[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)]
    }), fill = TRUE)
  })

  tables <- tables[!vapply(tables, is.null, logical(1))]
  if (length(tables) == 0L) {
    stop("No usable SUT data found in the input files.", call. = FALSE)
  }

  out <- rbindlist(tables, fill = TRUE)
  class(out) <- c("sube_suts", class(out))
  out[]
}

#' @rdname import_suts
#' @export
extract_domestic_block <- function(data) {
  data <- .standardize_names(data)
  .sube_required_columns(data, c("REP", "PAR"))
  out <- data[REP == PAR]
  class(out) <- c("sube_domestic_suts", "sube_suts", setdiff(class(out), c("sube_domestic_suts", "sube_suts")))
  out[]
}

#' Import FIGARO Supply-Use Tables
#'
#' `read_figaro()` reads a pair of Eurostat FIGARO industry-by-industry
#' flat-format CSV files (one supply, one use) from a single directory and
#' returns the canonical `sube_suts` long table with columns `REP`, `PAR`,
#' `CPA`, `VAR`, `VALUE`, `YEAR`, and `TYPE`. The output feeds directly into
#' [extract_domestic_block()], [build_matrices()], and [compute_sube()]
#' without modification.
#'
#' The function expects a directory containing exactly one supply file and
#' exactly one use file. Files are identified by filename: supply files
#' match `-supply-` or `_supply_` (case-insensitive), use files match
#' `-use-` or `_use_`. Zero or multiple matches on either side is a hard
#' error. Single-file input is not supported in this release.
#'
#' Primary-input rows (`rowPi` values not starting with `CPA_`, e.g.
#' `B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES`) are dropped
#' during import because they are SNA/ESA value-added blocks, not products.
#' The `CPA_` prefix on the remaining `rowPi` values is stripped so product
#' codes match NACE-style industry codes lexically.
#'
#' FIGARO publishes five final-demand codes (`P3_S13`, `P3_S14`, `P3_S15`,
#' `P51G`, `P5M`). On the use file these are summed per `(REP, PAR, CPA)`
#' into a single synthetic row with `VAR = "FU_bas"` so the result consumes
#' cleanly with [build_matrices()] `final_demand_var = "FU_bas"`. Pass a
#' custom character vector to `final_demand_vars` to override the
#' aggregation set (e.g. only household consumption).
#'
#' `FIGW1` (FIGARO rest-of-world 1) is a real country code in FIGARO
#' releases and is preserved in the output alongside real country codes.
#'
#' @param path Directory containing one FIGARO supply file and one FIGARO
#'   use file. Neither a single-file path nor recursive directory scanning
#'   is supported.
#' @param year Four-digit integer reference year for the data (the year
#'   encoded in the FIGARO filename, e.g. `2023` in
#'   `flatfile_eu-ic-supply_25ed_2023.csv`). Required; there is no
#'   auto-inference from the filename.
#' @param final_demand_vars Character vector of FIGARO `colPi` codes to sum
#'   into the synthetic `VAR = "FU_bas"` row on the use file. Defaults to
#'   the full FIGARO final-demand set. Every supplied code must exist in
#'   the use file's `colPi` column; unknown codes are a hard error.
#'
#' @return An object of class `c("sube_suts", "data.table", "data.frame")`
#'   with columns `REP`, `PAR`, `CPA`, `VAR`, `VALUE`, `YEAR`, `TYPE`.
#'
#' @details
#' Full FIGARO flat files (e.g. the 25th-edition 2023 release) are
#' approximately 400--500 MB each and expand to roughly 3--5 GB of peak
#' resident memory during `data.table::fread()`. Ensure sufficient RAM
#' before calling `read_figaro()` on a production release. The synthetic
#' fixture under `inst/extdata/figaro-sample/` is a few kilobytes and is
#' intended for tests and examples only.
#'
#' The `year` argument should match the reference / data year encoded in
#' the FIGARO filename (e.g. `2023` in `flatfile_eu-ic-supply_25ed_2023.csv`),
#' not the edition or release year.
#'
#' @export
read_figaro <- function(path, year,
                        final_demand_vars = c("P3_S13", "P3_S14", "P3_S15", "P51G", "P5M")) {
  # --- Step 1: validate `path` (D-11) ------------------------------------
  if (missing(path) || length(path) != 1L || !is.character(path) || !nzchar(path)) {
    stop("`path` must be a single directory path.", call. = FALSE)
  }
  if (!dir.exists(path)) {
    stop(sprintf("`path` does not exist or is not a directory: %s", path),
         call. = FALSE)
  }

  # --- Step 2: validate `year` (D-08) ------------------------------------
  if (missing(year) || length(year) != 1L || !is.numeric(year) ||
      is.na(year) || year != as.integer(year) ||
      year < 1900L || year > 2100L) {
    stop("`year` must be a single four-digit integer (e.g. 2023).",
         call. = FALSE)
  }
  year <- as.integer(year)

  # --- Step 3: validate `final_demand_vars` (D-22) -----------------------
  if (!is.character(final_demand_vars) || length(final_demand_vars) < 1L ||
      any(!nzchar(final_demand_vars)) || anyNA(final_demand_vars)) {
    stop("`final_demand_vars` must be a non-empty character vector.",
         call. = FALSE)
  }

  # --- Step 4: pair supply + use files in the directory (D-11, D-12) -----
  csv_files <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                          ignore.case = TRUE, recursive = FALSE)
  supply_files <- csv_files[grepl("[-_]supply[-_]", basename(csv_files),
                                  ignore.case = TRUE)]
  use_files    <- csv_files[grepl("[-_]use[-_]",    basename(csv_files),
                                  ignore.case = TRUE)]

  if (length(supply_files) != 1L) {
    stop(sprintf(
      "Expected exactly one FIGARO supply file in %s (found %d: %s).",
      path, length(supply_files),
      paste(basename(supply_files), collapse = ", ")
    ), call. = FALSE)
  }
  if (length(use_files) != 1L) {
    stop(sprintf(
      "Expected exactly one FIGARO use file in %s (found %d: %s).",
      path, length(use_files),
      paste(basename(use_files), collapse = ", ")
    ), call. = FALSE)
  }

  # --- Step 5: read each file and transform into canonical shape ---------
  process_one <- function(file_path, type_tag) {
    dt <- fread(file_path)

    required_in <- c("refArea", "rowPi", "counterpartArea", "colPi", "obsValue")
    missing_in <- setdiff(required_in, names(dt))
    if (length(missing_in) > 0L) {
      stop(sprintf(
        "FIGARO file %s is missing required columns: %s",
        basename(file_path), paste(missing_in, collapse = ", ")
      ), call. = FALSE)
    }

    # Step 5a: drop primary-input rows (D-19) -- rowPi must start with CPA_
    dt <- dt[startsWith(rowPi, "CPA_")]

    # Step 5b: rename + project to canonical columns (D-03)
    out <- data.table(
      REP   = as.character(dt$refArea),
      PAR   = as.character(dt$counterpartArea),
      CPA   = substring(dt$rowPi, 5L),   # strip "CPA_" prefix (D-06)
      VAR   = as.character(dt$colPi),    # D-07 pass-through
      VALUE = as.numeric(dt$obsValue),
      YEAR  = year,
      TYPE  = type_tag
    )

    # Step 5c: on the USE file, validate final_demand_vars then aggregate (D-20)
    if (type_tag == "USE") {
      missing_fd <- setdiff(final_demand_vars, unique(out$VAR))
      if (length(missing_fd) > 0L) {
        stop(sprintf(
          "`final_demand_vars` references codes not present in the USE file's colPi: %s",
          paste(missing_fd, collapse = ", ")
        ), call. = FALSE)
      }

      fd <- out[VAR %in% final_demand_vars,
                .(VALUE = sum(VALUE, na.rm = TRUE),
                  VAR   = "FU_bas",
                  YEAR  = year,
                  TYPE  = "USE"),
                by = .(REP, PAR, CPA)]
      non_fd <- out[!(VAR %in% final_demand_vars)]

      out <- rbindlist(
        list(
          non_fd,
          fd[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)]
        ),
        use.names = TRUE, fill = FALSE
      )
    }

    out[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)]
  }

  sup <- process_one(supply_files, "SUP")
  use <- process_one(use_files,    "USE")

  # --- Step 6: bind + canonical shape assertion + class tag --------------
  out <- rbindlist(list(sup, use), use.names = TRUE, fill = FALSE)
  .sube_required_columns(out, c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE"))
  class(out) <- c("sube_suts", class(out))
  out[]
}

#' @rdname import_suts
#' @export
sube_example_data <- function(name = c("sut_data", "cpa_map", "ind_map", "inputs", "model_data")) {
  name <- match.arg(name)
  path <- system.file("extdata", "sample", paste0(name, ".csv"), package = "sube")
  if (!nzchar(path)) {
    stop("Example data file was not found.", call. = FALSE)
  }
  fread(path)
}

