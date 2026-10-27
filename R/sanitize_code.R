remove_empty_or_whitespace <- function(lns) {
  stringi::stri_subset_regex(lns, "^\\s*$", negate = TRUE)
}
