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
#' @param path Path from which package root is looked up.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @param force_wrappers Logical indicating whether to install a minimal wrapper
#'   file in the cases when generating wrappers by Rust code failed. This might
#'   be needed when the wrapper file is accidentally lost or corrupted.
#' @param compile Logical indicating whether to recompile DLLs:
#'   \describe{
#'     \item{`TRUE`}{always recompiles}
#'     \item{`NA`}{recompiles if needed (i.e., any source files or manifest file are newer than the DLL)}
#'     \item{`FALSE`}{never recompiles}
#'   }
#' @return (Invisibly) Path to the file containing generated wrappers.
#' @export
register_extendr <- function(path = ".", quiet = FALSE, force_wrappers = FALSE, compile = NA) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  if (!isTRUE(quiet)) {
    cli::cli_alert_info("Generating extendr wrapper functions for package: {.pkg {pkg_name}}.")
  }

  entrypoint_c_file <- rprojroot::find_package_root_file("src", "entrypoint.c", path = path)
  if (!file.exists(entrypoint_c_file)) {
    ui_throw(
      "Unable to register the extendr module.",
      c(
        ui_x("Could not find file {cli::col_blue(\"src/entrypoint.c\")}."),
        ui_q("Are you sure this package is using extendr Rust code?")
      )
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
      cli::cli_alert_danger("Failed to generate wrapper functions: {e$message}.")
      cli::cli_alert_warning("Falling back to a minimal wrapper file instead.")

      make_example_wrappers(pkg_name, outfile, path = path)
    }
  } else {
    error_handle <- function(e) {
      ui_throw(
        "Failed to generate wrapper functions.",
        c(
          ui_x(e[["message"]])
        )
      )
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

  # Ensures path is absolute
  invisible(normalizePath(outfile))
}

#' Creates R wrappers for Rust functions.
#'
#' Invokes `wrap__make_{module_name}_wrappers` exported from
#' the Rust library and writes obtained R wrappers to the `outfile`.
#' @param module_name The name of the Rust module. Can be the same as `package_name`
#' @param package_name The name of the package.
#' @param outfile Determines where to write wrapper code.
#' @param path Path from which package root is looked up. Used for message formatting.
#' @param use_symbols Logical, indicating wether to add additonal symbol information to
#' the generated wrappers. Default (`FALSE`) is used when making wrappers for the package,
#' while `TRUE` is used to make wrappers for dynamically generated libraries using
#' [`rust_source`], [`rust_function`], etc.
#' @param quiet Logical scalar indicating whether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @keywords internal
make_wrappers <- function(module_name, package_name, outfile,
                          path = ".", use_symbols = FALSE, quiet = FALSE) {
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

#' Creates R wrappers for Rust functions.
#'
#' Does the same as [`make_wrappers`], but out of process.
#' @inheritParams make_wrappers
#' @inheritParams register_extendr
#' @keywords internal
make_wrappers_externally <- function(module_name, package_name, outfile,
                                    path, use_symbols = FALSE, quiet = FALSE,
                                    compile = NA) {

  path <- rprojroot::find_package_root_file(path = path)

  # If compile is NA, compile if the DLL is newer than the source files
  if (isTRUE(is.na(compile))) {
    compile <- needs_compilation(path, quiet) || pkgbuild::needs_compile(path)
  }

  func <- function(path, make_wrappers, compile, quiet,
                   module_name, package_name, outfile,
                   use_symbols, ...) {
    if (isTRUE(compile)) {
      # This relies on [`pkgbuild::needs_compile()`], which
      # does not know about Rust files modifications.
      # `force = TRUE` enforces compilation.
      pkgbuild::compile_dll(
        path = path,
        force = TRUE,
        quiet = quiet
      )
    }

    dll_path <- fs::path(path, "src", paste0(package_name, .Platform$dynlib.ext))
    # Loads native library
    lib <- dyn.load(dll_path)
    # Registers library unloading to be invoked at the end of this function
    on.exit(dyn.unload(lib[["path"]]), add = TRUE)

    make_wrappers(
      module_name = module_name,
      package_name = package_name,
      outfile = outfile,
      path = path,
      use_symbols = use_symbols,
      quiet = quiet
    )
  }

  args <- list(
    path = path,
    make_wrappers = make_wrappers,
    compile = compile,
    # arguments passed to make_wrappers()
    module_name = module_name,
    package_name = package_name,
    outfile = outfile,
    use_symbols = use_symbols,
    quiet = quiet
  )

  invisible(callr::r(func, args = args, show = !isTRUE(quiet)))
}
