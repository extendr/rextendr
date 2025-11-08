# Changelog

## rextendr (development version)

- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  now generates `cleanup` and `cleanup.win`.
- Refactor of
  [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  and
  [`rust_function()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  \<(<https://github.com/extendr/rextendr/pull/478>)\>
  - Adds `opts = extendr_options()` to simplify
    [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
    API with `...` to maintain backwards compatibility
  - Adds rlang standalone type checks to
    [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
    and
    [`rust_function()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  - Replaces internal `invoke_cargo()` with `run_cargo()` in
    [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  - Simplifies handling of macro options in
    `rust_function(extendr_fn_options = list())`
  - Unknown macro options in dev and release now throw errors instead of
    warnings
- [`vendor_pkgs()`](https://extendr.github.io/rextendr/dev/reference/vendor_pkgs.md)
  now has a `clean` argument to remove the `src/rust/vendor` directory
  after creating the `vendor.tar.xz` file.
  ([\#479](https://github.com/extendr/rextendr/issues/479))
- `Makevars`(.win) now uses the `vendor/`, if it exists, before
  unzipping the tarball.
  ([\#479](https://github.com/extendr/rextendr/issues/479))

## rextendr 0.4.2

CRAN release: 2025-08-26

- Sets the `extendr-api` version to the latest stable version instead of
  `"*"` when creating a new package. This is fetched from
  <https://crates.io/api/v1/crates/extendr-api> and will fall back to
  `"*"` if not available <https://github.com/extendr/rextendr/pull/467>
- Adds `xz` to `SystemRequirements` to ensure extendr based packages
  build on Posit Package Manager
  <https://github.com/extendr/rextendr/pull/467>
- Sets the release profile to use `lto=true` and `codegen-units=1` to
  ensure compatible builds with WebR as well as reduce the overall
  compiled package size <https://github.com/extendr/rextendr/pull/465>.
- Fixes compatibility with WebR by adding
  `CARGO_PROFILE_DEV_PANIC="abort" CARGO_PROFILE_RELEASE_PANIC="abort"`
  when targeting `wasm32-unknown-emsacripten` target
  <https://github.com/extendr/rextendr/pull/461>

## rextendr 0.4.1

CRAN release: 2025-06-19

- Fix tests executed on CRAN
  ([\#449](https://github.com/extendr/rextendr/issues/449))

- Added
  [`use_vscode()`](https://extendr.github.io/rextendr/dev/reference/use_vscode.md)
  and its alias
  [`use_positron()`](https://extendr.github.io/rextendr/dev/reference/use_vscode.md)
  to create `.vscode/settings.json`, enhancing the `rextendr` experience
  in VSCode/Positron. Additionally,
  [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  now automatically calls
  [`use_vscode()`](https://extendr.github.io/rextendr/dev/reference/use_vscode.md)
  when VSCode or Positron is detected as the IDE
  ([\#441](https://github.com/extendr/rextendr/issues/441)).

## rextendr 0.4.0

CRAN release: 2025-05-02

- Adds [WebR](https://docs.r-wasm.org/webr/latest/) support out of the
  box for all extendr packages.
  - Note that not all Rust crates are wasm compatible. This change only
    enables the package to build in the `wasm32-unknown-emscripten`
    target. It does not guarantee all dependencies will compile.
- Addresses new CRAN check in R 4.5+ adding warning for `_abort` usage
- [`use_extendr_badge()`](https://extendr.github.io/rextendr/dev/reference/use_extendr_badge.md)
  has been added to add an extendr-specific badge to a `README.Rmd` via
  [`usethis::use_badge()`](https://usethis.r-lib.org/reference/badges.html)
  <https://github.com/extendr/rextendr/pull/417>
- Removes `Makevars.ucrt` as R versions \< 4.1 are not supported by
  extendr <https://github.com/extendr/rextendr/pull/414>
- `purrr` has been replaced with
  [`R/standalone-purrr.R`](https://github.com/r-lib/rlang/blob/main/R/standalone-purrr.R)
  removing `purrr` from `Imports`
  <https://github.com/extendr/rextendr/pull/408>
- [`document()`](https://extendr.github.io/rextendr/dev/reference/document.md)
  will no longer try to save all open files using rstudioapi
  <https://github.com/extendr/rextendr/issues/404>
  <https://github.com/extendr/rextendr/issues/407>
- `use_cran_default()` has been removed as the default package template
  is CRAN compatible <https://github.com/extendr/rextendr/pull/394>
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  now creates `tools/msrv.R`, `configure` and `configure.win`. These
  have been moved out of `use_cran_defaults()`
  <https://github.com/extendr/rextendr/pull/393>
- `Makevars` now prints linked static libraries at compile time by
  adding `--print=native-static-libs` to `RUSTFLAGS`
  <https://github.com/extendr/rextendr/pull/393>
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  sets the `DESCRIPTION`’s `SystemRequirements` field according to CRAN
  policy to `Cargo (Rust's package manager), rustc`
  ([\#329](https://github.com/extendr/rextendr/issues/329))
- Introduces new functions `use_cran_defaults()` and
  [`vendor_pkgs()`](https://extendr.github.io/rextendr/dev/reference/vendor_pkgs.md)
  to ease the publication of extendr-powered packages on CRAN. See the
  new article *CRAN compliant extendr packages* on how to use these
  ([\#320](https://github.com/extendr/rextendr/issues/320)).
- [`rust_sitrep()`](https://extendr.github.io/rextendr/dev/reference/rust_sitrep.md)
  now better communicates the status of the Rust toolchain and available
  targets. It also guides the user through necessary installation steps
  to fix Rust setup
  ([\#318](https://github.com/extendr/rextendr/issues/318)).
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  and
  [`document()`](https://extendr.github.io/rextendr/dev/reference/document.md)
  now set the `SystemRequirements` field of the `DESCRIPTION` file to
  `Cargo (rustc package manager)` if the field is empty
  ([\#298](https://github.com/extendr/rextendr/issues/298)).
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  gets a new ability to overwrite existing rextendr templates
  ([\#292](https://github.com/extendr/rextendr/issues/292)).
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  sets `publish = false` in the `[package]` section of the `Cargo.toml`
  ([\#297](https://github.com/extendr/rextendr/issues/297)).
- [`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
  correctly handles calls with `path` not equal to `"."` (current
  folder), or when there is no active
  [usethis](https://usethis.r-lib.org) project
  ([\#323](https://github.com/extendr/rextendr/issues/323)).
- Fixes an issue in pre-defined set of known features: added `either`
  ([\#338](https://github.com/extendr/rextendr/issues/338))
- `create_extendr_package()` allows user to create project directory
  using RStudio’s **Project Command**.
  ([\#321](https://github.com/extendr/rextendr/issues/321))
- Support `RTOOLS44`
  ([\#347](https://github.com/extendr/rextendr/issues/347))
- Removed `use_try_from` as an option in `rust_function`, and added
  `use_rng` ([\#354](https://github.com/extendr/rextendr/issues/354))
- Added
  [`use_crate()`](https://extendr.github.io/rextendr/dev/reference/use_crate.md)
  function to make adding dependencies to Cargo.toml easier within R,
  similar to
  [`usethis::use_package()`](https://usethis.r-lib.org/reference/use_package.html)
  ([\#361](https://github.com/extendr/rextendr/issues/361))
- Fixed an issue in
  [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  family of functions that prevented usage of `r#` escape sequences in
  Rust function names
  ([\#374](https://github.com/extendr/rextendr/issues/374))
- `use_cran_defaults()` now checks the `SystemRequirements` field in the
  `DESCRIPTION` file for cargo and rustc. It will display installation
  instructions if either is missing or provide the minimum required
  version if the installed version is outdated.
- Added
  [`use_msrv()`](https://extendr.github.io/rextendr/dev/reference/use_msrv.md)
  to aid in specifying the minimum supported rust version (MSRV) for an
  R package
- Added
  [`read_cargo_metadata()`](https://extendr.github.io/rextendr/dev/reference/read_cargo_metadata.md)
  to retrieve Cargo metadata for packages and workspaces.
  ([\#389](https://github.com/extendr/rextendr/issues/389))
- `rustup_sitrep()` now checks if a default toolchain has been set.
  <https://github.com/extendr/rextendr/pull/416>
- Minimum R version is set to `4.1`
  ([\#435](https://github.com/extendr/rextendr/issues/435))
- [tibble](https://tibble.tidyverse.org/) is no longer a dependency
  ([\#435](https://github.com/extendr/rextendr/issues/435))

## rextendr 0.3.0

CRAN release: 2023-05-30

- Ilia Kosenkov is now the official maintainer.

- Josiah Parry is now a contributor.

- Support Rtools43
  ([\#231](https://github.com/extendr/rextendr/issues/231)).

- `rextendr` has migrated to the use of `cli` for raising errors and
  warnings.

- Developer note: new helper function
  [`local_quiet_cli()`](https://extendr.github.io/rextendr/dev/reference/local_quiet_cli.md)
  introduced in `R/utils.R` to simplify silencing cli output.

### New features

- A new function
  [`rust_sitrep()`](https://extendr.github.io/rextendr/dev/reference/rust_sitrep.md)
  that prints out a short report on the currently installed Rust
  toolchain ([\#274](https://github.com/extendr/rextendr/issues/274)).

- A new function
  [`write_license_note()`](https://extendr.github.io/rextendr/dev/reference/write_license_note.md)
  to generate `LICENSE.note` file from `Cargo.toml`
  ([\#271](https://github.com/extendr/rextendr/issues/271)).

- `extendr_fn_options` parameter of
  [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  controls what type of options are emitted to `#[extendr()]` attribute
  ([\#252](https://github.com/extendr/rextendr/issues/252)).

- `use_dev_extendr` flag makes
  [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  family of functions compile code using development version of
  `extendr`. Development configuration is stored as an option named
  `rextendr.extendr_dev_deps`
  ([\#251](https://github.com/extendr/rextendr/issues/251)).

- `features` parameter of
  [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  now correctly enables features in `extendr-api` and references
  required crates. `features` not available in release version of
  `extendr` raises a warning
  ([\#249](https://github.com/extendr/rextendr/issues/249)).

- A `<pkg_name>-win.def` file containing DLL exports is created by
  [`rextendr::use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md).
  It is used during linking phase on Windows and solves the problem of
  compiling very large projects, such as `polars`
  ([\#212](https://github.com/extendr/rextendr/issues/212))

- Support extendr macro with options
  ([\#128](https://github.com/extendr/rextendr/issues/128)).

- [`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)
  got `features` argument to specify Cargo features to activate
  ([\#140](https://github.com/extendr/rextendr/issues/140)).

- [`rextendr::document()`](https://extendr.github.io/rextendr/dev/reference/document.md)
  now sets the envvars that
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
  sets, e.g. `NOT_CRAN`
  ([\#135](https://github.com/extendr/rextendr/issues/135)).

## rextendr 0.2.0

CRAN release: 2021-06-15

First official release.
