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
#'   hello_rust <- function(..., quiet = FALSE) {
#'     local_quiet_cli(quiet)
#'     cli::cli_alert_info("This should be silenced when {.code quiet = TRUE}")
#'   }
#'
#'   hello_rust()
#'   hello_rust(quiet = TRUE)
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

#' Helper function for checking cargo sub-commands.
#' @param args Character vector, arguments to the `cargo` command. Passed to [processx::run()]'s args param.
#' @return Logical scalar indicating if the command was available.
#' @noRd
cargo_command_available <- function(args = "--help") {
  !anyNA(try_exec_cmd("cargo", args))
}

#' Helper function for executing commands.
#' @param cmd Character scalar, command to execute.
#' @param args Character vector, arguments passed to the command.
#' @return Character vector containing the stdout of the command or `NA_character_` if the command failed.
#' @noRd
try_exec_cmd <- function(cmd, args = character()) {
  result <- tryCatch(
    processx::run(cmd, args, error_on_status = FALSE),
    error = function(...) list(status = -1)
  )
  if (result[["status"]] != 0) {
    NA_character_
  } else {
    stringi::stri_split_lines1(result$stdout)
  }
}

#' Replace missing values in vector
#'
#' @param data vector, data with missing values to replace
#' @param replace scalar, value to substitute for missing values in data
#' @param ... currently ignored
#'
#' @keywords internal
#' @noRd
#'
replace_na <- function(data, replace = NA, ...) {
  if (vctrs::vec_any_missing(data)) {
    missing <- vctrs::vec_detect_missing(data)
    data <- vctrs::vec_assign(data, missing, replace,
      x_arg = "data",
      value_arg = "replace"
    )
  }
  data
}
