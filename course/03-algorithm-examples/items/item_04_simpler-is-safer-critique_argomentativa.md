# Item 04 — Which algorithm fits these data, and why?

**ID**: IB-03-algorithm-examples-04
**Learning objective**: Argue, in terms of *the shape of decision regions each algorithm can produce*, which algorithm family fits a given dataset and which does not (Obj. 1 + light Obj. 2).
**Category**: Argumentation
**Type**: argomentativa (open-ended)
**Difficulty**: medium
**Chapter**: 03-algorithm-examples

## Question

A colleague shows you a 2D scatter of training patients where the two classes form **interlocked half-moons** (clearly non-linearly separable: every straight line crosses both classes). They ask:

> *"Which algorithm should I use on these data, and why?"*

Argue your answer in two parts, using **only the language of this chapter** — namely, *what shape of decision regions* each algorithm family can produce (the wiggly piecewise curve of $k$-NN, the straight cut of linear SVM, the smooth curved boundary of kernel-SVM, the axis-aligned staircase of Random Forest). For *Part 2* you may also use the *0/1 risk on the sample* from chapter 02.

1. **Propose one algorithm family that would FIT these data well.** Name **the shape of boundary it produces** and argue why that shape *matches the shape of the data*.
2. **Identify one algorithm family that would NOT fit these data well.** Name **the shape of boundary it produces** and argue why that shape *cannot match* the data — using the *0/1 risk on the sample* (ch. 02) to name the concrete consequence.

## Expected answer

**Any one of the following is correct for Part 1**, provided the student explicitly names the boundary shape and ties it to the data:

- **SVM with a non-linear kernel** — boundary shape: a *smooth curve* in the original space (obtained by applying a non-linear feature map, e.g., $\phi(y_1, y_2) = (y_1^2, y_2^2, \sqrt{2}\,y_1 y_2)$, cutting with a hyperplane in $\phi$-space, and projecting back). A smooth curve can enclose one of the half-moons.
- **$k$-Nearest Neighbor** (e.g., $3$NN) — boundary shape: a *wiggly, piecewise curve* defined by the training points themselves. It naturally follows whatever shape the clusters have, including interlocked half-moons.
- **Random Forest** — boundary shape: an *axis-aligned staircase* of small rectangular regions, combined by majority vote of many tree classifiers. The staircase can carve interlocked half-moons into rectangular pieces of the right class; by the chapter's binomial-vote argument, the vote concentrates on the right answer as more trees are added (whenever each tree has accuracy $p > 0.5$).

**For Part 2: linear (non-kernel) SVM.** Boundary shape: a **single straight cut** (a hyperplane $f(x) = \text{sgn}(w^\top x + b)$). On interlocked half-moons, *no straight line* can put each class on one side — every straight cut crosses both half-moons. The concrete consequence is **high 0/1 risk on the sample**: many patients end up on the wrong side of the boundary, so the average 0/1 loss is large. The mismatch is structural — a straight cut *cannot* produce the curved boundary the data require.

## Rubric

See [rubriche/rubrica_04_simpler-is-safer-critique.md](../rubriche/rubrica_04_simpler-is-safer-critique.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
