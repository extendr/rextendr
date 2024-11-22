#' Vendor Rust dependencies
#'
#' `vendor_pkgs()` is used to package the dependencies as required by CRAN.
#' It executes `cargo vendor` on your behalf creating a `vendor/` directory and a
#' compressed `vendor.tar.xz` which will be shipped with package itself.
#' If you have modified your dependencies, you will need need to repackage
#  the vendored dependencies using [`vendor_pkgs()`].
#'
#' @inheritParams use_extendr
#' @returns
#'
#' - `vendor_pkgs()` returns a data.frame with two columns `crate` and `version`
#'
#' @examples
#' \dontrun{
#' vendor_pkgs()
#' }
#' @export
vendor_pkgs <- function(path = ".", quiet = FALSE, overwrite = NULL) {
  stderr_line_callback <- function(x, proc) {
    if (!cli::ansi_grepl("To use vendored sources", x) && cli::ansi_nzchar(x)) {
      cli::cat_bullet(stringi::stri_trim_left(x))
    }
  }
  local_quiet_cli(quiet)

  # get path to rust folder
  src_dir <- rprojroot::find_package_root_file("src", "rust", path = path)

  # if `src/rust` does not exist error
  if (!dir.exists(src_dir)) {
    cli::cli_abort(
      "{.path src/rust} cannot be found. Did you run {.fn use_extendr}?",
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
        stderr_line_callback = stderr_line_callback
      )
    })

    if (update_res[["status"]] != 0) {
      cli::cli_abort(
        "{.file Cargo.lock} could not be created using {.code cargo generate-lockfile}",
        class = "rextendr_error"
      )
    }
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
      stderr_line_callback = stderr_line_callback
    )
  })

  if (vendor_res[["status"]] != 0) {
    cli::cli_abort(
      "{.code cargo vendor} failed",
      class = "rextendr_error"
    )
  }

  # create a dataframe of vendored crates
  vendored <- vendor_res[["stderr"]] %>%
    cli::ansi_strip() %>%
    stringi::stri_split_lines1()

  res <- stringi::stri_match_first_regex(vendored, "Vendoring\\s([A-z0-9_][A-z0-9_-]*?)\\s[vV](.+?)(?=\\s)") %>%
    tibble::as_tibble(.name_repair = "minimal") %>%
    rlang::set_names(c("source", "crate", "version")) %>%
    dplyr::filter(!is.na(source)) %>%
    dplyr::select(-source) %>%
    dplyr::arrange(.data$crate)

  # capture vendor-config.toml content
  config_toml <- vendor_res[["stdout"]] %>%
    cli::ansi_strip() %>%
    stringi::stri_split_lines1()

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

  # return packages and versions invisibly
  invisible(res)
}


#' CRAN compliant extendr packages
#'
#' R packages developed using extendr are not immediately ready to
#' be published to CRAN. The extendr package template ensures that
#' CRAN publication is (farily) painless.
#'
#' @section CRAN requirements:
#'
#' In order to publish a Rust based package on CRAN it must meet certain
#' requirements. These are:
#'
#' - Rust dependencies are vendored
#' - The package is compiled offline
#' - the `DESCRIPTION` file's `SystemRequirements` field contains `Cargo (Rust's package manager), rustc`
#'
#' The extendr templates handle all of this _except_ vendoring dependencies.
#' This must be done prior to publication using [`vendor_pkgs()`].
#'
#' In addition, it is important to make sure that CRAN maintainers
#' are aware that the package they are checking contains Rust code.
#' Depending on which and how many crates are used as a dependencies
#' the `vendor.tar.xz` will be larger than a few megabytes. If a
#' built package is larger than 5mbs CRAN may reject the submission.
#'
#' To prevent rejection make a note in your `cran-comments.md` file
#' (create one using [`usethis::use_cran_comments()`]) along the lines of
#' "The package tarball is 6mb because Rust dependencies are vendored within src/rust/vendor.tar.xz which is 5.9mb."
#' @name cran
NULL
