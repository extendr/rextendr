# rextendr (development version)

* Ilia Kosenkov is now the official maintainer.

* Support Rtools43 (#231).

## New features

* `features` parameter of `rust_source()` now correctly enables features in `extendr-api` and references required crates.
`features` not available in release version of `extendr` raises a warning ([#249](https://github.com/extendr/rextendr/pull/249)).

* A `<pkg_name>-win.def` file containing DLL exports is created by `rextendr::use_extendr()`. It is used during linking phase on Windows and solves the problem of compiling very large projects, such as `polars` ([#212](https://github.com/extendr/rextendr/pull/212))

* Support extendr macro with options (#128).

* `rust_source()` got `features` argument to specify Cargo features to activate
  (#140).

* `rextendr::document()` now sets the envvars that `devtools::document()` sets,
  e.g. `NOT_CRAN` (#135).

# rextendr 0.2.0

First official release.
