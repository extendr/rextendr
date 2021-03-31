#' Formats text as an error message.
#'
#' Prepends `text` with red cross (`x`).
#' Supports {cli}'s inline styles and string interpolation.
#' @param text String to format.
#' @noRd
ui_x <- function(text = "") {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  cli::cli_format_method(cli::cli_alert_danger(text))
}

#' Formats text as an information message.
#'
#' Prepends `text` with cyan info sign (`i`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_i <- function(text = "") {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  cli::cli_format_method(cli::cli_alert_info(text))
}

#' Formats text as a success message.
#'
#' Prepends `text` with green check mark (`v`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_v <- function(text = "") {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  cli::cli_format_method(cli::cli_alert_success(text))
}

#' Formats text as a bullet point
#'
#' Prepends `text` with red bullet point
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_o <- function(text = "") {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  cli::cli_format_method(cli::cli_ul(text))
}

#' Formats text as a warning message.
#'
#' Prepends `text` with yellow exclamation mark (`!`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_w <- function(text = "") {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

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
#'     ui_o("Are you sure you did it right?")
#'   )
#' )
#' # Error: Something bad has happened!
#' # x This thing happened.
#' # x That thing happened.
#' # o Are you sure you did it right?
#' }
#' @noRd
ui_throw <- function(message = "Internal error", details = character(0)) {
  message <- cli::cli_format_method(cli::cli_text(message))

  if (length(details) != 0L) {
    details <- glue::glue_collapse(details, sep = "\n")
    message <- glue::glue(message, details, .sep = "\n")
  }

  rlang::abort(message, call. = FALSE, class = "rextendr_error")
}
