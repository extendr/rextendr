#' Create roclet that tracks Rust source files changes.
#' @returns A roclet.
#' @export
filetracker_roclet <- function() {
  roxygen2::roclet("filetracker")
}

#' @importFrom roxygen2 roclet_process
#' @method roclet_process roclet_filetracker
#' @export
roclet_process.roclet_filetracker <- function(x, blocks, env, base_path) {
  list()
}

#' @importFrom roxygen2 roclet_output
#' @method roclet_output roclet_filetracker
#' @export
roclet_output.roclet_filetracker <- function(x, results, base_path, ...) {
  if (needs_compilation()) {
    touch_makevars()
  }
  invisible(NULL)
}