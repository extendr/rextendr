#' Generate extendr module macro for Rust source
#'
#' Read some Rust source code, find functions or implementations with the
#' `#[extendr]` attribute, and generate an `extendr_module!` macro statement.
#'
#' This function uses simple regular expressions to do the Rust parsing and
#' can get confused by valid Rust code. It is only meant as a convenience for
#' simple use cases. In particular, it cannot currently handle implementations
#' for generics.
#' @param code Character vector containing Rust code.
#' @param module_name Module name
#' @keywords internal
#' @export
make_module_macro <- function(code, module_name = "rextendr") {
  # make sure we have cleanly separated lines
  lines <- stringi::stri_split_lines(
    glue::glue_collapse(code, sep = "\n"),
    omit_empty = TRUE
  )[[1]]
  # idents <- get_extendr_idents(lines[[1]])
  idents <- find_exports(clean_rust_code(lines))
  outlines <- c("extendr_module! {", glue::glue("mod {module_name};"))
  outlines <- c(outlines, glue::glue_data(idents, "{type} {name};"))
  outlines <- c(outlines, "}")
  outlines
}


get_extendr_idents <- function(lines) {
  # remove all lines that are commented out
  not_comment <- !grepl("^\\s*//", lines)
  lines <- lines[not_comment]

  # find all lines with the "#[extendr]" decoration
  idx <- which(grepl("\\#\\[extendr\\]", lines))
  idx <- idx + 1 # bump indices by one to look in subsequent lines

  # simple regex to parse the start of a rust fn or impl declaration
  pattern <- "^\\s*(fn|impl)\\s+(_\\w+|[A-z]\\w*)"
  fn_lines <- lines[idx]
  match_list <- gregexpr(pattern, fn_lines, perl = TRUE)

  purrr::map2_dfr(fn_lines, match_list, extract_matches)
}

extract_matches <- function(line, match) {
  match <- attributes(match)
  if (match$capture.start[1] > 0) {
    type <- substr(line, match$capture.start[1], match$capture.start[1] + match$capture.length[1] - 1)
  } else {
    type <- NA_character_
  }
  if (match$capture.start[2] > 0) {
    ident <- substr(line, match$capture.start[2], match$capture.start[2] + match$capture.length[2] - 1)
  } else {
    ident <- NA_character_
  }

  tibble::tibble(type, ident)
}
