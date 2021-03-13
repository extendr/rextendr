try_save_all <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::hasFun("documentSaveAll")) {
    rstudioapi::documentSaveAll()
    cli::cli_alert_success("Saving changes in the open files.")
  }
}
