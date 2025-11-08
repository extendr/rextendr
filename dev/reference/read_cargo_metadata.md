# Retrieve metadata for packages and workspaces

Retrieve metadata for packages and workspaces

## Usage

``` r
read_cargo_metadata(path = ".", dependencies = FALSE, echo = FALSE)
```

## Arguments

- path:

  character scalar, the R package directory

- dependencies:

  Default `FALSE`. A logical scalar, whether to include all recursive
  dependencies in stdout.

- echo:

  Default `FALSE`. A logical scalar, should cargo command and outputs be
  printed to the console.

## Value

A `list` including the following elements:

- `packages`

- `workspace_members`

- `workspace_default_members`

- `resolve`

- `target_directory`

- `version`

- `workspace_root`

- `metadata`

## Details

For more details, see [Cargo
docs](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) for
`cargo-metadata`. See especially "JSON Format" to get a sense of what
you can expect to find in the returned list.

## Examples

``` r
if (FALSE) { # \dontrun{
read_cargo_metadata()
} # }
```
