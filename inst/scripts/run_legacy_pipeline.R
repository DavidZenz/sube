#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4L) {
  stop(
    "Usage: run_legacy_pipeline.R <sut_path> <cpa_map.csv> <ind_map.csv> <inputs.csv> [output_dir]",
    call. = FALSE
  )
}

library(sube)

output_dir <- if (length(args) >= 5L) args[[5L]] else "output"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

sut <- import_suts(args[[1L]])
domestic <- extract_domestic_block(sut)

cpa_map <- data.table::fread(args[[2L]])
ind_map <- data.table::fread(args[[3L]])
inputs <- data.table::fread(args[[4L]])

bundle <- build_matrices(domestic, cpa_map, ind_map)
result <- compute_sube(bundle, inputs)
write_sube(file.path(output_dir, "sube_results"), result$summary, format = "csv")
write_sube(file.path(output_dir, "sube_tidy"), result$tidy, format = "csv")

message("Wrote outputs to: ", normalizePath(output_dir, winslash = "/", mustWork = FALSE))
