#' Get path to Rust crate in R package directory
#'
#' @param path character scalar, the R package directory
#' @param error_call call scalar, from rlang docs: "the defused call with which
#' the function running in the frame was invoked"
#'
#' @return character scalar, path to Rust crate
#'
#' @noRd
find_extendr_crate <- function(
  path = ".",
  error_call = rlang::caller_call()
) {
  check_string(path, call = error_call, class = "rextendr_error")

  rust_folder <- rprojroot::find_package_root_file(
    "src",
    "rust",
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
