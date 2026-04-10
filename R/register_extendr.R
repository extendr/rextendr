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

#' Creates R wrappers for Rust functions.
#'
#' Invokes `wrap__make_{module_name}_wrappers` exported from
#' the Rust library and writes obtained R wrappers to the `outfile`.
#' @param module_name The name of the Rust module. Can be the same as `package_name`
#' @param package_name The name of the package.
#' @param outfile Determines where to write wrapper code.
#' @param path Path from which package root is looked up. Used for message formatting.
#' @param use_symbols Logical, indicating wether to add additional symbol information to
#' the generated wrappers. Default (`FALSE`) is used when making wrappers for the package,
#' while `TRUE` is used to make wrappers for dynamically generated libraries using
#' [`rust_source`], [`rust_function`], etc.
#' @param quiet Logical scalar indicating whether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @noRd
make_wrappers <- function(
  module_name,
  package_name,
  outfile,
  path = ".",
  use_symbols = FALSE,
  quiet = FALSE
) {
  wrapper_function <- glue("wrap__make_{module_name}_wrappers")
  x <- .Call(
    wrapper_function,
    use_symbols = use_symbols,
    package_name = package_name,
    PACKAGE = package_name
  )
  generated_wrappers <- stringi::stri_split_lines1(x)

  generated_wrappers <- c(
    generated_wrappers[1],
    "",
    "# nolint start",
    "",
    generated_wrappers[-1],
    "",
    "# nolint end"
  )

  write_file(
    text = generated_wrappers,
    path = outfile,
    search_root_from = path,
    quiet = quiet
  )
}
