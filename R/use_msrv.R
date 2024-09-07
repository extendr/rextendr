#' Set the minimum supported rust version (MSRV)
#' `use_msrv()` sets the minimum supported rust version for your R package. 
#' @param version character scalar, the minimum supported Rust version
#' @param path character scalar, path to folder containing DESCRIPTION file
#' 
#' @details

#' The minimum supported rust version (MSRV) is determined by the `SystemRequirements` field in a package's `DESCRIPTION` file. For example, to set the MSRV to `1.67.0`, the `SystemRequirements` must have `rustc >= 1.67.0`.
#' 
#' By default, there is no MSRV set. However, some crates have features that depend on a minimum version of Rust. As of this writing the version of Rust on CRAN's Fedora machine's is 1.69. If you require a version of Rust that is greater than that, you must set it in your DESCRIPTION file.
#' 
#' It is also important to note that if CRAN's machines do not meet the specified MSRV, they will not be able to build a binary of your package. As a consequence, if users try to install the package they will be required to have Rust installed as well. 
#' 
#' To determine the MSRV of your R package, we recommend installing the `cargo-msrv` cli. You can do so by running `cargo install cargo-msrv`. To determine your MSRV, set your working directory to `src/rust` then run `cargo msrv`. Note that this may take a while.
#' 
#' For more details, please see [cargo-msrv](https://github.com/foresterre/cargo-msrv). 
#'
#' @return `version`
#' @export
#' 
#' @examples
#' \dontrun{
#' use_msrv("1.67.1")
#' }
#' 
use_msrv <- function(version, path = "."){

  if (length(version) != 1L) {
    cli::cli_abort("Version must be a character scalar", class = "rextendr_error")
  }
  
  msrv_call <- rlang::caller_call()
  version <- tryCatch(numeric_version(version), error = function(e) {
    cli::cli_abort(
      "Invalid version provided",
      class = "rextendr_error",
      call = msrv_call
    )
  })

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
      "Please update it manually if needed.",
      "{.code SystemRequirements: {cur}}"
     )
    )
  }

  invisible(version)

}
