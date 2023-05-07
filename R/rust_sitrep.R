rust_sitrep <- function() {
  # Windows-specific code

  exe_versions <- tibble::tibble(cmd = c("cargo", "rustup", "cargo2")) %>%
    dplyr::mutate(version = purrr::map_chr(cmd, get_version)) %>%
    dplyr::mutate(message = purrr::map2(cmd, version, get_cli_notification, max_len = max(nchar(cmd))))

  msgs <- exe_versions %>% dplyr::pull(message)

  names <- purrr::map_chr(msgs, rlang::names2)

  msgs <- purrr::flatten_chr(msgs) %>% rlang::set_names(names)

  cli::cli_inform(msgs)
}

try_exec_cmd <- function(cmd, args = character()) {
  result <- tryCatch(
    processx::run(cmd, args, error_on_status = FALSE),
    error = \(e) list(status = 0)
  )
  if(result[["status"]] != 0) {
    NULL
  } else {
    result$stdout
  }
}

get_version <- function(cmd) {
  output <- try_exec_cmd(cmd, "--version")
    if(is.null(output)) {
      NA_character_
    } else {
        stringi::stri_trim_both(stringi::stri_sub(output, nchar(cmd) + 1L))
    }
}

get_cli_notification <- function(cmd, version, max_len = 0L) {
  pad <- stringr::str_dup(" ", max_len - nchar(cmd))
  if(is.na(version))
  {
    c("x" = glue::glue("{{.val {cmd}}}{pad}: {{.strong not found}}"))
  } else {
    c("v" = glue::glue("{{.val {cmd}}}{pad}: {{.emph {version}}}"))
  }
}

rust_sitrep()