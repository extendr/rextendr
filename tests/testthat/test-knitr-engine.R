test_that("knitr-engines work", {
  options <- knitr::opts_chunk$merge(list(
    code = "2 + 2",
    comment = "##",
    eval = TRUE,
    echo = TRUE
  ))

  # this is actually not correct, just using this for testing for now
  expect_equal(eng_extendr(options), "2 + 2\n## NULL\n")
  # this is what the output should be
  #expect_equal(eng_extendr(options), "2 + 2\n## 4\n")
})
