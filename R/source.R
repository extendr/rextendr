#' Compile Rust code
#'
#' [rust_source()] compiles and loads a single Rust file for use in R.
#'
#' @param file Input rust file to source.
#' @param code Input rust code, to be used instead of `file`.
#' @param dependencies Character vector of dependencies lines to be added to the
#'   `Cargo.toml` file.
#' @param patch.crates_io Character vector of patch statements for crates.io to
#'   be added to the `Cargo.toml` file.
#' @param env The R environment in which the wrapping functions will be defined.
#' @param cache_build Logical indicating whether builds should be cached between
#'   calls to [rust_source()].
#' @param quiet Logical indicating whether compile output should be generated or not.
#' @export
rust_source <- function(file, code = NULL, dependencies = NULL, patch.crates_io = NULL,
                        env = parent.frame(), cache_build = TRUE, quiet = FALSE) {
  dir <- get_build_dir(cache_build)
  if (!isTRUE(quiet)) {
    cat(sprintf("build directory: %s\n", dir))
    stdout <- "" # to be used by `system2()` below
  } else {
    stdout <- NULL
  }

  # copy rust code into src/lib.rs and determine library name
  rust_file <- file.path(dir, "src", "lib.rs")
  if (!is.null(code)) {
    brio::write_lines(code, rust_file)

    # generate lib name
    libname <- paste0("rextendr", the$count)
    the$count <- the$count + 1L
  } else {
    file.copy(file, rust_file, overwrite = TRUE)
    libname <- tools::file_path_sans_ext(basename(file))
  }

  if (!isTRUE(cache_build)) {
    on.exit(clean_build_dir())
  }

  # generate Cargo.toml file and compile shared library
  cargo.toml_content <- generate_cargo.toml(libname, dependencies, patch.crates_io)
  brio::write_lines(cargo.toml_content, file.path(dir, "Cargo.toml"))

  status <- system2(
    command = "cargo",
    args = c(
      "build",
      #"--release",  # release vs debug should be configurable at some point; for now, debug compiles faster
      sprintf("--manifest-path=%s", file.path(dir, "Cargo.toml"))
    ),
    stdout = stdout,
    stderr = stdout
  )
  if (status != 0L) {
    stop("Rust code could not be compiled successfully. Aborting.", call. = FALSE)
  }


  # generate R bindings for shared library
  funs <- get_exported_functions(rust_file) # extract function declarations
  r_functions <- generate_r_functions(funs)
  r_path <- file.path(dir, "R", "rextendr.R")
  brio::write_lines(r_functions, r_path)
  source(r_path, local = env)

  # load shared library
  shared_lib <- file.path(dir, "target", "debug", paste0("lib", libname, get_dynlib_ext()))
  dyn.load(shared_lib, local = TRUE, now = TRUE)
}

generate_cargo.toml <- function(libname = "rextendr", dependencies = NULL, patch.crates_io = NULL) {
  cargo.toml <- c(
    '[package]',
    glue::glue('name = "{libname}"'),
    'version = "0.0.1"\nedition = "2018"',
    '[lib]\ncrate-type = ["dylib"]',
    '[dependencies]',
    'extendr-api = "0.1.3"',
    'extendr-macros = "0.1.2"'
  )

  # add user-provided dependencies
  cargo.toml <- c(cargo.toml, dependencies)

  # use locally installed bindings if they exist
  package_dir <- find.package("rextendr")
  bindings_file <- file.path(package_dir, "rust", "libR-sys", "src", "bindings.rs")
  if (isTRUE(file.exists(bindings_file))) {
    patch.crates_io <- c(
      patch.crates_io,
      glue::glue(
        'libR-sys = {{ path = "{path}" }}',
        path = file.path(package_dir, "rust", "libR-sys")
      )
    )
  }

  # add user-provided patch.crates-io statements
  cargo.toml <- c(
    cargo.toml,
    "[patch.crates-io]",
    patch.crates_io
  )

  cargo.toml
}

get_dynlib_ext <- function() {
  # .Platform$dynlib.ext is not reliable on OS X, so need to work around it
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      return(".dylib")
  }
  .Platform$dynlib.ext
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
