#' Writes text to file
#'
#' This function is a wrapper around [`brio::write_lines`].
#' It also supports verboe output, similar to [`usethis::write_over`],
#' controlled by the `quiet` parameter.
#' @param text Character vector containing text to write.
#' @param path A string giving the file path to write to.
#' @param search_root_from A string giving path to a package subfolder,
#' which is used to find package root and produce message for the user.
#' Unused if `quiet == TRUE`.
#' @param quiet Logical scalar indicating whether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @return The output of [`brio::write_lines`] (invisibly).
#' @noRd
write_file <- function(text, path, search_root_from = ".", quiet = FALSE) {
  output <- brio::write_lines(text = text, path = path)
  if (!isTRUE(quiet)) {
    rel_path <- pretty_rel_path(path, search_from = search_root_from)
    cli::cli_alert_success("Writing file {.file {rel_path}}.")
  }
  invisible(output)
}
