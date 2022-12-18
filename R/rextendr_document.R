#' Compile Rust code and generate package documentation.
#'
#' `rextendr::document()` was a wrapper for [devtools::document()] to ensure
#' that Rust code is recompiled (when necessary) and that up-to-date R wrappers
#' are generated before re-generating the package documentation. However, as of
#' pkgdown 1.4.0, `devtools::document()` detects the changes on Rust code, so
#' the users can rely on it directly.
#' @inheritParams devtools::document
#' @return No return value, called for side effects.
#' @export
document <- function(pkg = ".", quiet = getOption("usethis.quiet", FALSE), roclets = NULL) {
  lifecycle::deprecate_soft("0.3.0", "rextendr::document()", "devtools::document()")
  devtools::document(pkg = pkg, roclets = roclets, quiet = FALSE)
}
