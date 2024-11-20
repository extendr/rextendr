#' Get path to Rust crate in R package directory
#'
#' @param path character scalar, the R package directory
#' @param error_call call scalar, from rlang docs: "the defused call with which
#' the function running in the frame was invoked"
#'
#' @return character scalar, path to Rust crate
#'
#' @keywords internal
#' @noRd
find_extendr_crate <- function(
    path = ".",
    error_call = rlang::caller_call()) {
  check_character(path, call = error_call, class = "rextendr_error")

  rust_folder <- rprojroot::find_package_root_file(
    "src", "rust",
    path = path
  )

  if (!dir.exists(rust_folder)) {
    cli::cli_abort(
      "Could not find Rust crate at {.path rust_folder}.",
      call = error_call,
      class = "rextendr_error"
    )
  }

  rust_folder
}

#' Get path to Cargo manifest in R package directory
#'
#' @param path character scalar, the R package directory
#' @param error_call call scalar, from rlang docs: "the defused call with which
#' the function running in the frame was invoked"
#'
#' @return character scalar, path to Cargo manifest
#'
#' @keywords internal
#' @noRd
find_extendr_manifest <- function(
    path = ".",
    error_call = rlang::caller_call()) {
  check_character(path, call = error_call, class = "rextendr_error")

  manifest_path <- rprojroot::find_package_root_file(
    "src", "rust", "Cargo.toml",
    path = path
  )

  if (!file.exists(manifest_path)) {
    cli::cli_abort(
      "Could not find Cargo manifest at {.path manifest_path}.",
      call = error_call,
      class = "rextendr_error"
    )
  }

  manifest_path
}
