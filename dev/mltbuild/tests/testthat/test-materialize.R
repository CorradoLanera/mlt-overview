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

test_that("materialize_workshop preserves _authoring/ and data-raw/ at the out_dir root", {
  out <- tempfile("wkout-")
  dir.create(file.path(out, "_authoring"), recursive = TRUE)
  writeLines("sentinel", file.path(out, "_authoring", "keep.txt"))
  dir.create(file.path(out, "data-raw"), recursive = TRUE)
  writeLines("a,b\n1,2", file.path(out, "data-raw", "toy.csv"))
  # a stale generated subtree that MUST be wiped + rebuilt:
  dir.create(file.path(out, "steps", "stale"), recursive = TRUE)
  writeLines("old", file.path(out, "steps", "stale", "old.R"))

  wk <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  materialize_workshop(wk, out)

  expect_true(file.exists(file.path(out, "_authoring", "keep.txt")))   # source untouched
  expect_true(file.exists(file.path(out, "data-raw", "toy.csv")))      # source untouched
  expect_false(dir.exists(file.path(out, "steps", "stale")))           # stale subtree gone
  expect_true(dir.exists(file.path(out, "steps", "00-setup")))         # rebuilt
})

test_that("materialize writes a substituted report.qmd for transform-terminal steps (no .R)", {
  out <- tempfile("wkout-")
  wk  <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  materialize_workshop(wk, out)

  rep_dir <- file.path(out, "steps", "03-report")
  expect_true(file.exists(file.path(rep_dir, "report.qmd")))
  expect_false(file.exists(file.path(rep_dir, "03-report.R")))   # transform: no student .R
  rq <- readLines(file.path(rep_dir, "report.qmd"))
  expect_true(any(grepl("clean_names\\(toy\\)", rq)))            # token substituted
  expect_false(any(grepl("\\{\\{frag:", rq)))                    # no leftover tokens
  # append steps still produce their .R:
  expect_true(file.exists(file.path(out, "steps", "02-eda", "02-eda.R")))
})
