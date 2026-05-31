# Formative · min 88 · MCQ (after Step 03, pre-break)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `ENGINE` — Engine-swap idiom (one line = new algorithm); `MODEL` (parsnip)

## Prompt

You built a logistic-regression workflow. To turn it into a **random forest**
workflow on the *same* data, what is the **minimal** change?

## Options

- **A. ✓ (correct)** Change **only the model spec** — swap
  `logistic_reg() |> set_engine("glm")` for
  `rand_forest() |> set_engine("ranger")`. The split, recipe, and workflow scaffold
  stay exactly the same.
- **B.** Rewrite the **recipe and the train/test split** to suit the new algorithm,
  because each algorithm needs its own preprocessing pipeline and its own data split.
- **C.** Abandon the tidymodels scaffold and go back to the algorithm's
  **package-specific function** (e.g. call `ranger::ranger()` directly with its own
  formula and arguments).
- **D.** Keep `logistic_reg()` and just change `set_mode()` from `"classification"`
  to `"regression"` to get the random forest behaviour.

## Misconception each distractor reveals

- **B → "rewrite recipe/split per algorithm."** Misses that the **preprocessing and
  split are model-agnostic** in tidymodels; thinks each algorithm demands a bespoke
  pipeline, defeating the engine-swap idiom.
- **C → "back to package-specific functions."** Doesn't see that `parsnip` provides a
  **unified front-end**; reverts to calling each modelling package directly, losing
  the one-line swap and the shared workflow.
- **D → "confuses MODE with ENGINE."** Conflates the **model type / engine** (which
  algorithm) with the **mode** (classification vs regression); changing the mode does
  not change the algorithm to a random forest.
