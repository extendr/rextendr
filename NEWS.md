# rextendr (development version)

* Removes `Makevars.ucrt` as R versions < 4.1 are not supported by extendr <https://github.com/extendr/rextendr/pull/414> 
* `purrr` has been replaced with [`R/standalone-purrr.R`](https://github.com/r-lib/rlang/blob/main/R/standalone-purrr.R) removing `purrr` from `Imports` <https://github.com/extendr/rextendr/pull/408>
* `document()` will no longer try to save all open files using rstudioapi <https://github.com/extendr/rextendr/issues/404> <https://github.com/extendr/rextendr/issues/407>
* `use_cran_default()` has been removed as the default package template is CRAN compatible <https://github.com/extendr/rextendr/pull/394>
* `use_extendr()` now creates `tools/msrv.R`, `configure` and `configure.win`. These have been moved out of `use_cran_defaults()` <https://github.com/extendr/rextendr/pull/393>
* `Makevars` now prints linked static libraries at compile time by adding `--print=native-static-libs` to `RUSTFLAGS` <https://github.com/extendr/rextendr/pull/393>
* `use_extendr()` sets the `DESCRIPTION`'s `SystemRequirements` field according to CRAN policy to `Cargo (Rust's package manager), rustc` (#329)
* Introduces new functions `use_cran_defaults()` and `vendor_pkgs()` to ease the publication of extendr-powered packages on CRAN. See the new article _CRAN compliant extendr packages_ on how to use these (#320).
* `rust_sitrep()` now better communicates the status of the Rust toolchain and available targets. It also guides the user through necessary installation steps to fix Rust setup (#318).
* `use_extendr()` and `document()` now set the `SystemRequirements` field of the `DESCRIPTION` file to
  `Cargo (rustc package manager)` if the field is empty (#298).
* `use_extendr()` gets a new ability to overwrite existing rextendr templates (#292).
* `use_extendr()` sets `publish = false` in the `[package]` section of the `Cargo.toml` (#297).
* `use_extendr()` correctly handles calls with `path` not equal to  `"."` (current folder), or when there is no active `{usethis}` project (#323).
* Fixes an issue in pre-defined set of known features: added `either` (#338)
* `create_extendr_package()` allows user to create project directory using RStudio's **Project Command**. (#321)
* Support `RTOOLS44` (#347)
* Removed `use_try_from` as an option in `rust_function`, and added `use_rng` (#354)
* Added `use_crate()` function to make adding dependencies to Cargo.toml easier within R, similar to `usethis::use_package()` (#361)
* Fixed an issue in `rust_source()` family of functions that prevented usage of `r#` escape sequences in Rust function names (#374)
* `use_cran_defaults()` now checks the `SystemRequirements` field in the `DESCRIPTION` file for cargo and rustc. It will display installation instructions if either is missing or provide the minimum required version if the installed version is outdated.
* Added `use_msrv()` to aid in specifying the minimum supported rust version (MSRV) for an R package
* Added `read_cargo_metadata()` to retrieve Cargo metadata for packages and
  workspaces. (#389)
* `rustup_sitrep()` now checks if a default toolchain has been set. <https://github.com/extendr/rextendr/pull/416>

# rextend 0.3.1

* Update package templates to work with Rust >= 1.70 (#285)

# rextendr 0.3.0

* Ilia Kosenkov is now the official maintainer.

* Josiah Parry is now a contributor.

* Support Rtools43 (#231).

* `rextendr` has migrated to the use of `cli` for raising errors and warnings.

* Developer note: new helper function `local_quiet_cli()` introduced in `R/utils.R` to simplify silencing cli output.
  
## New features

* A new function `rust_sitrep()` that prints out a short report on the currently installed Rust toolchain (#274).

* A new function `write_license_note()` to generate `LICENSE.note` file from `Cargo.toml` (#271).

* `extendr_fn_options` parameter of `rust_source()` controls what type of options are emitted to `#[extendr()]` attribute (#252).

* `use_dev_extendr` flag makes `rust_source()` family of functions compile code using development version of `extendr`.
Development configuration is stored as an option named `rextendr.extendr_dev_deps` (#251).

* `features` parameter of `rust_source()` now correctly enables features in `extendr-api` and references required crates.
`features` not available in release version of `extendr` raises a warning (#249).

* A `<pkg_name>-win.def` file containing DLL exports is created by `rextendr::use_extendr()`. It is used during linking phase on Windows and solves the problem of compiling very large projects, such as `polars` (#212)

* Support extendr macro with options (#128).

* `rust_source()` got `features` argument to specify Cargo features to activate
  (#140).

* `rextendr::document()` now sets the envvars that `devtools::document()` sets,
  e.g. `NOT_CRAN` (#135).

# rextendr 0.2.0

First official release.
