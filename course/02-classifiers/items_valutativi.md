# Item bank — 02 Classifiers

> Chapter: `02-classifiers` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-28. Items student-facing in English; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED** (2026-05-28). Anti-leakage check from ch. 03 (kNN/SVM/kernel/RF) and ch. 04 (overfitting/train-test/CV) held cleanly across all 4 items + both rubrics. Item 04 walks the line deliberately (its sub-question 3 names the informational gap that ch. 04 will fill) and stays on the right side. Applied: rubric 04 bias-clarification — the C3 rule "do not penalise / do not reward ch. 04 vocabulary" rephrased so the heading aligns with the body (substance only counts).

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — distinguish classification from regression by type of output | Comprehension | MCQ | low | [item_01_classification-vs-regression_mcq.md](items/item_01_classification-vs-regression_mcq.md) |
| 02 | Obj. 2 — represent a classifier as a function $f:\mathbb{R}^d \to \{1,\ldots,K\}$ partitioning the feature space into decision regions | Application | applicativa | medium | [item_02_partition-the-plane_applicativa.md](items/item_02_partition-the-plane_applicativa.md) |
| 03 | Obj. 3 — apply the 0/1 loss and compute the risk on a sample as the average 0/1 loss | Application | MCQ (scenario) | medium | [item_03_count-the-cost_mcq.md](items/item_03_count-the-cost_mcq.md) |
| 04 | Obj. 2 + Obj. 3 + epistemic awareness — argue which of two competing classifiers is supported by the chapter's evidence; identify the informational gap that the chapter cannot close | Argumentation | argomentativa | medium–high | [item_04_compare-two-boundaries_argomentativa.md](items/item_04_compare-two-boundaries_argomentativa.md) |

## Coverage

**By objective** (all three chapter objectives covered):

- **Obj. 1** (classification vs regression by output type): item 01 (primary).
- **Obj. 2** (classifier as function partitioning the feature space): item 02 (primary), item 04 (secondary).
- **Obj. 3** (0/1 loss + risk as average loss on the sample): item 03 (primary), item 04 (secondary).

**By cognitive category** (3 of 4 categories; no pure-recall item, appropriate for graduate level):

- Knowledge: 0
- Comprehension: 1
- Application: 2
- Argumentation/evaluation: 1

## Rubrics

- [rubrica_02_partition-the-plane.md](rubriche/rubrica_02_partition-the-plane.md) — item 02 (applicativa)
- [rubrica_04_compare-two-boundaries.md](rubriche/rubrica_04_compare-two-boundaries.md) — item 04 (argomentativa)

*(Items 01 and 03 are MCQ — single correct option, no rubric.)*

## Pre-hook to ch. 03 — embedded in item 04

Item 04's sub-question 3 deliberately surfaces — without resolving — the question of *whether* one classifier might do better on a different group of patients. The expected answer names this as the **natural endpoint of ch. 02**: with the chapter's tools we can pick the lower-risk classifier on the sample we have, but **not** make any claim about patients we have not measured. That informational gap is the gancio operativo for ch. 04 (model selection / validation).

The bank therefore mirrors the chapter's own arc: items 01–03 *apply* the chapter's machinery; item 04 *exposes its limit* and points beyond it without smuggling the next chapter's vocabulary in.
