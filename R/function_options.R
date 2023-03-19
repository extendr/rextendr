extendr_function_config <- rlang::env(
  known_options = tibble::tribble(
    ~Name, ~Ptype,
    "use_try_from", logical(),
    "r_name", character(),
    "mod_name", character(),
  )
)

#' Converts a list of user-specified options into a data frame containing `Name` and `RustValue`
#'
#' @param options A list of user-specified options.
#' @param suppress_warnings Logical, suppresses warnigns if `TRUE`.
#' @noRd
convert_function_options <- function(options, suppress_warnings) {
  if (rlang::is_null(options) || rlang::is_empty(options)) {
    return(tibble::tibble(Name = character(), RustValue = character()))
  }

  if (!rlang::is_list(options) || !rlang::is_named(options)) {
    cli::cli_abort("Extendr function options should be either a named {.code list()} or {.code NULL}.")
  }

  options_table <- tibble::tibble(Name = rlang::names2(options), Value = unname(options)) %>%
    dplyr::left_join(extendr_function_config$known_options, by = "Name")

  options_table <- options_table %>%
    dplyr::rows_update(
      options_table %>%
        dplyr::filter(!purrr::map_lgl(.data$Ptype, rlang::is_null)) %>%
        dplyr::mutate(
          Value = purrr::pmap(
            list(.data$Value, .data$Ptype, .data$Name),
            ~vctrs::vec_cast(..1, ..2, x_arg = ..3)
          )
        ),
      by = "Name"
    )

  unknown_option_names <- options_table %>%
    dplyr::filter(purrr::map_lgl(.data$Ptype, rlang::is_null)) %>%
    dplyr::pull(.data$Name)

  invalid_options <- options_table %>%
    dplyr::mutate(
      IsNameInvalid = !is_valid_rust_name(.data$Name),
      IsValueNull = purrr::map_lgl(.data$Value, rlang::is_null),
      IsNotScalar = !purrr::map_lgl(.data$Value, vctrs::vec_is, size = 1L)
    ) %>%
    dplyr::filter(
      .data$IsNameInvalid | .data$IsValueNull | .data$IsNotScalar
    )

  if (vctrs::vec_size(invalid_options) > 0) {
    cli_abort_invalid_options(invalid_options)
  } else if (!isTRUE(suppress_warnings) && length(unknown_option_names) > 0) {
    cli::cli_warn(c(
      "Found unknown {.code extendr} function option{?s}: {.val {unknown_option_names}}.",
      inf_dev_extendr_used()
    ))
  }

  options_table %>%
    dplyr::transmute(
      .data$Name,
      RustValue = purrr::map_chr(.data$Value, convert_option_to_rust)
    )
}

cli_abort_invalid_options <- function(invalid_options) {
  n_invalid_opts <- vctrs::vec_size(invalid_options)  # nolint: object_usage_linter

  message <- "Found {.val {n_invalid_opts}} invalid {.code extendr} function option{?s}:"
  info <- character(0)

  invalid_names <- invalid_options %>%
    dplyr::filter(.data$IsNameInvalid) %>%
    dplyr::pull(.data$Name)

  if(vctrs::vec_size(invalid_names) > 0) {
    message <- c(message, x = "Unsupported name{?s}: {.val {invalid_names}}.")
    info <- c(info, i = "Option names should be valid rust names.")
  }

  null_values <- invalid_options %>%
    dplyr::filter(.data$IsValueNull) %>%
    dplyr::pull(.data$Name)

  if(vctrs::vec_size(null_values) > 0) {
    message <- c(message, x = "Null value{?s}: {.val {null_values}}.")
    info <- c(info, i = "{.code NULL} values are disallowed.")
  }

  vector_values <- invalid_options %>%
    dplyr::filter(.data$IsNotScalar) %>%
    dplyr::pull(.data$Name)

   if(vctrs::vec_size(vector_values) > 0) {
    message <- c(message, x = "Vector value{?s}: {.val {vector_values}}.")
    info <- c(info, i = "Only scalars are allowed as option values.")
  }

  cli::cli_abort(c(message, info))
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
