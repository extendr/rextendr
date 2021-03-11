
#' Use roclets to augment package compilaion.
#'
#' @param use_roxygen_roclets Logical (default: `TRUE`), indicates
#' if default `roxygen2` roclets should be referenced in the DESCRIPTION file.
#' @returns `NULL` (invisibly)
#' @export
use_roclets <- function(
  use_roxygen_roclets = TRUE
) {
  # recompilation roclet
  # registration roclet
  roclet_args <- "rextendr::test_roclet"
  if (isTRUE(use_roxygen_roclets)) {
    roclet_args <- c(roclet_args, "roxygen2::roxy_meta_get(\"roclets\")")
  }
  roxygen_prop <- desc::desc_get("Roxygen")
  if (all(is.na(roxygen_prop)) || all(!nzchar(roxygen_prop))) {
    # No 'Roxygen' field in DESCRIPTION or it is empty
    roxygen <- glue::glue(
      "roclets = c(",
      glue::glue_collapse(roclet_args, sep = ", "),
      ")"
    )
  } else {
    # 'Roxygen' field is not empty
    roxygen <- stringi::stri_match_first_regex(
      roxygen_prop,
      "^\\s*list\\((.*)\\)\\s*$"
    )[2]

    if (all(is.na(roxygen))) {
     cli::cli_alert_danger(
       c(
          "{.var Roxygen} field in {.file DESCRIPTION} has unsupported format.",
          " Skipping initialization of roclets."
       )
     )
     return(invisible(NULL))
    }
    roxygen <- glue::glue(
      roxygen,
      glue::glue(
        "roclets = c(",
        glue::glue_collapse(roclet_args, sep = ", "),
        ")"
      ),
      .sep = ",\n\t",
      .trim = FALSE
    )
  }

  desc::desc_set(
    Roxygen = glue::glue("list(\n\t{roxygen}\n)")
  )
  cli::cli_alert_success(
    "Adding roclets to {.var Roxygen} field in {.file DESCRIPTION}."
  )

  invisible(NULL)
}