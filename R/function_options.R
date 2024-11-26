extendr_function_config <- rlang::env(
  known_options = tibble::tribble(
    ~Name, ~Ptype,
    "r_name", character(),
    "mod_name", character(),
    "use_rng", logical()
  )
)

#' Converts a list of user-specified options into a data frame containing `Name` and `RustValue`
#'
#' @param options A list of user-specified options.
#' @param suppress_warnings Logical, suppresses warnings if `TRUE`.
#' @noRd
convert_function_options <- function(options, suppress_warnings) {
  if (rlang::is_null(options) || rlang::is_empty(options)) {
    return(tibble::tibble(Name = character(), RustValue = character()))
  }

  if (!rlang::is_list(options) || !rlang::is_named(options)) {
    cli::cli_abort(
      "Extendr function options should be either a named {.code list()} or {.code NULL}.",
      class = "rextendr_error"
    )
  }

  options_table <- tibble::tibble(Name = rlang::names2(options), Value = unname(options)) %>%
    dplyr::left_join(extendr_function_config$known_options, by = "Name") %>%
    dplyr::mutate(
      Value = pmap(
        list(.data$Value, .data$Ptype, .data$Name),
        ~ if (rlang::is_null(..2)) ..1 else vctrs::vec_cast(..1, ..2, x_arg = ..3)
      ),
    )

  unknown_option_names <- options_table %>%
    dplyr::filter(map_lgl(.data$Ptype, rlang::is_null)) %>%
    dplyr::pull(.data$Name)

  invalid_options <- options_table %>%
    dplyr::mutate(
      IsNameInvalid = !is_valid_rust_name(.data$Name),
      IsValueNull = map_lgl(.data$Value, rlang::is_null),
      IsNotScalar = !.data$IsValueNull & !map_lgl(.data$Value, vctrs::vec_is, size = 1L)
    ) %>%
    dplyr::filter(
      .data$IsNameInvalid | .data$IsValueNull | .data$IsNotScalar
    )

  if (vctrs::vec_size(invalid_options) > 0) {
    cli_abort_invalid_options(invalid_options)
  } else if (!isTRUE(suppress_warnings) && length(unknown_option_names) > 0) {
    cli::cli_warn(c(
      "Found unknown {.code extendr} function option{?s}: {.val {unknown_option_names}}.",
      "i" = inf_dev_extendr_used()
    ))
  }

  options_table %>%
    dplyr::transmute(
      .data$Name,
      RustValue = map_chr(.data$Value, convert_option_to_rust)
    )
}

#' Throws an error given a data frame of invalid options
#'
#' @param invalid_options A data frame of invalid options.
#' @noRd
cli_abort_invalid_options <- function(invalid_options) {
  n_invalid_opts <- vctrs::vec_size(invalid_options) # nolint: object_usage_linter

  invalid_names <- invalid_options %>% get_option_names(.data$IsNameInvalid)
  null_values <- invalid_options %>% get_option_names(.data$IsValueNull)
  vector_values <- invalid_options %>% get_option_names(.data$IsNotScalar)

  message <- c(
    "Found {.val {n_invalid_opts}} invalid {.code extendr} function option{?s}:",
    x = "Unsupported name{?s}: {.val {invalid_names}}." %>% if_any_opts(invalid_names),
    x = "Null value{?s}: {.val {null_values}}." %>% if_any_opts(null_values),
    x = "Vector value{?s}: {.val {vector_values}}." %>% if_any_opts(vector_values),
    i = "Option names should be valid rust names." %>% if_any_opts(invalid_names),
    i = "{.code NULL} values are disallowed." %>% if_any_opts(null_values),
    i = "Only scalars are allowed as option values." %>% if_any_opts(vector_values)
  )

  cli::cli_abort(message, class = "rextendr_error")
}

#' Returns the names of options that satisfy the given filter
#' @param invalid_options A data frame of invalid options.
#' @param filter_column A column expression/name in the data frame.
#' @return A character vector of option names.
#' @noRd
get_option_names <- function(invalid_options, filter_column) {
  invalid_options %>%
    dplyr::filter({{ filter_column }}) %>%
    dplyr::pull(.data$Name)
}

#' Returns the given text if the options are not empty
#' @param text A string.
#' @param options A character vector which length is tested.
#' @return The given string if the options are not empty, otherwise an empty character vector
#' @noRd
if_any_opts <- function(text, options) {
  if (vctrs::vec_size(options) > 0) {
    text
  } else {
    character(0)
  }
}

#' Converts an R option value to a Rust option value
#'
#' @param option_value An R scalar option value.
#' @return A Rust option value as a string.
#' @noRd
convert_option_to_rust <- function(option_value) {
  if (vctrs::vec_is(option_value, character())) {
    paste0("\"", option_value, "\"")
  } else if (vctrs::vec_is(option_value, logical())) {
    ifelse(option_value, "true", "false")
  } else {
    as.character(option_value)
  }
}
