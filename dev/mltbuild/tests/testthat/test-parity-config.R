test_that("parity_checks reads kw/imgs from each step's meta$check", {
  wk <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  ck <- parity_checks(wk)
  expect_true("02-eda" %in% names(ck))
  expect_equal(ck[["02-eda"]]$imgs, 0L)
  expect_true("janitor" %in% ck[["02-eda"]]$kw)
})
