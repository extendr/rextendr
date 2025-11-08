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

  String that is used as the name of the Rust crate. If `NULL`,
  sanitized R package name is used instead.

- lib_name:

  String that is used as the name of the Rust library. If `NULL`,
  sanitized R package name is used instead.

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
