find_exports <- function(clean_lns) {
  ids <- find_extendr_attrs_ids(clean_lns)
  start <- ids
  end <- dplyr::lead(ids, default = length(clean_lns) + 1L) - 1L

  # start and end may empty
  if (rlang::is_empty(start) || rlang::is_empty(end)) {
    return(tibble::tibble(name = character(0), type = character(0), lifetime = character(0)))
  }

  purrr::map2(start, end, ~ extract_meta(clean_lns[.x:.y])) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(type = dplyr::coalesce(.data$impl, .data$fn)) %>%
    dplyr::select(dplyr::all_of(c("name", "type", "lifetime")))
}

# Finds lines which contain #[extendr] (allowing additional spaces)
find_extendr_attrs_ids <- function(lns) {
  which(stringi::stri_detect_regex(lns, r"{#\s*\[\s*extendr(\s*\(.*\))?\s*\]}"))
}

# Gets function/module metadata from a subset of lines.
# Finds first occurrence of `fn` or `impl`.
extract_meta <- function(lns) {
  # Matches fn|impl<'a> item_name
  result <- stringi::stri_match_first_regex(
    glue_collapse(lns, sep = "\n"),
    "(?:(?<fn>fn)|(?<impl>impl)(?:\\s*<(?<lifetime>.+?)>)?)\\s+(?<name>(?:r#)?(?:_\\w+|[A-z]\\w*))"
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


    rlang::abort(
      cli::cli_fmt({
        cli::cli_text(
          "Rust code contains invalid attribute macros."
        )
        cli::cli_alert_danger(
          "No valid {.code fn} or {.code impl} block found in the \\
          following sample:"
        )
        cli::cli_code(code_sample)
      }),
      class = "rextendr_error"
    )
  }
  result
}
