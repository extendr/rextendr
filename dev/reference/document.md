# Compile Rust code and generate package documentation.

The function `rextendr::document()` updates the package documentation
for an R package that uses `extendr` code, taking into account any
changes that were made in the Rust code. It is a wrapper for
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html),
and it executes `extendr`-specific routines before calling
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html).
Specifically, it ensures that Rust code is recompiled (when necessary)
and that up-to-date R wrappers are generated before regenerating the
package documentation.

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
