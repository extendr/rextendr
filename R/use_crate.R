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

  if (!is.null(version)) {
    crate <- paste0(crate, "@", version)
  }

  # combine main options
  cargo_add_opts <- list(
    "--features" = paste0(features, collapse = " "),
    "--git" = git,
    "--optional" = tolower(as.character(optional))
  )

  # clear empty options
  cargo_add_opts <- purrr::discard(cargo_add_opts, rlang::is_empty)

  # combine option names and values into single strings
  adtl_args <- unname(purrr::imap_chr(
    cargo_add_opts,
    function(x, i) {
      paste(i, paste0(x, collapse = " "))
    }
  ))

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
    c("add", crate, adtl_args),
    echo_cmd = TRUE,
    wd = rust_folder
  )

  invisible()
}
