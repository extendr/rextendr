#' Create roclet that tracks Rust source files changes.
#' @returns A roclet.
#' @export
filetracker_roclet <- function() {
  roxygen2::roclet("filetracker")
}

#' @export
roclet_process.roclet_filetracker <- function(x, blocks, env, base_path) {
  list()
}

#' @export
roclet_output.roclet_filetracker <- function(x, results, base_path, ...) {
  if (needs_compilation()) {
    touch_makevars()
    cli::cli_alert_warning("Run {.code devtools::document()} one more time to recompile Rust source.")
  }
  invisible(NULL)
}
