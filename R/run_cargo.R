#' Run Cargo subcommands
#'
#' This internal function allows us to maintain consistent specifications for
#' `processx::run()` everywhere it uses.
#'
#' @param args character vector, the Cargo subcommand and flags to be executed.
#' @param wd character scalar, location of the Rust crate, (default is
#' `find_extendr_crate()`).
#' @param error_on_status Default `TRUE`. A logical scalar, whether to error on a non-zero exist status.
#' @param echo_cmd Default `TRUE`. A logical scalar, whether to print Cargo subcommand and flags
#' to the console.
#' @param echo Default `TRUE`. Alogical scalar, whether to print standard output and error to the
#' console.
#' @param env character vector, environment variables of the child process.
#' @param parse_json Default `FALSE`. A logical scalar, whether to parse JSON-structured standard
#' output using [`jsonlite::parse_json()`] with `simplifyDataFrame = TRUE`.
#' @param error_call Default [`rlang::caller_call()`]. The defused call with which
#' the function running in the frame was invoked.
#' @param ... additional arguments passed to [`processx::run()`].
#' @returns
#' A list with elements `status`, `stdout`, `stderr`, and `timeout`.
#' See [`processx::run()`]. If `parse_json = TRUE`, result of parsing
#' JSON-structured standard output.
#'
#' @keywords internal
#' @noRd
run_cargo <- function(
  args,
  wd = find_extendr_crate(),
  error_on_status = TRUE,
  echo = TRUE,
  env = get_cargo_envvars(),
  parse_json = FALSE,
  error_call = rlang::caller_call(),
  ...
) {
  check_character(args, call = error_call, class = "rextendr_error")
  check_string(wd, call = error_call, class = "rextendr_error")
  check_bool(error_on_status, call = error_call, class = "rextendr_error")
  check_bool(echo, call = error_call, class = "rextendr_error")
  check_character(env, call = error_call, class = "rextendr_error")
  check_bool(parse_json, call = error_call, class = "rextendr_error")

  out <- processx::run(
    command = "cargo",
    args = args,
    error_on_status = error_on_status,
    wd = wd,
    echo_cmd = echo,
    echo = echo,
    env = env,
    ...
  )

  stdout <- out[["stdout"]]

  if (length(stdout) != 1L || !is.character(stdout) || is.null(stdout)) {
    cli::cli_abort(
      "{.code cargo paste(args, collapse = ' ')} failed to return stdout.",
      call = error_call,
      class = "rextendr_error"
    )
  }

  if (parse_json) {
    res <- rlang::try_fetch(
      jsonlite::parse_json(stdout, simplifyDataFrame = TRUE),
      error = function(cnd) {
        cli::cli_abort(
          c("Failed to {.code stdout} as json:", " " = "{stdout}"),
          parent = cnd,
          class = "rextendr_error"
        )
      }
    )
    return(res)
  }

  out
}
