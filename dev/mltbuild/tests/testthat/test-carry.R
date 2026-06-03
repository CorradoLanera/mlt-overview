fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("carry: copies the file into its own step and every downstream step + full", {
  out <- tempfile("carryout-")
  wk  <- read_workshop(fixroot)
  materialize_workshop(wk, out)
  # declared at 01-import -> present from 01 onward + full, absent at 00-setup
  expect_false(file.exists(file.path(out, "steps", "00-setup", "R", "helper.R")))
  expect_true(file.exists(file.path(out, "steps", "01-import", "R", "helper.R")))
  expect_true(file.exists(file.path(out, "steps", "02-eda",   "R", "helper.R")))
  expect_true(file.exists(file.path(out, "full", "R", "helper.R")))
  expect_equal(readLines(file.path(out, "full", "R", "helper.R")), "helper <- function() 42L")
})
