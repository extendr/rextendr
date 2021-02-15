find_exports <- function(clean_lns) {
  clean_lns
  ids <- find_extendr_attrs_ids(clean_lns)
  start <- ids
  end <- lead(ids, default = length(clean_lns) + 1L) - 1L

  map2_dfr(
    start,
    end,
    ~extract_func(clean_lns[seq(.x, .y, by = 1L)])
  ) %>%
  transmute(name, type = if_else(is.na(impl), "fn", "impl"), lifetime)
}

find_extendr_attrs_ids <- function(lns) {
  which(stri_detect_regex(lns, "#\\s*\\[\\s*extendr\\s*\\]"))
}

extract_func <- function(lns) {

  result <- stri_match_first_regex(
      paste(lns, collapse = "\n"),
      "(?:(fn)|(impl)<(.+?)>)\\s+(_\\w+|[A-z]\\w*)"
  ) %>%
    as_tibble(.name_repair = "minimal") %>%
    set_names(c("match", "fn", "impl", "lifetime", "name")) %>%
    filter(!is.na(match))

  if (nrow(result) == 0L) {
    # This unfortunately does not provide
    # meaningful output or source line numbers.
    code_sample <- stri_sub(
      paste(lns, collapse = "\n  "),
      1, 20
    )
    stop(
      glue::glue(
        "Rust code contains invalid attribute macros.",
        "x No valid `fn` or `impl` block found in the following sample:",
        "`{code_sample}`",
        .sep = "\n ",
        .trim = FALSE
      ),
      call. = FALSE
    )
  }
  result
}
