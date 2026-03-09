# Update extendr scaffolding

When a new extendr or rextendr release requires changes to scaffolding,
this function helps update those files to the new specification.

## Usage

``` r
update_extendr(
  path = ".",
  crate_name = NULL,
  lib_name = NULL,
  revendor = TRUE,
  quiet = FALSE
)
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

- revendor:

  boolean scalar, whether to clear vendor files and re-run
  [`rextendr::vendor_pkgs()`](https://extendr.github.io/rextendr/dev/reference/vendor_pkgs.md)
  (default is `TRUE`).

- quiet:

  Logical indicating whether any progress messages should be generated
  or not.

## Value

a logical scalar indicating whether updating was successful

## Details

Unfortunately, this process cannot be fully automated, so information is
also printed to the console explaining what needs to be updated by hand.
Usually, this will be accompanied by a more detailed blog post
explaining changes.

### Current list of updated files:

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

### Additionally updated when `revendor = TRUE`:

- `src/rust/vendor/`

- `src/rust/vendor.tar.xz`

- `src/rust/vendor-config.toml`
