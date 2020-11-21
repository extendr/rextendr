#' Compile Rust code
#'
#' [rust_source()] compiles and loads a single Rust file for use in R.
#'
#' @param file Input rust file to source (not yet implemented).
#' @param code Input rust code, to be used instead of `file`.
#' @param env The R environment in which the wrapping functions will be defined.
#' @param cache_build Logical indicating whether builds should be cached between
#'   calls to [rust_source()]. Caching may not work yet.
#' @param quiet Logical indicating whether compile output should be generated or not.
#' @export
rust_source <- function(file, code = NULL, env = parent.frame(), cache_build = TRUE, quiet = FALSE) {
  dir <- get_build_dir(cache_build)
  if (!isTRUE(quiet)) {
    cat(sprintf("build directory: %s\n", dir))
    stdout <- "" # to be used by `system2()` below
  } else {
    stdout <- NULL
  }

  if (!is.null(code)) {
    rust_file <- file.path(dir, "src", "lib.rs")
    brio::write_lines(code, rust_file)
  } else {
    stop("sourcing of external files not yet implemented")
  }

  package <- tools::file_path_sans_ext(basename(rust_file))

  if (!isTRUE(cache_build)) {
    on.exit(clean_build_dir())
  }

  # generate Cargo.toml file and compile shared library
  cargo.toml_content <- generate_cargo.toml()
  brio::write_lines(cargo.toml_content, file.path(dir, "Cargo.toml"))

  system2(
    command = "cargo",
    args = c(
      "build",
      "--release",
      sprintf("--manifest-path=%s", file.path(dir, "Cargo.toml"))
    ),
    stdout = stdout,
    stderr = stdout
  )

  # generate R bindings for shared library
  funs <- get_exported_functions(rust_file) # extract function declarations
  r_functions <- generate_r_functions(funs)
  r_path <- file.path(dir, "R", "rextendr.R")
  brio::write_lines(r_functions, r_path)
  source(r_path, local = env)

  # load shared library
  count <- the$count
  the$count <- the$count + 1L
  shared_lib <- file.path(dir, "target", "release", paste0("librextendr", get_dynlib_ext()))

  # do we need to change the name each time we rebuild? caching doesn't seem to work regardless
  shared_lib_counted <- file.path(dir, paste0("librextendr", count, get_dynlib_ext()))
  file.rename(shared_lib, shared_lib_counted)
  dyn.load(shared_lib_counted, local = TRUE, now = TRUE)
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

the <- new.env(parent = emptyenv())
the$build_dir <- NULL
the$count <- 1L

get_build_dir <- function(cache_build) {
  if (!isTRUE(cache_build)) {
    clean_build_dir()
  }

  if (is.null(the$build_dir)) {
    dir <- tempfile()
    dir.create(dir)
    dir.create(file.path(dir, "R"))
    dir.create(file.path(dir, "src"))
    the$build_dir <- dir
  }
  the$build_dir
}

clean_build_dir <- function() {
  if (!is.null(the$build_dir)) {
    unlink(the$build_dir, recursive = TRUE)
    the$build_dir <- NULL
  }
}
