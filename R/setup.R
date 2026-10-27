rextendr_setup <- function(path = ".", cur_version = NULL) {
  desc_path <- rprojroot::find_package_root_file("DESCRIPTION", path = path)
  if (!file.exists(desc_path)) {
    cli::cli_abort(
      "{.arg path} ({.path {path}}) does not contain a DESCRIPTION",
      class = "rextendr_error"
    )
  }

  prev <- stringi::stri_trim_both(
    desc::desc_get("Config/rextendr/version", desc_path)[[1]]
  )

  if (is.na(prev)) {
    cli::cli_alert_info("First time using rextendr. Upgrading automatically...")
  }

  # update rextendr version
  cur <- cur_version %||% as.character(utils::packageVersion("rextendr"))

  if (
    !is.na(cur) && !is.na(prev) && package_version(cur) < package_version(prev)
  ) {
    cli::cli_alert_warning(c(
      "Installed rextendr is older than the version used with this package",
      "You have {.str {cur}} but you need {.str {prev}}"
    ))
  } else if (!identical(cur, prev)) {
    update_description("Config/rextendr/version", cur, desc_path = desc_path)
  }

  # update system requirements
  cur_sys_reqs <- "Cargo (Rust's package manager), rustc >= 1.65.0, xz"
  prev_sys_reqs <- stringi::stri_trim_both(
    desc::desc_get("SystemRequirements", file = desc_path)[[1]]
  )

  if (is.na(prev_sys_reqs)) {
    update_description(
      "SystemRequirements",
      cur_sys_reqs,
      desc_path = desc_path
    )
  } else if (!identical(cur_sys_reqs, prev_sys_reqs)) {
    cli::cli_ul(
      c(
        "The SystemRequirements field in the {.file DESCRIPTION} file is already set.",
        "Please update it manually if needed."
      )
    )
  }

  invisible(TRUE)
}

update_description <- function(field, value, desc_path) {
  cli::cli_alert_info(
    "Setting {.var {field}} to {.str {value}} in the {.file DESCRIPTION} file."
  )
  desc::desc_set(field, value, file = desc_path)
}
