# Formative · min 165 · predict-output (after Step 04)

- **Type:** predict-output (predict before the reveal)
- **Concept-graph node checked:** `OPT` — Optimism gap (single split lies); `CV`, `LASTFIT`

## Prompt

Before we reveal the numbers, think about these three AUC-ROC values for the
**winning random forest**:

- **A** = resubstitution AUC (model scored on the **training** data it was fit on)
- **B** = cross-validated AUC (mean over the 5 folds)
- **C** = test AUC (`last_fit()` on the **held-out** test set)

Which is clearly the **largest**? And can you be sure whether **B > C** or **C > B**?

## Expected answer

**A is, by a wide margin, the largest** — a random forest scored on its own training
rows nearly memorizes them (AUC close to 1). You **cannot** be sure of the B-vs-C
order: both are honest-ish estimates, and on a small cohort their gap is mostly
**noise**.

$$
\text{A (resubstitution)} \;\gg\; \{\text{B (CV)},\; \text{C (test)}\}
$$

- **A flatters:** scoring on the same data used to fit rewards memorization — never
  quote it.
- **B and C are the honest estimates.** Here it actually comes out
  **C ≈ 0.87 > B ≈ 0.79** — the single test split landed *high* by luck, the opposite
  of the textbook "test is lowest" story.
- That flip **is** the lesson: on ~75 test patients one number is unreliable, which is
  why we select the model on **cross-validation**, not on a single split.

## Diagnostic note (teacher)

If the room confidently predicts a strict **A ≥ B ≥ C** and is surprised that C beat
B, that surprise is the teachable moment: resubstitution (A) is always optimistic,
but the CV-vs-test gap is **sampling noise on a small cohort**, not a guaranteed
ordering. The point of `last_fit()` is one honest, pre-committed read — to be weighed
**alongside** the CV, never instead of it.
