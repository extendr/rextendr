# CRAN compliant extendr packages

R packages developed using extendr are not immediately ready to be
published to CRAN. The extendr package template ensures that CRAN
publication is (farily) painless.

## CRAN requirements

In order to publish a Rust based package on CRAN it must meet certain
requirements. These are:

- Rust dependencies are vendored

- The package is compiled offline

- the `DESCRIPTION` file's `SystemRequirements` field contains
  `Cargo (Rust's package manager), rustc`

The extendr templates handle all of this *except* vendoring
dependencies. This must be done prior to publication using
[`vendor_pkgs()`](https://extendr.github.io/rextendr/dev/reference/vendor_pkgs.md).

In addition, it is important to make sure that CRAN maintainers are
aware that the package they are checking contains Rust code. Depending
on which and how many crates are used as a dependencies the
`vendor.tar.xz` will be larger than a few megabytes. If a built package
is larger than 5mbs CRAN may reject the submission.

To prevent rejection make a note in your `cran-comments.md` file (create
one using
[`usethis::use_cran_comments()`](https://usethis.r-lib.org/reference/use_cran_comments.html))
along the lines of "The package tarball is 6mb because Rust dependencies
are vendored within src/rust/vendor.tar.xz which is 5.9mb."
