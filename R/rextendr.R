#' Call Rust code from R using the 'extendr' Crate
#'
#' The rextendr package implements functions to interface with Rust code from R.
#' See [rust_source()] for details.
#' @name rextendr
#' @importFrom dplyr   mutate
#' @importFrom purrr   map2 map_lgl flatten_chr map_if every map discard
#' @importFrom glue    glue
#' @importFrom rlang   dots_list names2 as_function is_missing is_atomic is_null is_na
#' @importFrom stringi stri_replace_all_regex
#' @docType package
NULL

# In the above code, we need to import something from dplyr to make R check happy;
# dplyr is needed for purrr::mutated_dfr() but not called directly.
