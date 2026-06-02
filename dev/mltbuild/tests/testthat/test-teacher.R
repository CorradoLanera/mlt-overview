test_that("build_teacher_qmd wraps blank (verbatim) and solved (executed) tabs", {
  out <- build_teacher_qmd("Step 01 — Import", c("y <- ___"), c("y <- 1"))
  expect_true(any(grepl("^title:", out)))
  expect_true(any(grepl("embed-resources: true", out)))
  expect_true(any(grepl("^::: \\{\\.panel-tabset\\}$", out)))
  expect_true(any(grepl("^## To fill$", out)))
  expect_true(any(grepl("^## Solved$", out)))
  # blank is a NON-executed ```r block; solved is an executed ```{r} chunk:
  expect_true(any(out == "```r"))
  expect_true(any(out == "```{r}"))
  expect_true(any(out == "y <- ___"))
  expect_true(any(out == "y <- 1"))
  expect_true(any(out == ":::"))
})
