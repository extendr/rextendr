#' Knitr engines
#'
#' Two knitr engines that enable code chunks of type `extendr` (individual Rust
#' statements to be evaluated) and `extendrfuns` (Rust functions that will be
#' exported to R).
#' @param options A list of chunk options.
#' @return A character string representing the engine output.
#' @export
eng_extendr <- function(options) {
  eng_impl(options, rust_eval)
}

#' @rdname eng_extendr
#' @export
eng_extendrfuns <- function(options) {
  eng_impl(options, rust_source)
}



eng_impl <- function(options, rextendr_fun) {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    stop("The knitr package is required to run the extendr chunk engine.", call. = TRUE)
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

  code <- glue::glue_collapse(code, sep = "\n") # code to compile
  code_out <- glue::glue_collapse(options$code, sep = "\n") # code to output to html

  # engine.opts is a list of arguments to be passed to rust_eval, e.g.
  # engine.opts = list(dependencies = 'pulldown-cmark = "0.8"')
  opts <- options$engine.opts

  if (!is.environment(opts$env)) opts$env <- knitr::knit_global() # default env is knit_global()

  if (isTRUE(options$eval)) {
    message('Evaluating Rust extendr code chunk...')
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
