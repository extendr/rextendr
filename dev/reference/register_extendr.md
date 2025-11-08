# Register the extendr module of a package with R

This function generates wrapper code corresponding to the extendr module
for an R package. This is useful in package development, where we
generally want appropriate R code wrapping the Rust functions
implemented via extendr. In most development settings, you will not want
to call this function directly, but instead call
[`rextendr::document()`](https://extendr.github.io/rextendr/dev/reference/document.md).

## Usage

``` r
register_extendr(path = ".", quiet = FALSE, force = FALSE, compile = NA)
```

## Arguments

- path:

  Path from which package root is looked up.

- quiet:

  Logical indicating whether any progress messages should be generated
  or not.

- force:

  Logical indicating whether to force regenerating
  `R/extendr-wrappers.R` even when it doesn't seem to need updated. (By
  default, generation is skipped when it's newer than the DLL).

- compile:

  Logical indicating whether to recompile DLLs:

  `TRUE`

  :   always recompiles

  `NA`

  :   recompiles if needed (i.e., any source files or manifest file are
      newer than the DLL)

  `FALSE`

  :   never recompiles

## Value

(Invisibly) Path to the file containing generated wrappers.

## Details

The function `register_extendr()` compiles the package Rust code if
required, and then the wrapper code is retrieved from the compiled Rust
code and saved into `R/extendr-wrappers.R`. Afterwards, you will have to
re-document and then re-install the package for the wrapper functions to
take effect.

## See also

[`document()`](https://extendr.github.io/rextendr/dev/reference/document.md)
