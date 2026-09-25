#' Knitr engines
#'
#' Two knitr engines that enable code chunks of type `extendr` (individual Rust
#' statements to be evaluated via [rust_eval()]) and `extendrsrc` (Rust functions
#' or classes that will be exported to R via [rust_source()]).
#'
#' @param options A list of chunk options.
#' @return A character string representing the engine output.
#'
#' @details
#' Both engines support the following chunk options:
#'
#' * `preamble`: A character vector of chunk labels. The code from those chunks
#'   is placed before the current chunk's code, in the order given, and the
#'   combined code is compiled as a single unit. Only the current chunk's code
#'   is shown in the output. This is useful for splitting Rust code across
#'   several chunks, for example defining helper functions in one chunk
#'   (typically with `eval = FALSE`) and calling them in another. Unlike
#'   knitr's `ref.label` option, which shows the reused code in the rendered
#'   document, `preamble` adds the code to the compile unit without displaying
#'   it. See `vignette("rmarkdown", package = "rextendr")` for an example.
#' * `engine.opts`: A list of arguments passed to [rust_eval()] (for `extendr`)
#'   or [rust_source()] (for `extendrsrc`), e.g.
#'   `engine.opts = list(dependencies = list(rand = "0.8"))`. The `env` argument
#'   defaults to [knitr::knit_global()].
#' * `eval`: If `FALSE`, the code is displayed but not compiled.
#' * `error`: If `TRUE`, a compilation error is shown in the document instead of
#'   stopping the render.
#'
#' @export
eng_extendr <- function(options) {
  eng_impl(options, rust_eval_deferred)
}

#' @rdname eng_extendr
#' @export
eng_extendrsrc <- function(options) {
  eng_impl(options, rust_source)
}

eng_impl <- function(options, extendr_engine) {
  rlang::check_installed("knitr")

  # code to output to html
  code_out <- glue_collapse(options$code, sep = "\n")

  # wrap up source code in rust syntax
  options$engine <- "rust"

  # default chunk output
  out <- ""
  # skip compilation when eval is false
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, code_out, out))
  }

  # code to compile
  if (!rlang::is_null(options$preamble)) {
    code <- c(unlist(knitr::knit_code$get(options$preamble)), options$code)
  } else {
    code <- options$code
  }
  code <- glue_collapse(code, sep = "\n")

  # engine.opts is a list of arguments to be passed to rust_eval, e.g.
  # engine.opts = list(dependencies = list(`pulldown-cmark` = "0.8"))
  opts <- options$engine.opts

  # default env is knit_global()
  if (!rlang::is_environment(opts$env)) {
    opts$env <- knitr::knit_global()
  }

  # try to compile
  cli::cli_alert_success("Compiling Rust extendr code chunk...")
  compiled_code <- rlang::try_fetch(
    do.call(extendr_engine, c(list(code = code), opts)),
    system_command_status_error = function(cnd) {
      if (!isTRUE(options$error)) {
        rlang::cnd_signal(cnd)
      }
      cnd
    }
  )

  # if compilation succeeded (and code should be evaluated)
  if (rlang::is_function(compiled_code)) {
    cli::cli_alert_success("Evaluating Rust extendr code chunk...")
    out <- utils::capture.output({
      result <- withVisible(
        compiled_code()
      )
      if (isTRUE(result$visible)) {
        print(result$value)
      }
    })
  }

  # if compilation failed (and error message should be printed)
  if (rlang::inherits_any(compiled_code, "system_command_status_error")) {
    out <- cli::ansi_strip(compiled_code$stderr)
  }

  knitr::engine_output(options, code_out, out)
}
