extendr_function_config <- rlang::env(
  known_options = tibble::tribble(
    ~Name, ~Ptype,
    "use_try_from", logical(),
    "r_name", character(),
    "mod_name", character(),
  )
)

convert_extendr_function_options <- function(options) {
  if (rlang::is_null(options) || rlang::is_empty(options)) {
    return ("")
  }

  if (!rlang::is_list(options) || !rlang::is_named(options)) {
    cli::cli_abort("Extendr function options should be either a named {.code list()} or {.code NULL}.")
  }

  options_table <- tibble::tibble(Name = rlang::names2(options), Value = unname(options)) %>%
    dplyr::left_join(extendr_function_config$known_options, by = "Name") %>%
    dplyr::mutate(
      Value = purrr::pmap(
        list(.data$Value, .data$Ptype, .data$Name),
        ~ if(rlang::is_null(..2)) ..1 else vctrs::vec_cast(..1, ..2, x_arg = ..3)
      ),
    )

  unknown_options <- options_table %>%
    dplyr::filter(purrr::map_lgl(.data$Ptype, rlang::is_null)) %>%
    dplyr::pull(.data$Name)

  if (length(unknown_options) > 0) {
    cli::cli_warn(c(
      "Found unknown {.code extendr} function option{?s}: {.val {unknown_options}}.",
      ui_messages$inf_dev_extendr_used()
    ))
  }

  invalid_options <- options_table %>%
    dplyr::filter(
      purrr::map_lgl(
        .data$Value,
        ~ rlang::is_null(.x) || !vctrs::vec_is(.x, size = 1L)
      )
    ) %>%
    dplyr::pull(.data$Name)

  if (length(invalid_options) > 0) {
    cli::cli_abort(c(
      "Found invalid {.code extendr} function option{?s}: {.val {invalid_options}}.",
      "x" = "Option values should not be {.code NULL}.",
      "i" = "Options are expected to have scalar values."
    ))
  }

  options_table %>%
    dplyr::mutate(RustValue = purrr::map_chr(.data$Value, convert_option_to_rust)) %>%
    glue::glue_data("{Name} = {RustValue}") %>%
    glue::glue_collapse(sep = ", ") %>%
    as.character()
}

convert_option_to_rust <- function(option_value) {
  if (vctrs::vec_is(option_value, character())) {
    paste0("\"", option_value, "\"")
  } else if (vctrs::vec_is(option_value, logical())) {
    ifelse(option_value, "true", "false")
  } else {
    as.character(option_value)
  }
}
