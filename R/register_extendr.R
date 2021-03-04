#' Register the extendr module of a package with R
#'
#' This function generates wrapper code corresponding to the extendr module
#' for an R package. This is useful in package development, where we generally
#' want appropriate R code wrapping the Rust functions implemented via extendr.
#'
#' To run `register_extendr()`, the R package containing extendr code must have
#' previously been compiled and installed. If this condition is met, the
#' wrapper code will be retrieved from the compiled Rust code and saved into
#' `R/extendr-wrappers.R`. Afterwards, you will have to re-document and then
#' re-install the package for the wrapper functions to take effect.
#' @param path File path to the package for which to generate wrapper code.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @return The generated wrapper code. Note that this is not normally needed,
#' as the function saves the wrapper code to `R/extendr-wrappers.R`.
#' @export
register_extendr <- function(path = ".", quiet = FALSE) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  if (!isTRUE(quiet)) {
    message(glue::glue("Generating extendr wrapper functions for package: {pkg_name}"))
  }

  outfile <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = path)

  if (requireNamespace(pkg_name, quietly = TRUE)) {
    make_wrappers(pkg_name, pkg_name, outfile, use_symbols = TRUE, quiet = quiet)
  } else {
    stop(
      glue::glue("Package {pkg_name} cannot be loaded. No wrapper functions were generated."),
      call. = FALSE
    )
  }
}

make_wrappers <- function(module_name, package_name, outfile,
                          use_symbols = FALSE, quiet = FALSE) {
  wrapper_function <- glue::glue("wrap__make_{module_name}_wrappers")
  x <- .Call(
    wrapper_function,
    use_symbols = use_symbols,
    package_name = package_name,
    PACKAGE = package_name
  )
  x <- stringi::stri_split_lines1(x)

  if (!isTRUE(quiet)) {
    message("Writting wrappers to:\n", outfile)
  }
  brio::write_lines(x, outfile)
}
