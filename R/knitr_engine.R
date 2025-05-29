#' Knitr engines
#'
#' Two knitr engines that enable code chunks of type `extendr` (individual Rust
#' statements to be evaluated via [rust_eval()]) and `extendrsrc` (Rust functions
#' or classes that will be exported to R via [rust_source()]).
#' @param options A list of chunk options.
#' @return A character string representing the engine output.
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
  if (!requireNamespace("knitr", quietly = TRUE)) {
    cli::cli_abort(
      "The {.pkg knitr} package is required to run the extendr chunk engine.",
      class = "rextendr_error"
    )
  }

  if (!is.null(options$preamble)) {
    code <- c(
      lapply(options$preamble, function(x) knitr::knit_code$get(x)),
      recursive = TRUE
    )
    code <- c(code, options$code)
  } else {
    code <- options$code
  }

  code <- paste0(code, collapse = "\n") # code to compile
  code_out <- paste0(options$code, collapse = "\n") # code to output to html

  # engine.opts is a list of arguments to be passed to rust_eval, e.g.
  # engine.opts = list(dependencies = list(`pulldown-cmark` = "0.8"))
  opts <- options$engine.opts

  if (!is.environment(opts$env)) {
    # default env is knit_global()
    opts$env <- knitr::knit_global()
  }

  cli::cli_alert_success("Compiling Rust extendr code chunk...")
  compiled_code <- do.call(extendr_engine, c(list(code = code), opts))

  if (isTRUE(options$eval) && rlang::is_function(compiled_code)) {
    cli::cli_alert_success("Evaluating Rust extendr code chunk...")

    out <- utils::capture.output({
      result <- withVisible(
        compiled_code()
      )
      if (isTRUE(result$visible)) {
        print(result$value)
      }
    })
  } else {
    out <- ""
  }

  options$engine <- "rust" # wrap up source code in rust syntax
  knitr::engine_output(options, code_out, out)
}
