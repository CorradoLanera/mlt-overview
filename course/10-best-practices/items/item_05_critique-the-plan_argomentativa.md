# Item 05 — Critique Anna's plan: four violations of three disciplines

**ID**: IB-10-best-practices-05
**Learning objective**: Synthesise the chapter's three disciplines — *earn complexity* (Obj. 1), *protect the test* in its two rules R1 *accuracy trap* and R2 *leakage rule* (Obj. 2), *match interpretability to the model family + weigh the tradeoff as a clinical decision* (Obj. 3) — on a project plan that violates each discipline at a single, isolable point. Identify each violation by the chapter's vocabulary, articulate the operational consequence (what the clinical lead or the ethics committee will reject and why), and propose a corrected plan that fixes all four violations as **one coherent revision** — not four patches glued together. The corrected plan must read as the **order of operations** the three disciplines compose: *start simple, measure honestly, defend clinically* (Obj. 1 + Obj. 2 + Obj. 3 in synthesis).

**Category**: Argumentation
**Type**: open-ended (*argomentativa*)
**Difficulty**: high
**Chapter**: 10-best-practices

## Question

A colleague — **Anna** — circulates the following **project plan** by email on Friday morning, for the $30$-day ICU readmission audit ($5\,000$ patients, $50$ candidate features, prevalence $p \approx 5\%$, defence to clinical lead + ethics committee in three weeks).

> *"Friday morning — sending the project plan for the $30$-day ICU readmission audit.*
>
> *(1) **Model**: random forest on all $50$ features, since random forest is the best model class for tabular clinical data — it handles non-linearity and feature interactions automatically, and there's no reason to start with anything simpler.*
>
> *(2) **Metric**: accuracy on the held-out test set. If we hit $\ge 90\%$, the model is ready for the defence.*
>
> *(3) **Hyperparameter tuning**: $5$-fold cross-validation on the combined train+test data, to maximise statistical power and reduce variance in the estimates.*
>
> *(4) **Interpretability**: if the committee asks, I'll read off the coefficients of each feature in the random forest — coefficients are the standard interpretability technique.*
>
> *Plan to defend in three weeks."*

Anna's plan contains **four** distinct violations of the chapter's three disciplines — one violation per numbered point. Write a critique of the plan that:

(a) **Names each violation by the chapter's vocabulary** — you should find one violation of *earn complexity* (Obj. 1), one of the *accuracy trap* rule R1 (Obj. 2), one of the *leakage rule* R2 (Obj. 2), and one of the *match interpretability + clinical defensibility* discipline (Obj. 3). Anchor each name to the specific sentence in Anna's plan.

(b) **For each violation, explain in one or two sentences why it breaks the defence** — what the clinical lead or the ethics committee will reject when they see it, and what specifically about Anna's text triggers the rejection.

