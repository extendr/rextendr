#' Set up a package for use with Rust extendr code
#'
#' Create the scaffolding needed to add Rust extendr code to an R package. `use_extendr()`
#' adds a small Rust library with a single Rust function that returns the string
#' `"Hello world!"`. It also adds wrapper code so this Rust function can be called from
#' R with `hello_world()`.
#'
#' @param path File path to the package for which to generate wrapper code.
#' @param crate_name String that is used as the name of the Rust crate.
#' If `NULL`, sanitized R package name is used instead.
#' @param lib_name String that is used as the name of the Rust library.
#' If `NULL`, sanitized R package name is used instead.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @param overwrite Logical scalar or `NULL` indicating whether the files in the `path` should be overwritten.
#' If `NULL` (default), the function will ask the user whether each file should
#' be overwritten in an interactive session or do nothing in a non-interactive session.
#' If `FALSE` and each file already exists, the function will do nothing.
#' If `TRUE`, all files will be overwritten.
#' @param edition String indicating which Rust edition is used; Default `"2021"`.
#' @return A logical value (invisible) indicating whether any package files were
#' generated or not.
#' @export
use_extendr <- function(path = ".",
                        crate_name = NULL,
                        lib_name = NULL,
                        quiet = FALSE,
                        overwrite = NULL,
                        edition = c("2021", "2018")) {
  # https://github.com/r-lib/cli/issues/434

  local_quiet_cli(quiet)

  if (!interactive()) {
    overwrite <- overwrite %||% FALSE
  }

  rlang::check_installed("usethis")

  # Root path computed from user input
  root_path <- try_get_root_path(path)
  # Root path computed from `{usethis}`
  usethis_proj_path <- try_get_proj_path()

  # If they do not match, something is off, try to set up temporary project
  if (!isTRUE(root_path == usethis_proj_path)) {
    usethis::local_project(path, quiet = quiet)
  }

  # Check project path once again
  usethis_proj_path <- try_get_proj_path()
  # Check what is current working directory
  curr_path <- try_get_normalized_path(getwd)

  # If they do not match, let's temporarily change working directory
  if (!isTRUE(curr_path == usethis_proj_path)) {
    withr::local_dir(usethis_proj_path)
  }

  # At this point, our working directory is at the project root and
  # we have an active `{usethis}` project

  rextendr_setup()

  pkg_name <- pkg_name()
  mod_name <- as_valid_rust_name(pkg_name)

  if (is.null(crate_name)) {
    crate_name <- mod_name
  } else {
    throw_if_invalid_rust_name(crate_name)
  }

  if (is.null(lib_name)) {
    lib_name <- mod_name
  } else {
    throw_if_invalid_rust_name(lib_name)
  }

  src_dir <- rprojroot::find_package_root_file("src")
  r_dir <- rprojroot::find_package_root_file("R")


  if (!dir.exists(r_dir)) {
    dir.create(r_dir)
    cli::cli_alert_success("Creating {.file {pretty_rel_path(r_dir, path)}}.")
  }

  rust_src_dir <- file.path(src_dir, "rust", "src")
  if (!dir.exists(rust_src_dir)) {
    dir.create(rust_src_dir, recursive = TRUE)
    cli::cli_alert_success("Creating {.file {pretty_rel_path(rust_src_dir, path)}}.")
  }

  use_rextendr_template(
    "entrypoint.c",
    save_as = file.path("src", "entrypoint.c"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(mod_name = mod_name)
  )

  use_rextendr_template(
    "Makevars.in",
    save_as = file.path("src", "Makevars.in"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "Makevars.win.in",
    save_as = file.path("src", "Makevars.win.in"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "_gitignore",
    save_as = file.path("src", ".gitignore"),
    quiet = quiet,
    overwrite = overwrite
  )

  edition <- match.arg(edition, several.ok = FALSE)
  cargo_toml_content <- to_toml(
    package = list(name = crate_name, publish = FALSE, version = "0.1.0", edition = edition),
    lib = list(`crate-type` = array("staticlib", 1), name = lib_name),
    dependencies = list(`extendr-api` = "*")
  )

  use_rextendr_template(
    "Cargo.toml",
    save_as = file.path("src", "rust", "Cargo.toml"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(cargo_toml_content = cargo_toml_content)
  )

  use_rextendr_template(
    "lib.rs",
    save_as = file.path("src", "rust", "src", "lib.rs"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(mod_name = mod_name)
  )

  use_rextendr_template(
    "win.def",
    save_as = file.path("src", paste0(pkg_name, "-win.def")),
    quiet = quiet,
    overwrite = overwrite,
    data = list(mod_name = mod_name)
  )

  use_rextendr_template(
    "extendr-wrappers.R",
    save_as = file.path("R", "extendr-wrappers.R"),
    quiet = quiet,
    overwrite = FALSE,
    data = list(pkg_name = pkg_name)
  )

  # create tools directory if it does not exist
  if (!dir.exists("tools")) {
    dir.create("tools")
  }

  # add msrv.R template
  use_rextendr_template(
    "msrv.R",
    save_as = file.path("tools", "msrv.R"),
    quiet = quiet,
    overwrite = overwrite
  )

  # add configure and configure.win templates
  use_rextendr_template(
    "configure",
    save_as = "configure",
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "configure.win",
    save_as = "configure.win",
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  # configure needs to be made executable
  # ignore for Windows
  if (.Platform[["OS.type"]] == "unix") {
    Sys.chmod("configure", "0755")
  }

  # Set the minimum version of R to 4.2 as now required by libR-sys 0.7
  usethis::use_package("R", "Depends", "4.2")

  # the temporary cargo directory must be ignored
  usethis::use_build_ignore("src/.cargo")

  # ensure that the vendor directory is ignored
  usethis::use_build_ignore(
    file.path("src", "rust", "vendor")
  )

  usethis::use_git_ignore(
    file.path("src", "rust", "vendor")
  )

  # the src/Makevars should be created each time the package
  # is built. This is handled via the configure file
  usethis::use_build_ignore("src/Makevars")
  usethis::use_git_ignore("src/Makevars")
  usethis::use_build_ignore("src/Makevars.win")
  usethis::use_git_ignore("src/Makevars.win")


  use_extendr_badge()

  if (!isTRUE(quiet)) {
    cli::cli_alert_success("Finished configuring {.pkg extendr} for package {.pkg {pkg_name}}.")
    cli::cli_ul(
      c(
        "Please run {.fun rextendr::document} for changes to take effect."
      )
    )
  }

  return(invisible(TRUE))
}

try_get_normalized_path <- function(path_fn) {
  tryCatch(normalizePath(path_fn(), winslash = "/", mustWork = FALSE), error = function(e) NA)
}

try_get_proj_path <- function() {
  try_get_normalized_path(usethis::proj_get)
}

try_get_root_path <- function(path) {
  try_get_normalized_path(function() rprojroot::find_package_root_file(path = path))
}

#' Checks if provided name is a valid Rust name (identifier)
#'
#' @param name \[ character(n) \] Names to test.
#' @return \[ logical(n) \] `TRUE` if the name is valid, otherwise `FALSE`.
#' @noRd
is_valid_rust_name <- function(name) {
  # We require the name starts with a letter,
  # ends with a letter or digit,
  # and contains only alphanumeric ASCII chars, `-` or `_`.
  stringi::stri_detect_regex(name, "^[A-z][\\A-z0-9_-]*[A-z0-9]$")
}

#' Convert R package name into equivalent valid Rust name.
#'
#' @param name \[ character(n) \] R names to convert.
#' @return \[ character(n) \] Equivalent Rust name (if exists), otherwise `NA`.
#' @noRd
as_valid_rust_name <- function(name) {
  rust_name <- stringi::stri_replace_all_regex(name, "[^\\w-]", "_")
  if (stringi::stri_detect_regex(rust_name, "^\\d")) {
    rust_name <- paste0("_", rust_name)
  }
  throw_if_invalid_rust_name(rust_name)
  rust_name
}

#' Verifies if a function argument is a valid Rust name.
#'
#' @param name \[ string \] Tested caller function argument.
#' @param call \[ env \] Environment of the caller, passed to `cli::cli_abort()`.
#' @noRd
throw_if_invalid_rust_name <- function(name, call = caller_env()) {
  quo <- enquo(name) # nolint: object_usage_linter
  if (!rlang::is_scalar_character(name) || !is_valid_rust_name(name)) {
    cli::cli_abort(
      c(
        "Argument {.arg {as_name(quo)}} is invalid.",
        "!" = "{.code {as_label(name)}} cannot be used as Rust package or library name."
      ),
      call = call,
      class = "rextendr_error"
    )
  }
}
#' Write templates from `inst/templates`
#'
#' `use_rextendr_template()` is a wrapper around `usethis::use_template()` when
#' it's available and otherwise implements a simple version of `use_template()`.
#'
#' @inheritParams usethis::use_template
#' @inheritParams use_extendr
#' @param overwrite Logical scalar or `NULL` indicating whether the file in the `path` should be overwritten.
#' If `FALSE` and the file already exists, the function will do nothing.
#' If `NULL` and the `usethis` package is installed, the function will ask the user whether the file should
#' be overwritten in an interactive session or do nothing in a non-interactive session.
#' Otherwise, the file will be overwritten.
#' @noRd
use_rextendr_template <- function(template,
                                  save_as = template,
                                  data = list(),
                                  quiet = FALSE,
                                  overwrite = NULL) {
  local_quiet_cli(quiet)

  if (isFALSE(overwrite) && file.exists(save_as)) {
    cli::cli_alert("File {.path {save_as}} already exists. Skip writing the file.")
    return(invisible(NULL))
  }

  if (is_installed("usethis") && is.null(overwrite)) {
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
    .open = "{{{", .close = "}}}",
    .trim = FALSE
  )

  write_file(
    stringi::stri_trim(template_content),
    path = save_as,
    search_root_from = rprojroot::find_package_root_file(),
    quiet = quiet,
    overwrite = overwrite
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
