library(tidyverse)
library(janitor)

# Wrangle ----
# >>>hole id=wrangle kind=fill prompt=clean names; drop the leaky time column; build the event-first outcome factor; factor the 0/1 flags
#   solved:
hf <- hf_raw |>
  # >>>frag id=wrangle-tail
  clean_names() |>
  select(-time) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "died", "survived"),
      levels = c("died", "survived"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor))
  # <<<frag
#   blank:
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
# <<<hole

glimpse(hf)

# Quick checks: 12 columns, a 2-level factor (event first), ~32% events.
ncol(hf)
levels(hf$outcome)
count(hf, outcome)
