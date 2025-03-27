#' extendr README badge
#'
#' Add the version of extendr being used by an R package to its README.
#'
#' Requires `usethis` to be available.
#'
#' @examples
#' \dontrun{
#' use_extendr_badge()
#' }
#'
#' @inheritParams use_extendr
#' @export
use_extendr_badge <- function(path = ".") {
  rlang::check_installed("usethis")
  meta <- read_cargo_metadata(path)
  deps <- meta[[c("packages", "dependencies")]][[1]]

  if (rlang::is_null(deps)) {
    cli::cli_abort("Unable to determine version of `extendr-api`")
  }

  is_extendr <- which(deps$name == "extendr-api")
  if (!rlang::is_bare_numeric(is_extendr, 1)) {
    cli::cli_abort("Unable to determine version of `extendr-api`")
  }

  extendr_version <- deps$req[is_extendr]

  usethis::use_badge(
    "extendr",
    "https://extendr.github.io/extendr/extendr_api/",
    sprintf("https://img.shields.io/badge/extendr-%s-276DC2", extendr_version)
  )
}
