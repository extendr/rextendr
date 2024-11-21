#' Retrieve metadata for packages and workspaces
#'
#' @param path character scalar, the R package directory
#' @param dependencies Default `FALSE`. A logical scalar, whether to include
#' all recursive dependencies in stdout.
#' @param echo Default `FALSE`. A logical scalar, should cargo command and
#'  outputs be printed to the console.
#'
#' @details
#' For more details, see
#' \href{https://doc.rust-lang.org/cargo/commands/cargo-metadata.html}{Cargo docs}
#' for `cargo-metadata`. See especially "JSON Format" to get a sense of what you
#' can expect to find in the returned list.
#'
#' @returns
#' A `list` including the following elements:
#' - `packages`
#' - `workspace_members`
#' - `workspace_default_members`
#' - `resolve`
#' - `target_directory`
#' - `version`
#' - `workspace_root`
#' - `metadata`
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_cargo_metadata()
#' }
#'
read_cargo_metadata <- function(
    path = ".",
    dependencies = FALSE,
    echo = FALSE) {
  check_string(path, class = "rextendr_error")
  check_bool(dependencies, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

  args <- c(
    "metadata",
    "--format-version=1",
    if (!dependencies) {
      "--no-deps"
    },
    if (tty_has_colors()) {
      "--color=always"
    } else {
      "--color=never"
    }
  )

  run_cargo(
    args,
    wd = find_extendr_crate(path = path),
    echo = echo,
    parse_json = TRUE
  )
}
