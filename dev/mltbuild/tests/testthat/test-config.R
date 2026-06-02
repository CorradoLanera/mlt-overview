fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("read_workshop loads ordered steps with parsed beats and metas", {
  wk <- read_workshop(fixroot)
  expect_equal(wk$slug, "wkfix")
  expect_equal(length(wk$steps), 3L)
  expect_equal(vapply(wk$steps, function(s) s$slug, ""), c("00-setup", "01-import", "02-eda"))
  expect_equal(wk$steps[[2]]$meta$packages, "janitor")
  # beat parsed into segments:
  expect_true(any(vapply(wk$steps[[1]]$beat, function(s) s$type == "hole", logical(1))))
})
