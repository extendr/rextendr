bullet <- function(text = "", cli_f = cli::cli_alert_success, env = parent.frame()) {
  cli::cli_format_method(cli_f(text, .envir = env))
}

bullet_x <- function(text = "", env = parent.frame()) {
  bullet(text, cli::cli_alert_danger, env = env)
}

bullet_i <- function(text = "", env = parent.frame()) {
  bullet(text, cli::cli_alert_info, env = env)
}

bullet_v <- function(text = "", env = parent.frame()) {
  bullet(text, cli::cli_alert_success, env = env)
}

bullet_o <- function(text = "", env = parent.frame()) {
  bullet(text, cli::cli_ul, env = env)
}

bullet_w <- function(text = "", env = parent.frame()) {
  bullet(text, cli::cli_alert_warning, env = env)
}

ui_bullet <- function(text) {
  if (getOption("usethis.quiet", FALSE)) {
    return(invisible())
  }

  rlang::inform(text)
}

#' Formats text as an error message.
#'
#' Prepends `text` with red cross (`x`).
#' Supports {cli}'s inline styles and string interpolation.
#' @param text String to format.
#' @noRd
ui_x <- function(text = "", env = parent.frame()) {
  ui_bullet(bullet_x(text, env = env))
}

#' Formats text as an information message.
#'
#' Prepends `text` with cyan info sign (`i`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_i <- function(text = "", env = parent.frame()) {
  ui_bullet(bullet_i(text, env = env))
}

#' Formats text as a success message.
#'
#' Prepends `text` with green check mark (`v`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_v <- function(text = "", env = parent.frame()) {
  ui_bullet(bullet_v(text, env = env))
}

#' Formats text as a bullet point
#'
#' Prepends `text` with red bullet point
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_o <- function(text = "", env = parent.frame()) {
  ui_bullet(bullet_o(text, env = env))
}

#' Formats text as a warning message.
#'
#' Prepends `text` with yellow exclamation mark (`!`).
#' Supports {cli}'s inline styles and string interpolation.
#' @inheritParams ui_x
#' @noRd
ui_w <- function(text = "", env = parent.frame()) {
  ui_bullet(bullet_w(text, env = env))
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
#'     bullet_x("This thing happened."),
#'     bullet_x("That thing happened."),
#'     bullet_o("Are you sure you did it right?")
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
