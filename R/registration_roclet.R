#' Create roclet that registers `extendr` package
#'   and updates wrappers.
#' @returns A roclet.
#' @export
registration_roclet <- function() {
  roxygen2::roclet("registration")
}

#' @export
roclet_process.roclet_registration <- function(x, blocks, env, base_path) {
  list()
}

#' @export
roclet_output.roclet_registration <- function(x, results, base_path, ...) {
  rextendr::register_extendr()
  invisible(NULL)
}
