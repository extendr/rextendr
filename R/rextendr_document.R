#' Compile Rust code and generate package documentation.
#'
#' The function `rextendr::document()` updates the package documentation for an
#' R package that uses `extendr` code, taking into account any changes that were
#' made in the Rust code. It is a wrapper for [devtools::document()], and it
#' executes `extendr`-specific routines before calling [devtools::document()].
#' Specifically, it ensures that Rust code is recompiled (when necessary) and that
#' up-to-date R wrappers are generated before re-generating the package documentation.
#' @inheritParams devtools::document
#' @return No return value, called for side effects.
#' @export
document <- function(pkg = ".", quiet = getOption("usethis.quiet", FALSE), roclets = NULL) {
  try_save_all(quiet = quiet)

  register_extendr(path = pkg, quiet = quiet)

  rlang::check_installed("devtools")
  devtools::document(pkg = pkg, roclets = roclets, quiet = FALSE)
}
