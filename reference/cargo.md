# Run Cargo subcommands

Call the `cargo` command line tool from R. This function delegates to
`processx::run("cargo")` enabling calls such as `cargo("test")` or
`cargo("check")`.

## Usage

``` r
cargo(
  args,
  echo = TRUE,
  error_on_status = TRUE,
  wd = NULL,
  env = NULL,
  parse_json = FALSE,
  error_call = rlang::caller_call(),
  ...
)
```

## Arguments

- args:

  character vector, the Cargo subcommand and flags to be executed.

- echo:

  Default `TRUE`. Alogical scalar, whether to print standard output and
  error to the console.

- error_on_status:

  Default `TRUE`. A logical scalar, whether to error on a non-zero exist
  status.

- wd:

  character scalar, location of the Rust crate, (default is
  `find_extendr_crate()`).

- env:

  character vector, environment variables of the child process.

- parse_json:

  Default `FALSE`. A logical scalar, whether to parse JSON-structured
  standard output using
  [`jsonlite::parse_json()`](https://jeroen.r-universe.dev/jsonlite/reference/read_json.html)
  with `simplifyDataFrame = TRUE`.

- error_call:

  Default
  [`rlang::caller_call()`](https://rlang.r-lib.org/reference/stack.html).
  The defused call with which the function running in the frame was
  invoked.

- ...:

  additional arguments passed to
  [`processx::run()`](http://processx.r-lib.org/reference/run.md).

## Value

Invisibly, a list with elements `status`, `stdout`, `stderr`, and
`timeout`. See
[`processx::run()`](http://processx.r-lib.org/reference/run.md). If
`parse_json = TRUE`, result of parsing JSON-structured standard output.

## Details

When `wd = NULL` (the default), the `cargo` command is called from the
package's Rust crate's source. Otherwise, when `wd = "/my/path"`,
`cargo` will be run there.

## Examples

``` r
if (FALSE) { # \dontrun{
# run cargo test from package root
cargo("test")
} # }
```
