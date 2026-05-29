# Item 02 — Protect the test (R1): the accuracy trap on $p = 5\%$

**ID**: IB-10-best-practices-02
**Learning objective**: Choose metrics for the problem you actually have, *not* for the problem accuracy assumes you have. On an **imbalanced** problem with positive-class prevalence $p$ (e.g. $p = 1\%$, a rare event), reporting *accuracy* is misleading because the always-predict-majority classifier reaches accuracy $= 1 - p$ while being *clinically useless* — use **precision**, **recall**, **F1**, or **AUPRC** instead, and *pick the threshold deliberately based on the clinical cost of false positives vs false negatives* (Obj. 2 — Rule R1, *accuracy trap*).

**Category**: Comprehension/Application
**Type**: MCQ
**Difficulty**: medium
**Chapter**: 10-best-practices

## Question

At Tuesday's lab meeting, a senior colleague — Sara — presents the results of her **$30$-day ICU readmission** classifier on the hospital's de-identified extract ($5\,000$ patients, prevalence $p \approx 5\%$, logistic regression on $8$ clinically-chosen features). Her closing slide is titled *"Excellent classification performance"* and reads:

> *"Logistic regression achieves $94.8\%$ accuracy on the held-out test set."*

The room is quiet; the PI nods. You are asked to comment. Which of the four critiques below applies the chapter's *accuracy trap* discipline (Rule R1) correctly?

## Options

- A) *"$94.8\%$ accuracy is roughly the score the always-predict-NO classifier would get on this kind of problem — but in our hospital around one-in-five ICU patients gets readmitted within $30$ days, so the always-predict-NO baseline would actually be near $80\%$, not $95\%$. Your model is therefore meaningfully above baseline, but I'd still like to see recall."*
- B) *"$94.8\%$ is essentially the accuracy of the always-predict-NO classifier on this prevalence ($1 - p = 95\%$), which has recall $0$ on the readmission class. Accuracy alone, on this dataset, cannot distinguish your model from always-predict-NO. Can you show recall (or AUPRC) on the positive class — at the threshold you would actually use in practice?"*
- C) *"$94.8\%$ is well above the $50\%$ baseline that a random classifier would achieve on a binary problem, so the model is clearly doing better than chance. The next step is to confirm that this generalises beyond the test set."*
- D) *"$94.8\%$ accuracy means the model is right $94.8\%$ of the time across the patient population — that's the overall hit rate, and it's what matters for clinical deployment. The class imbalance means more of the correct calls are on non-readmitted patients, but the model is still right most of the time."*

## Expected answer

**Correct: B.** Critique B is the only one that names *the* baseline that accuracy cannot, on this dataset, distinguish the model from — the **always-predict-NO classifier**, whose accuracy is exactly $1 - p = 95\%$ on a prevalence of $p = 5\%$ — and asks for the metric that *can* make the distinction:

- **Names the right comparator.** *Always-predict-NO* (the *majority* baseline) is the relevant baseline on imbalanced data, not the coin-flip random baseline. The majority baseline's accuracy is $1 - p$, which on $p = 5\%$ is *exactly* $95\%$. Sara's $94.8\%$ sits *inside* the band where always-predict-NO already lives.
- **Names the right discriminator.** *Recall on the positive class* (i.e. *sensitivity on readmission*) and *AUPRC* are the metrics that *cannot be inflated by majority-prediction*: always-predict-NO has recall $= 0$ on the positive class by construction, and AUPRC summarises the precision–recall curve without giving the negative class the integration weight it dominates in AUROC. Any positive value on these metrics is evidence the model is doing real work.
- **Names the operational caveat.** *"At the threshold you would actually use in practice"* anchors the metric request to the *operating point* — Sara's $94.8\%$ does not tell you where on the precision–recall curve she is. Reporting recall *at a specific threshold* (the one a clinician would use) is what makes the metric *clinically* informative, not just *statistically* better than accuracy.

Why the distractors are plausible but wrong:

