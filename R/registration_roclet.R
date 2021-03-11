#' Create roclet that registers `extendr` package
#'   and updates wrappers.
#' @returns A roclet.
#' @export
register_extendr_roclet <- function() {
  roxygen2::roclet("registration")
}

#' @importFrom roxygen2 roclet_process
#' @export
roclet_process.roclet_registration <- function(x, blocks, env, base_path) {
  list()
}

#' @importFrom roxygen2 roclet_output
#' @export
roclet_output.roclet_registration <- function(x, results, base_path, ...) {
  rextendr::register_extendr()
  invisible(NULL)
}