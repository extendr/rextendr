# Package index

## Compiling and running Rust code

- [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  [`rust_function()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  [`extendr_options()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  [`print(`*`<extendr_opts>`*`)`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  : Compile Rust code and call from R
- [`rust_eval()`](https://extendr.github.io/rextendr/dev/reference/rust_eval.md)
  : Evaluate Rust code
- [`eng_extendr()`](https://extendr.github.io/rextendr/dev/reference/eng_extendr.md)
  [`eng_extendrsrc()`](https://extendr.github.io/rextendr/dev/reference/eng_extendr.md)
  : Knitr engines

## Package development

- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  : Set up a package for use with Rust extendr code
- [`use_crate()`](https://extendr.github.io/rextendr/dev/reference/use_crate.md)
  : Add dependencies to a Cargo.toml manifest file
- [`document()`](https://extendr.github.io/rextendr/dev/reference/document.md)
  : Compile Rust code and generate package documentation.
- [`register_extendr()`](https://extendr.github.io/rextendr/dev/reference/register_extendr.md)
  : Register the extendr module of a package with R
- [`write_license_note()`](https://extendr.github.io/rextendr/dev/reference/write_license_note.md)
  : Generate LICENSE.note file.
- [`clean()`](https://extendr.github.io/rextendr/dev/reference/clean.md)
  : Clean Rust binaries and package cache.
- [`cran`](https://extendr.github.io/rextendr/dev/reference/cran.md) :
  CRAN compliant extendr packages
- [`vendor_pkgs()`](https://extendr.github.io/rextendr/dev/reference/vendor_pkgs.md)
  : Vendor Rust dependencies
- [`use_msrv()`](https://extendr.github.io/rextendr/dev/reference/use_msrv.md)
  : Set the minimum supported rust version (MSRV)
- [`use_vscode()`](https://extendr.github.io/rextendr/dev/reference/use_vscode.md)
  [`use_positron()`](https://extendr.github.io/rextendr/dev/reference/use_vscode.md)
  : Set up VS Code configuration for an rextendr project

## Various utility functions

- [`to_toml()`](https://extendr.github.io/rextendr/dev/reference/to_toml.md)
  :

  Convert R [`list()`](https://rdrr.io/r/base/list.html) into
  toml-compatible format.

- [`make_module_macro()`](https://extendr.github.io/rextendr/dev/reference/make_module_macro.md)
  : Generate extendr module macro for Rust source

- [`rust_sitrep()`](https://extendr.github.io/rextendr/dev/reference/rust_sitrep.md)
  : Report on Rust infrastructure

- [`read_cargo_metadata()`](https://extendr.github.io/rextendr/dev/reference/read_cargo_metadata.md)
  : Retrieve metadata for packages and workspaces

- [`use_extendr_badge()`](https://extendr.github.io/rextendr/dev/reference/use_extendr_badge.md)
  : extendr README badge
