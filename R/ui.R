#' Formats text as an error message.
#'
#' Prepends `text` with red cross (`x`).
#' Supports {cli}'s inline styles and string interpolation.
#' @param text String to format.
#' @noRd
ui_x <- function(text = "") {
  cli::cli_format_method(cli::cli_alert_danger(text))
}

#' Formats text as an information message.
#'
#' Prepends `text` with cyan info sign (`i`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_i <- function(text = "") {
  cli::cli_format_method(cli::cli_alert_info(text))
}

#' Formats text as a success message.
#'
#' Prepends `text` with green check mark (`v`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_v <- function(text = "") {
  cli::cli_format_method(cli::cli_alert_success(text))
}

#' Formats text as a question message.
#'
#' Prepends `text` with yellow question mark (`?`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_q <- function(text = "") {
  # There is no built-in style questioning message,
  # so we construct it ourselves.
  # This will not be affected by global styling.
  cli::cli_format_method(
    cli::cli_alert(
      paste(
        cli::col_yellow("?"),
        cli::cli_format_method(
          cli::cli_text(text)
        )
      )
    )
  )
}

#' Formats text as a warning message.
#'
#' Prepends `text` with yellow exclamation mark (`!`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_w <- function(text = "") {
  cli::cli_format_method(cli::cli_alert_warning(text))
}

#' Throws an error with formatted message.
#'
#' Creates a styled error message that is then thrown
#' using [`stop()`]. Supports {cli} formatting.
#' @param message The primary error message.
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
#' @noRd
ui_throw <- function(message, details = character(0)) {
  if (missing(message) || !nzchar(message)) {
    message <- "Internal error."
  } else {
    message <- cli::cli_format_method(cli::cli_text(message))
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
