# use_vendor()
# adds template files
# runs vendor_pkgs()
# vendor_pkgs() will build the necessary tarball

#' @export
#' @rdname use_vendor
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
}


#' Vendor Cargo Dependencies
#'
#' @inheritParams use_extendr
#' @export
use_vendor <- function(path = ".", quiet = FALSE, overwrite = FALSE) {

  # silence output
  local_quiet_cli(quiet)

  pkg_root <- rprojroot::find_package_root_file(path)

  pkg_name <- pkg_name(path)
  lib_name <- as_valid_rust_name(pkg_name)

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

  # vendor will be big when expanded and should be ignored
  usethis::use_build_ignore(
    file.path("src", "rust", "vendor")
  )


}
