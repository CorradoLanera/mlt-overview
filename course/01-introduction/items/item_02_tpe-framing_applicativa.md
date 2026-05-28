# Item 02 — Frame a clinical task as T/P/E

**ID**: IB-01-introduction-02
**Learning objective**: Frame an applied clinical problem as an ML problem by specifying its Task ($T$), Performance ($P$), and Experience ($E$), and reason about why a performance measure is or is not appropriate for the data (Obj. 1).
**Category**: Application
**Type**: applicativa (open-ended)
**Difficulty**: medium
**Chapter**: 01-introduction

## Question

An ICU team wants a system that, **at admission**, predicts whether a patient will develop **sepsis during their ICU stay**. They have several years of past ICU admissions, each described by the information available *at admission* and labelled with whether sepsis later occurred. In their data, only about **4% of admissions developed sepsis**.

1. Frame this as a machine-learning problem by specifying its **Task ($T$)**, **Performance measure ($P$)**, and **Experience ($E$)**.

2. The team proposes to judge the system by plain **accuracy** (the proportion of all patients predicted correctly). A measure designed for imbalanced problems is **balanced accuracy**: the average of the model's accuracy *within each class* — i.e. the average of the fraction of sepsis patients it correctly flags and the fraction of non-sepsis patients it correctly clears.

   Consider a trivial model that predicts **"no sepsis" for every patient**.
   (a) What is its plain accuracy, and what is its balanced accuracy?
   (b) Use your answer to explain why balanced accuracy is the more appropriate choice of $P$ for this task.

## Expected answer

- **$T$**: predict, at admission, whether a patient will develop sepsis during the ICU stay — a binary classification task.
- **$P$**: balanced accuracy (rather than plain accuracy).
- **$E$**: the past ICU admissions labelled with whether sepsis occurred — supervised experience.
- **(a)** The "always no-sepsis" model is correct on the 96% who never develop sepsis, so its **plain accuracy ≈ 96%**. But its accuracy on the sepsis class is 0% and on the non-sepsis class is 100%, so its **balanced accuracy = (0% + 100%) / 2 = 50%**.
- **(b)** Plain accuracy is inflated by the 96% majority of negatives, so a clinically useless model still scores ≈ 96%. Balanced accuracy weighs the two classes equally, so failing to catch any sepsis case drags it down to 50% — no better than chance — which honestly reveals that the model is useless for the task that matters.

## Rubric

See [rubriche/rubrica_02_tpe-framing.md](../rubriche/rubrica_02_tpe-framing.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
