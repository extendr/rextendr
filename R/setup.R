rextendr_setup <- function(path = ".", cur_version = NULL) {
  if (!file.exists(file.path(path, "DESCRIPTION"))) {
    cli::cli_abort(
      "{.arg path} ({.path {path}}) does not contain a DESCRIPTION",
      class = "rextendr_error"
    )
  }

  is_first <- is.na(rextendr_version(path))

  if (is_first) {
    cli::cli_alert_info("First time using rextendr. Upgrading automatically...")
  }

  update_rextendr_version(path, cur_version = cur_version)

  invisible(is_first)
}

update_rextendr_version <- function(path, cur_version = NULL) {
  cur <- cur_version %||% as.character(utils::packageVersion("rextendr"))
  prev <- rextendr_version(path)

  if (!is.na(cur) && !is.na(prev) && package_version(cur) < package_version(prev)) {
    cli::cli_alert_warning(c(
      "Installed rextendr is older than the version used with this package",
      "You have {.str {cur}} but you need {.str {prev}}"
    ))
  } else if (!identical(cur, prev)) {
    cli::cli_alert_info("Setting {.var Config/rextendr/version} to {.str {cur}}")
    desc::desc_set(`Config/rextendr/version` = cur, file = path)
  }
}

rextendr_version <- function(path = ".") {
  stringi::stri_trim_both(desc::desc_get("Config/rextendr/version", path)[[1]])
}
