features_config <- rlang::env(
  known_features = c("ndarray", "serde", "num-complex", "num-complex", "graphics")
)

validate_extendr_features <- function(features, quiet) {
  features <- features %||% character(0)
  vctrs::vec_assert(features, character())
  features <- unique(features)

  unknown_features <- features %>%
    setdiff(features_config$known_features) %>%
    discard_empty()

  # TODO: Fox this
  if (!isTRUE(quiet) && length(unknown_features) > 0) {
    cli::cli_warn(c(
      "Found unknown {.code extendr} feature{?s}: {.val {unknown_features}}.",
      inf_dev_extendr_used() # nolint: object_usage_linter
    ))
  }

  features
}

discard_empty <- function(input) {
  vctrs::vec_slice(input, nzchar(input))
}

enable_features <- function(extendr_deps, features) {
  features <- setdiff(features, "graphics")
  if (length(features) == 0L) {
    return(extendr_deps)
  }

  extendr_api <- extendr_deps[["extendr-api"]]
  if (is.null(extendr_api)) {
    cli::cli_abort("{.arg extendr_deps} should contain a reference to {.code extendr-api} crate.")
  }

  if (is.character(extendr_api)) {
    extendr_api <- list(version = extendr_api, features = array(features))
  } else if (is.list(extendr_api)) {
    existing_features <- extendr_api[["features"]] %||% character(0)
    extendr_api[["features"]] <- array(unique(c(existing_features, features)))
  } else {
    cli::cli_abort("{.arg extendr_deps} contains an invalid reference to {.code extendr-api} crate.")
  }

  extendr_deps[["extendr-api"]] <- extendr_api

  extendr_deps
}
