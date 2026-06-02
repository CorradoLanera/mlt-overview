test_that("strip_frag_markers removes only marker lines, keeps enclosed code", {
  x <- c("a <- 1", "# >>>frag id=foo", "b <- 2", "# <<<frag", "c <- 3")
  expect_equal(strip_frag_markers(x), c("a <- 1", "b <- 2", "c <- 3"))
})

test_that("extract_fragment slices the named region (markers excluded)", {
  x <- c("head |>", "  # >>>frag id=tail", "  step_a() |>", "  step_b()", "  # <<<frag", "done")
  expect_equal(extract_fragment(x, "tail"), c("  step_a() |>", "  step_b()"))
})

test_that("extract_fragment errors on a missing id", {
  expect_error(extract_fragment(c("x <- 1"), "nope"), "fragment")
})

test_that("collect_fragments gathers frags across all beats (solved render)", {
  b1 <- parse_beat(c("# >>>hole id=h kind=fill prompt=p", "#   solved:",
                     "v <- 0 |>", "  # >>>frag id=tail", "  f()", "  # <<<frag",
                     "#   blank:", "v <- ___", "# <<<hole"))
  wk <- list(steps = list(list(beat = b1)))
  fr <- collect_fragments(wk)
  expect_equal(fr$tail, "  f()")
})