- **A** is wrong on **the prevalence**. The critique *recognises* the always-predict-NO trap as a category — that is the half-correct move — but reads the prevalence as $p \approx 20\%$ (*"one-in-five ICU patients"*) instead of the stated $p \approx 5\%$. The always-predict-NO baseline is then mis-computed as $80\%$, and Sara's $94.8\%$ is judged *meaningfully above baseline* — which is *false* on this dataset, because the real always-predict-NO score is $95\%$ and Sara is *below* it by $0.2$ percentage points. A student who picks A has the *right concept* (compare against the majority baseline) but applied it with the *wrong number*. This is the *"$80\%$"* distractor of Poll 1 in [objectives.md](../objectives.md) translated into a verbal critique. Diagnostic for the corrector: in clinical-ML reading, *misreading the prevalence by a factor of three or four* is a more common failure than *not knowing what prevalence is* — the student knows the concept but does not check the number against the stated value before reasoning forward.
- **C** is wrong on **the baseline class**. The critique compares Sara's $94.8\%$ to the $50\%$ baseline of a coin-flip random classifier, concluding *"clearly above chance"*. But the relevant baseline on imbalanced data is *never* the coin-flip ($50\%$): a coin-flip on $p = 5\%$ achieves accuracy $0.5 \cdot 0.05 + 0.5 \cdot 0.95 = 0.5$, while the always-predict-majority classifier achieves $1 - p = 0.95$ — and the majority classifier is *deterministic*, requires *no training*, and is the *trivial baseline that any non-trivial model must clearly beat*. Comparing to $50\%$ instead of $95\%$ confuses *random-baseline* with *majority-baseline* on imbalanced data — exactly the *"$50\%$"* distractor of Poll 1. A student who picks C has carried over the binary-classification intuition that *"$50\%$ is the floor"* from the balanced-data world, where it holds. On imbalanced data the floor is $1 - p$, not $0.5$, and the floor *moves with the prevalence* — which is the part of the chapter the student has not internalised. The tail clause *"the next step is to confirm that this generalises beyond the test set"* is a separate concern (and prematurely touches the leakage rule, R2) but does not save the diagnosis: the metric is uninterpretable *before* generalisation is even on the table.
- **D** is wrong on **what *accuracy* on imbalanced data means clinically**. The critique reads *"the model is right $94.8\%$ of the time"* as if *"being right"* on the patient population were the clinically-meaningful target — when in fact the $95\%$ of patients on whom *being right* is easy (the always-no-readmission majority) are precisely the patients the model was *not* built to identify. On $p = 5\%$, an accuracy of $94.8\%$ is compatible with sensitivity $= 0\%$ and specificity $\approx 99.8\%$ — *zero readmissions correctly identified*, with all the apparent score coming from correctly classifying negatives. The clinically-useful target is *being right on the rare event* (readmission), and the *"overall hit rate is what matters"* framing dilutes this signal — the model can be right on $94.8\%$ of patients and still recall *zero* readmissions, which is operationally the worst outcome for a tool the clinical lead would consider deploying. This is the *"$100\%$"* distractor of Poll 1 translated into a misreading: the student equates *"how often we're right"* (plain English) with *"how clinically useful we are"* (the actual question). The plain-English reading of *accuracy* — *"how often we're right"* — is the trap; the formal reading (a weighted average where the majority class swamps the minority) is what the chapter asks the student to use.

The single discriminator across A / B / C / D is whether the student computes *the right baseline on the right prevalence* before reading any model score: $1 - p = 95\%$ on this dataset (which rules in B), $1 - 0.2 = 80\%$ on a *different* dataset that this isn't (which rules out A), $0.5$ on a *random* baseline that doesn't apply to imbalanced data (which rules out C), and *no baseline computation at all* — only a plain-English reading of *"the model is right $94.8\%$ of the time"* (which rules out D). Only B applies the *accuracy trap* discipline with the *correct prevalence*, the *correct baseline class*, the *correct discriminating metric*, and the *correct operating-point anchor*.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
