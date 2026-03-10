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
      .sube_required_columns(data, c("REP", "PAR", "CPA", "VAR", "VALUE", "YEAR", "TYPE"))
      return(data[, .(REP, PAR, CPA, VAR, VALUE, YEAR, TYPE)])
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

