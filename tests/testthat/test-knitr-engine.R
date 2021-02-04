test_that("knitr-engine works", {
  options <- knitr::opts_chunk$merge(list(
    code = "2 + 2",
    comment = "##",
    eval = TRUE,
    echo = TRUE
  ))

  expect_equal(eng_extendr(options), "2 + 2\n## [1] 4\n")

  options <- knitr::opts_chunk$merge(list(
    code = "rprintln!(\"hello world!\");",
    comment = "##",
    eval = TRUE,
    echo = FALSE
  ))

  expect_equal(eng_extendr(options), "## hello world!\n")
})
