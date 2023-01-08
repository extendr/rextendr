#' Clean Rust binaries and package cache.
#'
#' Removes Rust binaries (such as `.dll`/`.so` libraries), C wrapper object files,
#' invokes `cargo clean` to reset cargo target directory
#' (found by default at `pkg_root/src/rust/target/`).
#' Useful when Rust code should be recompiled from scratch.
#' @param path \[ string \] Path to the package root.
#' @export
clean <- function(path = ".") {
  root <- rprojroot::find_package_root_file(path = path)

  rust_folder <- normalizePath(
    file.path(root, "src", "rust"),
    winslash = "/",
    mustWork = FALSE
  )

  toml_path <- normalizePath(
    file.path(rust_folder, "Cargo.toml"),
    winslash = "/",
    mustWork = FALSE
  )

  # Note: This should be adjusted if `TARGET_DIR` changes in `Makevars`
  target_dir <- normalizePath( # nolint: object_usage_linter
    file.path(rust_folder, "target"),
    winslash = "/",
    mustWork = FALSE
  )

  if (!file.exists(toml_path)) {
    ui_throw(
      "Unable to clean binaries.",
      c(
        bullet_w(
          "{.file Cargo.toml} not found in {.path {rust_folder}}."
        )
      )
    )
  }

  cargo_envvars <- get_cargo_envvars()

  args <- c(
    "clean",
    glue("--manifest-path={toml_path}"),
    glue("--target-dir={target_dir}"),
    if (tty_has_colors()) {
      "--color=always"
    } else {
      "--color=never"
    },
    "--quiet"
  )
  exec_result <- processx::run(
    command = "cargo",
    args = args,
    echo_cmd = FALSE,
    windows_verbatim_args = FALSE,
    stderr = "|",
    stdout = "|",
    error_on_status = FALSE,
    env = cargo_envvars
  )

  if (!isTRUE(exec_result$status == 0)) {
    if (!tty_has_colors()) {
      err_msg <- cli::ansi_strip(exec_result$stderr)
    } else {
      err_msg <- exec_result$stderr
    }
    ui_throw(
      "Unable to execute {.code cargo clean}.",
      bullet_x(paste(err_msg, collapse = "\n")),
      call = caller_env(),
      glue_open = "{<{",
      glue_close = "}>}"
    )
  }
  pkgbuild::clean_dll(path = root)
}
