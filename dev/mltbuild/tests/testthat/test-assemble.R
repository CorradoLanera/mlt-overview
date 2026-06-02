mk <- function(txt) parse_beat(strsplit(txt, "\n", fixed = TRUE)[[1]])

beats <- list(
  mk("# B0 ----\n# >>>hole id=a kind=fill prompt=p\n#   solved:\nx <- 0\n#   blank:\nx <- ___\n# <<<hole"),
  mk("# B1 ----\n# >>>hole id=b kind=fill prompt=p\n#   solved:\ny <- 1\n#   blank:\ny <- ___\n# <<<hole"),
  mk("# B2 ----\n# >>>hole id=c kind=fill prompt=p\n#   solved:\nz <- 2\n#   blank:\nz <- ___\n# <<<hole")
)

test_that("assemble_step n shows prior beats solved and beat n blank", {
  out <- assemble_step(beats, 2L)  # step index 2 (third beat)
  expect_true(all(c("x <- 0", "y <- 1") %in% out))   # 0..n-1 solved
  expect_true("z <- ___" %in% out)                    # beat n blank
  expect_false("z <- 2" %in% out)
})

test_that("assemble_step 0 has only the first beat blank", {
  out <- assemble_step(beats, 0L)
  expect_true("x <- ___" %in% out)
  expect_false(any(c("y <- 1", "y <- ___") %in% out))
})

test_that("assemble_full shows every beat solved", {
  out <- assemble_full(beats)
  expect_true(all(c("x <- 0", "y <- 1", "z <- 2") %in% out))
  expect_false(any(grepl("___", out)))
})

metas <- list(
  list(packages = character(0)),   # step 0
  list(packages = c("janitor")),   # step 1
  list(packages = c("janitor", "gtsummary"))  # step 2
)

test_that("packages_through gives the START state of step n = packages of beats 0..n-1", {
  expect_equal(packages_through(metas, 0L), character(0))            # step 0: nothing yet
  expect_equal(packages_through(metas, 1L), character(0))            # step 1: from beat 0 (empty)
  expect_setequal(packages_through(metas, 2L), c("janitor"))        # step 2: beats 0..1
})

test_that("assemble_step strips frag markers from prior solved beats", {
  fb <- list(
    parse_beat(c("# B0 ----", "x <- 0 |>", "  # >>>frag id=f", "  g()", "  # <<<frag")),
    parse_beat(c("# B1 ----", "# >>>hole id=h kind=fill prompt=p",
                 "#   solved:", "y <- 1", "#   blank:", "y <- ___", "# <<<hole"))
  )
  out <- assemble_step(fb, 1L)
  expect_false(any(grepl(">>>frag|<<<frag", out)))
  expect_true(all(c("x <- 0 |>", "  g()", "y <- ___") %in% out))
})

test_that("assemble_solved_through joins beats 0..n all solved, strips frags", {
  fb <- list(
    parse_beat(c("# B0 ----", "x <- 0 |>", "  # >>>frag id=f", "  g()", "  # <<<frag")),
    parse_beat(c("# B1 ----", "y <- 1")),
    parse_beat(c("# B2 ----", "z <- 2"))
  )
  out <- assemble_solved_through(fb, 1L)
  expect_true(all(c("x <- 0 |>", "  g()", "y <- 1") %in% out))   # 0..1 solved, frag inlined
  expect_false("z <- 2" %in% out)                                # beat 2 excluded
  expect_false(any(grepl(">>>frag|<<<frag", out)))               # markers stripped (now non-vacuous)
})
