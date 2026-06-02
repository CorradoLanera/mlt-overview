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
