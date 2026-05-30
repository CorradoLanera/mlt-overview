# Formative · min 50 · MCQ (after Step 02)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `METRIC` — Metrics / ROC-AUC (yardstick); motivated by `OUT` (imbalanced outcome)

## Prompt

The outcome (post-ERCP pancreatitis) occurs in about **13%** of patients. Why do we
plan to compare models by **ROC-AUC** rather than **accuracy**?

## Options

- **A. ✓ (correct)** With ~13% events, a model that **always predicts "no"** scores
  ~87% accuracy yet is **clinically useless** (it never flags a single at-risk
  patient). ROC-AUC measures how well the model **ranks** risk across thresholds, so
  it does not reward the majority-class shortcut.
- **B.** ROC-AUC is just a fancier, more **cosmetic** metric — it reports the same
  information as accuracy but on a nicer scale, so we use it for presentation.
- **C.** Class imbalance makes **accuracy mathematically undefined / impossible to
  compute**, so we are forced to use ROC-AUC instead.
- **D.** **Accuracy is invalid for any split with unequal class sizes**, so it should
  never be reported in any classification problem.

## Misconception each distractor reveals

- **B → "AUC is a cosmetic metric."** Treats ROC-AUC as a re-scaled accuracy rather
  than a threshold-free measure of *ranking/discrimination*; misses why the
  majority-class baseline is the problem.
- **C → "imbalance makes accuracy undefined."** Confuses "uninformative" with
  "uncomputable" — accuracy is perfectly well-defined here (~87%), it is just
  *misleading*.
- **D → "over-generalizes: accuracy invalid for every unequal split."** Correctly
  senses imbalance is an issue but over-extends it into an absolute ban, losing the
  specific reason (the trivial majority predictor).
