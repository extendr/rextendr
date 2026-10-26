#' Run Cargo subcommands
#'
#' Call the `cargo` command line tool from R. This function delegates to
#' `processx::run("cargo")` enabling calls such as `cargo("test")` or
#' `cargo("check")`.
#'
#' When `wd = NULL` (the default), the `cargo` command is called from the
#' package's Rust crate's source. Otherwise, when `wd = "/my/path"`, `cargo`
#' will be run there.
#'
#' @param args character vector, the Cargo subcommand and flags to be executed.
#' @param wd character scalar, location of the Rust crate, (default is
#'   `find_extendr_crate()`).
#' @param error_on_status Default `TRUE`. A logical scalar, whether to error on
#'   a non-zero exist status.
#' @param echo Default `TRUE`. Alogical scalar, whether to print standard output
#'   and error to the console.
#' @param env character vector, environment variables of the child process.
#' @param parse_json Default `FALSE`. A logical scalar, whether to parse
#'   JSON-structured standard output using [`jsonlite::parse_json()`] with
#'   `simplifyDataFrame = TRUE`.
#' @param error_call Default [`rlang::caller_call()`]. The defused call with
#'   which the function running in the frame was invoked.
#' @param ... additional arguments passed to [`processx::run()`].
#' @returns
#' Invisibly, a list with elements `status`, `stdout`, `stderr`, and `timeout`.
#' See [`processx::run()`]. If `parse_json = TRUE`, result of parsing
#' JSON-structured standard output.
#'
#' @export
#' @examples
#' \dontrun{
#' # run cargo test from package root
#' cargo("test")
#' }
cargo <- function(
  args,
  echo = TRUE,
  error_on_status = TRUE,
  wd = NULL,
  env = NULL,
  parse_json = FALSE,
  error_call = rlang::caller_call(),
  ...
) {
  if (rlang::is_null(env)) {
    env <- get_cargo_envvars()
  }

  if (rlang::is_null(wd)) {
    wd <- find_extendr_crate(getwd(), error_call = error_call)
  }

  check_character(args, call = error_call, class = "rextendr_error")
  check_string(
    wd,
    allow_null = TRUE,
    call = error_call,
    class = "rextendr_error"
  )
  check_bool(error_on_status, call = error_call, class = "rextendr_error")
  check_bool(echo, call = error_call, class = "rextendr_error")
  check_character(env, call = error_call, class = "rextendr_error")
  check_bool(parse_json, call = error_call, class = "rextendr_error")

  if (isTRUE(cli::num_ansi_colors() > 1L)) {
    args <- c(args, "--color=always")
  } else {
    args <- c(args, "--color=never")
  }

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
          c("Failed to parse {.code stdout} as json:", " " = "{stdout}"),
          parent = cnd,
          class = "rextendr_error"
        )
      }
    )
    return(res)
  }

  invisible(out)
}
