# Item 01 — Diagnose overfitting from a training/CV error pair

**ID**: IB-04-model-selection-01
**Learning objective**: Diagnose overfitting from the signature *low training error + high error on new data*; recognise the phenomenon and distinguish it from underfit and from a healthy model fit (Obj. 1).
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low–medium
**Chapter**: 04-model-selection

## Question

Four classifiers, all trained for the same binary clinical task, are evaluated on the *same* dataset using $5$-fold cross-validation. The table below reports each classifier's **training error** (on the data it was trained on) and its **CV error** (the average error across the $5$ held-out folds):

| Classifier | Training error | $5$-fold CV error |
|---|---|---|
| $M_1$ | $25\%$ | $28\%$ |
| $M_2$ | $0\%$ | $32\%$ |
| $M_3$ | $48\%$ | $50\%$ |
| $M_4$ | $7\%$ | $9\%$ |

Which **one** of these classifiers shows the clearest signature of **overfitting**?

## Options

- A) $M_1$ — training error and CV error are both around $25$–$28\%$.
- B) $M_2$ — training error is $0\%$ and CV error is $32\%$.
- C) $M_3$ — both training error and CV error are close to $50\%$.
- D) $M_4$ — training error and CV error are both very low (around $7$–$9\%$).

## Expected answer

**Correct: B ($M_2$).** Overfitting has a specific signature in the chapter: **very low training error *together with* a much higher error on data the model has not been trained on** (here, the CV error). $M_2$ has *zero* training error — it gets every training patient right — but a $32\%$ CV error: it has memorised the training sample's idiosyncrasies, not the underlying pattern.

Why the distractors are plausible but wrong:

- **A ($M_1$, $25 / 28\%$)** is *not* overfitting. The two errors are close (small gap, $\sim 3$ percentage points) and both moderate. There is no signature of "memorised the sample" — the model is doing roughly the same on training and on held-out data, just not very well.
- **C ($M_3$, $48 / 50\%$)** is **underfitting**, the opposite phenomenon: both errors are high *and close to chance* ($50\%$ is the baseline for binary), meaning the model is too rigid to capture even the training data, let alone new patients. Underfit and overfit are two different failures; this MCQ tests recognising overfit, and underfit is the most-attractive *wrong* answer for students who confuse "high error" with "overfit".
- **D ($M_4$, $7 / 9\%$)** is a **healthy fit**: both errors are low *and close to each other* — the model has learned a real pattern and it generalises. A student who thinks "low training error = overfit" picks D and is wrong: overfit is not low train, it is *low train **plus** big gap to new-data error*.

The single discriminator is the **gap between training error and CV error, together with how low the training error is** — not the size of either error alone, and not the presence of any gap whatsoever. Only $M_2$ matches the *low-train + big-gap* signature.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
