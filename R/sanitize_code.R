sanitize_rust_code <- function(lines) {
  lines |>
    remove_empty_or_whitespace() |>
    remove_block_comments() |>
    remove_line_comments() |>
    remove_empty_or_whitespace()
}

remove_empty_or_whitespace <- function(lns) {
  stringi::stri_subset_regex(lns, "^\\s*$", negate = TRUE)
}

remove_line_comments <- function(lns) {
  stringi::stri_replace_first_regex(lns, "//.*$", "")
}

# Replace each `/* block comment */` with a line break rather than deleting it.
remove_block_comments <- function(lns) {
  txt <- paste0(lns, collapse = "\n")
  if (!nzchar(txt)) {
    return(character(0))
  }

  # One pass finds both delimiters without overlaps: in `/*/**/*/`,
  # matching is left-to-right, so `/*/` can't yield both `/*` and `*/`.
  pos <- stringi::stri_locate_all_regex(txt, "/\\*|\\*/")[[1]]
  if (is.na(pos[1, "start"])) {
    return(stringi::stri_split_lines(txt, omit_empty = TRUE)[[1]])
  }

  type <- stringi::stri_sub(txt, pos[, "start"], pos[, "end"])
  depth <- cumsum(ifelse(type == "/*", 1L, -1L))

  # Well-formed iff depth never dips below 0 (no stray `*/`) and
  # ends at 0 (no unclosed `/*`).
  if (any(depth < 0L) || depth[length(depth)] != 0L) {
    cli::cli_abort(
      c(
        "Malformed comments.",
        "x" = "{.code /*} and {.code */} are not paired correctly."
      ),
      class = "rextendr_error"
    )
  }

  # A top-level block spans from a delimiter entered at depth 0
  # to the delimiter that returns to depth 0.
  prev_depth <- c(0L, depth[-length(depth)])
  open <- pos[prev_depth == 0L, "start"]
  close <- pos[depth == 0L, "end"]

  txt <- stringi::stri_sub_replace_all(txt, open, close, replacement = "\n")
  stringi::stri_split_lines(txt, omit_empty = TRUE)[[1]]
}
