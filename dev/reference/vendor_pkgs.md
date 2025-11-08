# Vendor Rust dependencies

`vendor_pkgs()` is used to package the dependencies as required by CRAN.
It executes `cargo vendor` on your behalf creating a `vendor/` directory
and a compressed `vendor.tar.xz` which will be shipped with package
itself. If you have modified your dependencies, you will need need to
repackage

## Usage

``` r
vendor_pkgs(path = ".", quiet = FALSE, overwrite = NULL, clean = FALSE)
```

## Arguments

- path:

  File path to the package for which to generate wrapper code.

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

- clean:

  `logical(1)` indicating whether the `vendor/` directory should be
  removed after creating the `vendor.tar.xz` file. Defaults to `FALSE`.

## Value

- `vendor_pkgs()` returns a data.frame with two columns `crate` and
  `version`

## Examples

``` r
if (FALSE) { # \dontrun{
vendor_pkgs()
} # }
```
