# Item 04 — Interpretability defence: technique + clinical argument

**ID**: IB-10-best-practices-04
**Learning objective**: Match the interpretability technique to the model family — **linear / logistic regression** $\to$ *coefficients*; **decision tree** $\to$ *decision path*; **random forest / gradient boosting** $\to$ *variable importance*; **neural network / deep model** $\to$ *SHAP or surrogate models* — and weigh the interpretability/performance tradeoff in a healthcare deployment context. State the operational rule: *if the deployment requires clinical defensibility, prefer a model whose interpretability is built-in (linear or single tree) — unless the performance gap to the opaque model is large enough that the patient is better off with the box-with-attribution than with a simpler model that misclassifies more often. The tradeoff is a clinical decision, not a technical one* (Obj. 3).

**Category**: Application
**Type**: open-ended (*applicativa*)
**Difficulty**: medium-high
**Chapter**: 10-best-practices

## Question

The audit is over. The final model for the $30$-day ICU readmission task is **random forest** on $\sim 12$ clinically-chosen features, with validation AUPRC $= 0.32$ — an escalation from logistic regression on $6$ clinically-chosen features (validation AUPRC $= 0.27$), justified by the pre-registered stop-criterion (target $\ge 0.30$, baseline missed it). The clinical lead has signed off on the cost ratio between false positives and false negatives, and the threshold has been set on a *fresh validation* split for an operating point of recall $\approx 0.55$ at precision $\approx 0.40$. The defence to the clinical lead and the ethics committee is in five days.

Write the **Interpretability** section of the defence document. The section must contain:

(a) **Which interpretability technique** you will use to explain the model to the clinical lead and the ethics committee, with one or two sentences on *why this technique matches this model family* — and why the alternative (reading off coefficients) is not available for a random forest.

(b) **One sentence** stating why the choice in (a) — rather than reverting to logistic regression on the original $6$ features and reading off coefficients — is **clinically defensible** before the ethics committee.

*Plain prose. No code, no diagrams. Write as text the clinical lead could read aloud back to the committee without rephrasing.*

## Expected answer

A response at the *Excellent* level reads approximately as follows.

> **(a)** *We will use **variable importance** computed across the random forest ensemble — a ranking of the features by how much each contributes, on average across the trees, to the model's ability to separate readmitted from non-readmitted patients. Variable importance matches the random forest family because the model's prediction is the **average across many independent trees**: no single tree's coefficient or rule is the model, so there is no per-feature weight with sign and magnitude to read off, the way logistic regression's coefficients are read off — the natural read-from-the-model route is therefore unavailable, and a **post-hoc** ranking like variable importance is what stands in for it. For the ethics committee's question "what does the model rely on?" we report the global variable-importance ranking; for the clinical lead's question "why **this** patient?" we additionally show the values of the top-ranked features on that specific patient's chart, so the explanation lands on the record the clinician is already reading.*
>
> **(b)** *The random forest catches meaningfully more readmissions than the logistic baseline on the validation set (AUPRC $0.32$ vs $0.27$, an extra recall margin that is, at this service, clinically material) — and the clinical cost of a missed $30$-day readmission (re-admission, possible adverse event, longer length of stay) substantially exceeds the cost of explaining each prediction with a feature-importance ranking rather than with a single logistic coefficient, so on this audit the patient is better served by the more accurate model with a variable-importance defence than by the simpler logistic model that misses more events.*

What the response must contain, across the three criteria of the rubric:

- **C1 — Technique matching to model family.** Names *variable importance* as the technique for the random forest. Rules out reading off *coefficients* (which exist for logistic regression, not for tree ensembles). At higher levels, distinguishes *global* variable importance (population-level — the ethics committee's *"what does the model rely on?"*) from a *per-patient* explanation (the clinical lead's *"why this patient?"*) — and either provides a concrete per-patient route (the top-ranked features read against the patient's chart) or, as a bonus, names a per-patient attribution technique seen outside the classroom (e.g. SHAP, LIME, partial dependence at the patient's values).
- **C2 — Technical justification of the matching.** States a correct technical reason for the matching, ideally framed as the chapter's *built-in* (linear → coefficients, single tree → decision path) vs *post-hoc* (RF/GB → variable importance, NN → SHAP or surrogate) distinction. At higher levels, recognises the chapter's full $1{:}1$ mapping as a *rule*, not a *menu of options* — the technique follows the structure the model exposes, not the analyst's preference.
- **C3 — Clinical defensibility framing.** Defends the choice as a **clinical decision**, not as a technical preference: the subject of the defence sentence is the *patient* (not the model), the cost-of-failure is *clinically named* (re-admission, adverse event, length of stay — not just *"performance"*), and the tradeoff is positioned as the *clinical lead's call* (given the cost ratio they have signed off on), not the data scientist's. At the Excellent level the sentence reads as something the clinical lead could *read aloud back to the ethics committee* without rephrasing.

A response that **inverts the choice** — i.e. that argues the team should **revert to logistic regression on $6$ features and read off coefficients** because *"on this audit, the extra recall the random forest buys is below the threshold our clinical lead has set for accepting model opacity"* — **is accepted at Excellent** if the matching is technically correct (logistic $\to$ coefficients) AND the clinical argument is well-posed (the tradeoff is *named*, the cost-of-failure is *clinically qualified*, the subject is the *patient*). The rubric measures *applying the tradeoff as a clinical decision*, not *picking random forest*.

A response that cites **SHAP**, **LIME**, **Shapley values**, or another per-patient attribution technique as a *bonus* on top of variable importance — typically from independent reading or from recalling the chapter's narrative illustration of *SHAP-on-a-forest* — is accepted at Excellent **if** the citation is anchored operationally (the student names what SHAP *adds* over variable importance: per-patient attribution that variable importance, being global, does not provide). A mechanical citation of *"SHAP because it is the standard"* without the operational anchor is at *Base / Good* on C2, **not** Excellent — the rubric does not require SHAP, but it does require *reasons* for whichever technique is named.

## Rubric

[rubrica_04_interpretability-defence.md](../rubriche/rubrica_04_interpretability-defence.md) — $3$ criteria $\times$ $3$ levels (Base / Good / Excellent).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*
