.onLoad <- function(...) {

  # register the extendr knitr chunk engine if knitr is available
  if (requireNamespace("knitr", quietly = TRUE)) {
    knitr::knit_engines$set(
      extendr = eng_extendr,
      extendrsrc = eng_extendrsrc
    )
  }

  # Setting default options
  # If rextendr options are already set, do not override
  # NULL values are present for reference and may later be replaced
  # by concrete values

  git_ref <- list(git = "https://github.com/extendr/extendr")

  rextendr_opts <- list(
    # Controls default Rust toolchain; NULL corresponds to system's default
    rextendr.toolchain = NULL,
    #   rextendr.toolchain = "nightly",    # use 'nightly' tool chain

    # Overrides Rust dependencies; mainly used for development
    rextendr.patch.crates_io = NULL, # most recent extendr crates on crates.io
    #    rextendr.patch.crates_io = list(  # most recent extendr crates on github
    #      `extendr-api` = git_ref
    #    ),

    # Version of 'extendr_api' to be used
    rextendr.extendr_deps = list(
      `extendr-api` = "*"
    )
  )


  id_opts_to_set <- !(names(rextendr_opts) %in% names(options()))

  options(rextendr_opts[id_opts_to_set])
}
