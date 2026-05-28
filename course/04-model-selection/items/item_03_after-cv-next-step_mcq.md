# Item 03 — After CV picks a winner: what is the trustworthy next step?

**ID**: IB-04-model-selection-03
**Learning objective**: Apply the train / validation / test split: invoke the *contamination principle* — every decision taken after looking at a number on a dataset spends that number as a future estimate — to choose the next procedural step (Obj. 2).
**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 04-model-selection

## Question

A clinical team has set aside a separate **test set** at the start of a project and used the remaining data for $5$-fold cross-validation to compare four candidate classifiers ($M_A$, $M_B$, $M_C$, $M_D$). The model with the lowest CV error is $M_B$, at $18\%$. The team must now report a number to the clinical staff that represents how the chosen model is expected to perform on **new patients**.

What is the **correct next step**?

## Options

- A) Report the CV error ($18\%$) of $M_B$ as the expected performance of $M_B$ on new patients — no further evaluation is needed.
- B) Retrain $M_B$ on the combined training + validation data, then evaluate it on the held-out test set; report the resulting test error as the expected performance.
- C) Re-run the $5$-fold cross-validation with a different $K$ (e.g., $K = 10$) to confirm $M_B$'s $18\%$ CV error is robust, then report it as the final number.
- D) Pool the training, validation, and test sets together into one combined dataset and report the average error of $M_B$ on the whole pool.

## Expected answer

**Correct: B.** The CV error of $M_B$ ($18\%$) is the very number that was *used to choose* $M_B$ among the four candidates. By the chapter's **contamination principle** — *"every time you take a decision based on a number on a dataset, that number is no longer a valid estimate"* — the chosen winner's CV error is no longer an unbiased estimate of its performance on new patients: it is *optimistically biased toward the smallest of four CV errors*, because the team picked it for being small. The **test set** is the *only* dataset that has not been spent in any decision so far; evaluating the (retrained) $M_B$ on it gives a single, trustworthy number with no contamination.

Why the distractors are plausible but wrong:

- **A ($18\%$ as the final estimate)** is the classic contamination violation. It is the most attractive wrong answer because the CV error *exists* and *looks like* a performance number — but it has already been spent in the act of selection. Reporting it is like reporting your *best* score across many attempts as your "expected" score.
- **C (re-run CV with different $K$)** still does not solve the problem. Even if a $K = 10$ CV gives the *same* $18\%$, that number too would now be involved in a selection-style decision (confirming $M_B$). Re-running CV does not "unspend" the prior CV; it doubles down on the same set. The test set is still untouched only because it has never been evaluated on at all.
- **D (pool train + val + test, report error on the pool)** is the most damaging error of the four: it uses the **test set as training data** (it includes the test patients in the data the model can effectively see for fitting / for averaging error). The held-out test set's whole purpose — being untouched — is destroyed. The reported error would be a mix of training error (where the model has seen the data) and a small contribution from the test patients (now no longer held out). It violates the test set's *role* (Obj. 2).

The single discriminating principle is: **does the procedure produce a number from a dataset that has not yet been used in any decision about $M_B$?** Only B does.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
