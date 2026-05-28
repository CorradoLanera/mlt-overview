# Item bank — 04 Model selection & validation

> Chapter: `04-model-selection` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-28. Items student-facing in English; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED-WITH-FIXES** (2026-05-28). Anti-leakage check from ch. 05+ (deep learning, NN architecture, layers, neurons, regularisation, dropout, LLMs, agents) held cleanly across all 4 items + both rubrics. Item 04 verified within ch.04 scope (Obj 2 explicitly mentions *candidate models*; cross-technique selection falls there). Applied: (1) item 04 bonus tightened to make clear the fix is *discipline, not more partitions* — no nested-CV endorsement; (2) rubrica 04 soglia di sufficienza upgraded from "1/2 a Base" to "**entrambi a Base**" (a graduate-level Argumentation requires both the critical part C1 *and* the constructive part C2). One non-blocking nice-to-have left for future iteration: item 03 distractor C ("re-run CV with different $K$") slightly weaker than A/D, but still defensible as testing "more validation will rescue me" misconception.

> **Note on numbers:** item 01 uses $M_1$–$M_4$ with values *different* from objectives.md's summative table ($M_A$–$M_D$ at $0/30, 12/18, 20/22, 40/42$). This is intentional — the items must measure the *signature* of overfitting (low train + big gap), not the student's memory of the summative-exercise rows. Each item's pedagogical role is preserved by the separation.

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — diagnose overfitting from the train/CV error pair signature, distinguishing it from underfit and healthy fit | Comprehension | MCQ | low–medium | [item_01_diagnose-overfitting_mcq.md](items/item_01_diagnose-overfitting_mcq.md) |
| 02 | Obj. 3 — apply $K$-fold CV: compute the CV error rate, state what it estimates, recognise the $K$ trade-off (bias vs variance of the CV procedure) | Application | applicativa | medium | [item_02_compute-kfold-cv_applicativa.md](items/item_02_compute-kfold-cv_applicativa.md) |
| 03 | Obj. 2 — after CV picks a (single-technique) winner: choose the correct next procedural step (retrain on train+val, evaluate once on held-out test set) | Application | MCQ (scenario) | medium | [item_03_after-cv-next-step_mcq.md](items/item_03_after-cv-next-step_mcq.md) |
| 04 | Obj. 1 + Obj. 2 — argue why a cross-technique comparison procedure that *appears* correct (each technique tuned with CV, then evaluated on test) actually violates the contamination principle by hiding a *second selection step* on the test set; propose the corrected procedure (validation chooses *both* within- and between-technique) | Argumentation | argomentativa | medium–high | [item_04_skip-the-test-critique_argomentativa.md](items/item_04_skip-the-test-critique_argomentativa.md) |

## Coverage

**By objective** (all three chapter objectives covered):

- **Obj. 1** (diagnose overfitting): item 01 (primary), item 04 (secondary, via the consequences of the contamination violation).
- **Obj. 2** (train/val/test split + contamination principle): item 03 (single-technique, primary), item 04 (cross-technique, deeper).
- **Obj. 3** ($K$-fold CV + $K$ trade-off): item 02 (primary).

**By cognitive category** (3 of 4 categories; no pure-recall item, appropriate for graduate level):

- Knowledge: 0
- Comprehension: 1
- Application: 2
- Argumentation/evaluation: 1

## Rubrics

- [rubrica_02_compute-kfold-cv.md](rubriche/rubrica_02_compute-kfold-cv.md) — item 02 (applicativa)
- [rubrica_04_skip-the-test-critique.md](rubriche/rubrica_04_skip-the-test-critique.md) — item 04 (argomentativa)

*(Items 01 and 03 are MCQ — single correct option, no rubric.)*

## Internal coherence — items 03 and 04 build on each other

The set deliberately stages two levels of the chapter's *contamination principle*:

- **Item 03** tests the **single-technique correct procedure**: after CV picks one winner among hyperparameter settings of the *same* model, the next step is to retrain that winner on train+val and evaluate it *once* on the held-out test set.
- **Item 04** tests the **cross-technique trap**: the student must recognise that when the same student tries to extend the procedure to *compare multiple ML techniques*, doing the cross-technique selection on the test set is a *second* selection that re-spends the test set. The fix is to do **both** within-technique and between-technique selection on validation.

This 03→04 progression mirrors the chapter's own arc: the canonical procedure first (Obj. 2 single-stage), then the subtle violation that *looks* like that procedure but isn't (Obj. 2 + 1, Argumentation).

## Pre-hook to ch. 05 — left to the chapter, not embedded in items

The pre-hook to ch. 05 (*deep learning*) is staged in the chapter's [narrative](narrative.md) and [storyboard frame 6](storyboard.md) — *"and what if the model itself can be made arbitrarily complex?"* — *not* inside the items. The items themselves stay strictly within ch. 04 vocabulary (train/val/test, CV, contamination, hyperparameter tuning) and do not presuppose any concept from ch. 05+ (neural network architecture, layers, neurons, regularisation, dropout, deep nets, LLMs, agents).
