#' Try to save open files if \pkg{rextendr} is called from an IDE.
#'
#' Uses rstudio API (if available) to save modfied files.
#' Improves package development experience within RStudio.
#' @param quiet Logical scalar indicating whether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @noRd
try_save_all <- function(quiet = FALSE) {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::hasFun("documentSaveAll")) {
    rstudioapi::documentSaveAll()
    if (!isTRUE(quiet)) {
      ui_v("Saving changes in the open files.")
    }
  }
}
