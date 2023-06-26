#' Set up a package for use with Rust extendr code
#'
#' Create the scaffolding needed to add Rust extendr code to an R package. `use_extendr()`
#' adds a small Rust library with a single Rust function that returns the string
#' `"Hello world!"`. It also adds wrapper code so this Rust function can be called from
#' R with `hello_world()`.
#'
#' This function can be called on an existing package including rextendr templates;
#' you will be asked if overwrite each file. If you are not in an interactive session,
#' the files will not be overwritten.
#'
#' @param path File path to the package for which to generate wrapper code.
#' @param crate_name String that is used as the name of the Rust crate.
#' If `NULL`, sanitized R package name is used instead.
#' @param lib_name String that is used as the name of the Rust library.
#' If `NULL`, sanitized R package name is used instead.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @param edition String indicating which Rust edition is used; Default `"2021"`.
#' @return A logical value (invisible) indicating whether any package files were
#' generated or not.
#' @export
use_extendr <- function(path = ".",
                        crate_name = NULL,
                        lib_name = NULL,
                        quiet = FALSE,
                        edition = c("2021", "2018")) {
  # https://github.com/r-lib/cli/issues/434

  local_quiet_cli(quiet)

  # If interactive, ask for overwrite. Else, skip writing files if they exist.
  if (interactive()) {
    overwrite <- NULL
  } else {
    overwrite <- FALSE
  }

  if (!is_installed("usethis")) {
    cli::cli_abort(
      "The {.pkg usethis} package is required to use {.fun use_extendr}.",
      class = "rextendr_error"
    )
  }

  rextendr_setup(path = path)

  pkg_name <- pkg_name(path)
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

  src_dir <- rprojroot::find_package_root_file("src", path = path)
  r_dir <- rprojroot::find_package_root_file("R", path = path)

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
    "Makevars",
    save_as = file.path("src", "Makevars"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "Makevars.win",
    save_as = file.path("src", "Makevars.win"),
    quiet = quiet,
    overwrite = overwrite,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "Makevars.ucrt",
    save_as = file.path("src", "Makevars.ucrt"),
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

  usethis::use_build_ignore("src/.cargo")

  edition <- match.arg(edition, several.ok = FALSE)
  cargo_toml_content <- to_toml(
    package = list(name = crate_name, version = "0.1.0", edition = edition),
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
    overwrite = overwrite,
    data = list(pkg_name = pkg_name)
  )

  if (!isTRUE(quiet)) {
    cli::cli_alert_success("Finished configuring {.pkg extendr} for package {.pkg {pkg_name}}.")
    cli::cli_ul(
      c(
        "Please update the system requirement in {.file DESCRIPTION} file.",
        "Please run {.fun rextendr::document} for changes to take effect."
      )
    )
  }

  return(invisible(TRUE))
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
#' @inheritParams write_file
#'
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

  if (is_installed("usethis")) {
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
