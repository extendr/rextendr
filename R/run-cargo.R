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
    if (identical(.Platform$OS.type, "windows")) {
      # On Windows, PATH to Rust toolchain should be set by the installer.
      # If R >= 4.2, we need to override the linker setting.
      if (identical(R.version$crt, "ucrt")) {
        # `rustc` adds `-lgcc_eh` flags to the compiler, but Rtools' GCC doesn't have
        # `libgcc_eh` due to the compilation settings. So, in order to please the
        # compiler, we need to add empty `libgcc_eh` to the library search paths.
        #
        # For more details, please refer to
        # https://github.com/r-windows/rtools-packages/blob/2407b23f1e0925bbb20a4162c963600105236318/mingw-w64-gcc/PKGBUILD#L313-L316 # nolint: line_length_linter
        libgcc_path <- file.path(
          system.file(package = "rextendr"),
          "libgcc_mock"
        )
        dir.create(libgcc_path, showWarnings = FALSE)
        file.create(file.path(libgcc_path, "libgcc_eh.a"))

        env <- c(
          "current",
          CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = "x86_64-w64-mingw32.static.posix-gcc.exe",
          LIBRARY_PATH = paste0(libgcc_path, ";", Sys.getenv("LIBRARY_PATH"))
        )
      }
    } else {
      # In some environments, ~/.cargo/bin might not be included in PATH, so we need
      # to set it here to ensure cargo can be invoked. It's added to the tail as a
      # fallback, which is used only when cargo is not found in the user's PATH.
      path_envvar <- Sys.getenv("PATH", unset = "") # nolint: object_usage_linter
      cargo_path <- path.expand("~/.cargo/bin") # nolint: object_usage_linter
      # "current" means appending or overwriting the envvars in addition to the current ones.
      env <- c("current", PATH = glue("{path_envvar}:{cargo_path}"))
    }
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
