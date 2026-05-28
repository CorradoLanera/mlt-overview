# Rubric — Item 04 (Critique a learning-problem framing)

**Item**: IB-01-introduction-04
**Objective**: Classify a scenario into the correct learning paradigm and justify it from the kind of supervision available, by arguing against a plausible but mistaken framing.

| Criterion | Base | Good | Excellent |
|---|---|---|---|
| **C1 — Refute the "labels are available" argument** | States that the ICD codes do not fit, without a clear reason | Explains that ICD codes are *pre-existing*, human-defined categories — not the previously unrecognised subgroups the goal asks to discover | As *Good*, and articulates the core point: training on them only reproduces known labels, so "labels available" ≠ "labels that match the goal" |
| **C2 — Correct paradigm + justification** | Names unsupervised learning, but the justification is weak or missing | Names unsupervised learning (clustering) and justifies it by the absence of labels for the *target* (the phenotypes) | As *Good*, and frames it as discovering structure/subgroups in data unlabelled w.r.t. the goal |
| **C3 — Reframe (when supervised is right)** | Vague or no statement | States that supervised fits if the goal were instead to predict a known diagnosis | As *Good*, and is specific: predicting the patient's existing ICD code from the lab panels, with the ICD codes as legitimate target labels |

**Threshold (sufficiency)**: at least **Base** on all three criteria; **C1 and C2 at least Base are mandatory** — refuting the plausible framing and naming the correct paradigm are the load-bearing points.

**Bias da evitare in correzione** *(nota docente):* valutare la *coerenza dell'argomentazione*, non le parole-chiave; il punto chiave è "label disponibili ≠ label che servono all'obiettivo", non il termine esatto; accettare "clustering"/"unsupervised"/descrizione equivalente; non penalizzare lessico imperfetto se il concetto è chiaro; non premiare la lunghezza.
