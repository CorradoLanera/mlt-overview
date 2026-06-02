test_that("parse_beat splits literal text and a fill hole", {
  beat <- c(
    "# Setup ----",
    "# >>>hole id=load kind=fill prompt=load the toy data",
    "#   solved:",
    "x <- 1",
    "#   blank:",
    "x <- ___",
    "# <<<hole"
  )
  segs <- parse_beat(beat)
  expect_equal(length(segs), 2L)
  expect_equal(segs[[1]]$type, "text")
  expect_equal(segs[[1]]$lines, "# Setup ----")
  expect_equal(segs[[2]]$type, "hole")
  expect_equal(segs[[2]]$id, "load")
  expect_equal(segs[[2]]$kind, "fill")
  expect_equal(segs[[2]]$prompt, "load the toy data")
  expect_equal(segs[[2]]$solved, "x <- 1")
  expect_equal(segs[[2]]$blank, "x <- ___")
})

test_that("parse_beat handles prose holes (solved only)", {
  beat <- c(
    "# >>>hole id=summ kind=prose prompt=summarise it",
    "#   solved:",
    "summary(toy)",
    "# <<<hole"
  )
  segs <- parse_beat(beat)
  expect_equal(segs[[1]]$kind, "prose")
  expect_equal(segs[[1]]$solved, "summary(toy)")
  expect_equal(segs[[1]]$blank, character(0))
})

test_that("render_beat solved keeps solved lines", {
  beat <- c("# A ----",
            "# >>>hole id=h kind=fill prompt=p", "#   solved:", "x <- 1",
            "#   blank:", "x <- ___", "# <<<hole")
  out <- render_beat(parse_beat(beat), "solved")
  expect_equal(out, c("# A ----", "x <- 1"))
})

test_that("render_beat blank keeps blank lines", {
  beat <- c("# >>>hole id=h kind=fill prompt=p", "#   solved:", "x <- 1",
            "#   blank:", "x <- ___", "# <<<hole")
  expect_equal(render_beat(parse_beat(beat), "blank"), "x <- ___")
})

test_that("render_beat blank for prose emits a TODO", {
  beat <- c("# >>>hole id=h kind=prose prompt=do the thing", "#   solved:",
            "summary(x)", "# <<<hole")
  expect_equal(render_beat(parse_beat(beat), "blank"), "# TODO: do the thing")
  expect_equal(render_beat(parse_beat(beat), "solved"), "summary(x)")
})

test_that("render_beat blank for parsons reverses solved lines under a prompt", {
  beat <- c("# >>>hole id=h kind=parsons prompt=order these", "#   solved:",
            "step_one()", "step_two()", "# <<<hole")
  expect_equal(
    render_beat(parse_beat(beat), "blank"),
    c("# Reorder the lines to: order these", "step_two()", "step_one()")
  )
})
