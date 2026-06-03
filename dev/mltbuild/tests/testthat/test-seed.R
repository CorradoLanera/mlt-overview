# A minimal sibling-workshop pair built in temp dirs.
.make_seed_fixture <- function() {
  rootp <- tempfile("seedfix-"); dir.create(rootp)
  ws <- file.path(rootp, "workshops"); dir.create(ws)
  renv_src <- file.path(ws, "_renv"); dir.create(renv_src)
  writeLines("# fake activate", file.path(renv_src, "activate.R"))
  mk_step <- function(auth, slug, meta, beat = NULL) {
    d <- file.path(auth, slug); dir.create(d, recursive = TRUE)
    writeLines(meta, file.path(d, "meta.yml"))
    if (!is.null(beat)) writeLines(beat, file.path(d, "beat.R"))
  }
  # base workshop: 00 introduces pkgA; 01 introduces pkgB
  bauth <- file.path(ws, "wkbase", "_authoring"); dir.create(bauth, recursive = TRUE)
  dir.create(file.path(ws, "wkbase", "renv"))
  file.copy(file.path(renv_src, "activate.R"), file.path(ws, "wkbase", "renv", "activate.R"))
  dir.create(file.path(ws, "wkbase", "data-raw")); writeLines("x", file.path(ws, "wkbase", "data-raw", "d.csv"))
  writeLines(c("slug: wkbase", "r_version: \"4.6.0\"", "ppm_snapshot: \"2026-06-01\"",
               "dataset: data-raw/d.csv", "steps: [00-a, 01-b]"), file.path(bauth, "workshop.yml"))
  mk_step(bauth, "00-a", c("slug: 00-a", "title: A", "packages: [pkgA]"), c("library(pkgA)", "a_value <- 1"))
  mk_step(bauth, "01-b", c("slug: 01-b", "title: B", "packages: [pkgB]"), c("library(pkgB)", "b_value <- 2"))
  # downstream workshop: step 00 seeds from wkbase; step 01 is a normal append
  dauth <- file.path(ws, "wkdown", "_authoring"); dir.create(dauth, recursive = TRUE)
  dir.create(file.path(ws, "wkdown", "renv"))
  file.copy(file.path(renv_src, "activate.R"), file.path(ws, "wkdown", "renv", "activate.R"))
  dir.create(file.path(ws, "wkdown", "data-raw")); writeLines("x", file.path(ws, "wkdown", "data-raw", "d.csv"))
  writeLines(c("slug: wkdown", "r_version: \"4.6.0\"", "ppm_snapshot: \"2026-06-01\"",
               "dataset: data-raw/d.csv", "steps: [00-recap, 01-next]"), file.path(dauth, "workshop.yml"))
  mk_step(dauth, "00-recap", c("slug: 00-recap", "title: Recap", "seed_from: wkbase", "packages: [pkgWarm]"),
          c("library(pkgWarm)", "warm <- TRUE"))
  mk_step(dauth, "01-next", c("slug: 01-next", "title: Next", "packages: [pkgC]"), c("library(pkgC)", "c_value <- 3"))
  list(down_auth = dauth)
}

test_that("seed_from inlines the sibling's full into the seeded step", {
  fx  <- .make_seed_fixture()
  wk  <- read_workshop(fx$down_auth)
  out <- dirname(fx$down_auth)                       # the wkdown workshop dir
  materialize_workshop(wk, out)
  s0 <- readLines(file.path(out, "steps", "00-recap", "00-recap.R"))
  expect_true(any(grepl("a_value <- 1", s0)))        # base beat 00 solved, inlined
  expect_true(any(grepl("b_value <- 2", s0)))        # base beat 01 solved, inlined
  expect_true(any(grepl("warm <- TRUE", s0)))        # the recap's own beat, appended after the seed
  # the seed is PREPENDED: sibling content precedes the recap's own beat
  expect_lt(which(grepl("a_value <- 1", s0))[[1]], which(grepl("warm <- TRUE", s0))[[1]])
})

test_that("a seeded step 0 is a FULL renv project (not bare) and carries the unioned packages", {
  fx    <- .make_seed_fixture()
  wk    <- read_workshop(fx$down_auth)
  metas <- lapply(wk$steps, `[[`, "meta")
  expect_setequal(packages_for_step(metas, 0L), c("pkgA", "pkgB", "pkgWarm"))
  out <- dirname(fx$down_auth)
  materialize_workshop(wk, out)
  s0 <- file.path(out, "steps", "00-recap")
  expect_true(file.exists(file.path(s0, ".Rprofile")))           # NOT bare
  expect_true(file.exists(file.path(s0, "renv", "activate.R")))
})
