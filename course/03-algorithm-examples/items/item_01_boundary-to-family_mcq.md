# Item 01 — Read the algorithm family off the boundary shape

**ID**: IB-03-algorithm-examples-01
**Learning objective**: Compare three algorithm families ($k$-NN, SVM with/without kernel, Random Forest) by the *shape of the decision regions* each carves in feature space — each shape is the kind of boundary that algorithm family is *capable* of producing (Obj. 1).
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low–medium
**Chapter**: 03-algorithm-examples

## Question

A binary classifier is trained on a 2D feature space. Its decision boundary is drawn in the figure and can be described as: a **wiggly, piecewise curve that hugs the training data closely, with small detours around individual points**. The two decision regions look as if they were *carved by the points themselves* — every region in the plane takes the colour of the nearest patient cluster, with no smooth global cut.

Which algorithm family most likely produced this decision boundary?

## Options

- A) $k$-Nearest Neighbor (with small $k$).
- B) Support-Vector Machine with a **linear** (non-kernel) classifier.
- C) Random Forest.
- D) Support-Vector Machine with a **non-linear kernel** (e.g., $\phi(y_1, y_2) = (y_1^2, y_2^2, \sqrt{2}\,y_1 y_2)$).

## Expected answer

**Correct: A.** The defining clue is *the boundary follows the data*. $k$-NN does not build a single global rule: a new point is labelled by the majority class of its $k$ nearest training neighbours, so the decision regions are defined *by the training points themselves* — a piecewise, data-hugging boundary that detours around individual examples (especially for small $k$). The kind of boundary $k$-NN can produce is "regions defined by neighbourhoods of training points", and the description fits that exactly.

Why the distractors are plausible but wrong:

- **B (linear SVM)** — a linear (non-kernel) SVM produces a *single straight line* (a hyperplane) by construction. The only kind of boundary it can produce is "one global straight cut". A wiggly, data-hugging curve is the opposite of what it can produce.
- **C (Random Forest)** — RF produces a boundary made of **axis-aligned rectangular steps** (a "staircase" pattern), because each weak tree splits along one axis at a time. RF boundaries look blocky, not smoothly wiggly around individual points.
- **D (SVM with non-linear kernel)** — a kernel-warped SVM produces a *smooth curved* boundary (a hyperplane in the lifted $\phi$-space, projected back as a curve in the original space). Smooth curves are not the same as piecewise wiggly boundaries with detours around single points.

The distinguishing question for Obj. 1 is *which kind of boundary each algorithm family can produce*; the description here matches $k$-NN and no other.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
