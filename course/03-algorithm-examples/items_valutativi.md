# Item bank — 03 Algorithm examples

> Chapter: `03-algorithm-examples` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-28. Items student-facing in English; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED** (2026-05-28). Anti-leakage check from ch. 04 (overfitting / train-test / cross-validation / model selection / regularisation / hyperparameter tuning) held cleanly across all 4 items + both rubrics. Vocabulary discipline verified: "inductive bias" removed from all student-facing artifacts; the single residual mention in `rubrica_04` is a corrector instruction ("do not require this term"). Item 04 remains *genuine* Argumentation after the simplification (the teacher had flagged v1 as too complex; v3 keeps the compare+justify cognitive move without the meta-epistemic load). Two nice-to-have non-blocking notes: (a) "smoothly wiggly" wording in `item_01` for RF (minor), (b) the binomial-sum formula in `item_03` expected-answer is corrector-only, not required of students.

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — read the algorithm family off the **shape of the boundary** (wiggly piecewise / straight cut / smooth curve / staircase) | Comprehension | MCQ | low–medium | [item_01_boundary-to-family_mcq.md](items/item_01_boundary-to-family_mcq.md) |
| 02 | Obj. 2 — apply a non-linear feature map $\phi$ to a non-linearly-separable dataset and find a linear separator in the transformed space; explain what changed and what didn't | Application | applicativa | medium | [item_02_apply-the-kernel-trick_applicativa.md](items/item_02_apply-the-kernel-trick_applicativa.md) |
| 03 | Obj. 3 — predict the direction of change of majority-vote accuracy when $p > 0.5$ vs $p < 0.5$ (with fixed $m$); state why $p > 0.5$ is necessary | Application | MCQ (scenario) | medium | [item_03_majority-vote-direction_mcq.md](items/item_03_majority-vote-direction_mcq.md) |
| 04 | Obj. 1 + light Obj. 2 — argue which algorithm family fits a non-linearly-separable dataset and which does not, in terms of *the shape of boundary each can produce*; use the 0/1 risk on the sample (ch. 02) to name the concrete consequence of a mismatched choice | Argumentation | argomentativa | medium | [item_04_simpler-is-safer-critique_argomentativa.md](items/item_04_simpler-is-safer-critique_argomentativa.md) |

## Coverage

**By objective** (all three chapter objectives covered):

- **Obj. 1** (algorithm family by boundary shape): item 01 (primary), item 04 (primary in argument form).
- **Obj. 2** (kernel trick as re-coordinatisation): item 02 (primary), item 04 (light, in the alternative-proposal for kernel SVM).
- **Obj. 3** (majority-vote behaviour, $p > 0.5$ requirement): item 03 (primary).

**By cognitive category** (3 of 4 categories; no pure-recall item, appropriate for graduate level):

- Knowledge: 0
- Comprehension: 1
- Application: 2
- Argumentation/evaluation: 1

## Rubrics

- [rubrica_02_apply-the-kernel-trick.md](rubriche/rubrica_02_apply-the-kernel-trick.md) — item 02 (applicativa)
- [rubrica_04_simpler-is-safer-critique.md](rubriche/rubrica_04_simpler-is-safer-critique.md) — item 04 (argomentativa)

*(Items 01 and 03 are MCQ — single correct option, no rubric.)*

## Pre-hook to ch. 04 — embedded in the chapter, not in items

The pre-hook to ch. 04 (*model selection / overfitting*) is staged in the chapter's [narrative](narrative.md) ("which holds on a patient never seen?") and [storyboard frame 6](storyboard.md) (the $k$NN $k=1$ wrap that hugs every training point but mislabels the first new patient) — *not* inside the items. The items themselves stay strictly within ch. 02–03 vocabulary: they test *what shape each algorithm produces* and *whether a chosen algorithm's shape can match the data*, not *which algorithm generalises best to unseen patients*.

## Vocabulary discipline

The chapter teaches the **shape of decision regions** each algorithm family can produce (*wiggly piecewise* for $k$NN, *straight cut* for linear SVM, *smooth curved boundary* for kernel SVM, *axis-aligned staircase* for RF). The technical term "*inductive bias*" — used in some textbooks for exactly this concept — was **deliberately not promoted** to student-facing vocabulary: the items, narrative, storyboard, and rubrics use "*the kind of boundary the algorithm can produce*" / "*the shape of decision regions*" instead. The rubrics explicitly instruct correctors **not** to require or reward the term — only the substance counts.
