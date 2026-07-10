find_exports <- function(clean_lns) {
  ids <- find_extendr_attrs_ids(clean_lns)
  start <- ids
  end <- c(ids[-1], length(clean_lns) + 1L) - 1L

  # start and end may be empty
  if (rlang::is_empty(start) || rlang::is_empty(end)) {
    return(data.frame(
      name = character(0),
      type = character(0),
      lifetime = character(0)
    ))
  }

  lns <- map2(start, end, \(.x, .y) extract_meta(clean_lns[.x:.y])) |>
    discard(\(.x) is.na(.x["impl"]) & is.na(.x["fn"])) |>
    do.call(rbind, args = _)

  lns[["type"]] <- ifelse(is.na(lns[["impl"]]), lns[["fn"]], lns[["impl"]])
  lns[c("name", "type", "lifetime")]
}

# Finds lines which contain #[extendr] (allowing additional spaces)
# Excludes #[extendr(default=...)] which is used for function arguments
find_extendr_attrs_ids <- function(lns) {
  which(stringi::stri_detect_regex(
    lns,
    r"{#\s*\[\s*extendr(\s*\((?!.*default\s*=).*\))?\s*\]}"
  ))
}

# Gets function/module metadata from a subset of lines.
# Finds first occurrence of `fn` or `impl`.
extract_meta <- function(lns) {
  # Matches fn|impl<'a> item_name
  result <- stringi::stri_match_first_regex(
    glue_collapse(lns, sep = "\n"),
    "(?:(?<struct>struct)|(?<enum>enum)|(?<fn>fn)|(?<impl>impl)(?:\\s*<(?<lifetime>.+?)>)?)\\s+(?<name>(?:r#)?(?:_\\w+|[A-z]\\w*))" # nolint: line_length_linter
  ) |>
    as.data.frame() |>
    rlang::set_names(c(
      "match",
      "struct",
      "enum",
      "fn",
      "impl",
      "lifetime",
      "name"
    ))

  result <- result[!is.na(result[["match"]]), ]

  # If no matches have been found, then the attribute is misplaced
  if (nrow(result) == 0L) {
    # This unfortunately does not provide
    # meaningful output or source line numbers.
    code_sample <- stringi::stri_sub(
      glue_collapse(lns, sep = "\n  "),
      1,
      80
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
