# rextendr design prinicples

This guide documents important internal coding conventions used in rextendr.

## Communicating with the user

rextendr uses the cli package to format messages to the user, which are generally then routed through `rlang::inform()`. Most UI will happen through `ui_*()` functions:

| function | purpose                                                                                                       |
|----------|---------------------------------------------------------------------------------------------------------------|
| `cli::cli_alert_success()` | communicate that rextendr has done something successfully, such as wrote a file                               |
| `cli::cli_alert_info()` | provide extra information to the user                                                                         |
| `cli::cli_alert_warning()` | warn the user about something (note: this is still condition of class `message`, not `warning`)               |
| `cli::cli_ul()` | indicate that the user has something to do                                                                    |
| `cli::cli_alert_danger()` | tell the user that something has gone wrong (note: this still is a condition of class `message`, not `error`) |



[`{cli}`](https://cli.r-lib.org/) supports [glue-based interpolation](https://cli.r-lib.org/articles/semantic-cli.html#interpolation) and [inline text formatting](https://cli.r-lib.org/articles/semantic-cli.html#inline-text-formatting). 

## Throwing and testing errors

Pass all errors via `cli::cli_abort()`. Ensure that the class `rextendr_error` is specified. You can also add details by providing a named vector. See `?cli::cli_abort()` and `?cli::cli_bulelts()` for the `message` argument. 

```r
cli::cli_abort(
  c(
    "Unable to register the extendr module.",
    "x" = "Could not find file {.file src/entrypoint.c}.",
    "*" = "Are you sure this package is using extendr Rust code?"
  ),
  class = "rextendr_error"
)
```

## Silencing messages 

`{cli}` is used to verbosely inform the user. The user should be able to optionally silence functions that have particularly verbose output by setting `quiet` argument to `TRUE`—see `?rust_source` for example. 

Silencing `cli` output should be done with the helper `local_quiet_cli(quiet)`. When `quiet = TRUE` all, `cli` output is suppressed.
