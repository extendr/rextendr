# Silence `{cli}` output

Use for functions that use cli output that should optionally be
suppressed.

## Usage

``` r
local_quiet_cli(quiet, env = rlang::caller_env())
```

## Examples

``` r
if (interactive()) {
  hello_rust <- function(..., quiet = FALSE) {
    local_quiet_cli(quiet)
    cli::cli_alert_info("This should be silenced when {.code quiet = TRUE}")
  }

  hello_rust()
  hello_rust(quiet = TRUE)
}
```
