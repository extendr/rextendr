# rextendr (development version)

* Ilia Kosenkov is now the official maintainer.

* Support Rtools43 (#231).

* `rextendr` has migrated to the use of `cli` for raising errors and warnings.
* Developer note: new helper `with_quiet()` in `R/utils.R` introduced to handle silencing cli output.
  
## New features

* `extendr_fn_options` parameter of `rust_source()` controls what type of options are emitted to `#[extendr()]` attribute ([#252](https://github.com/extendr/rextendr/pull/252)).

* `use_dev_extendr` flag makes `rust_source()` family of functions compile code using development version of `extendr`.
Development configuration is stored as an option named `rextendr.extendr_dev_deps` ([#251](https://github.com/extendr/rextendr/pull/251)).

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
