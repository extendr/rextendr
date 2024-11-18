#' Retrieve metadata for packages and workspaces
#'
#' @param path character scalar, the R package directory
#' @param echo logical scalar, should cargo command and outputs be printed to
#' console (default is TRUE)
#'
#' @details
#' For more details, see
#' \href{https://doc.rust-lang.org/cargo/commands/cargo-metadata.html}{Cargo docs}
#' for `cargo-metadata`. See especially "JSON Format" to get a sense of what you
#' can expect to find in the returned list.
#'
#' @return `list`, including the following elements:
#' - "packages"
#' - "workspace_members"
#' - "workspace_default_members"
#' - "resolve"
#' - "target_directory"
#' - "version"
#' - "workspace_root"
#' - "metadata"
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_cargo_metadata()
#' }
#'
read_cargo_metadata <- function(path = ".", echo = TRUE) {
  check_string(path, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

  rust_folder <- rprojroot::find_package_root_file(
    "src", "rust",
    path = path
  )

  args <- c("metadata", "--format-version=1", "--no-deps")

  out <- processx::run(
    command = "cargo",
    args = args,
    error_on_status = TRUE,
    wd = rust_folder,
    echo_cmd = echo,
    echo = echo,
    env = get_cargo_envvars()
  )

  jsonlite::parse_json(
    out[["stdout"]],
    simplifyDataFrame = TRUE
  )
}
