#' Formats text as an error message.
#'
#' Prepends `text` with red cross (`x`). Performs [`glue::glue()`] interpolation.
#' @param text String to format.
#' @keywords internal
ui_x <- function(text = "") {
  glue::glue("{cli::col_red(cli::symbol$cross)} {glue::glue(text)}")
}

#' Formats text as an information message.
#'
#' Prepends `text` with cyan info sign (`i`). Performs [`glue::glue()`] interpolation.
#' @inheritParams ui_x
#' @keywords internal
ui_i <- function(text = "") {
  glue::glue("{cli::col_cyan(cli::symbol$info)} {glue::glue(text)}")
}

#' Formats text as a success message.
#'
#' Prepends `text` with green check mark (`v`). Performs [`glue::glue()`] interpolation.
#' @inheritParams ui_x
#' @keywords internal
ui_v <- function(text = "") {
  glue::glue("{cli::col_green(cli::symbol$tick)} {glue::glue(text)}")
}

#' Formats text as a question message.
#'
#' Prepends `text` with yellow question mark (`?`). Performs [`glue::glue()`] interpolation.
#' @inheritParams ui_x
#' @keywords internal
ui_q <- function(text = "") {
  glue::glue("{cli::col_yellow(\"?\")} {glue::glue(text)}")
}

#' Formats text as a warning message.
#'
#' Prepends `text` with yellow exclamation mark (`!`). Performs [`glue::glue()`] interpolation.
#' @inheritParams ui_x
#' @keywords internals
ui_w <- function(text = "") {
  glue::glue("{cli::col_yellow(\"!\")} {glue::glue(text)}")
}

#' Throws an error with formatted message.
#' 
#' Creates a styled error message that is then thrown
#' using [`stop()`].
#' @param message The primary error message. Mandatory.
#' @param details An optional character vector of error detais.
#' can be formatted with `ui_*` helper functions.
#' @examples
#' \dontrun{
#' ui_throw(
#'   "Something bad has happened!",
#'   c(
#'     ui_x("This thing happened."),
#'     ui_x("That thing happened."),
#'     ui_q("Are you sure you did it right?")
#'   )
#' )
#' # Error: Something bad has happened!
#' # x This thing happened.
#' # x That thing happened.
#' # ? Are you sure you did it right?
#' }
#' @keywords internal
ui_throw <- function(message, details = character(0)) {
  if (missing(message) || !nzchar(message)) {
    message <- "Internal error."
  }

  if (length(details) != 0L) {
    details <- glue::glue_collapse(
        details,
        sep = "\n"
      )
    stop(
      glue::glue(
        message,
        details,
        .sep = "\n"
      ),
      call. = FALSE
    )
  } else {
    stop(message, call. = FALSE)
  }
}
