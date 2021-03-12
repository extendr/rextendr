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
#' @param force_wrappers Logical indicating whether to generate a minimal
#'   wrapper in the cases when the package's namespace cannot be loaded. This is
#'   useful to recover the wrapper file when something is wrong with it.
#' @return The generated wrapper code. Note that this is not normally needed,
#' as the function saves the wrapper code to `R/extendr-wrappers.R`.
#' @export
register_extendr <- function(path = ".", quiet = FALSE, force_wrappers = FALSE) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  if (!isTRUE(quiet)) {
    message(glue("Generating extendr wrapper functions for package: {pkg_name}"))
  }

  entrypoint_c_file <- rprojroot::find_package_root_file("src", "entrypoint.c", path = ".")
  if (!file.exists(entrypoint_c_file)) {
    stop(
      "Could not find file `src/entrypoint.c`. Are you sure this package is using extendr Rust code?",
      call. = FALSE
    )
  }

  outfile <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = path)

  # If force_wrappers is TRUE, generate minimal wrappers even when there's some
  # error (e.g. the symbol cannot be found).
  if (isTRUE(force_wrappers)) {
    error_handle <- function(e) {
      msg <- "Generating the wrapper functions failed, so a minimal one is used instead"
      warning(msg, call. = FALSE)
      make_example_wrappers(pkg_name, outfile)
    }
  } else {
    error_handle <- function(e) {
      stop("Generating the wrapper functions failed", call. = FALSE)
    }
  }

  tryCatch(
    make_wrappers(pkg_name, pkg_name, outfile,
      use_symbols = TRUE, quiet = quiet,
      # Call the wrapper generation in a separate R process to avoid the problem
      # of loading and unloading the same name of library (c.f. #64).
      use_callr = TRUE
    ),
    error = error_handle
  )
}

make_wrappers <- function(module_name, package_name, outfile,
                          use_symbols = FALSE, quiet = FALSE,
                          use_callr = FALSE) {
  wrapper_function <- glue("wrap__make_{module_name}_wrappers")

  func <- function(package_root, ...) {
    pkgload::load_all(package_root, quiet = TRUE)
    .Call(...)
  }

  args <- list(
    package_root = rprojroot::find_package_root_file(path = "."),
    wrapper_function,
    use_symbols = use_symbols,
    package_name = package_name,
    PACKAGE = package_name
  )

  if (isTRUE(use_callr)) {
    x <- callr::r_safe(func, args = args)
  } else {
    x <- do.call(func, args = args)
  }
  x <- stringi::stri_split_lines1(x)

  if (!isTRUE(quiet)) {
    message("Writting wrappers to:\n", outfile)
  }
  brio::write_lines(x, outfile)
}
