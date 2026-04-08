#' sube: Supply-Use Based Econometric Workflow Tools
#'
#' The package turns the original script-based SUBE workflow into reusable,
#' side-effect-light functions. Most users will work through a package-first
#' sequence of [import_suts()], [build_matrices()], [compute_sube()],
#' [estimate_elasticities()], [prepare_sube_comparison()], and
#' export or plotting helpers such as [write_sube()] and [plot_sube()].
#'
#' @keywords internal
"_PACKAGE"

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    "..keep", ".N", "CPAgroup", "Dp", "leontief", "lwr", "measure",
    "outlier", "std.error", "trend", "type", "upr", "value", "y"
  ))
}