(c) **Propose a corrected plan** that fixes all four violations as **one coherent revision** — written as the order of operations the three disciplines compose (not four patches glued onto Anna's original).

*Plain prose. Write the critique as text Anna could read and understand without you sitting next to her. No code, no diagrams. Bullet lists are acceptable only in (a) if they help anchor each violation to a sentence of the plan.*

## Expected answer

A response at the *Excellent* level reads approximately as follows.

> **(a) Anna's plan violates each of the three disciplines in turn — one violation per numbered point of her email.**
>
> - Point $(1)$ violates **earn complexity** (Obj. $1$). The plan ramps directly to random forest on all $50$ features as the *primary* model, with no logistic-regression baseline on a smaller clinically-chosen subset, no pre-registered target, and no stop-criterion written before training. The justification — *"random forest is the best model class"* — is a population-level prior, not a project-level argument.
> - Point $(2)$ violates the **accuracy trap** rule (Obj. $2$, R1). The plan reports *accuracy* on a problem with prevalence $p \approx 5\%$, where the always-predict-NO classifier already scores $1 - p = 95\%$ — and sets the success threshold at $\ge 90\%$, a number Anna has not compared to that baseline.
> - Point $(3)$ violates the **leakage rule** (Obj. $2$, R2). $5$-fold cross-validation on the *combined* train+test data uses the test set to choose hyperparameters; *any decision taken after observing the test set converts the test set into a training set*. There is no test set left to read at the end.
> - Point $(4)$ violates the **match interpretability + clinical defensibility** discipline (Obj. $3$). Random forests do not expose coefficients — the prediction is the average across many trees, so there is no per-feature linear weight to read off; the chapter's mapping for ensembles is **variable importance**, not coefficients. The framing — *"if the committee asks"* — treats interpretability as an afterthought, not as a clinical defensibility argument the team owes the patient.
>
> **(b) Why each violation breaks the defence.**
>
> The earn-complexity violation breaks the defence because the ethics committee's question *"why **this** model?"* cannot be answered with general superiority in the literature; it must be answered with a documented failure of the simpler model on **this** dataset. Anna has no such document.
>
> The accuracy-trap violation breaks the defence the moment the clinical lead does the arithmetic: $1 - p = 95\%$ is what the model that always-predicts-NO would score on this prevalence, and Anna's success threshold of $90\%$ sits *below* it. Her *"ready for defence"* model would, in the strict reading, be a model that performs **worse** than doing nothing — a number the clinical lead will not pass to the committee.
>
> The leakage-rule violation breaks the defence because the test number Anna will report is, by construction, a number read off a split she used to tune the model. The ethics committee's question *"why should I trust this on my next patient?"* is the question the held-out test is supposed to answer; Anna will have nothing held-out to answer it with.
>
> The interpretability violation breaks the defence on **two** axes. First, the matching error: Anna will sit in front of the clinical lead, open her notebook, and find that her *coefficients-on-random-forest* technique does not exist — there are no coefficients to read. Second, the framing error: *"if the committee asks"* is an afterthought; the chapter's discipline requires a clinical-defensibility argument the team poses **before** the committee even asks — the argument is owed to the **patient**, regardless of whether the committee remembers to interrogate it.
>
> **(c) The corrected plan.**
>
> Before any training, Anna writes the stop-criterion: *baseline = logistic regression on $5$–$10$ clinically-chosen features (e.g. age, ICU length of stay, Charlson comorbidity index, prior $90$-day admissions, discharge-time eGFR, number of medications at discharge); baseline metric and target = AUPRC $\ge 0.30$ (or, equivalently, recall $\ge 0.55$ at precision $\ge 0.40$) on a held-out **validation** split; escalation rule = if the baseline does not reach the target, escalate to random forest on a wider clinical feature set; if the baseline reaches the target, ship the baseline*. The metric is not accuracy — it is AUPRC or recall-at-precision, because $5\%$ prevalence makes accuracy uninterpretable, and the threshold is set by the cost ratio the clinical lead signs off on, not by an arbitrary $90\%$. Hyperparameter tuning runs on a **fresh validation split** drawn from the training pool; the test set is **sealed** in a separate folder until the day of the defence, and is opened **exactly once**, on that day. And the interpretability technique is matched to whatever model finally ships: **coefficients** if the logistic baseline reaches the target (which, on this audit, is the most defensible outcome — built-in interpretability, simpler model, smaller per-patient risk per unit error); **variable importance** + the top-ranked features read against this patient's chart if escalation to random forest is required, with the tradeoff between *missed readmissions* and *loss of built-in interpretability* posed explicitly to the clinical lead as a *clinical decision*, given the cost ratio they have set.
>
> The corrected plan does not predetermine the model; it predetermines the **discipline** that decides between the models. The three disciplines compose — *start simple, measure honestly, defend clinically* — and they compose as an **order of operations**, not as four independent patches on Anna's plan.

What the response must contain, across the three criteria of the rubric:

- **C1 — Identification of violations.** All four violations named by the chapter's vocabulary (*earn complexity*, *accuracy trap*, *leakage rule*, *match interpretability + clinical defensibility*), each anchored to the specific numbered point of Anna's plan that triggers it. At higher levels, the student recognises that the interpretability violation has *two* components — the *matching error* (coefficients on a random forest) and the *framing error* (*"if the committee asks"* as an afterthought).
- **C2 — Operational diagnosis.** For each named violation, the student articulates the *specific operational consequence* — what fails, who rejects it, and what about Anna's text triggers the rejection. At higher levels, the student names the *cascading failure mode* — the four violations reinforce each other (e.g. *the accuracy threshold of $\ge 90\%$ is below the always-predict-NO baseline of $95\%$, which masks the absence of a real baseline*).
- **C3 — Corrected plan.** The student proposes a single coherent revision that fixes all four violations as an *order of operations*: stop-criterion ex ante → metric matched to the problem → split discipline (sealed test + fresh validation) → interpretability matched to whatever model ships. At higher levels, the student frames the corrected plan as *not predetermining the model* (the simplest possible outcome — logistic + coefficients — is named as the **most defensible** outcome, not as a fallback), and explicitly states that the three disciplines are *an order of operations*, not *independent rules*.

## Rubric

[rubrica_05_critique-the-plan.md](../rubriche/rubrica_05_critique-the-plan.md) — $3$ criteria $\times$ $3$ levels (Base / Good / Excellent).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
