# Item 03 — Count the cost: 0/1 risk on a sample

**ID**: IB-02-classifiers-03
**Learning objective**: Apply the 0/1 loss to a classifier's predictions and interpret its **risk** on a sample as the average 0/1 loss over the patients — the quantity training seeks to minimise (Obj. 3).
**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 02-classifiers

## Question

A binary classifier $f$ is tested on 10 patients. For each patient the table reports the true class $Y$ and the classifier's prediction $\hat Y = f(X)$:

| Patient | True $Y$ | Predicted $\hat Y = f(X)$ |
|---|---|---|
| 1 | high-risk | high-risk |
| 2 | low-risk  | low-risk |
| 3 | high-risk | low-risk |
| 4 | low-risk  | low-risk |
| 5 | high-risk | high-risk |
| 6 | low-risk  | high-risk |
| 7 | high-risk | high-risk |
| 8 | low-risk  | low-risk |
| 9 | high-risk | low-risk |
| 10 | low-risk  | low-risk |

Using the 0/1 loss $\mathfrak{L}(y, \hat y) = 1$ if $y \ne \hat y$ and $0$ otherwise, what is the classifier's **0/1 risk on this sample** — the average 0/1 loss over the 10 patients?

## Options

- A) $0/10$
- B) $2/10$
- C) $3/10$
- D) $7/10$

## Expected answer

**Correct: C ($3/10$).** Going row by row, the 0/1 loss is $1$ exactly when $Y \ne \hat Y$. Three patients are misclassified: **#3** (true *high-risk*, predicted *low-risk*), **#6** (true *low-risk*, predicted *high-risk*), and **#9** (true *high-risk*, predicted *low-risk*). The average 0/1 loss is therefore

$$\text{risk on sample}(f) = \frac{1}{10} \sum_{i=1}^{10} \mathfrak{L}(y_i, \hat y_i) = \frac{3}{10}.$$

Why the distractors are plausible but wrong:

- **A ($0/10$)** is the "*the classifier looks accurate, so the risk must be zero*" misreading: it confuses *most-patients-right* with *no-error-on-any-patient*. Risk counts the misclassifications, and there are three.
- **B ($2/10$)** counts only **false negatives** — the two high-risk patients ($\#3$ and $\#9$) that the classifier missed — and ignores the **false positive** $\#6$ (a low-risk patient flagged as high-risk). The 0/1 loss is **symmetric**: every disagreement costs $1$, regardless of which direction the error goes.
- **D ($7/10$)** is the **accuracy / risk inversion**: $7$ is the count of *correctly* classified patients ($10 - 3 = 7$), so $7/10$ is the *accuracy*, not the risk. The 0/1 risk is the error rate, not the success rate — the very point of the chapter is that we are counting **costs**, not wins.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
