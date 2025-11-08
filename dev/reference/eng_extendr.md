# Knitr engines

Two knitr engines that enable code chunks of type `extendr` (individual
Rust statements to be evaluated via
[`rust_eval()`](https://extendr.github.io/rextendr/dev/reference/rust_eval.md))
and `extendrsrc` (Rust functions or classes that will be exported to R
via
[`rust_source()`](https://extendr.github.io/rextendr/dev/reference/rust_source.md)).

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
