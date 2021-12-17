bullet <- function(text = "", cli_f = cli::cli_alert_success, env = parent.frame()) {
  glue_collapse(cli::cli_format_method(cli_f(text, .envir = env)), sep = "\n")
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
ui_throw <- function(message = "Internal error", details = character(0),
                     env = parent.frame(),
                     glue_open = "{", glue_close = "}") {
  message <- cli_format_text(message, env = env)

  error_messages <- purrr::map(
    c(message, details),
    glue,
    .open = glue_open,
    .close = glue_close
  )

  error_messages <- subset_lines_to_fit_in_limit(error_messages, 8000L)

  message <- glue_collapse(error_messages, sep = "\n")

  withr::with_options(
    # Valid values are something between 1000 and 8170
    # This will be set by {rlang} in the future release,
    # https://github.com/r-lib/rlang/pull/1214
    list(warning.length = 8000),
    rlang::abort(message, class = "rextendr_error")
  )
}

cli_format_text <- function(message, env = parent.frame()) {
  cli::cli_format_method(cli::cli_text(message, .envir = env))
}

#' Subset lines to fit within provided character limit.
#'
#' Verifies that `lines` fit within given limit of `max_length`.
#' If not, lines are subset and an additional `truncation_notification`
#' is appended to `lines`. The function ensures that the output message
#' constructed by combining `lines` with `\n` separator
#' fits within `max_length` limit.
#'
#' @param lines \[ ansi_character(n) \] Error messages.
#' @param max_length Maximum total length of the collapsed message
#' (measured using `nchar()`).
#' @param truncation_notification Message pattern appended if any `lines`
#' were removed. Understands `cli` interpolation and
#' `n_removed` integer variable, which is set to the number of removed lines.
#' @return \[ ansi_character(n) \] A subset of `lines` with
#' `truncation_notification` appended (if needed).
#' @noRd
subset_lines_to_fit_in_limit <- function(lines,
                                         max_length = 1000,
                                         truncation_notification = "{.val {n_removed}} compiler messages not shown.") {
  n_removed <- 100L
  truncation_notification_size <- nchar(bullet_i(truncation_notification))

  max_length <- max_length - truncation_notification_size

  selected_lines <- lines[cumsum(nchar(lines) + 1L) <= max_length]
  n_removed <- length(lines) - length(selected_lines)

  if (n_removed > 0) {
    c(selected_lines, bullet_i(truncation_notification))
  } else {
    lines
  }
}
