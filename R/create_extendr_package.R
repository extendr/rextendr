
#' Create a project for R package development with Rust
#'
#' @description
#' This function creates an R project directory for package development
#' with Rust extensions.
#'
#' @param path a path to new directory
#' @param ... arguments passed on to `usethis::create_package()` and
#' `rextendr::use_extendr()`
#'
#' @return Path to the newly created project or package, invisibly.
#' @keywords internal
#'
#' @examples
create_extendr_package <- function(path, ...) {

  # error if usethis is not installed
  rlang::check_installed("usethis")

  args <- rlang::list2(...)

  # hunch is that rstudio project text input widgets return empty strings
  # when no value is given, want to make sure it is NULL so `use_extendr()`
  # handles it correctly
  nullify_empty_string <- function(x) {
    if (rlang::is_string(x) && nzchar(x)) x else NULL
  }

  args <- purrr::map(args, nullify_empty_string)

  # build package directory, but don't start a new R session with
  # it as the working directory! i.e., set `open = FALSE`
  usethis::create_package(
    path,
    fields = list(),
    rstudio = TRUE,
    roxygen = args[["roxygen"]] %||% TRUE,
    check_name = args[["check_name"]] %||% TRUE,
    open = FALSE
  )

  # add rust scaffolding to project dir
  use_extendr(
    path,
    crate_name = args[["crate_name"]],
    lib_name = args[["lib_name"]],
    quiet = TRUE,
    overwrite = TRUE,
    edition = args[["edition"]] %||% TRUE
  )

  # generate header for INDEX file
  header <- c(
    paste0("Package: ", basename(path)),
    "",
    "BUILD COMPLETE:",
    "The project build successfully generated the necessary R package files.",
    ""
  )

  text <- c(
    "NOTE:",
    "To use {rextendr} in any meaningful way, the user must have",
    "Rust and Cargo available on their local machine. To check that you do,",
    "please run `rextendr::rust_sitrep()`. This will provide a",
    "detailed report of the current state of your Rust infrastructure, along",
    "with some helpful advice about how to address any issues that may arise."
  )

  content <- paste(
    paste(header, collapse = "\n"),
    paste(text, collapse = "\n"),
    sep = "\n"
  )

  writeLines(content, con = file.path(path, "INDEX"))

  return(invisible(path))

}
