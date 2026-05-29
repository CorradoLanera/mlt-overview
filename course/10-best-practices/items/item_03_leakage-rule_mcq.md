# Item 03 — Protect the test (R2): when the test stops being a test

**ID**: IB-10-best-practices-03
**Learning objective**: *The data-leakage rule.* **Any** decision (model choice, hyperparameter, feature set, threshold) that is taken **after** having seen a performance number on a dataset *converts that dataset into a training set* — even if the file is labelled "test". A faithful test set is one that has been **looked at exactly once, at the end, and never again** (Obj. 2 — Rule R2, *leakage rule*).

**Category**: Application
**Type**: MCQ
**Difficulty**: medium-high
**Chapter**: 10-best-practices

## Question

A colleague — Davide — built a $30$-day ICU readmission classifier on the same hospital extract ($5\,000$ patients, $50$ candidate features, prevalence $p \approx 5\%$, $70 / 15 / 15$ train / validation / test split). He narrates, at lab meeting, the sequence of moves he took. He plans to report the final test-set number in his methods write-up.

> **Step $1$.** Train logistic regression on *training*. Validation AUPRC $= 0.25$.
> **Step $2$.** Train gradient boosting on *training*. Validation AUPRC $= 0.31$.
> **Step $3$.** Pick gradient boosting. Tune hyperparameters (learning rate, max depth, regularisation) by cross-validation on *training*. Final validation AUPRC $= 0.34$.
> **Step $4$.** Open the *test* split for the first time. Read **test AUPRC $= 0.29$**.
> **Step $5$.** Decide *"the L$2$ penalty looks a bit weak — let me nudge it up by a factor of two"*. Retrain. Re-open the *test* split. Read **test AUPRC $= 0.31$**, and plan to report this as the headline number in the *Methods* and the abstract.

Under the chapter's *leakage rule* (R2), is **$0.31$** a faithful test number?

## Options

- A) **Yes.** $0.31$ is the model's performance on a split that was held out during training — the model was never fit on the test rows, so the number is honest. The fact that Davide read the test set twice does not change the train/test separation: he did not train on it.
- B) **No.** Davide took a modelling decision (the L$2$ bump in Step $5$) *after* having seen a performance number on the test set (in Step $4$). Under R2, *any decision taken after observing a performance number on a dataset converts that dataset into a training set* — the second test reading ($0.31$) is therefore read off a *contaminated* test, and the original test split is, retrospectively, a third *training* split. The faithful number for this audit is **neither** $0.29$ **nor** $0.31$ — and the procedure now requires a *new* held-out split, drawn fresh from training data, before any defensible test number exists.
- C) **Yes** — provided Davide reports **both** numbers ($0.29$ and $0.31$) in the *Methods* section, and explicitly describes the L$2$ change between them. Full disclosure of the iteration preserves the test's epistemic status: the reader can see exactly what happened, judge the procedure, and discount the second number if they wish.
- D) **Yes** — provided Davide splits a *fresh validation* set from the training pool and re-tunes the L$2$ penalty on that fresh validation, then reads the **same** test split he originally used. With the tuning moved off the test, the second test number ($0.31$) becomes the legitimate held-out result of the corrected procedure.

## Expected answer

**Correct: B.** Option B is the only one that applies R2 in its **operationally exact** form. Three components carry the answer:

