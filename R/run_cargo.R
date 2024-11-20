#' Run Cargo subcommands
#'
#' This internal function allows us to maintain consistent specifications for
#' `processx::run()` everywhere it uses.
#'
#' @param args character vector, the Cargo subcommand and flags to be executed.
#' @param wd character scalar, location of the Rust crate, (default is
#' `find_extendr_crate()`).
#' @param error_on_status, logical scalar, whether to error if `status != 0`,
#' (default is `TRUE`).
#' @param echo_cmd logical scalar, whether to print Cargo subcommand and flags
#' to the console (default is `TRUE`).
#' @param echo logical scalar, whether to print standard output and error to the
#' console (default is `TRUE`).
#' @param env character vector, environment variables of the child process.
#' @param parse_json logical scalar, whether to parse JSON-structured standard
#' output (default is `FALSE`).
#' @param error_call call scalar, from rlang docs: "the defused call with which
#' the function running in the frame was invoked." (default is
#' `rlang::caller_call()`)
#'
#' @return if `parse_json = TRUE`, result of parsing JSON-structured standard
#' output; otherwise, standard output is returned as a character scalar.
#'
#' @keywords internal
#' @noRd
run_cargo <- function(
    args,
    wd = find_extendr_crate(),
    error_on_status = TRUE,
    echo_cmd = TRUE,
    echo = TRUE,
    env = get_cargo_envvars(),
    parse_json = FALSE,
    error_call = rlang::caller_call()) {
  check_character(args, call = error_call, class = "rextendr_error")
  check_string(wd, call = error_call, class = "rextendr_error")
  check_bool(error_on_status, call = error_call, class = "rextendr_error")
  check_bool(echo_cmd, call = error_call, class = "rextendr_error")
  check_bool(echo, call = error_call, class = "rextendr_error")
  check_character(env, call = error_call, class = "rextendr_error")
  check_bool(parse_json, call = error_call, class = "rextendr_error")

  out <- processx::run(
    command = "cargo",
    args = args,
    error_on_status = error_on_status,
    wd = wd,
    echo_cmd = echo_cmd,
    echo = echo,
    env = env
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
    stdout <- jsonlite::parse_json(stdout, simplifyDataFrame = TRUE)
  }

  stdout
}
