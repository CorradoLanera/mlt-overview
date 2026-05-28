# Item 01 — Classification or regression?

**ID**: IB-02-classifiers-01
**Learning objective**: Distinguish a classification task from a regression task by the type of output it produces — a discrete class label vs a continuous value — and identify which one a given clinical task requires (Obj. 1).
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low
**Chapter**: 02-classifiers

## Question

Which **one** of the following clinical machine-learning tasks is a **regression** task (rather than classification)?

## Options

- A) Predicting **whether** a patient will be re-admitted within 30 days of discharge from their electronic health record features.
- B) Predicting a patient's **HbA1c value** six months after starting metformin, from baseline labs.
- C) Predicting **which** of three diabetes subtypes (Type-1, Type-2, gestational) a newly diagnosed case belongs to, from clinical features.
- D) Predicting **whether** a chest X-ray shows pneumonia.

## Expected answer

**Correct: B.** HbA1c is a *continuous numeric value* (e.g., $6.5\%$); the task asks the model to predict that number, so its output is a value, not a label — the definition of regression in this chapter. Formally, the output lives in $\mathbb{R}$, not in a finite label set $\{1,\ldots,K\}$.

Why the distractors are plausible but wrong:

- **A** is binary classification: the *output* is a discrete label *re-admitted yes / re-admitted no*, not a number. The fact that one *could* report a risk *score* does not change the task as framed ("predicting **whether**").
- **C** is multi-class classification with $K = 3$: the output is one of three discrete subtype labels, not a number.
- **D** is binary classification: pneumonia *yes / no* is a discrete label, not a value.

The single discriminator is **what the model produces as output** — a label (classification) or a value (regression) — not the apparent simplicity of the task, the data type of the inputs, or whether a probability *could* be reported alongside.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
