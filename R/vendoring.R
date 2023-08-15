#' Vendor dependent Rust crates
#'
#' Vendoring all dependent Rust crates into a single tarball.
#' @inheritParams use_extendr
#' @return No return value, called for side effects.
#' @noRd
vendor_crates <- function(path = ".") {
  withr::with_dir(path, usethis::use_build_ignore("src/rust/vendor"))

  src_dir <- rprojroot::find_package_root_file("src", path = path)

  out_file <- file.path(src_dir, "rust", "vendor.tar.xz")
  config_toml_file <- file.path(src_dir, "rust", "vendor-config.toml")

  vendor_rel_path <- file.path("rust", "vendor")

  withr::local_dir(src_dir)

  config_toml_content <- processx::run(
    "cargo",
    c(
      "vendor",
      "--locked",
      "--manifest-path", file.path("rust", "Cargo.toml"),
      vendor_rel_path
    )
  )$stdout

  write_file(
    text = config_toml_content,
    path = config_toml_file,
    search_root_from = path,
    quiet = TRUE,
    overwrite = TRUE
  )

  withr::local_dir(file.path(src_dir, vendor_rel_path))
  withr::local_envvar(c(XZ_OPT = "-9"))
  processx::run(
    "tar",
    c(
      "-c",
      "-f", out_file,
      "--xz",
      "--sort=name",
      "--mtime=1970-01-01",
      "--owner=0",
      "--group=0",
      "--numeric-owner",
      "."
    )
  )

  invisible(TRUE)
}
