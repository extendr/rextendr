#' Add MSRV to DESCRIPTION
#' 
#' @param version character scalar, the minimum supported Rust version
#' @param path character scalar, path to folder containing DESCRIPTION file
#' 
#' @details
#' It is assumed that MSRV is greater than or equal to `version`. The result is
#' "SystemRequirements: Cargo (Rust's package manager), rustc >= `version`."
#' 
#' @return NULL
#' @export
#' 
#' @examples
#' \dontrun{
#' use_msrv("1.67.1")
#' }
#' 
use_msrv <- function(version = NULL, path = "."){

  if (is.null(version)){
    cli::cli_abort(
      "Minimum supported Rust {.arg version} not specified.",
      class = "rextendr_error"
    )
  }

  desc_path <- rprojroot::find_package_root_file("DESCRIPTION", path = path)

  if (!file.exists(desc_path)) {
    cli::cli_abort(
      "{.arg path} ({.path {path}}) does not contain a DESCRIPTION",
      class = "rextendr_error"
    )
  }

  cur <- paste("Cargo (Rust's package manager), rustc", paste(">=", version)) 

  prev <- desc::desc_get("SystemRequirements", file = desc_path)[[1]]
  prev <- stringi::stri_trim_both(prev)

  if (is.na(prev)) {
    update_description("SystemRequirements", cur, desc_path = desc_path)
  } else if (!identical(cur, prev)) {
    cli::cli_ul(
      c(
        "The SystemRequirements field in the {.file DESCRIPTION} file is already set.",
        "Please update it manually if needed."
      )
    )
  }

  invisible(version)

}