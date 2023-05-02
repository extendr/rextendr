#' Inform the user that a development version of `extendr` is being used.
#'
#' This function returns a string that should be used inside of a `cli` function.
#' See `validate_extendr_features()` for an example.
#'
#' @keywords internal
inf_dev_extendr_used <- function() "Are you using a development version of {.code extendr}?"


#' Silence `{cli}` output
#'
#' Use for functions that use cli output that should optionally be suppressed.
#'
#' @examples
#'
#' if (interactive()) {
#' hello_rust <- function(..., quiet = FALSE) {
#'   local_quiet_cli(quiet)
#'   cli::cli_alert_info("This should be silenced when {.code quiet = TRUE}")
#' }
#'
#' hello_rust()
#' hello_rust(quiet = TRUE)
#' }
#' @keywords internal
local_quiet_cli <- function(quiet, env = rlang::caller_env()) {
  if (quiet) {
    withr::local_options(
      list("cli.default_handler" = function(...) {
      }),
      .local_envir = env
    )
  }
}

#' Helper function for check cargo commands.
#' @param args Character vector, arguments to the `cargo` command. Pass to [processx::run()]'s args param.
#' @return a logical indicating if the command was available.
#' @noRd
cargo_command_available <- function(args = "--help") {
  if (processx::run("cargo", args, error_on_status = FALSE)$status == 0L) {
    is_available <- TRUE
  } else {
    is_available <- FALSE
  }

  is_available
}