#' Create roclet that registers `extendr` package
#'   and updates wrappers.
#' @returns A roclet.
#' @export
registration_roclet <- function() {
  roxygen2::roclet("registration")
}

#' @method roclet_process roclet_registration
#' @export
roclet_process.roclet_registration <- function(x, blocks, env, base_path) {
  list()
}

#' @method roclet_output roclet_registration
#' @export
roclet_output.roclet_registration <- function(x, results, base_path, ...) {
  rextendr::register_extendr()
  cli::cli_alert_success("Writting wrappers to {.file R/extendr-wrappers.R}.")
  invisible(NULL)
}
