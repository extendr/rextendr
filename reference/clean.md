# Clean Rust binaries and package cache.

Removes Rust binaries (such as `.dll`/`.so` libraries), C wrapper object
files, invokes `cargo clean` to reset cargo target directory (found by
default at `pkg_root/src/rust/target/`). Useful when Rust code should be
recompiled from scratch.

## Usage

``` r
clean(path = ".", echo = TRUE)
```

## Arguments

- path:

  character scalar, path to R package root.

- echo:

  logical scalar, should cargo command and outputs be printed to console
  (default is `TRUE`)

## Value

character vector with names of all deleted files (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
clean()
} # }
```
