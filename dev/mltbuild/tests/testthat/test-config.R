fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("read_workshop loads ordered steps with parsed beats and metas", {
  wk <- read_workshop(fixroot)
  expect_equal(wk$slug, "wkfix")
  expect_equal(length(wk$steps), 4L)
  expect_equal(vapply(wk$steps, function(s) s$slug, ""), c("00-setup", "01-import", "02-eda", "03-report"))
  expect_equal(wk$steps[[2]]$meta$packages, "janitor")
  # beat parsed into segments:
  expect_true(any(vapply(wk$steps[[1]]$beat, function(s) s$type == "hole", logical(1))))
})

test_that("read_workshop resolves data_raw_dir, preferring authoring/data-raw", {
  wk <- read_workshop(fixroot)
  expect_equal(normalizePath(wk$data_raw_dir),
               normalizePath(file.path(fixroot, "data-raw")))
})

test_that("read_workshop loads a transform-terminal template instead of beat.R", {
  wk <- read_workshop(fixroot)
  rep_step <- Filter(function(s) s$meta$type == "transform-terminal", wk$steps)[[1]]
  expect_equal(rep_step$meta$type, "transform-terminal")
  expect_true(length(rep_step$beat) == 0L)               # no append beat
  expect_true(any(grepl("\\{\\{frag:", rep_step$template)))  # template carries tokens
})
