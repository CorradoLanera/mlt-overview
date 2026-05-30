# Your turn — Step 01: wrangle the raw trial table into a modelling tibble.
#
# Start from `indo_raw` and build `indo` with a single pipe:
#   1. clean the column names,
#   2. keep ONLY the outcome and the six predictors,
#   3. drop rows with a missing age,
#   4. make `outcome` an explicit two-level factor (no event first).
#
# Fill the ___ blanks, then run a glimpse() to check 7 columns and the factor.

indo <- indo_raw |>
  clean_names() |>
  select(___) |>
  filter(!is.na(___)) |>
  mutate(outcome = factor(outcome, levels = c("___", "___")))

glimpse(indo)
