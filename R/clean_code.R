clean_rust_code <- function(lines) {
  lines <-
    lines %>%
    remove_empty_or_whitespace %>%
    fill_block_comments %>%
    remove_line_comments %>%
    remove_empty_or_whitespace
}

remove_empty_or_whitespace <- function(lns) {
  stri_subset_regex(lns, "^\\s*$", negate = TRUE)
}

remove_line_comments <- function(lns) {
  stri_replace_first_regex(lns, "//.*$", "")
}

fill_block_comments <- function(lns, fill_with = " ") {
  lns <- paste(lns, collapse = "\n")
  locations <- stri_locate_all_regex(lns, c("/\\*", "\\*/"))

  comment_syms <-
    locations %>%
    map(as_tibble) %>%
    imap_dfr(
      ~mutate(
        .x,
        type = if_else(.y == 1L, "open", "close")
      )
    ) %>%
    arrange(start)

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
    mutate(cnt = cumsum(if_else(type == "open", +1L, -1L))) %>%
    filter(lag(cnt) == 0 | cnt == 0 | row_number() == 1) %>%
    mutate(id = vec_rep_each(seq_len(n() / 2L), 2L))

  to_replace <- tibble(
    start_open = filter(to_replace, type == "open")[["start"]],
    end_close = filter(to_replace, type == "close")[["end"]],
  )

  reduce(
    seq_len(nrow(to_replace)),
    function(ln, i) {
      from <- to_replace[["start_open"]][i]
      to <- to_replace[["end_close"]][i]

      `stri_sub<-`(
        ln,
        from,
        to,
        value = strrep(fill_with, to - from + 1L)
      )
    },
    .init = lns
  ) %>%
  stri_split_regex("\n", simplify = TRUE) %>%
  as.character
}
