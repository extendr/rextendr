# Set the minimum supported rust version (MSRV)

`use_msrv()` sets the minimum supported rust version for your R package.

## Usage

``` r
use_msrv(version, path = ".", overwrite = FALSE)
```

## Arguments

- version:

  character scalar, the minimum supported Rust version.

- path:

  character scalar, path to folder containing DESCRIPTION file.

- overwrite:

  default `FALSE`. Overwrites the `SystemRequirements` field if already
  set when `TRUE`.

## Value

`version`

## Details

The minimum supported rust version (MSRV) is determined by the
`SystemRequirements` field in a package's `DESCRIPTION` file. For
example, to set the MSRV to `1.67.0`, the `SystemRequirements` must have
`rustc >= 1.67.0`.

By default, there is no MSRV set. However, some crates have features
that depend on a minimum version of Rust. As of this writing the version
of Rust on CRAN's Fedora machine's is 1.69. If you require a version of
Rust that is greater than that, you must set it in your DESCRIPTION
file.

It is also important to note that if CRAN's machines do not meet the
specified MSRV, they will not be able to build a binary of your package.
As a consequence, if users try to install the package they will be
required to have Rust installed as well.

To determine the MSRV of your R package, we recommend installing the
`cargo-msrv` cli. You can do so by running `cargo install cargo-msrv`.
To determine your MSRV, set your working directory to `src/rust` then
run `cargo msrv`. Note that this may take a while.

For more details, please see
[cargo-msrv](https://github.com/foresterre/cargo-msrv).

## Examples

``` r
if (FALSE) { # \dontrun{
use_msrv("1.67.1")
} # }
```
