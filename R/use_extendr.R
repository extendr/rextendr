#' Set up a package for use with Rust extendr code
#'
#' Create the scaffolding needed to add Rust extendr code to an R package. `use_extendr()`
#' adds a small Rust library with a single Rust function that returns the string
#' `"Hello world!"`. It also adds wrapper code so this Rust function can be called from
#' R with `hello_world()`.
#'
#' To avoid possibly messing up your R package, `use_extendr()` will not do anything if
#' either a directory `src` or a file `R/extendr-wrappers.R` is already present in your
#' package source.
#'
#' @param path File path to the package for which to generate wrapper code.
#' @param quiet Logical indicating whether any progress messages should be
#'   generated or not.
#' @return A logical value (invisible) indicating whether any package files were
#' generated or not.
#' @export
use_extendr <- function(path = ".", quiet = FALSE) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  src_dir <- rprojroot::find_package_root_file("src", path = ".")
  wrappers_file <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = ".")

  if (dir.exists(src_dir)) {
    if (!isTRUE(quiet)) {
      message("Directory `src` already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }
  if (file.exists(wrappers_file)) {
    if (!isTRUE(quiet)) {
      message("File `R/extendr-wrappers.R` already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }

  if (!isTRUE(quiet)) {
    message(glue::glue("Creating `src` ..."))
  }

  dir.create(src_dir)
  dir.create(file.path(src_dir, "rust"))
  dir.create(file.path(src_dir, "rust", "src"))

  entrypoint_content <- glue::glue(
r"(
// We need to forward routine registration from C to Rust
// to avoid the linker removing the static library.

void R_init_{pkg_name}_extendr(void *dll);

void R_init_{pkg_name}(void *dll) {{
    R_init_{pkg_name}_extendr(dll);
}}
)"
  )
  brio::write_lines(entrypoint_content, file.path(src_dir, "entrypoint.c"))

  makevars_content <- glue::glue(
"
LIBDIR = ./rust/target/release
STATLIB = $(LIBDIR)/lib{pkg_name}.a
PKG_LIBS = -L$(LIBDIR) -l{pkg_name}

all: C_clean

$(SHLIB): $(STATLIB)

$(STATLIB):
\tcargo build --lib --release --manifest-path=./rust/Cargo.toml

C_clean:
\trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)

clean:
\trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target
"
  )
  brio::write_lines(makevars_content, file.path(src_dir, "Makevars"))

  makevars_win_content <- glue::glue(
"
TARGET = $(subst 64,x86_64,$(subst 32,i686,$(WIN)))-pc-windows-gnu
LIBDIR = ./rust/target/$(TARGET)/release
STATLIB = $(LIBDIR)/lib{pkg_name}.a
PKG_LIBS = -L$(LIBDIR) -l{pkg_name} -lws2_32 -ladvapi32 -luserenv

all: C_clean

$(SHLIB): $(STATLIB)

$(STATLIB):
\tcargo build --target=$(TARGET) --lib --release --manifest-path=./rust/Cargo.toml

C_clean:
\trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)

clean:
\trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target
"
  )
  brio::write_lines(makevars_win_content, file.path(src_dir, "Makevars.win"))

  gitignore_content <- "*.o
*.so
*.dll
target
"
  brio::write_lines(gitignore_content, file.path(src_dir, ".gitignore"))

  cargo_toml_content <- glue::glue(
r"(
  [package]
  name = "{pkg_name}"
  version = "0.1.0"
  edition = "2018"

  [lib]
  crate-type = ["staticlib"]

  [dependencies]
  extendr-api = "*"
)"
  )
  brio::write_lines(cargo_toml_content, file.path(src_dir, "rust", "Cargo.toml"))

  lib_rs_content <- glue::glue(
r"(
use extendr_api::prelude::*;

/// Return string `"Hello world!"` to R.
/// @export
#[extendr]
fn hello_world() -> &'static str {{
    "Hello world!"
}}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {{
    mod {pkg_name};
    fn hello_world;
}}
)"
  )
  brio::write_lines(lib_rs_content, file.path(src_dir, "rust", "src", "lib.rs"))


  if (!isTRUE(quiet)) {
    message(glue::glue("Creating `R/extendr-wrappers.R` ..."))
  }


  roxcmt <- "#'" # workaround for roxygen parsing bug in raw strings

  wrappers_content <- glue::glue(
r"(
{roxcmt} @docType package
{roxcmt} @usage NULL
{roxcmt} @useDynLib {pkg_name}, .registration = TRUE
NULL

{roxcmt} Return string `"Hello world!"` to R.
{roxcmt} @export
hello_world <- function() .Call(wrap__hello_world)
)"
  )
  brio::write_lines(wrappers_content, wrappers_file)

  if (!isTRUE(quiet)) {
    message(glue::glue("Done.\n\nPlease run `devtools::document()` for changes to take effect.\nAlso update the system requirements in your `DESCRIPTION` file."))
  }

  return(invisible(TRUE))
}
