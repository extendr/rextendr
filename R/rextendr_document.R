#' Compiles Rust code and generates package documentation.
#'
#' This function is a wrapper for [`devtools::document()`].
#' It executes `extendr`-specific routine before calling [`devtools::document()`],
#' ensuring Rust code is recompiled (when necessary) and up-to-date R wrappers are generated.
#' @inheritParams devtools::document
#' @export
document <- function(pkg = ".", quiet = FALSE, roclets = NULL) {
  try_save_all(quiet = quiet)

  register_extendr(path = pkg, quiet = quiet)
  devtools::document(pkg = pkg, roclets = roclets, quiet = FALSE)
}
