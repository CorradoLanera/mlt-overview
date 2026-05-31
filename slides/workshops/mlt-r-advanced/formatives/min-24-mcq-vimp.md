# Formative · min 24 · MCQ (after Step 01, VIMP slide)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `VIMP` — Permutation VIMP via vip

## Prompt

The permutation-importance plot for the random forest places **`ejection_fraction`**
and **`serum_creatinine`** at the top. What does that score actually measure?

## Options

- **A. ✓ (correct)** Permuting a predictor's values breaks its relationship with
  the outcome; the **drop in AUC-ROC** measures how much the model **relies on**
  that predictor to discriminate. A high score means the model cannot do without it —
  not that the predictor causes the outcome.
- **B.** A high importance score means `ejection_fraction` **causes** heart failure
  death — variables the model relies on are the ones that drive the disease.
- **C.** Permutation importance is a **signed coefficient**: positive importance means
  higher `ejection_fraction` raises the predicted risk; negative means it lowers it.
- **D.** Importance is equivalent to a **p-value from a significance test**: a score
  above a threshold means the predictor is statistically significant in the model.

## Misconception each distractor reveals

- **B → "importance = causation."** Confuses predictive reliance with causal
  effect; permutation importance says nothing about the data-generating mechanism —
  it only quantifies the model's dependence on the variable.
- **C → "importance = signed coefficient."** Projects the linear-model idea of a
  signed regression weight onto a permutation-based, tree-ensemble score that has
  neither sign nor additive interpretation.
- **D → "importance = p-value."** Conflates a predictive performance measure with
  a frequentist test statistic; permutation importance does not come from a null
  hypothesis and has no associated p-value.
