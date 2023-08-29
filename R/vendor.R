#' @export
#' @rdname use_cargo_vendor
vendor_pkgs <- function(path = ".", quiet = FALSE) {
  local_quiet_cli(quiet)
  # get path to rust folder
  src_dir <- rprojroot::find_package_root_file(path, "src/rust")

  # run the script
  res <- withr::with_dir(
    src_dir,
    processx::run(
      "./vendor-update.sh",
      echo = FALSE,
      stderr_line_callback = function(x, proc) {
        if (!grepl("To use vendored sources", x) && x != "") {
          cli::cat_bullet(stringi::stri_trim_left(x))
        }
      }
    )
  )

  invisible(NULL)
}


#' Vendor Cargo Dependencies
#'
#' Creates the necessary infrastructure to vendor
#' Rust dependencies with an R package.
#'
#' @details
#' CRAN requires that any R package that uses Rust must also include
#' its dependencies in the package itself. This is to ensure that a
#' package can be installed in an offline manner.
#'
#' - `use_cargo_vendor()` creates the necessary files to vendor dependencies
#' - `vendor_pkgs()` creates a compressed folder `vendor.tar.xz` which contains
#'   the vendored dependencies that will be used in the build process.
#'
#'  If you have modified your dependencies, you will need need to repackage
#'  the vendored dependencies with `vendor_pkgs()`.
#'
#' @inheritParams use_extendr
#' @export
#' @returns `NULL`. Used purely for side effects.
#' @examples
#'
#' if (interactive()) {
#'  use_cargo_vendor()
#'  vendor_pkgs()
#' }
use_cargo_vendor <- function(
    path = ".",
    quiet = FALSE,
    overwrite = FALSE,
    lib_name = NULL
) {

  # silence output
  local_quiet_cli(quiet)

  pkg_root <- rprojroot::find_package_root_file(path)

  if (is.null(lib_name)) {
    lib_name <- as_valid_rust_name(pkg_name(path))
  } else if (length(lib_name) > 1) {
    cli::ci_abort(
      "{.arg lib_name} must be a character scalar",
      class = "rextendr_error"
      )
  }

  use_rextendr_template(
    "Makevars.vendor",
    save_as = file.path("src", "Makevars"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "Makevars.win.vendor",
    save_as = file.path("src", "Makevars.win"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  vendor_update <- file.path("src", "rust", "vendor-update.sh")

  use_rextendr_template(
    "vendor-update.sh",
    save_as = vendor_update,
    quiet = quiet,
    overwrite = overwrite
  )

  # make the script executable
  Sys.chmod(vendor_update, mode = "0755")

  use_rextendr_template(
    "vendor-config.toml",
    save_as = file.path("src", "rust", "vendor-config.toml"),
    quiet = quiet,
    overwrite = overwrite
  )

  # handle if uusethis is not installed
  if (!rlang::is_installed("usethis")) {
    cli::cli_inform(
      c(
        "!" = "Add {.code ^src/vendor$} to your {.file .Rbuildignore}",
        "!" = "Add {.code ^src/vendor$} to your {.file .gitignore}",
        "i" = "Install {.pkg usethis} to have this done automatically."
        )
    )
  } else {
    # vendor will be big when expanded and should be ignored
    usethis::use_build_ignore(
      file.path("src", "vendor")
    )

    usethis::use_git_ignore(
      file.path("src", "vendor")
    )
  }

  invisible(NULL)
}
