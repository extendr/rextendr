bullet <- function(type = c("x", "i", "v", "o", "w"), text = "", env = parent.frame()) {
  type <- match.arg(type)
  cli_f <- switch(
    type,
    x = cli::cli_alert_danger,
    i = cli::cli_alert_info,
    v = cli::cli_alert_success,
    o = cli::cli_ul,
    w = cli::cli_alert_warning
  )

  cli::cli_format_method(cli_f(text, .envir = env))
}

ui_bullet <- function(type, text, env = parent.frame()) {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  rlang::inform(bullet(type, text, env = env))
}

#' Formats text as an error message.
#'
#' Prepends `text` with red cross (`x`).
#' Supports {cli}'s inline styles and string interpolation.
#' @param text String to format.
#' @noRd
ui_x <- function(text = "", env = parent.frame()) {
  ui_bullet("x", text, env = env)
}

#' Formats text as an information message.
#'
#' Prepends `text` with cyan info sign (`i`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_i <- function(text = "", env = parent.frame()) {
  ui_bullet("i", text, env = env)
}

#' Formats text as a success message.
#'
#' Prepends `text` with green check mark (`v`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_v <- function(text = "", env = parent.frame()) {
  ui_bullet("v", text, env = env)
}

#' Formats text as a bullet point
#'
#' Prepends `text` with red bullet point
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_o <- function(text = "", env = parent.frame()) {
  ui_bullet("o", text, env = env)
}

#' Formats text as a warning message.
#'
#' Prepends `text` with yellow exclamation mark (`!`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_w <- function(text = "", env = parent.frame()) {
  ui_bullet("w", text, env = env)
}

#' Throws an error with formatted message.
#'
#' Creates a styled error message that is then thrown
#' using [`rlang::abort()`]. Supports {cli} formatting.
#' @param message The primary error message.
#' @param details An optional character vector of error detais.
#' can be formatted with `bullet()`.
#' @examples
#' \dontrun{
#' ui_throw(
#'   "Something bad has happened!",
#'   c(
#'     bullet("This thing happened.", "x"),
#'     bullet("That thing happened.", "x"),
#'     bullet("Are you sure you did it right?", "o")
#'   )
#' )
#' # Error: Something bad has happened!
#' # x This thing happened.
#' # x That thing happened.
#' # o Are you sure you did it right?
#' }
#' @noRd
ui_throw <- function(message = "Internal error", details = character(0), env = parent.frame()) {
  message <- cli_format_text(message, env = env)

  if (length(details) != 0L) {
    details <- glue::glue_collapse(details, sep = "\n")
    message <- glue::glue(message, details, .sep = "\n")
  }

  rlang::abort(message, class = "rextendr_error")
}

cli_format_text <- function(message, env = parent.frame()) {
  cli::cli_format_method(cli::cli_text(message, .envir = env))
}
