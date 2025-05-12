
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Call Rust code from R <img width="120px" alt="rextendr logo" align="right" src="man/figures/rextendr-logo.png">

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/rextendr)](https://CRAN.R-project.org/package=rextendr)
[![rextendr status
badge](https://extendr.r-universe.dev/badges/rextendr)](https://extendr.r-universe.dev/rextendr)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R build
status](https://github.com/extendr/rextendr/workflows/R-CMD-check/badge.svg)](https://github.com/extendr/rextendr/actions)
[![Codecov test
coverage](https://codecov.io/gh/extendr/rextendr/graph/badge.svg)](https://app.codecov.io/gh/extendr/rextendr)
<!-- badges: end -->

## Installation

To install release version from CRAN, run:

``` r
install.packages("rextendr")
```

or use `{remotes}`

``` r
remotes::install_cran("rextendr")
```

You can also install `{rextendr}` from
[r-universe](https://extendr.r-universe.dev/rextendr):

``` r
install.packages("rextendr", repos = c("https://extendr.r-universe.dev", "https://cloud.r-project.org"))
```

Latest development version can be installed from GitHub:

``` r
remotes::install_github("extendr/rextendr")
```

To execute Rust code, you will also need to set up a working Rust
toolchain. See the [installation instructions for
libR-sys](https://github.com/extendr/libR-sys) for help. If you can
successfully build libR-sys you’re good.

## Usage

### Sitrep

A good first step is to check the status of Rust toolchain and available
targets using `rust_sitrep()`. If everything is OK, you should see
something like this:

``` r
rust_sitrep()
# Rust infrastructure sitrep:
# ✔ "rustup": 1.26.0 (5af9b9484 2023-04-05)
# ✔ "cargo": 1.72.0 (103a7ff2e 2023-08-15)
# ℹ host: x86_64-pc-windows-msvc
# ℹ toolchain: stable-x86_64-pc-windows-msvc (default)
# ℹ target: x86_64-pc-windows-gnu
```

If, for instance, no toolchain is found, you will see something like
this:

``` r
rust_sitrep()
# Rust infrastructure sitrep:
# ✔ "rustup": 1.26.0 (5af9b9484 2023-04-05)
# ✔ "cargo": 1.72.0 (103a7ff2e 2023-08-15)
# ℹ host: x86_64-pc-windows-msvc
# ! Toolchain stable-x86_64-pc-windows-msvc is required to be installed and set as default
# ℹ Run `rustup toolchain install stable-x86_64-pc-windows-msvc` to install it
# ℹ Run `rustup default stable-x86_64-pc-windows-msvc` to make it default
```

Finally, if you are missing the required target (on all platforms but
Windows `{rextendr}` uses default target), the report will resemble the
following:

``` r
rust_sitrep()
# Rust infrastructure sitrep:
# ✔ "rustup": 1.26.0 (5af9b9484 2023-04-05)
# ✔ "cargo": 1.72.0 (103a7ff2e 2023-08-15)
# ℹ host: x86_64-pc-windows-msvc
# i toolchains: nightly-x86_64-pc-windows-msvc and stable-x86_64-pc-windows-msvc (default)
# i targets: x86_64-pc-windows-msvc and i686-pc-windows-msvc
# ! Target x86_64-pc-windows-gnu is required on this host machine
# i Run `rustup target add x86_64-pc-windows-gnu` to install it
```

### Code examples

Basic use example:

``` r
library(rextendr)

# create a Rust function
rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")

# call it from R
add(2.5, 4.7)
#> [1] 7.2
```

Something more sophisticated:

``` r
library(rextendr)

# Rust function that computes a sum of integer or double vectors, preserving the type

rust_function(
  "fn get_sum(x : Either<Integers, Doubles>) -> Either<Rint, Rfloat> {
      match x {
          Either::Left(x) => Either::Left(x.iter().sum()),
          Either::Right(x) => Either::Right(x.iter().sum()),
      }
  }",
  use_dev_extendr = TRUE, # Use development version of extendr from GitHub
  features = "either", # Enable support for Either crate
)

x <- 1:5
y <- c(1, 2, 3, 4, 5)

tibble::tibble(
  Name = c("x", "y"),
  Data = list(x, y),
  Types = purrr::map_chr(Data, typeof),
  Sum = purrr::map(Data, get_sum),
  SumRaw = purrr::flatten_dbl(Sum),
  ResultType = purrr::map_chr(Sum, typeof)
)
#> # A tibble: 2 × 6
#>   Name  Data      Types   Sum       SumRaw ResultType
#>   <chr> <list>    <chr>   <list>     <dbl> <chr>     
#> 1 x     <int [5]> integer <int [1]>     15 integer   
#> 2 y     <dbl [5]> double  <dbl [1]>     15 double
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

## See also

- The [cargo-framework](https://github.com/dbdahl/cargo-framework) and
  associated R package [cargo](https://cran.r-project.org/package=cargo)
- The [r-rust](https://github.com/r-rust) organization

------------------------------------------------------------------------

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/extendr/rextendr/blob/main/CODE-OF-CONDUCT.md).
By participating in this project you agree to abide by its terms.
