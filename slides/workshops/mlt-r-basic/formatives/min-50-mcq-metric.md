# Formative · min 50 · MCQ (after Step 02)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `METRIC` — Metrics: AUC-ROC + AUC-PR (yardstick); motivated by `OUT` (imbalanced outcome)

## Prompt

Death occurs in about **32%** of the patients, and we score every model with
**both** AUC-ROC **and** AUC-PR. Which statement best explains why we watch
**AUC-PR alongside** AUC-ROC, rather than AUC-ROC alone?

## Options

- **A. ✓ (correct)** AUC-PR focuses on the **positive (death) class**, and its
  no-skill baseline is the **prevalence** (~0.32) — not 0.5. So AUC-PR exposes poor
  performance *on the patients we care about* that a flattering AUC-ROC can hide,
  especially as the event gets rarer.
- **B.** AUC-ROC and AUC-PR always **rank models in the same order**, so AUC-PR is
  just a redundant second opinion we report out of habit.
- **C.** Like AUC-ROC, AUC-PR's no-skill baseline is **always 0.5**, so a AUC-PR
  above 0.5 always means a useful model.
- **D.** We add AUC-PR because, under class imbalance, **AUC-ROC cannot be computed**
  and AUC-PR is its only valid replacement.

## Misconception each distractor reveals

- **B → "the two metrics are interchangeable."** Misses that AUC-ROC (prevalence-free
  ranking) and AUC-PR (positive-class, prevalence-anchored) can and do disagree —
  which is the whole reason to watch both.
- **C → "PR baseline is 0.5."** Doesn't know that the AUC-PR no-skill line is the
  **prevalence** itself, so it mis-reads a "0.6" AUC-PR at 32% prevalence as far
  better than it is.
- **D → "imbalance breaks AUC-ROC."** Confuses "can be optimistic / less informative"
  with "uncomputable": AUC-ROC is perfectly computable under imbalance — it just does
  not, by itself, tell you about the minority class.
