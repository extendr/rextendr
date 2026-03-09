# Compile Rust code and generate package documentation.

**\[deprecated\]**

As of `rextendr` 0.4.0, this function is no longer strictly necessary.
Packages created with
[`use_extendr()`](https://extendr.github.io/rextendr/dev/reference/use_extendr.md)
now include a `document` binary that generates `R/extendr-wrappers.R` as
part of the normal `cargo build` step, so
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
works directly without any `rextendr`-specific pre-processing.
`rextendr::document()` is retained for backwards compatibility.

`rextendr::document()` updates the package documentation for an R
package that uses `extendr` code. It is a wrapper for
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html).

## Usage

``` r
document(pkg = ".", quiet = FALSE, roclets = NULL)
```

## Arguments

- pkg:

  The package to use, can be a file path to the package or a package
  object. See
  [`as.package()`](https://devtools.r-lib.org/reference/as.package.html)
  for more information.

- quiet:

  if `TRUE` suppresses output from this function.

- roclets:

  Character vector of roclet names to use with package. The default,
  `NULL`, uses the roxygen `roclets` option, which defaults to
  `c("collate", "namespace", "rd")`.

## Value

No return value, called for side effects.
