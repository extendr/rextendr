# Register the extendr module of a package with R

**\[deprecated\]**

This function is deprecated because we now rely on a small Rust binary
to generate wrappers, which is called during the package build process.

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

## See also

[`document()`](https://extendr.github.io/rextendr/reference/document.md)
