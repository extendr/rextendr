# Knitr engines

Two knitr engines that enable code chunks of type `extendr` (individual
Rust statements to be evaluated via
[`rust_eval()`](https://extendr.github.io/rextendr/reference/rust_eval.md))
and `extendrsrc` (Rust functions or classes that will be exported to R
via
[`rust_source()`](https://extendr.github.io/rextendr/reference/rust_source.md)).

## Usage

``` r
eng_extendr(options)

eng_extendrsrc(options)
```

## Arguments

- options:

  A list of chunk options.

## Value

A character string representing the engine output.

## Details

Both engines support the following chunk options:

- `preamble`: A character vector of chunk labels. The code from those
  chunks is placed before the current chunk's code, in the order given,
  and the combined code is compiled as a single unit. Only the current
  chunk's code is shown in the output. This is useful for splitting Rust
  code across several chunks, for example defining helper functions in
  one chunk (typically with `eval = FALSE`) and calling them in another.
  Unlike knitr's `ref.label` option, which shows the reused code in the
  rendered document, `preamble` adds the code to the compile unit
  without displaying it. See
  [`vignette("rmarkdown", package = "rextendr")`](https://extendr.github.io/rextendr/articles/rmarkdown.md)
  for an example.

- `engine.opts`: A list of arguments passed to
  [`rust_eval()`](https://extendr.github.io/rextendr/reference/rust_eval.md)
  (for `extendr`) or
  [`rust_source()`](https://extendr.github.io/rextendr/reference/rust_source.md)
  (for `extendrsrc`), e.g.
  `engine.opts = list(dependencies = list(rand = "0.8"))`. The `env`
  argument defaults to
  [`knitr::knit_global()`](https://rdrr.io/pkg/knitr/man/knit_global.html).

- `eval`: If `FALSE`, the code is displayed but not compiled.

- `error`: If `TRUE`, a compilation error is shown in the document
  instead of stopping the render.
