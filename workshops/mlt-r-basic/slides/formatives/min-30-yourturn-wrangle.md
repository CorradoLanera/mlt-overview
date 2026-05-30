# Formative · min 30 · your-turn (after Step 01)

- **Type:** your-turn (compute + `{countdown}`, then my-turn live-solve)
- **Concept-graph node checked:** `IMPORT` — Import & tidy data (rio + janitor + dplyr/tidyr); `LEAK` — data leakage

## Prompt

Starting from the imported raw tibble `hf_raw`, build the analysis cohort with a
single `|>` chain:

1. `clean_names()` — snake_case the column names.
2. `select(-time)` — **drop the follow-up duration**: it leaks the outcome.
3. Make `outcome` a two-level factor with the **event first** (`"died"`,
   `"survived"`) from `death_event`, then drop `death_event`.
4. Make the 0/1 clinical flags (`anaemia, diabetes, high_blood_pressure, sex,
   smoking`) explicit factors.
5. `glimpse()` to confirm **12 columns** and the factor.

## Expected answer

```r
hf <- hf_raw |>
  clean_names() |>
  select(-time) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "died", "survived"),
      levels = c("died", "survived"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor)) |>
  glimpse()
```

Each verb takes the tibble as its first argument and returns a **new** tibble; the
chain never mutates `hf_raw` in place.

## Stretch (Davide)

Explain **why `time` is leakage**. `time` is the number of follow-up days *until the
death-or-censoring event* — it is partly a function of the outcome itself (patients
who die early have small `time`). A model handed `time` would "predict" death by
reading its own answer, scoring deceptively high in training and collapsing in
real prospective use. Dropping it *before* modelling is the first rule of honest
clinical prediction: a predictor must be knowable **at the moment you would predict**.
