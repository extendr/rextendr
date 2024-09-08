#' Does code throw an rextendr_error?
#'
#' `expect_rextendr_error()` expects an error of class `rextendr_error`, as
#' thrown by `ui_throw()`.
#'
#' @param ... arguments passed to [testthat::expect_error()]
expect_rextendr_error <- function(...) {
  testthat::expect_error(..., class = "rextendr_error")
}

#' Create a local package
#'
#' `local_package()` creates a self-cleaning test package via usethis and withr.
#' It also sets the local working directory and usethis project to the temporary
#' package. These settings are reverted and the package removed via
#' `withr::defer()`. This clean-up happens at the end of the local scope,
#' usually the end of a `test_that()` call.
#'
#' @param nm The name of the temporary package
#' @param envir An environment where `withr::defer()`'s exit handler is
#'   attached, usually the `parent.frame()` to exist locally
#'
#' @return A path to the root package directory
local_package <- function(nm, envir = parent.frame()) {
  local_temp_dir(envir = envir)
  dir <- usethis::create_package(nm)
  setwd(dir)
  local_proj_set(envir = envir)

  invisible(dir)
}

#' Create a local temporary directory
#'
#' `local_temp_dir()` creates a local temporary directory and sets the created
#' directory as the working directory. These are then cleaned up with
#' `withr::defer()` at the end of the scope, usually the end of the `test_that()`
#' scope.
#'
#' @param envir An environment where `withr::defer()`'s exit handler is
#'   attached, usually the `parent.frame()` to exist locally
#'
#' @return A path to the temporary directory
local_temp_dir <- function(..., envir = parent.frame()) {
  current_wd <- getwd()
  path <- file.path(tempfile(), ...)
  dir.create(path, recursive = TRUE)

  setwd(path)

  withr::defer(
    {
      setwd(current_wd)
      usethis::proj_set(NULL)
      unlink(path)
    },
    envir = envir
  )

  invisible(path)
}

#' Set a local usethis project
#'
#' `local_proj_set()` locally sets a new usethis project. The project is
#' reverted with `withr::defer()` at the end of the scope, usually the end of
#' the `test_that()` scope.
#'
#' @param envir An environment where `withr::defer()`'s exit handler is
#'   attached, usually the `parent.frame()` to exist locally
local_proj_set <- function(envir = parent.frame()) {
  old_proj <- usethis::proj_set(getwd(), force = TRUE)
  withr::defer(usethis::proj_set(old_proj), envir = envir)
}

#' Helper function for snapshot testing.
#' Wraps `brio::read_file` and writes content to output using `cat`.
#' @param ... Path to the file being read.
#' @noRd
cat_file <- function(...) {
  cat(brio::read_file(file.path(...)))
}

#' Helper function for skipping tests when cargo subcommand is unavailable
#' @param args Character vector, arguments to the `cargo` command. Pass to [processx::run()]'s args param.
skip_if_cargo_unavailable <- function(args = "--help") {
  tryCatch(
    {
      processx::run("cargo", args, error_on_status = TRUE)
    },
    error = function(e) {
      message <- paste0("`cargo ", paste0(args, collapse = " "), "` is not available.")
      testthat::skip(message)
    }
  )
}

#' Helper function for skipping tests when the test possibly fails because of
#' the path length limit. This only happens on R (<= 4.2) on Windows.
skip_on_R42_win <- function() {
  if (.Platform$OS.type == "windows" && getRversion() < "4.3") {
    testthat::skip("Long path is not supported by this version of Rtools.")
  }
}

skip_if_opted_out_of_dev_tests <- function() {
  env_var <- Sys.getenv("REXTENDR_SKIP_DEV_TESTS") |>
    stringi::stri_trim_both() |>
    stringi::stri_trans_tolower()

  if (env_var == "true" || env_var == "1") {
    testthat::skip("Dev extendr tests disabled")
  }
}

#' Mask any version in snapshot files
#' @param snapshot_lines Character vector, lines of the snapshot file
#' @example
#' expect_snapshot(some_operation(), transform = mask_any_version)
#' @noRd
mask_any_version <- function(snapshot_lines) {
  stringi::stri_replace_all_regex(
    snapshot_lines,
    "\\d+\\.\\d+\\.\\d+(?:\\.\\d+)?",
    "*.*.*"
  )
}
