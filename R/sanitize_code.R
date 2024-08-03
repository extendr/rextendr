sanitize_rust_code <- function(lines) {
  lines %>%
    remove_empty_or_whitespace() %>%
    fill_block_comments() %>%
    remove_line_comments() %>%
    remove_empty_or_whitespace()
}

remove_empty_or_whitespace <- function(lns) {
  stringi::stri_subset_regex(lns, "^\\s*$", negate = TRUE)
}

remove_line_comments <- function(lns) {
  stringi::stri_replace_first_regex(lns, "//.*$", "")
}

# Because R does not allow straightforward iteration over
# scalar strings, determining `/*` and `*/` positions can be challenging.
# E.g., regex matches 3 `/*` and 3 `*/` in `/*/**/*/`.
# 1. We find all occurrence of `/*` and `*/`.
# 2. We find non-overlapping `/*` and `*/`.
# 3. We build pairs of open-close comment delimiters by collapsing nested
#   comments.
# 4. We fill in space between remaining delimiters with spaces (simplest way).
fill_block_comments <- function(lns, fill_with = " ") { # nolint: object_usage_linter
  lns <- glue_collapse(lns, sep = "\n")

  # Fast path if character input is empty
  if (length(lns) == 0L || !nzchar(lns)) {
    return(character(0))
  }

  locations <- stringi::stri_locate_all_regex(lns, c("/\\*", "\\*/"))

  # A sorted DF having `start`, `end`, and `type`
  comment_syms <-
    locations %>%
    purrr::map(tibble::as_tibble) %>%
    purrr::imap(
      ~ dplyr::mutate(
        .x,
        type = dplyr::if_else(.y == 1L, "open", "close")
      )
    ) %>%
    dplyr::bind_rows() %>%
    dplyr::filter(!is.na(.data$start)) %>%
    dplyr::arrange(.data$start)

  # Fast path if no comments are found at all.
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
  n <- nrow(comment_syms)
  selects <- logical(n)
  selects[1:n] <- TRUE
  # Select non-overlapping delimiters, starting with 1st
  i <- 2L
  while (i <= n) {
    if (comment_syms[["start"]][i] == comment_syms[["end"]][i - 1L]) {
      # If current overlaps with previous, exclude current and
      # jump over the next one, which is included automatically.
      selects[i] <- FALSE
      i <- i + 1L
    }
    # `i` can be incremented twice per cycle, this is intentional.
    i <- i + 1L
  }

  # Contains only valid comment delimiters in order of appearance.
  valid_syms <- dplyr::slice(comment_syms, which(.env$selects))

  n_open <- sum(valid_syms[["type"]] == "open")
  n_close <- sum(valid_syms[["type"]] == "close")
  # Fails if number of `/*` and `*/` are different.
  if (n_open != n_close) {
    cli::cli_abort(
      c(
        "Malformed comments.",
        "x" = "Number of start {.code /*} and end {.code */} \\
               delimiters are not equal.",
        "i" = "Found {n_open} occurrence{?s} of {.code /*}.",
        "i" = "Found {n_close} occurrence{?s} of {.code */}."
      ),
      class = "rextendr_error"
    )
  }

  # This handles 'nested' comments by calculating nesting depth.
  # Whenever `cnt` reaches 0 it indicates that it is an end of a comment block,
  # and the next delimiter starts the new block, so we include both, as well as
  # the first in the table.
  to_replace <-
    valid_syms %>%
    dplyr::mutate(
      cnt = cumsum(dplyr::if_else(.data$type == "open", +1L, -1L))
    ) %>%
    dplyr::filter(
      dplyr::lag(.data$cnt) == 0 | .data$cnt == 0 | dplyr::row_number() == 1
    )

  # This handles `*/ text /*` scenarios.
  # At this point all 'odd' entries should be 'open',
  # all 'even' -- 'close', representing open/close delimiters
  # of one comment block.
  # If not, comments are malformed.
  n_valid <- nrow(to_replace)
  if (
    any(to_replace[["type"]][2L * seq_len(n_valid / 2L) - 1L] != "open") ||
      any(to_replace[["type"]][2L * seq_len(n_valid / 2L)] != "close")
  ) {
    cli::cli_abort(
      c(
        "Malformed comments.",
        "x" = "{.code /*} and {.code */} are not paired correctly.",
        "i" = "This error may be caused by a code fragment like \\
               {.code */ ... /*}."
      ),
      class = "rextendr_error"
    )
  }
  # Manual `pivot_wider`.
  to_replace <- tibble::tibble(
    start_open = dplyr::filter(to_replace, .data$type == "open")[["start"]],
    end_close = dplyr::filter(to_replace, .data$type == "close")[["end"]],
  )

  # Replaces each continuous commnet block with whitespaces
  # of the same length -- this is needed to preserve line length
  # and previously computed positions, and it does not affect
  # parsing at later stages.
  result <- purrr::reduce2(
    to_replace[["start_open"]],
    to_replace[["end_close"]],
    function(ln, from, to) {
      stringi::stri_sub(
        ln,
        from,
        to,
      ) <- strrep(fill_with, to - from + 1L)
      ln
    },
    .init = lns
  )


  result <- stringi::stri_split_lines(result, omit_empty = TRUE)[[1]]
  result
}
