# Formative · min 46 · MCQ (after Step 01, SHAP parameter slide)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `PARAMS_I` — SHAP params: background size / which rows / exact-vs-sampling

## Prompt

In `kernelshap`, which two knobs govern the **variance-vs-cost trade-off** of the
SHAP estimates?

## Options

- **A. ✓ (correct)** The **size of `bg_X`** (the background dataset) and the
  **sampling effort** (number of coalitions evaluated per observation): a larger
  background and more sampling iterations give lower-variance estimates at higher
  computational cost. Using a tiny background (e.g. 30–50 rows) for live
  demonstration is deliberate — it trades some precision for speed.
- **B.** A **smaller background is more accurate**: restricting `bg_X` to the
  most representative rows focuses the explainer and reduces noise.
- **C.** The **number of sampling iterations equals the number of features** in the
  dataset — it is fixed by the data, not a tunable parameter.
- **D.** The **background only matters for tree-based models**: for logistic
  regression or neural networks, `bg_X` is ignored because those models do not
  split on feature values.

## Misconception each distractor reveals

- **B → "smaller background = more accurate."** Inverts the variance direction:
  a smaller background means fewer reference points for the conditional expectation
  estimate, which *increases* variance. The precision-cost trade-off runs in the
  other direction.
- **C → "sampling iterations are fixed by the data."** Treats the number of
  coalitions as a deterministic property of the feature set rather than a
  user-controlled parameter; misses that the default is a heuristic that can be
  overridden to improve precision at a cost.
- **D → "background only matters for trees."** Confuses tree-specific path-dependent
  methods (e.g. TreeSHAP) with kernel SHAP, which uses the background as a
  **universal baseline** for the conditional expectation regardless of model family.
