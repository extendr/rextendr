#' Retrieve metadata for packages and workspaces
#'
#' @param path character scalar, the R package directory
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
read_cargo_metadata <- function(path = ".") {
  check_string(path, class = "rextendr_error")

  root <- rprojroot::find_package_root_file(path = path)

  rust_folder <- normalizePath(
    file.path(root, "src", "rust"),
    winslash = "/",
    mustWork = FALSE
  )

  out <- processx::run(
    "cargo",
    args = c("metadata", "--format-version=1", "--no-deps"),
    wd = rust_folder
  )

  jsonlite::fromJSON(out[["stdout"]])
}
