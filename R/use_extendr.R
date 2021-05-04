#' Set up a package for use with Rust extendr code
#'
#' Create the scaffolding needed to add Rust extendr code to an R package. `use_extendr()`
#' adds a small Rust library with a single Rust function that returns the string
#' `"Hello world!"`. It also adds wrapper code so this Rust function can be called from
#' R with `hello_world()`.
#'
#' To avoid possibly messing up your R package, `use_extendr()` will not do anything if
#' either a directory `src` or a file `R/extendr-wrappers.R` is already present in your
#' package source.
#'
#' @param path File path to the package for which to generate wrapper code.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not. Also checks the `usethis.quiet` option.
#' @return A logical value (invisible) indicating whether any package files were
#' generated or not.
#' @export
use_extendr <- function(path = ".", quiet = getOption("usethis.quiet", FALSE)) {
  pkg_name <- pkg_name(path)

  src_dir <- rprojroot::find_package_root_file("src", path = path)
  wrappers_file <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = path)

  if (dir.exists(src_dir)) {
    if (!isTRUE(quiet)) {
      ui_x("Directory {.file src} already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }
  if (file.exists(wrappers_file)) {
    if (!isTRUE(quiet)) {
      ui_x("File {.file R/extendr-wrappers.R} already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }

  rust_src_dir <- file.path(src_dir, "rust", "src")
  dir.create(rust_src_dir, recursive = TRUE)
  ui_v("Creating {.file {pretty_rel_path(rust_src_dir, path)}}.")

  use_rextendr_template(
    "entrypoint.c",
    save_as = file.path("src", "entrypoint.c"),
    quiet = quiet,
    data = list(pkg_name = pkg_name)
  )

  use_rextendr_template(
    "Makevars",
    save_as = file.path("src", "Makevars"),
    quiet = quiet,
    data = list(pkg_name = pkg_name)
  )

  use_rextendr_template(
    "Makevars.win",
    save_as = file.path("src", "Makevars.win"),
    quiet = quiet,
    data = list(pkg_name = pkg_name)
  )

  use_rextendr_template(
    "_gitignore",
    save_as = file.path("src", ".gitignore"),
    quiet = quiet
  )

  cargo_toml_content <- to_toml(
    package = list(name = pkg_name, version = "0.1.0", edition = "2018"),
    lib = list(`crate-type` = array("staticlib", 1)),
    dependencies = list(`extendr-api` = "*")
  )

  write_file(
    text = cargo_toml_content,
    path = file.path("src", "rust", "Cargo.toml"),
    search_root_from = path,
    quiet = quiet
  )

  use_rextendr_template(
    "lib.rs",
    save_as = file.path("src", "rust", "src", "lib.rs"),
    quiet = quiet,
    data = list(pkg_name = pkg_name)
  )

  use_rextendr_template(
    "extendr-wrappers.R",
    save_as = file.path("R", "extendr-wrappers.R"),
    quiet = quiet,
    data = list(pkg_name = pkg_name)
  )

  if (!isTRUE(quiet)) {
    ui_v("Finished configuring {.pkg extendr} for package {.pkg {pkg_name}}.")
    ui_o("Please update the system requirement in {.file DESCRIPTION} file.")
    ui_o("Please run {.fun rextendr::document} for changes to take effect.")
  }

  return(invisible(TRUE))
}

#' Write templates from `inst/templates`
#'
#' `use_rextendr_template()` is a wrapper around `usethis::use_template()` when
#' it's available and otherwise implements a simple version of `use_template()`.
#'
#' @inheritParams usethis::use_template
#' @inheritParams use_extendr
#'
#' @noRd
use_rextendr_template <- function(template, save_as = template, data = list(), quiet = getOption("usethis.quiet", FALSE)) {
  if (is_installed("usethis")) {
    withr::local_options(usethis.quiet = quiet)
    created <- usethis::use_template(
      template,
      save_as = save_as,
      data = data,
      open = FALSE,
      package = "rextendr"
    )

    return(invisible(created))
  }

  template_path <- system.file(
    "templates",
    template,
    package = "rextendr",
    mustWork = TRUE
  )

  template_content <- brio::read_file(template_path)

  template_content <- glue::glue_data(
    template_content,
    .x = data,
    .open = "{{{", .close = "}}}"
  )

  write_file(
    template_content,
    path = save_as,
    search_root_from = rprojroot::find_package_root_file(),
    quiet = quiet
  )

  invisible(TRUE)
}

# Wrap `rlang::is_installed()` for ease of mocking installed packages
is_installed <- function(pkg) {
  rlang::is_installed(pkg)
}

pkg_name <- function(path = ".") {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  x$get("Package")
}
