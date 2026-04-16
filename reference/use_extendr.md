# Set up a package for use with Rust extendr code

Create the scaffolding needed to add Rust extendr code to an R package.
`use_extendr()` adds a small Rust library with a single Rust function
that returns the string `"Hello world!"`. It also adds wrapper code so
this Rust function can be called from R with `hello_world()`.

## Usage

``` r
use_extendr(
  path = ".",
  crate_name = NULL,
  lib_name = NULL,
  quiet = FALSE,
  overwrite = NULL,
  edition = c("2021", "2018")
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

- quiet:

  Logical indicating whether any progress messages should be generated
  or not.

- overwrite:

  Logical scalar or `NULL` indicating whether the files in the `path`
  should be overwritten. If `NULL` (default), the function will ask the
  user whether each file should be overwritten in an interactive session
  or do nothing in a non-interactive session. If `FALSE` and each file
  already exists, the function will do nothing. If `TRUE`, all files
  will be overwritten.

- edition:

  String indicating which Rust edition is used; Default `"2021"`.

## Value

A logical value (invisible) indicating whether any package files were
generated or not.

## Details

### Generated files

- `R/extendr-wrappers.R`: auto-generated R wrappers. Do not edit by
  hand.

- `src/entrypoint.c`: C entry point forwarding R's routine registration
  to the Rust library.

- `src/Makevars.in` / `src/Makevars.win.in`: Makefile templates compiled
  and employed at package build time.

- `src/<pkg>-win.def`: Windows DLL export definitions.

- `src/.gitignore`: Ignores compiled artifacts, Cargo directories, and
  generated `Makevars` files.

- `src/rust/Cargo.toml`: Rust package manifest with crate name, edition,
  `extendr-api` dependency, and release profile settings.

- `src/rust/src/lib.rs`: Main Rust library with an example
  `hello_world()` function and the `extendr_module!` macro.

- `src/rust/document.rs`: Rust binary that writes `R/extendr-wrappers.R`
  by introspecting exported function metadata at build time.

- `tools/msrv.R`: Verifies the installed Rust toolchain meets the MSRV
  in `DESCRIPTION`.

- `tools/config.R`: Reads `tools/msrv.R`, checks `DEBUG`/`NOT_CRAN` env
  vars, and writes the final `Makevars` file from the `.in` template.

- `configure` / `configure.win`: Shell scripts run before compilation
  that invoke `tools/config.R` via `Rscript`.

- `cleanup` / `cleanup.win`: Shell scripts that remove `src/Makevars` on
  package uninstall.
