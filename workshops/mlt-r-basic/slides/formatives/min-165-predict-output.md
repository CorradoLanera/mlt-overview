# Formative · min 165 · predict-output (after Step 04)

- **Type:** predict-output (predict before the reveal)
- **Concept-graph node checked:** `OPT` — Optimism gap (single split lies); `CV`, `LASTFIT`

## Prompt

Before we reveal the numbers, **order these three ROC-AUC values** from largest to
smallest:

- **A** = resubstitution AUC (model scored on the **training** data it was fit on)
- **B** = cross-validated AUC (mean over the 5 folds)
- **C** = test AUC (`last_fit()` on the **held-out** test set)

## Expected answer

$$
\text{A (resubstitution)} \;\ge\; \text{B (cross-validated)} \;\gtrsim\; \text{C (test)}
$$

- **A is the most optimistic:** scoring on the same data used to fit rewards
  memorization.
- **B is honest-ish:** each fold is scored on data it did not train on, but tuning
  still "peeks" across folds.
- **C is the honest number:** the test set was touched exactly once, at the end.

Here that is roughly **A ≳ 0.63+ ≥ B ≈ 0.628 ≳ C ≈ 0.538**.

## Diagnostic note (teacher)

If the room confidently says **A = B = C**, the **optimism gap has not landed** —
stop and re-explain why scoring on training data (and even on tuning resamples)
flatters the estimate before showing the reveal. The whole point of `last_fit()` is
that C is the number you would quote to a clinician.
