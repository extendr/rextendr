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
#' @return Character vector holding the contents of the generated macro statement.
#' @keywords internal
#' @export
make_module_macro <- function(code, module_name = "rextendr") {
  # make sure we have cleanly separated lines
  lines <- stringi::stri_split_lines(
    glue_collapse(code, sep = "\n"),
    omit_empty = TRUE
  )[[1]]

  idents <- find_exports(clean_rust_code(lines))
  outlines <- c("extendr_module! {", glue("mod {module_name};"))
  outlines <- c(outlines, glue::glue_data(idents, "{type} {name};"))
  outlines <- c(outlines, "}")
  outlines
}
