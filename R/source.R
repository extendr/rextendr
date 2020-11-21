#' Compile Rust code
#'
#' [rust_source()] compiles and loads a single Rust file for use in R.
#' @export
rust_source <- function(file, code = NULL, clean = TRUE, quiet = TRUE) {
  dir <- tempfile()
  dir.create(dir)
  dir.create(file.path(dir, "R"))
  dir.create(file.path(dir, "src"))

  if (!is.null(code)) {
    rust_file <- file.path(dir, "src", "lib.rs")
    brio::write_lines(code, rust_file)
  } else {
    stop("sourcing of external files not yet implemented")
  }

  package <- tools::file_path_sans_ext(basename(rust_file))

  if (isTRUE(clean)) {
    on.exit(unlink(dir, recursive = TRUE))
  }

  cargo.toml_content <- generate_cargo.toml()
  brio::write_lines(cargo.toml_content, file.path(dir, "Cargo.toml"))

  system(sprintf("cargo build --release --manifest-path=%s", file.path(dir, "Cargo.toml")))

  shared_lib <- file.path(dir, "target", "release", paste0("librextendr", get_dynlib_ext()))
  dyn.load(shared_lib, local = TRUE, now = TRUE)
}

generate_cargo.toml <- function() {
  c(
    '[package]\n  name = "rextendr"\n  version = "0.0.1"\n  edition = "2018"',
    '[lib]\n  crate-type = ["dylib"]',
    '[dependencies]\n',
    '  extendr-api = {path = "/Users/clauswilke/github/extendr/extendr-api"}',
    '  extendr-macros = {path = "/Users/clauswilke/github/extendr/extendr-macros"}'
  )
}

get_dynlib_ext <- function() {
  # .Platform$dynlib.ext is not reliable on OS X, so need to work around it
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      ".dylib"
  } else {
    .Platform$dynlib.ext
  }
}
