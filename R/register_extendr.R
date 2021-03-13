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
#'
#' @inheritParams pkgload::load_all
#' @param path File path to the package for which to generate wrapper code.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @param force_wrappers Logical indicating whether to install a minimal wrapper
#'   file in the cases when generating wrappers by Rust code failed. This might
#'   be needed when the wrapper file is accidentally lost or corrupted.
#' @return Logical scalar. `TRUE` if new wrappers were emitted, `FALSE`
#'   if wrappers did not require an update.
#' @export
register_extendr <- function(path = ".", quiet = FALSE, force_wrappers = FALSE, compile = NA) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  if (!isTRUE(quiet)) {
    cli::cli_alert_info("Generating extendr wrapper functions for package: {.pkg {pkg_name}}.")
  }

  entrypoint_c_file <- rprojroot::find_package_root_file("src", "entrypoint.c", path = path)
  if (!file.exists(entrypoint_c_file)) {
    stop(
      "Could not find file `src/entrypoint.c`. Are you sure this package is using extendr Rust code?",
      call. = FALSE
    )
  }

  outfile <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = path)

  # If force_wrappers is TRUE, use a minimal wrapper file even when
  # make_wrappers() fails; since the wrapper generation depends on the compiled
  # Rust code, the package needs to be installed before attempting this, but
  # it's not always the case (e.g. the package might be corrupted, or not
  # installed yet).
  if (isTRUE(force_wrappers)) {
    error_handle <- function(e) {
      cli::cli_alert_danger("Failed to generate wrapper functions. Falling back to a minimal wrapper file instead.")
      make_example_wrappers(pkg_name, outfile)
    }
  } else {
    error_handle <- function(e) {
      stop("Failed to generate wrapper functions", call. = FALSE)
    }
  }

  tryCatch(
    # Call the wrapper generation in a separate R process to avoid the problem
    # of loading and unloading the same name of a DLL (c.f. #64).
    make_wrappers_externally(
      module_name = pkg_name,
      package_name = pkg_name,
      outfile = outfile,
      path = path,
      use_symbols = TRUE,
      quiet = quiet,
      compile = compile
    ),
    error = error_handle
  )
  invisible(NULL)
}

make_wrappers <- function(module_name, package_name, outfile,
                          use_symbols = FALSE, quiet = FALSE,
                          path = ".") {
  wrapper_function <- glue("wrap__make_{module_name}_wrappers")
  x <- .Call(
    wrapper_function,
    use_symbols = use_symbols,
    package_name = package_name,
    PACKAGE = package_name
  )
  x <- stringi::stri_split_lines1(x)

  # Can't use usethis::write_over because it asks user for input if
  # file already exists.
  brio::write_lines(x, outfile)
  if (!isTRUE(quiet)) {
    rel_path <- pretty_rel_path(outfile, search_from = path)
    cli::cli_alert_success("Writting wrappers to {.file {rel_path}}.")
  }
}

make_wrappers_externally <- function(module_name, package_name, outfile,
                                    path, use_symbols = FALSE, quiet = FALSE,
                                    compile = NA) {

  func <- function(package_root, make_wrappers, compile, quiet,...) {
    pkgload::load_all(package_root, compile = compile, quiet = quiet)
    make_wrappers(...)
  }

  args <- list(
    package_root = rprojroot::find_package_root_file(path = path),
    make_wrappers = make_wrappers,
    compile = compile,
    # arguments passed to make_wrappers()
    module_name = module_name,
    package_name = package_name,
    outfile = outfile,
    use_symbols = use_symbols,
    quiet = quiet,
    path = path
  )

  invisible(callr::r(func, args = args, show = !isTRUE(quiet)))
}
