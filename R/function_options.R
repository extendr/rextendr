extendr_function_config <- rlang::env(
  known_options = tibble::tribble(
    ~Name, ~Ptype,
    "use_try_from", logical(),
    "r_name", character(),
    "mod_name", character(),
  )
)

convert_function_options <- function(options, quiet) {
  if (rlang::is_null(options) || rlang::is_empty(options)) {
    return(tibble::tibble(Name = character(), RustValue = character()))
  }

  if (!rlang::is_list(options) || !rlang::is_named(options)) {
    cli::cli_abort("Extendr function options should be either a named {.code list()} or {.code NULL}.")
  }

  options_table <- tibble::tibble(Name = rlang::names2(options), Value = unname(options)) %>%
    dplyr::left_join(extendr_function_config$known_options, by = "Name") %>%
    dplyr::mutate(
      Value = purrr::pmap(
        list(.data$Value, .data$Ptype, .data$Name),
        ~ if (rlang::is_null(..2)) ..1 else vctrs::vec_cast(..1, ..2, x_arg = ..3)
      ),
    )

  unknown_options <- options_table %>%
    dplyr::filter(purrr::map_lgl(.data$Ptype, rlang::is_null)) %>%
    dplyr::pull(.data$Name)

  if (!isTRUE(quiet) && length(unknown_options) > 0) {
    cli::cli_warn(c(
      "Found unknown {.code extendr} function option{?s}: {.val {unknown_options}}.",
      inf_dev_extendr_used()
    ))
  }

  invalid_options <- options_table %>%
    dplyr::filter(
      purrr::map_lgl(
        .data$Value,
        ~ rlang::is_null(.x) || !vctrs::vec_is(.x, size = 1L)
      ) |
      !is_valid_rust_name(.data$Name)
    ) %>%
    dplyr::pull(.data$Name)

  if (length(invalid_options) > 0) {
    cli::cli_abort(c(
      "Found invalid {.code extendr} function option{?s}: {.val {invalid_options}}.",
      "x" = "Option value should not be {.code NULL};",
      "i" = "Option is expected to have scalar value;",
      "i" = "Option name should be a valid rust identifier name."
    ))
  }

  options_table %>%
    dplyr::mutate(RustValue = purrr::map_chr(.data$Value, convert_option_to_rust)) %>%
    dplyr::select("Name", "RustValue")
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
