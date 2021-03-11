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
    message(glue("Creating `src` ..."))
  }

  dir.create(src_dir)
  dir.create(file.path(src_dir, "rust"))
  dir.create(file.path(src_dir, "rust", "src"))
  dir.create(file.path(src_dir, "rust", "src", "bin"))

  write_example_entrypoint(pkg_name, file.path(src_dir, "entrypoint.c"))

  write_example_makevars(pkg_name, file.path(src_dir, "Makevars"))
  write_example_makevars(pkg_name, file.path(src_dir, "Makevars.win"), windows = TRUE)

  write_example_gitignore(file.path(src_dir, ".gitignore"))

  write_example_cargo_toml(file.path(src_dir, "rust", "Cargo.toml"))

  write_example_lib_rs(pkg_name, file.path(src_dir, "rust", "src", "lib.rs"))

  write_example_generate_wrappers_rs(pkg_name, file.path(src_dir, "rust", "src", "bin", "generate_wrappers.rs"))

  if (!isTRUE(quiet)) {
    message(glue("Creating `R/extendr-wrappers.R` ..."))
  }

  roxcmt <- "#'" # workaround for roxygen parsing bug in raw strings

  example_function_wrapper <- glue(
    r"(
    {roxcmt} Return string `"Hello world!"` to R.
    {roxcmt} @export
    hello_world <- function() .Call(wrap__hello_world)
    )"
  )

  write_example_wrappers(pkg_name, wrappers_file, extra_items = example_function_wrapper)

  if (!isTRUE(quiet)) {
    message(glue("Done.\n\nPlease run `devtools::document()` for changes to take effect.\nAlso update the system requirements in your `DESCRIPTION` file."))
  }

  return(invisible(TRUE))
}

write_example_entrypoint <- function(pkg_name, outfile) {
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

  brio::write_lines(entrypoint_content, outfile)
}

write_example_makevars <- function(pkg_name, outfile, windows = FALSE) {
  if (windows) {
    target <- "TARGET = $(subst 64,x86_64,$(subst 32,i686,$(WIN)))-pc-windows-gnu"
    pkg_libs <- "PKG_LIBS = -L$(LIBDIR) -l{pkg_name} -lws2_32 -ladvapi32 -luserenv"
  } else {
    target <- ""
    pkg_libs <- "PKG_LIBS = -L$(LIBDIR) -l{pkg_name}"
  }

  makevars_content <- glue(
    "
    {target}
    LIBDIR = ./rust/target/$(TARGET)/release
    STATLIB = $(LIBDIR)/lib{pkg_name}.a
    {pkg_libs}
    WRAPPER_FILE = ./extendr-wrappers.R

    all: C_clean

    $(SHLIB): $(STATLIB) $(WRAPPER_FILE)

    $(STATLIB):
    \tcargo build --lib --release --manifest-path=./rust/Cargo.toml

    $(WRAPPER_FILE): $(STATLIB)
    \tcargo run --quiet --manifest-path=./rust/Cargo.toml --bin generate_wrappers > $@

    C_clean:
    \trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(WRAPPER_FILE)

    clean:
    \trm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(WRAPPER_FILE) rust/target
    "
  )

  brio::write_lines(makevars_content, outfile)
}

write_example_gitignore <- function(outfile) {
  gitignore_content <- glue(
    "
    *.o
    *.so
    *.dll
    target
    extendr-wrappers.R
    "
  )

  brio::write_lines(gitignore_content, outfile)
}

write_example_cargo_toml <- function(pkg_name, outfile) {
  cargo_toml_content <- to_toml(
    package = list(name = pkg_name, version = "0.1.0", edition = "2018"),
    lib = list(`crate-type` = c("staticlib", "lib")),
    dependencies = list(`extendr-api` = "*")
  )

  brio::write_lines(cargo_toml_content, outfile)
}

write_example_lib_rs <- function(pkg_name, outfile) {
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
  brio::write_lines(lib_rs_content, outfile)
}

write_example_generate_wrappers_rs <- function(pkg_name, outfile) {
  lib_rs_content <- glue(
    r"(
    fn main() {
      let metadata = {pkg_name}::get_{pkg_name}_metadata();
      print!(
        "{}",
        metadata.make_r_wrappers(true, "{pkg_name}").unwrap()
      );
    }
    )"
  )

  brio::write_lines(lib_rs_content, outfile)
}

write_example_wrappers <- function(pkg_name, outfile, extra_items = NULL) {
  roxcmt <- "#'" # workaround for roxygen parsing bug in raw strings

  wrappers_content <- glue(
    r"(
    {roxcmt} @docType package
    {roxcmt} @usage NULL
    {roxcmt} @useDynLib {pkg_name}, .registration = TRUE
    NULL
    )"
  )

  if (!is.null(extra_items)) {
    wrappers_content <- glue_collapse(
      c(wrappers_content, extra_items),
      sep = "\n"
    )
  }

  brio::write_lines(wrappers_content, outfile)
}

