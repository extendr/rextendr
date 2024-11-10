#' Add dependencies to a Cargo.toml manifest file
#'
#' Analogous to `usethis::use_package()` but for crate dependencies.
#'
#' @param crate character scalar, the name of the crate to add
#' @param features character vector, a list of features to include from the
#' crate
#' @param git character scalar, the full URL of the remote Git repository
#' @param version character scalar, the version of the crate to add
#' @param optional boolean scalar, whether to mark the dependency as optional
#' (FALSE by default)
#' @param path character scalar, the package directory
#'
#' @details
#' For more details regarding these and other options, see the
#' \href{https://doc.rust-lang.org/cargo/commands/cargo-add.html}{Cargo docs}
#' for `cargo-add`.
#'
#' @return `NULL`, invisibly
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # add to [dependencies]
#' use_crate("serde")
#'
#' # add to [dependencies] and [features]
#' use_crate("serde", features = "derive")
#'
#' # add to [dependencies] using github repository as source
#' use_crate("serde", git = "https://github.com/serde-rs/serde")
#'
#' # add to [dependencies] with specific version
#' use_crate("serde", version = "1.0.1")
#'
#' # add to [dependencies] with optional compilation
#' use_crate("serde", optional = TRUE)
#' }
use_crate <- function(
    crate,
    features = NULL,
    git = NULL,
    version = NULL,
    optional = FALSE,
    path = ".") {
  # check args
  check_string(crate)
  check_character(features, allow_null = TRUE)
  check_string(git, allow_null = TRUE)
  check_string(version, allow_null = TRUE)
  check_bool(optional)
  check_string(path)

  if (!is.null(version) && !is.null(git)) {
    cli::cli_abort(
      "Cannot specify a git URL ('{git}') with a version ('{version}')."
    )
  }

  if (!is.null(version)) {
    crate <- paste0(crate, "@", version)
  }

  if (!is.null(features)) {
    features <- c(
      "--features",
      paste(crate, features, sep = "/", collapse = ",")
    )
  }

  if (!is.null(git)) {
    git <- c("--git", git)
  }

  if (optional) {
    optional <- "--optional"
  } else {
    optional <- NULL
  }

  # get rust directory in project folder
  root <- rprojroot::find_package_root_file(path = path)

  rust_folder <- normalizePath(
    file.path(root, "src", "rust"),
    winslash = "/",
    mustWork = FALSE
  )

  # run the commmand
  processx::run(
    "cargo",
    c("add", crate, features, git, optional),
    echo_cmd = TRUE,
    wd = rust_folder
  )

  invisible()
}
