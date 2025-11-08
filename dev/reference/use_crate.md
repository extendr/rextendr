# Add dependencies to a Cargo.toml manifest file

Analogous to
[`usethis::use_package()`](https://usethis.r-lib.org/reference/use_package.html)
but for crate dependencies.

## Usage

``` r
use_crate(
  crate,
  features = NULL,
  git = NULL,
  version = NULL,
  optional = FALSE,
  path = ".",
  echo = TRUE
)
```

## Arguments

- crate:

  character scalar, the name of the crate to add

- features:

  character vector, a list of features to include from the crate

- git:

  character scalar, the full URL of the remote Git repository

- version:

  character scalar, the version of the crate to add

- optional:

  boolean scalar, whether to mark the dependency as optional (FALSE by
  default)

- path:

  character scalar, the package directory

- echo:

  logical scalar, should cargo command and outputs be printed to console
  (default is TRUE)

## Value

`NULL` (invisibly)

## Details

For more details regarding these and other options, see the [Cargo
docs](https://doc.rust-lang.org/cargo/commands/cargo-add.html) for
`cargo-add`.

## Examples

``` r
if (FALSE) { # \dontrun{
# add to [dependencies]
use_crate("serde")

# add to [dependencies] and [features]
use_crate("serde", features = "derive")

# add to [dependencies] using github repository as source
use_crate("serde", git = "https://github.com/serde-rs/serde")

# add to [dependencies] with specific version
use_crate("serde", version = "1.0.1")

# add to [dependencies] with optional compilation
use_crate("serde", optional = TRUE)
} # }
```
