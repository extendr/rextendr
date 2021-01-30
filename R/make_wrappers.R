# this file will eventually contain code to read wrapper info from a Rust
# library and write to a desired location.

# some relevant notes:
# to get the name of the current package, use code such as the following:
# library(desc)
# library(here)
#
# x <- desc(file = here("DESCRIPTION"))
# x$get("Package")


make_wrappers <- function(module_name, package_name, outfile,
                          use_symbols = FALSE, quiet = FALSE) {
  x <- .Call(
    glue::glue("wrap__make_{module_name}_wrappers"),
    use_symbols = use_symbols,
    package_name = package_name,
    PACKAGE = package_name
  )
  x <- strsplit(x, "\n")[[1]]

  if (!isTRUE(quiet)) {
    message("Writting wrappers to:\n", outfile)
  }
  brio::write_lines(x, outfile)
}
