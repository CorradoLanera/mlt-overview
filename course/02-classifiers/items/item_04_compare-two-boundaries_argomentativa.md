# Item 04 — Compare two boundaries: argue within the chapter's limits

**ID**: IB-02-classifiers-04
**Learning objective**: Argue, using the chapter's tools (classifier as $f:\mathbb{R}^d \to \{1,\ldots,K\}$ partitioning the feature space, 0/1 loss, risk as average loss on the sample), which of two competing classifiers is supported by the evidence available; *and* identify the kind of information that would be needed to go beyond what the chapter can settle (Obj. 2 + Obj. 3 + epistemic awareness of chapter scope).
**Category**: Argumentation
**Type**: argomentativa (open-ended)
**Difficulty**: medium–high
**Chapter**: 02-classifiers

## Question

Two clinicians, A and B, are working on the **same** 10-patient test sample. Each has built a classifier — a function $f:\mathbb{R}^2 \to \{0, 1\}$ that flags each patient as *high-risk* ($1$) or *low-risk* ($0$) — and the two classifiers disagree because their decision boundaries carve the feature space differently. On this 10-patient sample:

- $f_A$ correctly classifies **7 of 10** patients (3 misclassified).
- $f_B$ correctly classifies **8 of 10** patients (2 misclassified).

The two clinicians argue:

- **Clinician B:** *"My classifier $f_B$ is the better one — its 0/1 risk on this sample is lower."*
- **Clinician A:** *"That is only on these 10 patients. My classifier might do better on a different group."*

Answer the three sub-questions:

1. State the **0/1 risk on the sample** of each classifier as a fraction.
2. **Within the concepts of this chapter** — classifier as a function partitioning the feature space, 0/1 loss, risk as average loss on the sample — **whose claim is supported by the evidence available so far?** Justify in 3–5 sentences, naming explicitly the criterion the chapter gives you for comparing classifiers.
3. Clinician A's pushback raises a real concern *beyond what this chapter has given us*. **What kind of information about the data would we need** in order to settle whether $f_A$ might actually do better on "a different group of patients"? (You do **not** need to specify a *method* for collecting it — just state what would have to be true of the data we use to compare them.)

## Expected answer

1. $\text{risk}(f_A) = 3/10$ on this sample; $\text{risk}(f_B) = 2/10$ on this sample.

2. **Clinician B's claim is supported by what this chapter has given us.** This chapter provides exactly one criterion to compare two classifiers: their **0/1 risk on the available sample** — the average 0/1 loss over the patients we have measured. By that criterion $f_B$ ($2/10$) is lower-risk than $f_A$ ($3/10$); under the chapter's lens, that is what *"better classifier"* means here. Clinician A's pushback is a **hypothesis about patients we do not have**, and within the tools of ch. 02 we have **no way to compare** classifiers on patients absent from the sample: there is no number we could compute that would tell us about a "different group" we have not measured. So Clinician B has evidence from the data we possess; Clinician A has — at this point — only a hypothesis.

3. To settle Clinician A's pushback we would need **0/1 risk estimates on patients that are not in the 10-patient sample on which $f_A$ and $f_B$ have been compared so far**. Equivalently: a *second* set of patients (separate from the one used here, with their true labels also known) on which both classifiers can be evaluated, giving a fresh 0/1 risk for each on patients neither classifier was assessed on before. Within ch. 02 alone we have no such second set, so the question Clinician A is asking is *exactly the question the chapter cannot yet answer* — and that is the natural endpoint of the chapter. *(This is what ch. 04 will pick up.)*

## Rubric

See [rubriche/rubrica_04_compare-two-boundaries.md](../rubriche/rubrica_04_compare-two-boundaries.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
