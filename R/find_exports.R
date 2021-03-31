find_exports <- function(clean_lns) {
  ids <- find_extendr_attrs_ids(clean_lns)
  start <- ids
  end <- dplyr::lead(ids, default = length(clean_lns) + 1L) - 1L
  purrr::map2_dfr(
    start,
    end,
    ~ extract_meta(clean_lns[seq(.x, .y, by = 1L)])
  ) %>%
    # Keeps only name, type (fn|impl) and lifetime of impl
    # if present.
    dplyr::transmute(
      .data$name,
      type = dplyr::if_else(is.na(.data$impl), "fn", "impl"),
      .data$lifetime
    )
}

# Finds lines which contain #[extendr] (allowing additional spaces)
find_extendr_attrs_ids <- function(lns) {
  which(stringi::stri_detect_regex(lns, "#\\s*\\[\\s*extendr\\s*\\]"))
}

# Gets function/module metadata from a subset of lines.
# Finds first occurence of `fn` or `impl`.
extract_meta <- function(lns) {

  # Matches fn|impl<'a> item_name
  result <- stringi::stri_match_first_regex(
    glue_collapse(lns, sep = "\n"),
    "(?:(fn)|(impl)(?:\\s*<(.+?)>)?)\\s+(_\\w+|[A-z]\\w*)"
  ) %>%
    tibble::as_tibble(.name_repair = "minimal") %>%
    rlang::set_names(c("match", "fn", "impl", "lifetime", "name")) %>%
    dplyr::filter(!is.na(.data$match))

  # If no matches have been found, then the attribute is misplaced
  if (nrow(result) == 0L) {
    # This unfortunately does not provide
    # meaningful output or source line numbers.
    code_sample <- stringi::stri_sub(
      glue_collapse(lns, sep = "\n  "),
      1, 80
    )
    ui_throw(
      "Rust code contains invalid attribute macros.",
      c(
        bullet_x("No valid {.code fn} or {.code impl} block found in the \\
          following sample:"),
        code_sample
      )
    )
  }
  result
}

