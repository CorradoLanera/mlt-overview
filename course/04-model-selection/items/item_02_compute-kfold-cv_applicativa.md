# Item 02 — Compute a 5-fold cross-validation error

**ID**: IB-04-model-selection-02
**Learning objective**: Use $K$-fold cross-validation as the practical procedure for the validation step: state the algorithm, compute the CV error rate from per-fold errors, identify what the CV error estimates, and recognise that $K \in [5, 10]$ is the standard range (Obj. 3).
**Category**: Application
**Type**: applicativa (open-ended applicative)
**Difficulty**: medium
**Chapter**: 04-model-selection

## Question

A classifier is evaluated on a dataset of $20$ patients (each labelled *high-risk* or *low-risk*) using **$5$-fold cross-validation**. The dataset is divided into $5$ equal folds of $4$ patients each. For each fold, the classifier is trained on the other $4$ folds (i.e., on $16$ patients) and evaluated on the held-out fold (the remaining $4$ patients). The table reports the number of misclassified patients per held-out fold:

| Fold | Misclassified | Out of | Per-fold error rate |
|---|---|---|---|
| $1$ | $1$ | $4$ | $25\%$ |
| $2$ | $1$ | $4$ | $25\%$ |
| $3$ | $2$ | $4$ | $50\%$ |
| $4$ | $0$ | $4$ | $0\%$ |
| $5$ | $2$ | $4$ | $50\%$ |

Answer the three sub-questions:

1. **Compute** the **$5$-fold CV error rate** for this classifier. Show the formula you used and report the result as a percentage.
2. **State** what number the CV error rate **estimates** — i.e. *what is it a number about*? (1–2 sentences.)
3. **Describe** what would change if we used **$K = 10$** instead of $K = 5$ on the same $20$-patient dataset: (a) what the procedure would look like, and (b) one concrete trade-off involved in increasing $K$.

## Expected answer

1. The $5$-fold CV error rate is the **average** of the per-fold error rates (equivalently, the total misclassified patients divided by the total dataset size):

   $$\text{CV error} \;=\; \frac{1}{K} \sum_{k=1}^{K} (\text{error}_k) \;=\; \frac{25\% + 25\% + 50\% + 0\% + 50\%}{5} \;=\; \frac{150\%}{5} \;=\; \mathbf{30\%}.$$

   Equivalent computation: $(1 + 1 + 2 + 0 + 2) / 20 = 6 / 20 = 30\%$.

2. The CV error rate **estimates the prediction error of the classifier on unseen patients** — i.e., the error rate one would expect if the classifier were applied to a *new* group of patients drawn from the same population. It is *not* the training error (which measures fit on already-seen data) and it is *not* yet the test error (which is reserved for the final, held-out test set after a model is *chosen*).

3. With $K = 10$ instead of $K = 5$ on the same $20$ patients:

   **(a) Procedure:** divide the $20$ patients into $10$ equal folds of $2$ patients each. For each of the $10$ folds, train the classifier on the remaining $9$ folds (i.e., on $18$ patients) and estimate the error on the $2$ held-out patients. Average the $10$ per-fold error rates to get the CV error.

   **(b) Trade-off:** with larger $K$, **each round trains on more data** ($18$ instead of $16$ patients per round), so each round's classifier is closer to one trained on the full dataset — *less bias* in the error estimate. **But each fold is smaller** ($2$ patients instead of $4$): a single misclassified patient now flips the per-fold error rate by $50$ percentage points, so the **per-fold rates are noisier** and the average has *more variance*. This is why the chapter recommends $K \in [5, 10]$ as the standard range — it balances "enough training data per round" (low bias) against "enough patients per fold to make the rate meaningful" (low variance).

## Rubric

See [rubriche/rubrica_02_compute-kfold-cv.md](../rubriche/rubrica_02_compute-kfold-cv.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
