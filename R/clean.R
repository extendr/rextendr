#' Clean Rust binaries and package cache.
#'
#' Removes Rust binaries (such as `.dll`/`.so` libraries), C wrapper object files,
#' invokes `cargo clean` to reset cargo target directory
#' (found by default at `pkg_root/src/rust/target/`).
#' Useful when Rust code should be recompiled from scratch.
#'
#' @param path character scalar, path to R package root.
#' @param echo logical scalar, should cargo command and outputs be printed to
#' console (default is `TRUE`)
#'
#' @return character vector with names of all deleted files (invisibly).
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

  manifest_path <- find_extendr_manifest(path = path)

  # Note: This should be adjusted if `TARGET_DIR` changes in `Makevars`
  target_dir <- rprojroot::find_package_root_file(
    "src", "rust", "target",
    path = path
  )

  if (!dir.exists(target_dir)) {
    cli::cli_abort(
      c(
        "Could not clean binaries.",
        "Target directory not found at {.path target_dir}."
      ),
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
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

  run_cargo(
    args,
    wd = find_extendr_crate(path = path),
    echo = echo
  )

  root <- rprojroot::find_package_root_file(path = path)

  if (!dir.exists(root)) {
    cli::cli_abort(
      "Could not clean binaries.",
      "R package directory not found at {.path root}.",
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
  }

  pkgbuild::clean_dll(path = root)
}
