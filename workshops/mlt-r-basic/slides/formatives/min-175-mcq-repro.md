# Formative · min 175 · MCQ (after Step 05)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `REPORT` — Rendered Quarto report (cached) + renv::snapshot; `PROJ`

## Prompt

A colleague should be able to reproduce **every number and figure** in your report on
their own machine. What actually makes that possible?

## Options

- **A. ✓ (correct)** The combination: a **pinned environment** (`renv` lockfile),
  **stable paths** (`here::here()`), a **fixed seed** (`set.seed`), and a **cached
  Quarto report** that re-renders the same artifacts deterministically. All four
  together.
- **B.** Just **email the script** — if they have the `.R`/`.qmd` file, they can run
  it and get the same results.
- **C.** Just call **`set.seed(123)`** — a fixed seed alone guarantees identical
  output on any machine.
- **D.** **Save the final number** (the test AUC) in a text file — storing the result
  is what "reproducible" means.

## Misconception each distractor reveals

- **B → "emailing the script is enough."** Ignores that the script depends on
  **package versions, file paths, and data** that differ across machines; code alone
  is not the environment.
- **C → "`set.seed` alone is enough."** A seed fixes the random stream but not the
  **package versions** or paths; a different `glmnet`/`ranger` version can still change
  the numbers.
- **D → "saving the final number = reproducible."** Confuses **recording** a result
  with being able to **re-derive** it; a stored number is not reproducible, it is just
  a value someone has to trust.
