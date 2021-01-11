.onLoad <- function(...) {
  # register the extendr knitr chunk engine if knitr is available
  if (requireNamespace("knitr", quietly = TRUE)) {
    knitr::knit_engines$set(
      extendr = eng_extendr,
      extendrfuns = eng_extendrfuns
    )
  }
}
