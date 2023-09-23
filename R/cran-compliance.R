#' Use CRAN compliant defaults
#'
#' Modifies an extendr package to use CRAN compliant settings.
#'
#' @details
#'
#' `use_cran_defaults()` modifies an existing package to provide CRAN complaint
#' settings and files. It creates `configure` and `configure.win` files as well as
#'  modifies `Makevars` and `Makevars.win` to use required CRAN settings.
#'
#' `vendor_pkgs()` is used to package the dependencies as required by CRAN.
#' It executes `cargo vendor` on your behalf creating a `vendor/` directory and a
#' compressed `vendor.tar.xz` which will be shipped with package itself.
#' If you have modified your dependencies, you will need need to repackage
#  the vendored dependencies using `vendor_pkgs()`.
#'
#' @inheritParams use_extendr
#' @returns
#'
#' - `vendor_pkgs()` returns a data.frame with two columns `crate` and `version`
#' - `use_cran_defaults()` returns `NULL` and is used solely for its side effects
#'
#' @examples
#'
#' if (interactive()) {
#'   use_cran_defaults()
#'   vendor_pkgs()
#' }
#' @name cran
#' @export
use_cran_defaults <- function(
    path = ".",
    quiet = FALSE,
    overwrite = NULL,
    lib_name = NULL
) {

  # if not in an interactive session and overwrite is null, set it to false
  if (!rlang::is_interactive()) {
    overwrite <- overwrite %||% FALSE
  }

  # silence output
  local_quiet_cli(quiet)

  # find package root
  pkg_root <- rprojroot::find_package_root_file(path)

  # set the path for the duration of the function
  withr::local_dir(pkg_root)

  if (is.null(lib_name)) {
    lib_name <- as_valid_rust_name(pkg_name(path))
  } else if (length(lib_name) > 1) {
    cli::cli_abort(
      "{.arg lib_name} must be a character scalar",
      class = "rextendr_error"
    )
  }

  # add configure and configure.win templates
  use_rextendr_template(
    "cran/configure",
    save_as = "configure",
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  # configure needs to be made executable
  Sys.chmod("configure", "0755")

  use_rextendr_template(
    "cran/configure.win",
    save_as = "configure.win",
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  # use CRAN specific Makevars templates
  use_rextendr_template(
    "cran/Makevars",
    save_as = file.path("src", "Makevars"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "cran/Makevars.win",
    save_as = file.path("src", "Makevars.win"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  # vendor directory will need to be ignored by git and R CMD build
  if (!rlang::is_installed("usethis")) {
    cli::cli_inform(
      c(
        "!" = "Add {.code ^src/rust/vendor$} to your {.file .Rbuildignore}",
        "!" = "Add {.code ^src/rust/vendor$} to your {.file .gitignore}",
        "i" = "Install {.pkg usethis} to have this done automatically."
      )
    )
  } else {
    # vendor will be big when expanded and should be ignored
    usethis::use_build_ignore(
      file.path("src", "rust", "vendor")
    )

    usethis::use_git_ignore(
      file.path("src", "rust", "vendor")
    )
  }

  invisible(NULL)
}

#' @export
#' @name cran
vendor_pkgs <- function(path = ".", quiet = FALSE, overwrite = NULL) {
  local_quiet_cli(quiet)

  # get path to rust folder
  src_dir <- rprojroot::find_package_root_file(path, "src/rust")

  # if `src/rust` does not exist error
  if (!dir.exists(src_dir)) {
    cli::cli_abort(
      c("{.path src/rust} cannot be found", "i" = "Have you used {.fn use_extendr}?"),
      class = "rextendr_error"
    )
  }

  # if cargo.lock does not exist, cerate it using `cargo update`
  cargo_lock_fp <- file.path(src_dir, "Cargo.lock")

  if (!file.exists(cargo_lock_fp)) {
    withr::with_dir(src_dir, {
      update_res <- processx::run(
        "cargo",
        c(
          "generate-lockfile",
          "--manifest-path",
          file.path(src_dir, "Cargo.toml")
          ),
        stderr_line_callback = function(x, proc) {
          if (!grepl("To use vendored sources", x) && x != "") {
            cli::cat_bullet(stringi::stri_trim_left(x))
          }
        }
      )
    })
  }

  # vendor crates
  withr::with_dir(src_dir, {
    vendor_res <- processx::run(
      "cargo",
      c(
        "vendor",
        "--locked",
        "--manifest-path",
        file.path(src_dir, "Cargo.toml")
      ),
      stderr_line_callback = function(x, proc) {
        if (!grepl("To use vendored sources", x) && x != "") {
          cli::cat_bullet(stringi::stri_trim_left(x))
        }
      }
    )
  })

  if (vendor_res[["status"]] != 0) {
    cli::cli_abort(
      "{.code cargo vendor} was not executed successfully",
      class = "rextendr_error"
    )
  }

  # capture vendor-config.toml content
  config_toml <- stringi::stri_split(vendor_res$stdout, coll = "\n")[[1]]

  # always write to file as cargo vendor catches things like patch.crates-io
  # and provides the appropriate configuration.
  brio::write_lines(config_toml, file.path(src_dir, "vendor-config.toml"))
  cli::cli_alert_info("Writing {.file src/rust/vendor-config.toml}")

  # compress to vendor.tar.xz
  compress_res <- withr::with_dir(src_dir, {
    processx::run(
      "tar", c(
        "-cJ", "--no-xattrs", "-f", "vendor.tar.xz", "vendor"
      )
    )
  })

  if (compress_res[["status"]] != 0) {
    cli::cli_abort(
      "Folder {.path vendor} could not be compressed",
      class = "rextendr_error"
    )
  }

  # create a dataframe of vendored crates
  vendored <- stringi::stri_split(vendor_res[["stderr"]], coll = "\n")[[1]]
  trimmed <- stringi::stri_trim_left(vendored)
  to_remove <- grepl("To use vendored sources", trimmed) | trimmed == ""
  rows <- stringi::stri_split_fixed(trimmed[!to_remove], pattern = " ")

  res <- purrr::map_dfr(rows, function(x) {
    data.frame(crate = x[2], version = x[3])
  })

  # return packages and versions invisibly
  invisible(res)
}


