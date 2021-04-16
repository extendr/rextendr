#' Does code throw an rextendr_error?
#'
#' `expect_rextendr_error()` expects an error of class `rextendr_error`, as
#' thrown by `ui_throw()`.
#'
#' @param ... arguments passed to [testthat::expect_error()]
expect_rextendr_error <- function(...) {
  expect_error(..., class = "rextendr_error")
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
local_temp_dir <- function(envir = parent.frame()) {
  current_wd <- getwd()
  path <- tempfile()
  dir.create(path)

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

