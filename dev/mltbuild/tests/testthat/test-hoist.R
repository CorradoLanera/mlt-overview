test_that("hoist_libraries lifts library() calls to top, first-appearance order, deduped", {
  x <- c("# A ----", "library(here)", "x <- 1", "library(dplyr)", "y <- 2", "library(here)", "z <- 3")
  expect_equal(hoist_libraries(x),
               c("library(here)", "library(dplyr)", "", "# A ----", "x <- 1", "y <- 2", "z <- 3"))
})

test_that("hoist_libraries leaves set.seed and other calls in place", {
  x <- c("library(a)", "set.seed(1)", "f()", "library(b)")
  expect_equal(hoist_libraries(x), c("library(a)", "library(b)", "", "set.seed(1)", "f()"))
})

test_that("hoist_libraries squeezes blank runs left by removed library lines + trims leading blank", {
  x <- c("", "library(a)", "library(b)", "", "code()")
  expect_equal(hoist_libraries(x), c("library(a)", "library(b)", "", "code()"))
})

test_that("hoist_libraries is a no-op when there are no library() calls", {
  x <- c("a <- 1", "b <- 2")
  expect_equal(hoist_libraries(x), x)
})

test_that("hoist_libraries de-indents and matches library() with args", {
  x <- c("  library(future)", "code()")
  expect_equal(hoist_libraries(x), c("library(future)", "", "code()"))
})
