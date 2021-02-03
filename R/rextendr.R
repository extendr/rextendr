#' Call Rust code from R using the 'extendr' Crate
#'
#' The rextendr package implements functions to interface with Rust code from R.
#' See [rust_source()] for details.
#' @name rextendr
#' @importFrom dplyr mutate
#' @docType package
NULL

# In the above code, we need to import something from dplyr to make R check happy;
# dplyr is needed for purrr::mutated_dfr() but not called directly.
