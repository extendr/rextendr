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