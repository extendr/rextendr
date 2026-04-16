# Set up VS Code configuration for an rextendr project

This creates a `.vscode` folder (if needed) and populates it with a
`settings.json` template. If already exists, it will be updated to
include the `rust-analyzer.linkedProjects` setting.

## Usage

``` r
use_vscode(quiet = FALSE, overwrite = NULL)

use_positron(quiet = FALSE, overwrite = NULL)
```

## Arguments

- quiet:

  If `TRUE`, suppress messages.

- overwrite:

  If `TRUE`, overwrite existing files.

## Value

`TRUE` (invisibly) if the settings file was created or updated.

## Details

Rust-Analyzer VSCode extension looks for a `Cargo.toml` file in the
workspace root by default. This function creates a `.vscode` folder and
populates it with a `settings.json` file that sets the workspace root to
the `src` directory of the package. This allows you to open the package
directory in VSCode and have the Rust-Analyzer extension work correctly.
