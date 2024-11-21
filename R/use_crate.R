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
#' @param echo logical scalar, should cargo command and outputs be printed to
#' console (default is TRUE)
#'
#' @details
#' For more details regarding these and other options, see the
#' \href{https://doc.rust-lang.org/cargo/commands/cargo-add.html}{Cargo docs}
#' for `cargo-add`.
#'
#' @return `NULL` (invisibly)
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
    path = ".",
    echo = TRUE) {
  check_string(crate, class = "rextendr_error")
  check_character(features, allow_null = TRUE, class = "rextendr_error")
  check_string(git, allow_null = TRUE, class = "rextendr_error")
  check_string(version, allow_null = TRUE, class = "rextendr_error")
  check_bool(optional, class = "rextendr_error")
  check_string(path, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

  if (!is.null(version) && !is.null(git)) {
    cli::cli_abort(
      "Cannot specify a git URL ('{git}') with a version ('{version}').",
      class = "rextendr_error"
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

  args <- c(
    "add",
    crate,
    features,
    git,
    optional,
    if (tty_has_colors()) {
      "--color=always"
    } else {
      "--color=never"
    }
  )

  run_cargo(
    args,
    wd = find_extendr_crate(path = path),
    echo = echo
  )

  invisible()
}
