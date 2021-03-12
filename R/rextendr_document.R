#' This function is a wrapper for `devtools::document`.
#' It executes `extendr`-specific routine before calling `devtools::document`,
#' ensuring Rust code is recompiled when necessary and appropriate R wrappers are generated.
#'
#' @param pkg String scalar pointing to the package root.
#' @param quiet Logical scalar indicating wether the output should be verbose.
#' @param roclets Additional roclets from `roxygen2` that are passed into
#'   `roxygen2::document`.
#' @export
document <- function(pkg = ".", quiet = FALSE, roclets = NULL) {
  try_save_all()
  needs_compilation <- needs_compilation(pkg, quiet) || pkgbuild::needs_compile(pkg)

  pkgload::load_all(
    path = pkg,
    compile = needs_compilation,
    quiet = quiet
  )

  register_extendr(path = pkg, quiet = quiet)
  devtools::document(pkg = pkg, roclets = roclets, quiet = FALSE)
}