#' Vendor Cargo Dependencies
#'
#' Creates the necessary infrastructure to vendor
#' Rust dependencies with an R package.
#'
#' @details
#'
#' CRAN requires that any R package that uses Rust must also include
#' its dependencies in the package itself. This is to ensure that a
#' package can be installed in an offline manner.
#'
#' `use_cargo_vendor()` creates the scaffolding necessary to vendor dependencies. These
#' are a modified `Makevars`, `Makevars.win`, and `vendor-config.toml` files. In
#' addition, it will add requisite lines to your `.gitignore` and `.Rbuildignore`
#' if usethis is available.
#'
#' `vendor_pkgs()` is used to package the dependencies. It compresses the `vendor`
#' directory into a single `vendor.tar.xz` which will be shipped with package itself.
#' If you have modified your dependencies, you will need need to repackage
#  the vendored dependencies using `vendor_pkgs()`.
#'
#' @inheritParams use_extendr
#' @export
#' @returns
#'
#' - `vendor_pkgs()` returns a data.frame with two columns `crate` and `version`
#' - `use_cargo_vendor()` returns `NULL` and used solely for its side effects
#'
#' @examples
#'
#' if (interactive()) {
#'   use_cargo_vendor()
#'   vendor_pkgs()
#' }
use_cargo_vendor <- function(
    path = ".",
    quiet = FALSE,
    overwrite = NULL,
    lib_name = NULL) {
  if (!interactive()) {
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

  use_rextendr_template(
    "vendor-config.toml",
    save_as = file.path("src", "rust", "vendor-config.toml"),
    quiet = quiet,
    overwrite = overwrite
  )

  # handle if usethis is not installed
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
#' @rdname use_cargo_vendor
vendor_pkgs <- function(path = ".",
                        quiet = FALSE) {
  local_quiet_cli(quiet)

  # get path to rust folder
  src_dir <- rprojroot::find_package_root_file(path, "src/rust")

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

  # check to see if the config.toml is different than the template
  # if so update it
  config_toml <- stringi::stri_split(vendor_res$stdout, coll = "\n")[[1]]
  # remove trailing empty string char
  config_toml <- config_toml[1:(length(config_toml) - 1)]

  # get the text of the current vendor-config.toml
  cur_config <- readLines(file.path(src_dir, "vendor-config.toml"))

  # check if they are identical
  configs_match <- identical(
    config_toml,
    cur_config
  )

  # update vendor-config.toml if necessary
  if (!configs_match) {
    brio::write_lines(config_toml, file.path(src_dir, "vendor-config.toml"))
    cli::cli_alert_info("Updating {.file src/rust/vendor-config.toml}")
  }

  # compress the vendor.tar.xz
  compress_res <- withr::with_dir(src_dir, {
    processx::run(
      "tar", c(
        "-cJ", "--no-xattrs", "-f", "vendor.tar.xz", "vendor"
      )
    )
  })

  if (compress_res[["status"]] != 0 || vendor_res[["status"]] != 0) {
    cli::cli_abort(
      "{.code cargo vendor} failed.",
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

  invisible(res)
}
