#' Call Rust code from R using the 'extendr' Crate
#'
#' The rextendr package implements functions to interface with Rust code from R.
#' See [rust_source()] for details.
#' @name rextendr
#' @importFrom dplyr   mutate %>%
#' @importFrom purrr   map2 map2_chr map_lgl flatten_chr map_if every map discard
#' @importFrom glue    glue glue_collapse
#' @importFrom rlang   dots_list names2 as_function is_missing is_atomic is_null
#' @importFrom rlang   is_na .data .env
#' @importFrom stringi stri_replace_all_regex
#' @docType package
NULL
