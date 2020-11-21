get_exported_functions <- function(file) {
  lines <- brio::read_lines(file)

  # find all lines with the "#[extendr]" decoration
  idx <- which(grepl("\\#\\[extendr\\]", lines))
  idx <- idx + 1 # bump indices by one to look in subsequent lines

  # simple regex to parse a rust function declaration. declaration needs to be all on one line.
  pattern <- "\\s*fn\\s+(\\w+)\\s*\\(\\s*([^)]*\\S|)\\s*\\)\\s*(->|)"
  fn_lines <- lines[idx]
  match_list <- gregexpr(pattern, fn_lines, perl = TRUE)

  purrr::map2_dfr(fn_lines, match_list, extract_matches)
}

extract_matches <- function(line, match) {
  match <- attributes(match)
  if (match$capture.start[1] > 0) {
    name <- substr(line, match$capture.start[1], match$capture.start[1] + match$capture.length[1] - 1)
  } else {
    name <- NA_character_
  }
  if (match$capture.start[2] > 0) {
    arguments <- substr(line, match$capture.start[2], match$capture.start[2] + match$capture.length[2] - 1)
  } else {
    arguments <- NA_character_
  }
  if (match$capture.length[3] > 0) {
    is_void <- FALSE
  } else {
    is_void <- TRUE
  }

  tibble::tibble(name = name, arguments = arguments, is_void = is_void)
}

generate_r_functions <- function(funs) {
  funs$call_args <- ifelse(funs$arguments == "", "", ", ...")
  funs$fun_args <- ifelse(funs$arguments == "", "", "...")
  funs$calls <- ifelse(
    funs$is_void,
    glue::glue_data(funs, 'invisible(.Call("wrap__{name}"{call_args}))'),
    glue::glue_data(funs, '.Call("wrap__{name}"{call_args})')
  )

  out <- glue::glue_data(funs, '
    {name} <- function({fun_args}) {{
      {calls}
    }}
  ')
  out <- glue::glue_collapse(out, sep = "\n\n")
  unclass(out)
}
