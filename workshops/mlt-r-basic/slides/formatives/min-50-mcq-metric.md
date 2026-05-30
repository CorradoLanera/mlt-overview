# Formative · min 50 · MCQ (after Step 02)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `METRIC` — Metrics: ROC-AUC + PR-AUC (yardstick); motivated by `OUT` (imbalanced outcome)

## Prompt

Death occurs in about **32%** of the patients, and we score every model with
**both** ROC-AUC **and** PR-AUC. Which statement best explains why we watch
**PR-AUC alongside** ROC-AUC, rather than ROC-AUC alone?

## Options

- **A. ✓ (correct)** PR-AUC focuses on the **positive (death) class**, and its
  no-skill baseline is the **prevalence** (~0.32) — not 0.5. So PR-AUC exposes poor
  performance *on the patients we care about* that a flattering ROC-AUC can hide,
  especially as the event gets rarer.
- **B.** ROC-AUC and PR-AUC always **rank models in the same order**, so PR-AUC is
  just a redundant second opinion we report out of habit.
- **C.** Like ROC-AUC, PR-AUC's no-skill baseline is **always 0.5**, so a PR-AUC
  above 0.5 always means a useful model.
- **D.** We add PR-AUC because, under class imbalance, **ROC-AUC cannot be computed**
  and PR-AUC is its only valid replacement.

## Misconception each distractor reveals

- **B → "the two metrics are interchangeable."** Misses that ROC-AUC (prevalence-free
  ranking) and PR-AUC (positive-class, prevalence-anchored) can and do disagree —
  which is the whole reason to watch both.
- **C → "PR baseline is 0.5."** Doesn't know that the PR-AUC no-skill line is the
  **prevalence** itself, so it mis-reads a "0.6" PR-AUC at 32% prevalence as far
  better than it is.
- **D → "imbalance breaks ROC-AUC."** Confuses "can be optimistic / less informative"
  with "uncomputable": ROC-AUC is perfectly computable under imbalance — it just does
  not, by itself, tell you about the minority class.
