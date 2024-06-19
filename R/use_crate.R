#' Add dependencies to a Cargo.toml manifest file
#'
#' Analogous to `usethis::use_package()` but for crate dependencies.
#'
#' @param crate a character scalar, the name of the crate to add
#' @param features a character vector, a list of features to include from the
#' crate
#' @param git a character scalar, the URL of the Github repository
#' @param version a character scalar, the version of the crate to add
#' @param path a character scalar, the package directory
#' @param ... additional options to include
#'
#' @details
#' For a list of all available options, see \href{https://doc.rust-lang.org/cargo/commands/cargo-add.html}{Cargo docs}
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
#' use_crate("serde", git = "serde-rs/serde")
#'
#' # add to [dependencies] with specific version
#' use_crate("serde", version = "1.0.1")
#' }
use_crate <- function(
    crate,
    features = NULL,
    git = NULL,
    version = NULL,
    path = ".",
    ...
){

  # check crate
  if (!rlang::is_character(crate) && length(crate) != 1){

    cli::cli_abort(
      "{.var crate} should be a length one character vector.",
      "i" = "You supplied an object of class {class(crate)} with length {length(crate)}.",
      class = "rextendr_error"
    )

  }

  # check features
  if (!is.null(features) && !rlang::is_character(features)){

    cli::cli_abort(
      "{.var features} should be a character vector.",
      "i" = "You supplied an object of class {class(features)}.",
      class = "rextendr_error"
    )

  }

  # check git
  if (!is.null(git)){

    if (!rlang::is_character(git) && length(git) != 1){

      cli::cli_abort(
        "{.var git} should be a length one character vector.",
        "i" = "You supplied an object of class {class(git)} with length {length(git)}.",
        class = "rextendr_error"
      )

    }

    git <- paste0("https://github.com/", git)

  }

  # check version
  if (!is.null(version)){

    if (!rlang::is_character(version) && length(version) != 1){

      cli::cli_abort(
        "{.var version} should be a length one character vector.",
        "i" = "You supplied an object of class {class(version)} with length {length(version)}.",
        class = "rextendr_error"
      )

    }

    crate <- paste0(crate, "@", version)

  }

  # combine main options
  cargo_add_opts <- list(
    "--features" = features,
    "--git" = git
  )

  # add additional options from ...
  lst <- rlang::dots_list(...)

  if (length(lst) > 0){ names(lst) <- paste0("--", names(lst)) }

  cargo_add_opts <- c(cargo_add_opts, lst)

  # clear empty options
  cargo_add_opts <- Filter(length, cargo_add_opts)

  # combine option names and values into single strings
  adtl_args <- unname(purrr::imap_chr(
    cargo_add_opts,
    \(x, i){ paste(i, paste0(x, collapse = " ")) }
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
