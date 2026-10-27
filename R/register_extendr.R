#' Register the extendr module of a package with R
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated because we now rely on a small Rust binary to
#' generate wrappers, which is called during the package build process.
#'
#' @param path Path from which package root is looked up.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @param force Logical indicating whether to force regenerating
#'   `R/extendr-wrappers.R` even when it doesn't seem to need updated. (By
#'   default, generation is skipped when it's newer than the DLL).
#' @param compile Logical indicating whether to recompile DLLs:
#'   \describe{
#'     \item{`TRUE`}{always recompiles}
#'     \item{`NA`}{recompiles if needed (i.e., any source files or manifest file are newer than the DLL)}
#'     \item{`FALSE`}{never recompiles}
#'   }
#' @return (Invisibly) Path to the file containing generated wrappers.
#' @seealso [rextendr::document()]
#' @export
register_extendr <- function(
  path = ".",
  quiet = FALSE,
  force = FALSE,
  compile = NA
) {
  lifecycle::deprecate_warn(
    "0.4.0",
    "register_extendr()",
    "devtools::document()",
    details = "The current function is now no-op. Call `use_extendr()` to update configs."
  )
}
