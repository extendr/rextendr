ui_messages <- rlang::env(
  inf_dev_extendr_used = function() c("i" = "Are you using a development version of {.code extendr}?")
)

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
#' @param details An optional character vector of error details.
#' @param env Caller environment used for string interpolation.
#' @param call Environment of the 'origin' of the error.
#' It is used to determine what function name to show in the error message.
#' Passed to [rlang::abort()].
#' @param glue_open,glue_close Opening and closing delimiters,
#' passed to [glue::glue()] as `.open` and `.close` parameters.
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
                     env = caller_env(),
                     call = env,
                     glue_open = "{", glue_close = "}") {
  message <- cli_format_text(message, env = env)

  error_messages <- purrr::map(
    c(message, details),
    glue,
    .open = glue_open,
    .close = glue_close
  )

  message_limit_bytes <- 8000L
  error_messages <- subset_lines_to_fit_in_limit(
    error_messages,
    message_limit_bytes
  )

  message <- glue_collapse(error_messages, sep = "\n")

  rlang::abort(message, class = "rextendr_error", call = call)
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
#' @param max_length_in_bytes Maximum total length of the collapsed message
#' (measured using `nchar(type = "byte")`).
#' @param truncation_notification Message pattern appended if any `lines`
#' were removed. Understands `cli` interpolation and
#' `n_removed` integer variable, which is set to the number of removed lines.
#' @return \[ ansi_character(n) \] A subset of `lines` with
#' `truncation_notification` appended (if needed).
#' @noRd
subset_lines_to_fit_in_limit <- function(lines,
                                         max_length_in_bytes = 1000,
                                         truncation_notification = "{.val {n_removed}} compiler messages not shown.") {

  # This is a shortcut. If `lines` collapsed using `\n` separator
  # have length less than or equal to `max_length_in_bytes`, return `lines`.
  # With `max_length_in_bytes` set close to 8000, this should be the hot path.
  if (sum(nchar(lines, type = "byte") + 1L) <= max_length_in_bytes) {
    return(lines)
  }

  # We want to display only a subset of `lines` plus an additional
  # `truncation_notification` message at the end.
  # All of these messages combined should still be shorter
  # than `max_length_in_bytes`.

  # `n_removed` is the number of removed items from `lines`,
  # which is unknown at this point. We use a 3-digit integer to
  # interpolate `truncation_notification` and obtain its length.
  # This length is un upper estimate for `n_removed < 1000`, which should cover
  # all real cases (`n_removed <= length(lines)`,
  # which is the number of compiler messages).
  n_removed <- 100L # nolint: object_usage_linter

  # Here we count the size in bytes of the interpolated message.
  truncation_notification_size <- nchar(
    bullet_i(truncation_notification),
    type = "byte"
  )

  # We decrease the max length by the size of the `truncation_notification`
  # and an extra `1L` for `\n`.
  max_length <- max_length_in_bytes - truncation_notification_size - 1L

  # We filter out `lines` such that the collapsed with `\n` separator string
  # is shorter than new `max_length` in bytes.
  selected_lines <- lines[
    cumsum(nchar(lines, type = "byte") + 1L) <= max_length
  ]

  # Here we finally get the number of lines actually removed.
  n_removed <- length(lines) - length(selected_lines)

  # We return a subset of `lines` plus an appended
  # interpolated truncation notification.
  # These lines when combined using `\n` produce a string that is shorter than
  # `max_length_in_bytes`.
  c(selected_lines, bullet_i(truncation_notification))
}
