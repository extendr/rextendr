# rextendr design prinicples

This guide documents important internal coding conventions used in rextendr.

## Communicating with the user

rextendr uses the cli package to format messages to the user, which are generally then routed through `rlang::inform()`. Most UI will happen through `ui_*()` functions:

| function | purpose                                                                                                       |
|----------|---------------------------------------------------------------------------------------------------------------|
| `ui_v()` | communicate that rextendr has done something successfully, such as write a file                               |
| `ui_i()` | provide extra information to the user                                                                         |
| `ui_w()` | warn the user about something (note: this is still condition of class `message`, not `warning`)               |
| `ui_o()` | indicate that the user has something to do                                                                    |
| `ui_x()` | tell the user that something has gone wrong (note: this still is a condition of class `message`, not `error`) |

Each `ui_*()` function has a corresponding `bullet_*()` function that formats text to use in the message. 

Because each `ui_*()` and `bullet_*()` function is processed through cli, they support [glue-based interpolation](https://cli.r-lib.org/articles/semantic-cli.html#interpolation) and [inline text formatting](https://cli.r-lib.org/articles/semantic-cli.html#inline-text-formatting).

## Throwing and testing errors

Pass all errors via `ui_throw()`. You can also add additional details via the `details` argument. This can be a good place to provide more information with `bullet_*()` functions, e.g.

```r
ui_throw(
  "Unable to register the extendr module.",
  details = c(
    bullet_x("Could not find file {.file src/entrypoint.c }."),
    bullet_o("Are you sure this package is using extendr Rust code?")
  )
)
```

`ui_throw()` emits an error of class `rextendr_error`. This makes it easier to know that an error is coming from rextendr. It also allows downstream users to catch and handle rextendr errors more easily with `tryCatch(..., rextender_error = function(re) ...)`

To test for errors from rextendr, use `expect_rextendr_error()`
