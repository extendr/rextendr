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
  update_sys_reqs(path)

  invisible(TRUE)
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
    update_description("Config/rextendr/version", cur)
  }
}

update_sys_reqs <- function(path) {
  cur <- "Cargo (rustc package manager)"
  prev <- stringi::stri_trim_both(desc::desc_get("SystemRequirements", path)[[1]])

  if (is.na(prev)) {
    update_description("SystemRequirements", cur)
  } else if (!identical(cur, prev)) {
    cli::cli_ul(
      c(
        "The SystemRequirements field in the {.file DESCRIPTION} file is already set.",
        "Please update it manually if needed."
      )
    )
  }
}

update_description <- function(field, value) {
  cli::cli_alert_info("Setting {.var {field}} to {.str {value}} in the {.file DESCRIPTION} file.")
  desc::desc_set(field, value)
}

rextendr_version <- function(path = ".") {
  stringi::stri_trim_both(desc::desc_get("Config/rextendr/version", path)[[1]])
}
