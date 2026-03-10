#' sube: Supply-Use Based Econometric Workflow Tools
#'
#' The package turns the original script-based SUBE workflow into reusable,
#' side-effect-light functions. Most users will work with
#' [import_suts()], [build_matrices()], [compute_sube()],
#' [estimate_elasticities()], [filter_sube()], and [plot_sube()].
#'
#' @keywords internal
"_PACKAGE"

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    "..keep", ".N", "CPAgroup", "Dp", "leontief", "lwr", "measure",
    "outlier", "std.error", "trend", "type", "upr", "value", "y"
  ))
}
