# Formative · min 31 · MCQ (after Step 01)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `IMPORT` — Import & tidy data (pipe / verb semantics)

## Prompt

You run `indo_raw |> clean_names() |> select(outcome, age) |> filter(!is.na(age))`.
Which statement best describes what happens?

## Options

- **A. ✓ (correct)** The tibble flows in as the **first argument** of each verb, and
  each verb returns a **brand-new copy** — `indo_raw` is unchanged until you assign
  the result.
- **B.** The verbs edit `indo_raw` **in place**, like Stata's `keep if` / `drop` —
  after running, `indo_raw` itself has fewer rows and columns.
- **C.** `select(outcome, age)` fails because `outcome` and `age` are not defined
  objects in the global environment.
- **D.** The pipe forwards the **last object you created** (not the left-hand side),
  so the chain operates on whatever was assigned most recently.

## Misconception each distractor reveals

- **B → "in-place mutation / Stata mental model."** Thinks dplyr verbs mutate the
  source like `keep if`/`drop`; misses that the pipeline is functional and returns a
  new object, leaving the input intact.
- **C → "non-standard evaluation (NSE) not understood."** Doesn't grasp that dplyr
  evaluates bare column names inside the data frame's scope (tidy/NSE), expecting
  them to be global variables instead.
- **D → "pipe forwards the last object, not the LHS."** Misreads `|>` as passing the
  most recently created object rather than the **left-hand-side value** into the
  **first argument** of the right-hand-side call.
