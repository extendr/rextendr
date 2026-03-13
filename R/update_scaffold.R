#' Update extendr scaffolding
#'
#' When a new version of extendr or rextendr is released, this function updates
#' relevant scaffolding files to the new specification and removes any artifacts
#' that may affect dependency resolution, with the important exception of
#' Cargo.lock and Cargo.toml, which are left as is.
#'
#' @inheritParams use_extendr
#'
#' @return a logical scalar indicating whether scaffold updating was successful
#'
#' @details This is only *part* of the update process! In fact, this just does
#'   some basic file housekeeping, so that the developer can focus on the
#'   important part, namely updating Cargo.lock and Cargo.toml to use the newest
#'   version of extendr-api. Note that updating to the newest extendr version
#'   may require some manual dependency resolution.
#'
#'   The following files are rewritten to the current specification:
#'
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
#'   The following build artifacts and vendoring files are removed if present:
#'
#'   - `src/rust/vendor/`
#'   - `src/rust/vendor.tar.xz`
#'   - `src/rust/vendor-config.toml`
#'   - `src/rust/.cargo/`
#'   - `src/rust/target/`
#'
#'   After clearing these files and folders, `update_scaffold()` will print a
#'   message that explains what to do next (provided `quiet = FALSE`). Usually,
#'   this will be accompanied by a more detailed blog post explaining the update
#'   process.
#'
#' @export
update_scaffold <- function(
  path = ".",
  crate_name = NULL,
  lib_name = NULL,
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

  pkg_name <- pkg_name()
  mod_name <- as_valid_rust_name(pkg_name)

  if (rlang::is_null(crate_name)) {
    crate_name <- mod_name
  } else {
    throw_if_invalid_rust_name(crate_name)
  }

  if (rlang::is_null(lib_name)) {
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

  # wipe all dependency-related files and folders to ensure a clean update
  src_dir <- find_extendr_crate(path = path)
  vendor_dir <- file.path(src_dir, "vendor")
  vendor_tar <- file.path(src_dir, "vendor.tar.xz")
  vendor_cfg <- file.path(src_dir, "vendor-config.toml")
  cargo_cfg_dir <- file.path("src", ".cargo")
  target_dir <- file.path(src_dir, "target")

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

  if (dir.exists(cargo_cfg_dir)) {
    cli::cli_alert_danger("Removing {.path src/rust/.cargo}")
    unlink(cargo_cfg_dir, recursive = TRUE)
  }

  if (dir.exists(target_dir)) {
    cli::cli_alert_danger("Removing {.path src/rust/target}")
    unlink(target_dir, recursive = TRUE)
  }

  update_message()
  invisible(TRUE)
}

update_message <- function() {
  extendr_version <- getOption("rextendr.extendr_deps")[["extendr-api"]]
  toml_dependency <- sprintf('extendr-api = "%s"', extendr_version)
  use_crate_call <- sprintf(
    'rextendr::use_crate("extendr-api", version = "%s")',
    extendr_version
  )

  cli::cli_text()
  cli::cli_bullets(c(
    "v" = "Scaffolding updated successfully.",
    " " = "",
    "!" = "If your crate or library name differs from the R package name, please",
    " " = "re-run {.fn update_extendr} with explicit {.arg lib_name} and {.arg crate_name}.",
    "!" = "You will also need to update `Cargo.toml` to include the following:"
  ))
  cli::cli_div(theme = list(".code" = list("margin-left" = 4)))
  cli::cli_code(c(
    " ",
    "[lib]",
    'crate-type = [ "rlib", "staticlib" ]',
    " ",
    "[[bin]]",
    "name = 'document'",
    "path = 'document.rs'",
    " ",
    "[dependencies]",
    toml_dependency,
    " "
  ))
  cli::cli_end()
  cli::cli_alert_info("You should now call the following in order:")
  cli::cli_div(theme = list("ul" = list("margin-left" = 4)))
  cli::cli_ul(c(
    use_crate_call,
    "rextendr::vendor_pkgs()",
    "devtools::document()"
  ))
  cli::cli_end()
}
