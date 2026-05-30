# Formative · min 30 · your-turn (after Step 01)

- **Type:** your-turn (compute + `{countdown}`, then my-turn live-solve)
- **Concept-graph node checked:** `IMPORT` — Import & tidy data (rio + janitor + dplyr/tidyr)

## Prompt

Starting from the imported raw tibble, build the analysis cohort with a single
`|>` chain:

1. `clean_names()` — snake_case the column names.
2. `select()` the **7 modelling columns** (`outcome, age, risk, gender, sod, rx, type`).
3. `filter()` out the rows with **`NA` in `age`**.
4. `glimpse()` the result to confirm the shape.

## Expected answer

```r
indo <- indo_raw |>
  clean_names() |>
  select(outcome, age, risk, gender, sod, rx, type) |>
  filter(!is.na(age)) |>
  glimpse()
```

Each verb takes the tibble as its first argument and returns a **new** tibble; the
chain never mutates `indo_raw` in place.

## Stretch (Davide)

Add a `high_risk` indicator from the **median of `risk`** — but compute the median
**on the training set only**, never on the full data. Using the whole-data median
(or the test set) leaks information from test into train, inflating the optimism
later. This is the first taste of *data leakage* and why the split must come before
any data-dependent transformation.
