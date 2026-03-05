#' Update extendr scaffolding
#'
#' When a new extendr or rextendr release requires changes to scaffolding, this
#' function helps update those files to the new specification.
#'
#' @inheritParams use_extendr
#' @param revendor boolean scalar, whether to clear vendor files and re-run
#'   `rextendr::vendor_pkgs()` (default is `TRUE`).
#'
#' @return a logical scalar indicating whether updating was successful
#'
#' @details Unfortunately, this process cannot be fully automated, so
#'   information is also printed to the console explaining what needs to be
#'   updated by hand. Usually, this will be accompanied by a more detailed blog
#'   post explaining changes.
#'
#'   ## Current list of updated files:
#'   - `src/entrypoint.c`
#'   - `src/Makevars.in`
#'   - `src/Makevars.win.in`
#'   - `cleanup`
#'   - `cleanup.win`
#'   - `src/rust/document.rs`
#'   - `tools/msrv.R`
#'   - `tools/config.R`
#'   - `configure`
#'   - `configure.win`
#'
#'   ## Additionally updated when `revendor = TRUE`:
#'   - `src/rust/vendor/`
#'   - `src/rust/vendor.tar.xz`
#'   - `src/rust/vendor-config.toml`
#'
#' @export
update_extendr <- function(
  path = ".",
  crate_name = NULL,
  lib_name = NULL,
  revendor = TRUE,
  quiet = FALSE
) {
  check_string(
    path,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  check_string(
    crate_name,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  check_string(
    lib_name,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  check_bool(
    quiet,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  local_quiet_cli(quiet)

  update_message()

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

  use_rextendr_template(
    "entrypoint.c",
    save_as = file.path("src", "entrypoint.c"),
    quiet = quiet,
    overwrite = TRUE,
    data = list(mod_name = mod_name)
  )

  use_rextendr_template(
    "Makevars.in",
    save_as = file.path("src", "Makevars.in"),
    quiet = quiet,
    overwrite = TRUE,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "Makevars.win.in",
    save_as = file.path("src", "Makevars.win.in"),
    quiet = quiet,
    overwrite = TRUE,
    data = list(lib_name = lib_name)
  )

  use_rextendr_template(
    "cleanup",
    save_as = file.path("cleanup"),
    quiet = quiet,
    overwrite = TRUE
  )

  use_rextendr_template(
    "cleanup.win",
    save_as = file.path("cleanup.win"),
    quiet = quiet,
    overwrite = TRUE
  )

  use_rextendr_template(
    "document.rs",
    save_as = file.path("src", "rust", "document.rs"),
    quiet = quiet,
    overwrite = TRUE,
    data = list(lib_name = lib_name, mod_name = mod_name, pkg_name = pkg_name)
  )

  use_rextendr_template(
    "msrv.R",
    save_as = file.path("tools", "msrv.R"),
    quiet = quiet,
    overwrite = TRUE
  )

  use_rextendr_template(
    "config.R",
    save_as = file.path("tools", "config.R"),
    quiet = quiet,
    overwrite = TRUE
  )

  # add configure and configure.win templates
  use_rextendr_template(
    "configure",
    save_as = "configure",
    quiet = quiet,
    overwrite = TRUE
  )

  use_rextendr_template(
    "configure.win",
    save_as = "configure.win",
    quiet = quiet,
    overwrite = TRUE
  )

  if (revendor) {
    src_dir <- find_extendr_crate(path = path)
    vendor_dir <- file.path(src_dir, "vendor")
    vendor_tar <- file.path(src_dir, "vendor.tar.xz")
    vendor_cfg <- file.path(src_dir, "vendor-config.toml")

    if (file.exists(vendor_tar)) {
      cli::cli_alert_danger("Removing {.file src/rust/vendor.tar.xz}")
      file.remove(vendor_tar)
    }

    if (file.exists(vendor_cfg)) {
      cli::cli_alert_danger("Removing {.file src/rust/vendor-config.toml}")
      file.remove(vendor_cfg)
    }

    if (dir.exists(vendor_dir)) {
      cli::cli_alert_danger("Removing {.path src/rust/vendor}")
      unlink(vendor_dir, recursive = TRUE)
    }

    vendor_pkgs(path = path, quiet = quiet)
  }

  cli::cli_alert_info("Update complete. Be sure to run `devtools::document()`.")

  invisible(TRUE)
}

update_message <- function() {
  cli::cli_h3("Updating extendr scaffolding")
  txt <- paste(
    "If `crate_name` and `lib_name` differ from the R package name,",
    "those will need to be specified explicitly.",
    "Please re-run `update_extendr()`."
  )
  cli::cli_alert_warning(txt)
  cli::cli_alert_warning("Please add the below to your `Cargo.toml`:")
  cli::cli_text("")
  cli::cli_div(theme = list(".code" = list("margin-left" = 2)))
  cli::cli_code(c(
    "[lib]",
    'crate-type = [ "rlib", "staticlib" ]'
  ))
  cli::cli_text("")
  cli::cli_code(c(
    "[[bin]]",
    "name = 'document'",
    "path = 'document.rs'"
  ))
  cli::cli_end()
}
