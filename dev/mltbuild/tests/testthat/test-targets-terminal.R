tarroot <- testthat::test_path("fixtures", "wktar", "_authoring")

test_that("engine:targets materializes _targets.R + report.qmd + R/, with holes BLANK for the student", {
  out <- tempfile("tarout-")
  wk  <- read_workshop(tarroot)
  materialize_workshop(wk, out)
  sd <- file.path(out, "steps", "01-pipe")
  expect_true(file.exists(file.path(sd, "_targets.R")))
  expect_true(file.exists(file.path(sd, "report.qmd")))
  expect_true(file.exists(file.path(sd, "R", "pipeline-fns.R")))
  tt <- readLines(file.path(sd, "_targets.R"))
  expect_true(any(grepl("___", tt)))                 # the tar_target hole is BLANK for the student
  expect_false(any(grepl(">>>hole", tt)))            # hole markers stripped, not shipped
  expect_false(file.exists(file.path(sd, "01-pipe.R")))   # no student .R for a transform step
})

test_that("engine:targets can render the SOLVED tree for the build (no blanks, no markers)", {
  wk  <- read_workshop(tarroot)
  td  <- tempfile("tarsolved-"); dir.create(td)
  .emit_targets_step(file.path(wk$authoring_dir, "01-pipe"), td, mode = "solved")
  tt  <- readLines(file.path(td, "_targets.R"))
  expect_false(any(grepl("___", tt)))                # solved: blanks filled
  expect_false(any(grepl(">>>hole", tt)))
  expect_true(file.exists(file.path(td, "R", "pipeline-fns.R")))
})
