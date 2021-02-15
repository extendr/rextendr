utils::globalVariables(
  c("cnt", "start", "impl", "lifetime", "type", "name")
)

clean_rust_code <- function(lines) {
  lines <-
    lines %>%
    remove_empty_or_whitespace %>%
    fill_block_comments %>%
    remove_line_comments %>%
    remove_empty_or_whitespace
}

remove_empty_or_whitespace <- function(lns) {
  stringi::stri_subset_regex(lns, "^\\s*$", negate = TRUE)
}

remove_line_comments <- function(lns) {
  stringi::stri_replace_first_regex(lns, "//.*$", "")
}

fill_block_comments <- function(lns, fill_with = " ") {
  lns <- paste(lns, collapse = "\n")
  locations <- stringi::stri_locate_all_regex(lns, c("/\\*", "\\*/"))

  comment_syms <-
    locations %>%
    purrr::map(tibble::as_tibble) %>%
    purrr::imap_dfr(
      ~dplyr::mutate(
        .x,
        type = dplyr::if_else(.y == 1L, "open", "close")
      )
    ) %>%
    dplyr::arrange(start)

  if (
    all(is.na(comment_syms[["start"]])) &&
      all(is.na(comment_syms[["end"]]))
  ) {
    return(
      stringi::stri_split_lines(
      lns,
      omit_empty = TRUE
      )[[1]]
    )
  }
  i <- 2L
  n <- nrow(comment_syms)
  selects <- logical(n)
  selects[1:n] <- TRUE

  while (i <= n) {
    if (comment_syms[["start"]][i] == comment_syms[["end"]][i - 1L]) {
      selects[i] <- FALSE
      i <- i + 1L
    }
    i <- i + 1L
  }
  valid_syms <- dplyr::slice(comment_syms, which(selects))

  to_replace <-
    valid_syms %>%
    dplyr::mutate(cnt = cumsum(dplyr::if_else(type == "open", +1L, -1L))) %>%
    dplyr::filter(
      dplyr::lag(cnt) == 0 | cnt == 0 | dplyr::row_number() == 1
    ) %>%
    dplyr::mutate(id = rep(seq_len(dplyr::n() / 2L), each = 2L))

  to_replace <- tibble::tibble(
    start_open = dplyr::filter(to_replace, type == "open")[["start"]],
    end_close  = dplyr::filter(to_replace, type == "close")[["end"]],
  )

  result <- purrr::reduce(
    seq_len(nrow(to_replace)),
    function(ln, i) {
      from <- to_replace[["start_open"]][i]
      to <- to_replace[["end_close"]][i]

      stringi::stri_sub(
        ln,
        from,
        to,
      ) <- strrep(fill_with, to - from + 1L)
      ln
    },
    .init = lns
  )

  stringi::stri_split_lines(result, omit_empty = TRUE)[[1]]

}
