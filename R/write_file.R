#' Writes text to file
#'
#' This function is a wrapper around [`brio::write_lines()`].
#' It also supports verbose output, similar to [`usethis::write_over()`],
#' controlled by the `quiet` parameter.
#' @param text Character vector containing text to write.
#' @param path A string giving the file path to write to.
#' @param search_root_from This parameter only affects messages displayed to the user.
#' It has no effect on where the file is written.
#' It gets passed to [`pretty_rel_path()`] if `quiet = FALSE`.
#' It is unused otherwise.
#' @param quiet Logical scalar indicating whether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @param overwrite Logical scalar indicating whether the file in the `path` should be overwritten.
#' If `FALSE` and the file already exists, the function will do nothing.
#' @return The output of [`brio::write_lines()`] (invisibly).
#' @noRd
write_file <- function(text, path, search_root_from = ".", quiet = FALSE, overwrite = TRUE) {
  if (isFALSE(overwrite) && file.exists(path)) {
    cli::cli_alert("File {.path {pretty_rel_path(path, search_root_from)}} already exists. Skip writing the file.")
    return(invisible(NULL))
  }

  output <- brio::write_lines(text = text, path = path)
  if (!isTRUE(quiet)) {
    rel_path <- pretty_rel_path(path, search_from = search_root_from) # nolint: object_usage_linter
    cli::cli_alert_success("Writing {.path {rel_path}}")
  }
  invisible(output)
}
