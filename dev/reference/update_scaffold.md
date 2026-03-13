# Update extendr scaffolding

When a new version of extendr or rextendr is released, this function
updates relevant scaffolding files to the new specification.

## Usage

``` r
update_scaffold(path = ".", crate_name = NULL, lib_name = NULL, quiet = FALSE)
```

## Arguments

- path:

  File path to the package for which to generate wrapper code.

- crate_name:

  String that is used as the name of the Rust crate, specifically
  `[package] name` in `Cargon.toml`. If `NULL` (default), sanitized R
  package name is used instead.

- lib_name:

  String that is used as the name of the Rust library, specifically
  `[lib] name` in `Cargo.toml`. If `NULL` (default), sanitized R package
  name is used instead.

- quiet:

  Logical indicating whether any progress messages should be generated
  or not.

## Value

a logical scalar indicating whether scaffold updating was successful

## Details

This function does not touch any build artifacts or files or folders
generated when vendoring cargo. Cargo.lock and Cargo.toml are also left
unchanged. Only the following files are re-written:

- `src/entrypoint.c`

- `src/Makevars.in`

- `src/Makevars.win.in`

- `cleanup`

- `cleanup.win`

- `src/rust/document.rs`

- `tools/msrv.R`

- `tools/config.R`

- `configure`

- `configure.win`

After updating these files, `update_scaffold()` will print a message
that explains what to do next to get your package up-to-date with the
latest versions of extendr and rextendr (provided `quiet = FALSE`,
anyway). That will typically include handling dependency resolution,
updating Cargo.toml and Cargo.lock, and vendoring crates for CRAN
compliance. Usually, this will be accompanied by a more detailed blog
post explaining the update process.
