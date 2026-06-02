test_that("render_report substitutes a frag token, preserving fragment indentation", {
  template <- c("hf <- import(x) |>", "{{frag:wrangle-tail}}", "", "summary(hf)")
  frags <- list(`wrangle-tail` = c("  clean_names() |>", "  select(-time)"))
  out <- render_report(template, frags)
  expect_equal(out, c("hf <- import(x) |>", "  clean_names() |>", "  select(-time)",
                      "", "summary(hf)"))
})

test_that("render_report errors on an unknown token", {
  expect_error(render_report("{{frag:nope}}", list()), "nope")
})

test_that("render_report leaves non-token lines untouched", {
  expect_equal(render_report(c("a", "b"), list()), c("a", "b"))
})
