fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("materialize_workshop writes step scripts, data-raw, .here, packages.txt, full", {
  out <- file.path(tempfile("wkout-"))
  wk <- read_workshop(fixroot)
  materialize_workshop(wk, out)

  # step 00 — first formative blank, no prior, packages.txt empty
  s0 <- readLines(file.path(out, "steps", "00-setup", "00-setup.R"))
  expect_true(any(grepl('read.csv\\(here::here\\("data-raw", "___"\\)\\)', s0)))
  expect_false(any(grepl('"toy.csv"', s0)))
  expect_true(file.exists(file.path(out, "steps", "00-setup", ".here")))
  expect_true(file.exists(file.path(out, "steps", "00-setup", "data-raw", "toy.csv")))
  expect_equal(readLines(file.path(out, "steps", "00-setup", "packages.txt")), character(0))

  # step 02 — prior beats solved, this beat blank (prose TODO), packages from 00..01
  s2 <- readLines(file.path(out, "steps", "02-eda", "02-eda.R"))
  expect_true(any(grepl('clean_names\\(toy\\)', s2)))    # beat 01 solved (prior)
  expect_true(any(grepl("# TODO: summarise the toy table", s2)))  # beat 02 blank (prose)
  expect_equal(readLines(file.path(out, "steps", "02-eda", "packages.txt")), "janitor")

  # full — all solved
  full <- readLines(file.path(out, "full", "full.R"))
  expect_true(any(grepl('"toy.csv"', full)))
  expect_false(any(grepl("___", full)))
})
