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
#' @param use_roclets Logical (default: `FALSE`) indicating whether to use
#'   `roxygen2` roclets to augment pacakge compilation process.
#' @return A logical value (invisible) indicating whether any package files were
#' generated or not.
#' @export
use_extendr <- function(path = ".", use_roclets = FALSE, quiet = FALSE) {
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- x$get("Package")

  src_dir <- rprojroot::find_package_root_file("src", path = path)
  wrappers_file <- rprojroot::find_package_root_file("R", "extendr-wrappers.R", path = path)

  if (dir.exists(src_dir)) {
    if (!isTRUE(quiet)) {
      cli::cli_alert_danger("Directory {.file src} already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }
  if (file.exists(wrappers_file)) {
    if (!isTRUE(quiet)) {
      cli::cli_alert_danger("File {.file R/extendr-wrappers.R} already present in package source. No action taken.")
    }
    return(invisible(FALSE))
  }

  rust_src_dir <- fs::path(src_dir, "rust", "src")
  fs::dir_create(rust_src_dir, recurse = TRUE)
  cli::cli_alert_success("Creating {.file {pretty_rel_path(rust_src_dir, path)}}.")

  entrypoint_content <- glue(
    r"(
// We need to forward routine registration from C to Rust
// to avoid the linker removing the static library.

void R_init_{pkg_name}_extendr(void *dll);

void R_init_{pkg_name}(void *dll) {{
    R_init_{pkg_name}_extendr(dll);
}}
)"
  )
  usethis::write_over(fs::path(src_dir, "entrypoint.c"), entrypoint_content, quiet = quiet)

  makevars_content <- glue(
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
  usethis::write_over(fs::path(src_dir, "Makrvars"), makevars_content, quiet = quiet)

  makevars_win_content <- glue(
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
  usethis::write_over(fs::path(src_dir, "Makevars.win"), makevars_win_content, quiet = quiet)

  gitignore_content <- "*.o
*.so
*.dll
target
"
  usethis::write_over(fs::path(src_dir, ".gitignore"), gitignore_content, quiet = quiet)

  cargo_toml_content <- to_toml(
    package = list(name = pkg_name, version = "0.1.0", edition = "2018"),
    lib = list(`crate-type` = array("staticlib", 1)),
    dependencies = list(`extendr-api` = "*")
  )
  usethis::write_over(fs::path(src_dir, "rust", "Cargo.toml"), cargo_toml_content, quiet = quiet)

  lib_rs_content <- glue(
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

    usethis::write_over(fs::path(rust_src_dir, "lib.rs"), lib_rs_content, quiet = quiet)

  # if (!isTRUE(quiet)) {
  #   message(glue("Creating `R/extendr-wrappers.R` ..."))
  # }

  roxcmt <- "#'" # workaround for roxygen parsing bug in raw strings

  example_function_wrapper <- glue(
    r"(
    {roxcmt} Return string `"Hello world!"` to R.
    {roxcmt} @export
    hello_world <- function() .Call(wrap__hello_world)
    )"
  )

  make_example_wrappers(pkg_name, wrappers_file, extra_items = example_function_wrapper)
  write_namespace(pkg_name)

  if (isTRUE(use_roclets)) {
    use_roclets(use_roxygen_roclets = TRUE)
  }

  if (!isTRUE(quiet)) {
    cli::cli_alert_success("Finished configuring {.pkg extendr} for package {.pkg {pkg_name}}.")
    cli::cli_alert_info("Update the system requirement in {.file DESCRIPTION} file.")
    cli::cli_alert_warning("Please run {.fun rextendr::document} for changes to take effect.")
  }

  return(invisible(TRUE))
}

make_example_wrappers <- function(pkg_name, outfile, extra_items = NULL, quiet = FALSE) {
  roxcmt <- "#'" # workaround for roxygen parsing bug in raw strings

  wrappers_content <- glue::glue(
    r"(
    {roxcmt} @docType package
    {roxcmt} @usage NULL
    {roxcmt} @useDynLib {pkg_name}, .registration = TRUE
    NULL
    )"
  )

  if (!is.null(extra_items)) {
    wrappers_content <- glue::glue_collapse(
      c(wrappers_content, extra_items),
      sep = "\n"
    )
  }

  usethis::write_over(outfile, wrappers_content, quiet = quiet)
}

write_namespace <- function(pkg_name) {
  ns_path <- rprojroot::find_package_root_file("NAMESPACE", path = ".")
  if (!file.exists(ns_path)) {
    cli::cli_alert_warning("{.file NAMESPACE} file is missing. Make sure the project has been set up correctly.")
    usethis::use_namespace()
  }
  lines <- brio::read_lines(ns_path)
  if (!any(grepl("useDynLib", lines))) {
    # NAMESPACE has no `useDynLib`
    usethis::write_union(ns_path, glue::glue("useDynLib({pkg_name}, .registration = TRUE)"))
  }
}
