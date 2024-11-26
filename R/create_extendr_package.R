#' Create package that uses Rust
#'
#' @description
#' This function creates an R project directory for package development
#' with Rust extensions.
#'
#' @inheritParams usethis::create_package
#' @param ... arguments passed on to `usethis::create_package()` and
#' `rextendr::use_extendr()`
#'
#' @return Path to the newly created project or package, invisibly.
#' @keywords internal
#'
#' @noRd
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

  args <- map(args, nullify_empty_string)

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

  invisible(path)
}
