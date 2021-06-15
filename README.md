
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Call Rust code from R <img width="120px" alt="rextendr logo" align="right" src="man/figures/rextendr-logo.png">

<!-- badges: start -->

[![R build
status](https://github.com/extendr/rextendr/workflows/R-CMD-check/badge.svg)](https://github.com/extendr/rextendr/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/rextendr)](https://CRAN.R-project.org/package=rextendr)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

## Installation

To install the package, run:

``` r
remotes::install_github("extendr/rextendr")
```

Note that this will install the package but does not guarantee that the
package can do anything useful. You will also need to set up a working
Rust toolchain. See the [installation instructions for
libR-sys](https://github.com/extendr/libR-sys) for help. If you can
successfully build libR-sys you’re good.

## Usage

Basic use example:

``` r
library(rextendr)

# create a Rust function
rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")

# call it from R
add(2.5, 4.7)
#> [1] 7.2
```

The package also enables a new chunk type for knitr, `extendr`, which
compiles and evaluates Rust code. For example, a code chunk such as this
one:

```` markdown
```{extendr}
rprintln!("Hello from Rust!");

let x = 5;
let y = 7;
let z = x*y;

z
```
````

would create the following output in the knitted document:

``` rust
rprintln!("Hello from Rust!");

let x = 5;
let y = 7;
let z = x*y;

z
#> Hello from Rust!
#> [1] 35
```

------------------------------------------------------------------------

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/extendr/rextendr/blob/main/CODE-OF-CONDUCT.md).
By participating in this project you agree to abide by its terms.
