# Currently we have code here that works for the internal needs of this package.
# In the future, it should also work for package development, so that we can
# call a function here that generates the wrappers and saves them to the right
# location.

# Some relevant notes for the second application:
# to get the name of the current package, use code such as the following:
# library(desc)
# library(here)
#
# x <- desc(file = here("DESCRIPTION"))
# x$get("Package")


make_wrappers <- function(module_name, package_name, outfile,
                          use_symbols = FALSE, quiet = FALSE) {
  wrapper_function <- glue::glue("wrap__make_{module_name}_wrappers")
  wrapper_call <- glue::glue(
    ".Call(
       \"{wrapper_function}\",
       use_symbols = {use_symbols},
       package_name = \"{package_name}\",
       PACKAGE = \"{package_name}\"
    )"
  )

  x <- eval(str2expression(wrapper_call))
  x <- strsplit(x, "\n")[[1]]

  if (!isTRUE(quiet)) {
    message("Writting wrappers to:\n", outfile)
  }
  brio::write_lines(x, outfile)
}
