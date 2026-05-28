# Item 04 — Critique a learning-problem framing

**ID**: IB-01-introduction-04
**Learning objective**: Classify a scenario into the correct learning paradigm and justify it from the kind of supervision available, by arguing against a *plausible* but mistaken framing (Obj. 3, building on Obj. 1).
**Category**: Argumentation
**Type**: argomentativa (open-ended)
**Difficulty**: medium–high
**Chapter**: 01-introduction

## Question

A hospital data team is asked to **discover, from routinely collected lab panels, previously unrecognised subgroups ("phenotypes")** of patients with type 2 diabetes — groups that nobody has defined in advance. A colleague argues: *"We already have each patient's ICD diagnostic codes — let's just use those codes as the group labels and train a supervised classifier."*

1. The colleague's proposal is tempting because labels seem to be available. Argue whether using the ICD codes as labels actually achieves the stated goal.
2. State which learning paradigm fits the goal, and justify it.
3. Under what (different) goal would the colleague's supervised approach be exactly the right choice?

## Expected answer

1. **No — it does not achieve the goal.** The ICD codes are *pre-existing, human-defined diagnostic categories*, not the *previously unrecognised* subgroups the task asks to discover. A supervised classifier trained on them would only learn to reproduce labels that already exist — it cannot surface new structure. Having labels "available" is not the same as having labels that match the goal.
2. **Unsupervised learning (clustering)** fits: the goal is to discover structure / subgroups in data that carry *no* labels for the thing being sought (the phenotypes), which is exactly what clustering does.
3. The colleague's **supervised** approach would be exactly right under a *different* goal: **predicting a patient's existing ICD diagnosis from their lab panels**. There the ICD codes are legitimately the target labels, and assigning new patients to known categories is a supervised classification task.

## Rubric

See [rubriche/rubrica_04_critique-framing.md](../rubriche/rubrica_04_critique-framing.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
