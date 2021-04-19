#' Knitr engines
#'
#' Two knitr engines that enable code chunks of type `extendr` (individual Rust
#' statements to be evaluated via [rust_eval()]) and `extendrsrc` (Rust functions
#' or classes that will be exported to R via [rust_source()]).
#' @param options A list of chunk options.
#' @return A character string representing the engine output.
#' @export
eng_extendr <- function(options) {
  eng_impl(options, rust_eval)
}

#' @rdname eng_extendr
#' @export
eng_extendrsrc <- function(options) {
  eng_impl(options, rust_source)
}



eng_impl <- function(options, rextendr_fun) {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    ui_throw("The knitr package is required to run the extendr chunk engine.")
  }

  if (!is.null(options$preamble)) {
    preamble <- knitr::knit_code$get(options$preamble)
    code <- c(
      lapply(options$preamble, function(x) knitr::knit_code$get(x)),
      recursive = TRUE
    )
    code <- c(code, options$code)
  } else {
    code <- options$code
  }

  code <- glue_collapse(code, sep = "\n") # code to compile
  code_out <- glue_collapse(options$code, sep = "\n") # code to output to html

  # engine.opts is a list of arguments to be passed to rust_eval, e.g.
  # engine.opts = list(dependencies = 'pulldown-cmark = "0.8"')
  opts <- options$engine.opts

  if (!is.environment(opts$env)) opts$env <- knitr::knit_global() # default env is knit_global()

  if (isTRUE(options$eval)) {
    ui_v("Evaluating Rust extendr code chunk...")
    out <- utils::capture.output({
      result <- withVisible(
        do.call(rextendr_fun, c(list(code = code), opts))
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
