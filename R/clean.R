#' Clean Rust binaries and package cache.
#'
#' Removes Rust binaries (such as `.dll`/`.so` libraries), C wrapper object files,
#' invokes `cargo clean` to reset cargo target directory
#' (found by default at `pkg_root/src/rust/target/`).
#' Useful when Rust code should be recompiled from scratch.
#' @param path \[ string \] Path to the package root.
#' @param echo logical scalar, should cargo command and outputs be printed to
#' console (default is TRUE)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' clean()
#' }
clean <- function(path = ".", echo = TRUE) {
  check_string(path, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

  root <- rprojroot::find_package_root_file(path = path)

  rust_folder <- normalizePath(
    file.path(root, "src", "rust"),
    winslash = "/",
    mustWork = FALSE
  )

  manifest_path <- normalizePath(
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

  if (!file.exists(manifest_path)) {
    cli::cli_abort(c(
      "Unable to clean binaries.",
      "!" = "{.file Cargo.toml} not found in {.path {rust_folder}}.",
      class = "rextendr_error"
    ))
  }

  args <- c(
    "clean",
    glue::glue("--manifest-path={manifest_path}"),
    glue::glue("--target-dir={target_dir}"),
    if (tty_has_colors()) {
      "--color=always"
    } else {
      "--color=never"
    }
  )

  out <- processx::run(
    command = "cargo",
    args = args,
    error_on_status = TRUE,
    wd = rust_folder,
    echo_cmd = echo,
    echo = echo,
    env = get_cargo_envvars()
  )

  pkgbuild::clean_dll(path = root)
}
