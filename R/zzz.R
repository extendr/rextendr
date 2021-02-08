.onLoad <- function(...) {

  # register the extendr knitr chunk engine if knitr is available
  # if (requireNamespace("knitr", quietly = TRUE)) {
  #   knitr::knit_engines$set(
  #     extendr = eng_extendr,
  #     extendrsrc = eng_extendrsrc
  #   )
  # }

  # Setting default options
  # If rextendr options are already set, do not override
  # NULL values are present for reference and may later be replaced
  # by concrete values

  rextendr_opts <- list(
    # Controls default Rust toolchain; NULL corresponds to system's default
    rextendr.toolchain = NULL,
    # Overrides Rust dependencies; mainly used for development
    rextendr.patch.crates_io =  c(
      'extendr-api = { git = "https://github.com/extendr/extendr" }',
      'extendr-macros = { git = "https://github.com/extendr/extendr" }'
    ),
    # Default version of 'extendr_api' if no 'patch.crates_io' is specified
    rextendr.extendr_api.version = "*",
    # Default version of 'extendr_api' if no 'patch.crates_io' is specified
    rextendr.extendr_macros.version = "*"
  )


  id_opts_to_set <- !(names(rextendr_opts) %in% names(options()))

  options(rextendr_opts[id_opts_to_set])
}
