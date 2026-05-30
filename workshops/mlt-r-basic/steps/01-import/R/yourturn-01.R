# Your turn — Step 01: wrangle the raw heart-failure table into a modelling tibble.
#
# Start from `hf_raw` and build `hf` with a single pipe:
#   1. clean the column names,
#   2. DROP `time` (follow-up days) — it leaks the outcome,
#   3. turn `death_event` into a two-level factor `outcome` with the EVENT FIRST
#      ("died", "survived"), then drop the original `death_event`,
#   4. make the 0/1 clinical flags (anaemia, diabetes, high_blood_pressure, sex,
#      smoking) explicit factors.
#
# Fill the ___ blanks, then glimpse() to check 12 columns and the factor.

hf <- hf_raw |>
  clean_names() |>
  select(-___) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "___", "___"),
      levels = c("___", "___"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), ___))

glimpse(hf)