- **The rule triggers on the *decision*, not on the *observation*.** Step $4$ alone — reading the test number — does not, by itself, trigger R2: a single observation, *with no decision taken on the basis of that observation*, leaves the test set faithful. R2 triggers at Step $5$, when Davide *decides* to bump the L$2$ penalty *because* of what he saw at Step $4$. The decision is what *uses* the test-set information to shape the model, and that use is what *converts the test into a training set*. (The chapter's narrative makes this distinction explicit: *"the key is not the looking, it is the deciding after having looked"*.)
- **The contamination is retrospective, not prospective.** Once R2 has been violated, the original test split is **no longer a test split** — and there is no procedure, applied afterwards, that restores it. Reading the test *again* at Step $5$ is reading from a split that has already lost its epistemic status; the number $0.31$ is an inflated *training-grade* number, not a faithful *test-grade* one. The faithful number for this audit is therefore *neither* $0.29$ *nor* $0.31$: $0.29$ was *technically* faithful at the moment it was read, but Davide cannot now report it as "the test result" without also disclosing that he iterated on it (which would change the framing entirely); and $0.31$ was *never* faithful.
- **The correct fix is a *new* held-out split.** The only way to obtain a defensible test number, given that R2 has been violated, is to draw a **new** test split from the training pool — a split that has never been observed in *any* decision-relevant context — and read it exactly once at the end. (A new *validation* split fixes future hyperparameter tuning, but it does *not* repair the already-contaminated test; the chapter's discipline is precisely that the *test* must be a split that is "looked at exactly once, at the end, and never again", and a split that has been looked at twice can never be that split again.)

Why the distractors are plausible but wrong:

- **A** is wrong because it reads R2 as *a rule about training, not a rule about decisions*. The student who picks A is reasoning: *"the model was never fit on the test rows, so the test rows are uncontaminated"* — and this is true *as a statement about gradient descent*, but R2 is *not* about gradient descent. R2 is about *epistemic leakage*: the test set transfers information into the model not only via gradient updates, but also *via decisions made on the basis of test-set numbers* — those decisions (which hyperparameter to use, which split to keep, which run to report) carry test-set information back into the trained model, and the model that emerges from those decisions is, in effect, fit to the test set as well. A student who picks A has the textbook-mechanical reading of "test set" (*"it is the data the model was not fit on"*) without the chapter's *operational* reading (*"it is the data on which no decision has yet been taken"*). This is the Poll $2$ *"yes"* distractor of [objectives.md](../objectives.md) translated into a scenario.
- **C** is wrong because it confuses *transparency* with *correctness*. The student who picks C is reasoning: *"if I disclose what I did, the reader can judge, so the result is preserved"* — and disclosure *is* an ethical duty, but it does **not** un-contaminate the test set. The contamination is *structural*: the second number is statistically *biased* (it reports the L$2$ penalty's performance *on the data that selected the L$2$ penalty*), and that bias persists regardless of whether the reader knows about it. A transparent report of a biased number is still a biased number. The chapter's discipline is *operational*, not *rhetorical*: the test set's epistemic status is established by *how the work was done*, not by *how the work is described*. A student who picks C has internalised the (correct) norm that *one should disclose methodology* but has not internalised the (chapter-specific) rule that *some methodologies cannot be rescued by disclosure*. This is the Poll $2$ *"yes if both reported"* distractor.
- **D** is the **subtlest distractor**, and it is the response of a student who **has already seen serious work**. The student is reasoning: *"yes — the procedure was flawed, the fix is to use a fresh validation set for the tuning, and once that's in place the test number stands"*. The first half of the reasoning (the operational fix) is **directionally correct** and should be acknowledged at the reveal — *fresh validation* is, in general, the right way to separate tuning data from the held-out test. The second half is **wrong**, and on a specific point: *fresh validation* fixes the procedure **going forward**, but it does **not** repair the *already-contaminated* test set. By Step $5$, the original test split has already been used in a decision (the L$2$ bump); that decision has already imported test-set information into the model; the number $0.31$ is already a *training-grade* number; and no procedure applied afterwards can revoke that. The chapter's exact wording handles this case: *"the test set is one that has been looked at exactly once, at the end, and never again"* — a split that has been looked at twice **can never be that split again**, no matter what is done afterwards. The corrected procedure requires a **new test split** (drawn fresh from training data), not just a new validation split. A student who picks D has the *operational instinct* of someone who has worked in a real lab (they know about fresh validation as a fix) but has not internalised that *the contaminated test cannot be repaired* — only *replaced*. The diagnostic for the corrector: at the reveal, *praise the operational direction* (fresh validation is right), but *correct on the specific point* (the original test is now training; the second number $0.31$ remains contaminated; the fix is a *new test*, not a *fresh validation that legitimises the old test*). This is the Poll $2$ *"only after a fresh validation"* distractor.

The single discriminator across A / B / C / D is whether the student reads R2 as a rule about *decisions taken on a dataset*, applied *retrospectively to the moment the decision was made*: (A) reads it as a rule about *training*; (C) reads it as a rule about *disclosure*; (D) reads it as a rule about *future procedure*. Only B reads it as the chapter's *operational rule* — that the test loses its status at the moment of the *decision*, that no fix applied afterwards restores it, and that the only defensible move is to draw a *new* held-out split.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
