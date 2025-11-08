# Convert R `list()` into toml-compatible format.

`to_toml()` can be used to build `Cargo.toml`. The cargo manifest can be
represented in terms of R objects, allowing limited validation and
syntax verification. This function converts manifests written using R
objects into toml representation, applying basic formatting, which is
ideal for generating cargo manifests at runtime.

## Usage

``` r
to_toml(..., .str_as_literal = TRUE, .format_int = "%d", .format_dbl = "%g")
```

## Arguments

- ...:

  A list from which toml is constructed. Supports nesting and tidy
  evaluation.

- .str_as_literal:

  Logical indicating whether to treat strings as literal (single quotes
  no escapes) or basic (escaping some sequences) ones. Default is
  `TRUE`.

- .format_int, .format_dbl:

  Character scalar describing number formatting. Compatible with
  `sprintf`.

## Value

A character vector, each element corresponds to one line of the
resulting output.

## Examples

``` r
# Produces [workspace] with no children
to_toml(workspace = NULL)
#> [workspace]

to_toml(patch.crates_io = list(`extendr-api` = list(git = "git-ref")))
#> [patch.crates_io]
#> extendr-api = { git = 'git-ref' }

# Single-element arrays are distinguished from scalars
# using explicitly set `dim`
to_toml(lib = list(`crate-type` = array("cdylib", 1)))
#> [lib]
#> crate-type = [ 'cdylib' ]
```
