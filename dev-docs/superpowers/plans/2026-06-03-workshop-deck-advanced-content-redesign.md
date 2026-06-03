# Workshop deck — Advanced content redesign (plan 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the *exact same* per-step arc + in-deck formatives pattern proven on the Basic deck to the Advanced deck (`slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`): WHY-led step intros, the 11 formatives as in-deck **Engage → Reveal** pairs, per-step **Go to code** closers, the standalone formative HTMLs retired, and the concept-map mermaid made race-proof.

**Architecture:** Pure content authoring in one hand-authored Quarto revealjs `.qmd`. **The Basic deck (`../mlt-r-basic/00-basic-deck.qmd`) is the live reference exemplar** — every slide here matches its conventions. No pipeline/`_quarto.yml`/script changes. Each `# Step NN` divider becomes the WHY intro; existing theory slides are kept; each formative becomes a 2-slide Engage→Reveal pair at its mapped point; each step ends with a Go-to-code slide. The honesty-rule slide + labeled loss curve stay **content** (min-92 verifies them). The single concept-map mermaid gets the race-proof system-font treatment. Finally the 11 `formatives/min-*.md` (+ rendered `.html`/`_files`) are deleted and `formatives/README.md` becomes the map.

**Tech Stack:** Quarto revealjs (embed-resources, 1648×1080), `styles/_brand.scss` + `theme.scss`, pandoc MathML, Quarto CLI, chrome-devtools MCP for visual verification.

**Reference spec:** `dev-docs/superpowers/specs/2026-06-03-workshop-deck-content-redesign-design.md` (§8 Advanced inherits).
**Reference exemplar (live):** `slides/workshops/mlt-r-basic/00-basic-deck.qmd` — committed, visually verified.
**Source of formative content:** `slides/workshops/mlt-r-advanced/formatives/{README.md, min-*.md}` (present until Task 7). Exact Engage/Reveal text reproduced inline below.

---

## Conventions used by this plan

- **Branch:** `workshop-deck-redesign` (already in use; Basic is already done on it).
- **Render (per-task verify):** `quarto render slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` → `Output created: 00-advanced-deck.html`, no error. (Do **not** whole-project render during step tasks — it would re-render the still-present standalone formatives. Whole-project render returns only in Task 7.)
- **Visual verify (per-task):** chrome-devtools MCP — open the `file://` URL of `00-advanced-deck.html`, **hard reload** (`navigate_page` reload `ignoreCache:true`) to pick up the new render, resize to 1648×1080, navigate to the new slides by their heading-id hash (e.g. `#/your-turn-...`), screenshot, check for overflow/overlap/clipped code/math-not-rendering. Spot-check a ~1100px width.
- **Language:** slide text **English**; `::: {.notes}` **Italian**, instructor's (Corrado) first-person voice. Empty line before every list. All math in `$...$`/`$$...$$`. Native pipe `|>`.
- **Formative slide convention (identical to Basic):** **Engage** heading `## Your turn — …` (MCQ/your-turn/predict/Parsons) or `## Live check — …`; ends with a commitment line (`*Pick one — then we reveal it.*` / a predict prompt / "Run it…"). **Reveal** heading names the takeaway (`## The answer — A: …` MCQ, `## My turn — …` your-turn, `## The reveal — …` predict, `## GREEN — …` live-check). MCQ reveals: `**✓ A.**` then `**✗ B/C/D**` each with the one-line why. Optional de-personalized `**Going further.**` (ex-`Stretch (Davide)`). **Plain headings — no `data-menu-title`; `min-NN` and timing live ONLY in `::: {.notes}`.**
- **Commits:** one logical change per commit, prefix `slides(advanced):`. **Never `git push`.**
- **Do NOT touch:** opening slides (title, find-me, credits, `# Open the model you validated in Basic` day-overview), closing slides (`## You can hand this pipeline to a peer`, further reading, thank-you), `_quarto.yml`, `theme.scss`. Existing theory/content slides keep their body unless a task says otherwise.

## File structure

- **Modify:** `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` (Tasks 1–6).
- **Modify:** `slides/workshops/mlt-r-advanced/concept-graph.mmd` (Task 6 — race-proof font).
- **Delete:** `slides/workshops/mlt-r-advanced/formatives/min-*.md` (11) + rendered `.html`/`_files` (Task 7).
- **Modify:** `slides/workshops/mlt-r-advanced/formatives/README.md` → map note (Task 7).

---

## Task 0: Baseline render

- [ ] **Step 1:** `git -C "c:/Users/corra/github/cl/mlt-overview" branch --show-current` → `workshop-deck-redesign`.
- [ ] **Step 2:** `quarto render slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` → PASS (confirms toolchain before edits).

---

## Task 1: Step 00 · Recap & setup — WHY intro + min-10 live-check + go-to-code

**Files:** Modify `00-advanced-deck.qmd` — the `# Step 00 · Recap & setup` divider. (Step 00 has no theory slide; the divider is followed by `# Step 01 · Interpretability`.)

- [ ] **Step 1: Rewrite the divider** — replace exactly:

```
# Step 00 · Recap & setup {#sec-00-recap .center}

<!-- Step 00 (demo, 12 min): reload Basic's finalized workflow; predict 1 row; pre-warm torch. -->

**Objective.** Reopen the validated model — without retraining.
```

with:

```
# Step 00 · Recap & setup {#sec-00-recap .center}

<!-- Step 00 (demo, 12 min): reload Basic's finalized workflow; predict 1 row; pre-warm torch. -->

**Why first.** Advanced doesn't rebuild anything — it **reopens** the model you validated in Basic. Day one reloads that exact `final_fit`, so a clean, warm session is the precondition for everything that follows.
```

(Leave the three bullets and the `::: {.notes}` block that follow unchanged.)

- [ ] **Step 2: Insert min-10 Engage→Reveal + go-to-code immediately BEFORE `# Step 01 · Interpretability`** (after the Step 00 divider's `::: {.notes}` closing `:::`):

````
## Live check — did the model reload, is torch warm?

Run three checks. Signal **GREEN** if all pass, **RED** if any fails:

1. Does `predict(fitted_wf, hf_tbl[1, ], type = "prob")` return a **1-row tibble** (no error, no retrain)?
2. Does **`torch_tensor(1)`** run **without a download** — backend loads instantly (torch pre-warmed)?
3. Is the loaded object the **finalized workflow from Basic** (the one that passed `last_fit()`)?

::: {.notes}
Voce docente (IT): live-check min-10 (Engage). Presenza: alzata di mano GREEN/RED; remoto: poll.
:::

## GREEN — Basic's model, reopened (not retrained)

All three pass:

- `predict()` on the extracted `fitted_wf` returns immediately — the model is baked in, no `fit()`;
- `torch_tensor(1)` runs without downloading libtorch — the session was pre-warmed at setup;
- the object is Basic's finalized `last_fit` workflow (`model/final_fit.rds` → `readRDS()` → `extract_workflow()`).

**RED on torch?** Run `library(torch)` now and wait for backend init — normal once per session, never mid-workshop. **RED on the model?** Reload from the checkpoint before continuing — all of Step 01 depends on it.

::: {.notes}
Voce docente (IT): Reveal min-10. Su questa macchina `cuda_is_available()` è FALSE; in aula
sulla NVIDIA è TRUE. Una probabilità non è una spiegazione → apre lo step 01.
:::

## Go to code — `steps/00-recap/` {.center}

**Follow along.** Open `steps/00-recap/`: reload Basic's `final_fit`, `predict()` one row, pre-warm torch.

- Live check at minute 10: GREEN / RED.
- We never retrain — Advanced opens the model Basic validated.

::: {.notes}
Voce docente (IT): chiusura Step 00 (demo → "follow along"). Il workflow finalizzato di Basic
è il soggetto di tutta la giornata.
:::
````

- [ ] **Step 3: Render** → PASS. **Step 4: Visual verify** (hard reload; min-10 pair + go-to-code; no overflow). **Step 5: Commit**

```
git add slides/workshops/mlt-r-advanced/00-advanced-deck.qmd
git commit -m "slides(advanced): Step 00 arc — WHY intro, min-10 live-check in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Step 01 · Interpretability — WHY intro + min-24 + min-38 + min-46 + go-to-code

**Files:** Modify `00-advanced-deck.qmd` — `# Step 01 · Interpretability` divider + its two theory slides `## The logistic anchor — SHAP must recover what we already know` and `## SHAP settings — variance vs. cost`.

**Target order:** intro (WHY) → min-24 Engage → min-24 Reveal → `## The logistic anchor …` (KEEP) → min-38 Engage → min-38 Reveal → `## SHAP settings …` (KEEP) → min-46 Engage → min-46 Reveal → Go-to-code.

- [ ] **Step 1: Rewrite the divider** — replace exactly:

```
**Objectives.** Open the black box with two model-agnostic tools.
```

(the `**Objectives.**` line inside the `# Step 01 · Interpretability {#sec-01-interpret .center}` divider) with:

```
**Why this step.** A probability is not an explanation. We open the black box with two model-agnostic tools — permutation VIMP and SHAP — anchored on a logistic model we *can* read, so we can trust them on the forest we cannot.
```

(Leave the three bullets + notes that follow unchanged.)

- [ ] **Step 2: Insert min-24 pair immediately AFTER the Step 01 divider's `::: {.notes}` closing `:::`** (before `## The logistic anchor …`):

````
## Your turn — what does permutation VIMP measure?

The permutation-importance plot for the random forest puts **`ejection_fraction`** and **`serum_creatinine`** on top. What does that score actually measure?

- **A.** Permuting a predictor breaks its link to the outcome; the **drop in AUC-ROC** measures how much the model **relies on** it. High = the model can't do without it — *not* that it causes the outcome.
- **B.** A high score means `ejection_fraction` **causes** heart-failure death.
- **C.** Importance is a **signed coefficient**: positive = raises predicted risk, negative = lowers it.
- **D.** Importance is a **p-value**: above a threshold = statistically significant.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-24 (Engage). Distrattori: B = importanza = causazione; C = coefficiente
con segno; D = p-value.
:::

## The answer — A: reliance, not causation

**✓ A.** The AUC-ROC drop on permutation = how much the model **relies** on the predictor to discriminate.

- **✗ B** — *importance = causation.* It quantifies the model's dependence, says nothing about the data-generating mechanism.
- **✗ C** — *importance = signed coefficient.* A permutation score on a tree ensemble has **no sign** and no additive reading.
- **✗ D** — *importance = p-value.* It's a performance measure, not a test statistic from a null hypothesis.

::: {.notes}
Voce docente (IT): Reveal min-24. Numero reale: la VIMP mette in cima ejection_fraction e
serum_creatinine (con age) — feature che la foresta USA, non un'affermazione causale.
:::
````

- [ ] **Step 3: Insert min-38 pair immediately AFTER the `## The logistic anchor — SHAP must recover what we already know` slide's closing `:::`** (before `## SHAP settings …`):

````
## Your turn — predict the SHAP shape on the anchor

We ran `kernelshap` on the **logistic regression** (the anchor) and called `sv_waterfall()`. Before we look:

1. What **shape** do the waterfall bars take vs the model's raw `coef()` — same sign, same order, or something else?
2. Why run SHAP on the **logistic** model *first*, before pointing it at the random forest?

::: {.notes}
Voce docente (IT): predict-output min-38 (Engage). Faccio predire la forma PRIMA del reveal.
:::

## The reveal — SHAP must recover the known

**Shape:** the predictors that dominate the coefficient table dominate the waterfall, and **directions agree** (a negative coefficient → a negative/blue SHAP bar where the feature pushes the prediction down). Signs match; relative magnitudes mostly mirror the weighted contributions.

It is a **directional sanity check, not an exact identity** — we explain in probability space and `permshap` samples at this feature count, so it is not exactly $\beta_j (x_j - \bar{x}_j)$.

**Why first:** the anchor is a sanity check **for the method**. We know the ground truth (the coefficients); if the agnostic explainer recovers them, we can trust it on the random forest — whose logic we cannot read directly. Run it on the black box first and we'd have no way to know the explanation is real.

::: {.notes}
Voce docente (IT): Reveal min-38. permshap() esatto sul lineare (sanity-check più pulito);
kernelshap() ibrido sull'RF. "Model-agnostic" = l'approssimazione è il punto.
:::
````

- [ ] **Step 4: Insert min-46 pair immediately AFTER the `## SHAP settings — variance vs. cost` slide's closing `:::`**:

````
## Your turn — the SHAP variance-vs-cost knobs

In `kernelshap`, which **two** knobs govern the variance-vs-cost trade-off of the estimates?

- **A.** The **size of `bg_X`** (background) and the **sampling effort** (coalitions per row): larger + more sampling → lower variance, higher cost. A tiny background (30–50 rows) for the live demo trades precision for speed.
- **B.** A **smaller background is more accurate** — fewer, more representative rows reduce noise.
- **C.** The **number of sampling iterations equals the number of features** — fixed by the data.
- **D.** The **background only matters for tree models** — logistic/NN ignore `bg_X`.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-46 (Engage). Distrattori: B = meno background = più accurato (NO);
C = iterazioni fisse (NO); D = solo per alberi (NO, è agnostico).
:::

## The answer — A: background size + sampling effort

**✓ A.** Larger `bg_X` + more coalitions → lower-variance attributions at higher cost; the tiny live background is a deliberate speed trade.

- **✗ B** — *smaller background = more accurate.* Inverts it: fewer reference points **increase** variance.
- **✗ C** — *iterations fixed by the data.* The coalition count is a user knob (a heuristic default), not a property of the feature set.
- **✗ D** — *background only for trees.* That's TreeSHAP; **kernel** SHAP uses the background as a universal baseline for **every** model family.

::: {.notes}
Voce docente (IT): Reveal min-46. permshap esatto sull'ancora lineare, kernelshap ibrido come
p cresce. Background piccolo = più economico e più rumoroso.
:::
````

- [ ] **Step 5: Insert Go-to-code immediately BEFORE `# Step 02 · Deep learning`:**

````
## Go to code — `steps/01-interpret/` {.center}

Open `steps/01-interpret/`: permutation VIMP, then the **same** agnostic SHAP line on the logistic anchor and the RF.

- The anchor first: SHAP must recover the coefficients before we trust it on the forest.
- **Behind?** Copy `steps/02-deep-learning/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 01. La stessa riga di explainer gira su logistic → RF → (poi) MLP.
:::
````

- [ ] **Step 6: Render** → PASS. **Step 7: Visual verify** (min-24/38/46 pairs; the `$\beta_j (x_j - \bar{x}_j)$` math in min-38 Reveal; go-to-code). **Step 8: Commit** `slides(advanced): Step 01 arc — WHY intro, min-24/38/46 formatives in-deck, go-to-code`.

---

## Task 3: Step 02 · Deep learning — WHY intro + min-60 + min-66 + min-80 + min-92 + go-to-code

**Files:** Modify `00-advanced-deck.qmd` — `# Step 02 · Deep learning` divider + its four slides: `## MLP hyperparameters — and the overfit cure`, `## CNN / RNN / fused — written, not trained`, `## The honesty rule — one labeled exception`, `## GPU payoff — where the accelerator actually pays`.

**Target order:** intro (WHY) → `## MLP hyperparameters …` (KEEP) → min-60 Engage→Reveal → min-66 Engage→Reveal → `## CNN / RNN / fused …` (KEEP) → min-80 Engage→Reveal → `## The honesty rule …` (KEEP — content) → min-92 Engage→Reveal → `## GPU payoff …` (KEEP) → Go-to-code.

- [ ] **Step 1: Rewrite the divider** — replace exactly:

```
**Objectives.** Train one net honestly; write the rest.
```

with:

```
**Why this step.** Interpretability is model-agnostic — so the same explainer follows us into deep learning. We train **one** small net honestly, write the richer architectures (validated by a shape-check, not trained), and keep one labeled exception explicit.
```

(Leave the bullets + notes unchanged.)

- [ ] **Step 2: Insert min-60 pair, then min-66 pair, AFTER the `## MLP hyperparameters — and the overfit cure` slide's closing `:::`** (before `## CNN / RNN / fused …`):

`````
## Your turn — the MLP is overfitting; which knob?

Training loss keeps dropping, validation loss has levelled off or risen. Which intervention most directly addresses the overfit?

- **A.** **Increase `penalty`** (L2) **or decrease `hidden_units`** — reduce capacity, push toward high-bias / low-variance.
- **B.** **Train for more epochs** — it just needs more gradient steps.
- **C.** **Raise the learning rate** — a bigger step escapes the sharp overfit minima.
- **D.** **Change the activation** (ReLU → tanh) — a smoother activation regularises.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-60 (Engage). Lo faccio dal vivo cambiando UN numero. Distrattori:
B = più epoche (peggiora); C = learning-rate↑ (diverge); D = activation regolarizza (NO).
:::

## The answer — A: penalty ↑ / hidden_units ↓

**✓ A.** Capacity and weight-decay are the overfit knobs in an MLP.

- **✗ B** — *more epochs.* Backwards: more training **deepens** the overfit; early stopping is the remedy, not the cause.
- **✗ C** — *raise learning rate.* That's optimisation dynamics, not capacity; it may destabilise training and does not regularise.
- **✗ D** — *activation as regulariser.* Activation shapes gradient flow/expressiveness, but it is not a direct regulariser; `penalty` and width are.

::: {.notes}
Voce docente (IT): Reveal min-60. penalty↑ / hidden↓ (o taglia epochs). La slide-parametro
precede il train.
:::

## Your turn — the same explainer, now on the MLP

We have `mlp_fit`. Using the **same explainer call** as on the logistic anchor (just swap the model), make a waterfall for observation 1:

```r
kernelshap(mlp_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun) |>
  shapviz() |>
  sv_waterfall()
```

Run it: do the top features match what VIMP told us?

::: {.notes}
Voce docente (IT): your-turn min-66 (Engage). Stessa riga del blocco 01, cambia solo il modello.
:::

## My turn — model-agnostic, unchanged

The call runs **unchanged** — only the fitted model differs. `kernelshap` reaches the model **only** through `pred_fun`; it never looks inside. The waterfall still puts `ejection_fraction` and `serum_creatinine` near the top (consistent with VIMP), though magnitudes differ (SHAP is per-observation; VIMP is averaged).

The point: the **same three lines** worked on logistic, RF (Step 01), and now the MLP — the explainer is truly model-agnostic.

**Going further.** Why? `kernelshap` needs only `pred_fun(object, X, ...)` mapping rows → probabilities. It treats the model as a black box (no coefficients, splits, or weights), evaluating it on feature coalitions and fitting a weighted regression to recover Shapley values. "Give me a prediction function" is the only assumption — so it spans the whole model zoo.

::: {.notes}
Voce docente (IT): Reveal/my-turn min-66. Riuso intenzionale di SHAP (non nuovo carico):
rinforza l'agnosticismo. Going further = ex-stretch.
:::
`````

- [ ] **Step 3: Insert min-80 (Parsons) pair AFTER the `## CNN / RNN / fused — written, not trained` slide's closing `:::`** (before `## The honesty rule …`):

`````
## Your turn — reorder the fused `forward()`

The `forward()` of the fused network is scrambled. Put these six lines in execution order:

```
(a)  self$head(torch_cat(list(t, c, r), dim = 2))
(b)  t <- self$tab(x_tab)
(c)  r <- self$rnn(x_seq)
(d)  torch_cat(list(t, c, r), dim = 2)
(e)  c <- self$cnn(x_sig)
(f)  forward = function(x_tab, x_sig, x_seq) {
```

Then: (1) branch widths are 16, `sig_ch`, `hidden` — what must the **head's input dim** equal? (2) The head emits 2 logits — what's the output **shape** for a batch of $B = 5$?

::: {.notes}
Voce docente (IT): Parsons min-80 (Engage). (d) è il distrattore (concat senza head). Errori
comuni: concat prima dei tre rami, o head prima del concat → shape error a runtime.
:::

## The answer — branches first, then concat + head

**Order:** f → b → e → c → a (build `t`, `c`, `r` in any order, then concat + head in one call):

```r
forward = function(x_tab, x_sig, x_seq) {
  t <- self$tab(x_tab)   # [B, 16]
  c <- self$cnn(x_sig)   # [B, sig_ch]
  r <- self$rnn(x_seq)   # [B, hidden]
  self$head(torch_cat(list(t, c, r), dim = 2))
}
```

**Head input dim:** $16 + \text{sig\_ch} + \text{hidden}$ — `torch_cat(dim = 2)` concatenates along the feature axis; any mismatch errors at the first forward pass. **Output shape:** $[5, 2]$ — one row per observation, two logits per row (batch is always `dim = 1`).

::: {.notes}
Voce docente (IT): Reveal min-80. Riga (d) scartata. torch segnala lo shape mismatch subito →
scrivere il forward + un batch fittizio è il modo più rapido di validare un'architettura.
:::
`````

- [ ] **Step 4: Insert min-92 pair AFTER the `## The honesty rule — one labeled exception` slide's closing `:::`** (before `## GPU payoff …`):

````
## Your turn — does the loss curve break the honesty rule?

We showed the fused network's loss curve and said *"I trained this earlier on GPU."* How does this fit the workshop's honesty rule?

- **A.** It's the **single labeled exception** — announced as pre-trained, shown as a *didactic object*, not a live result. The killed CPU epoch **was** live (a real performance gap). Everything else is computed in real time.
- **B.** **Nothing is ever cached** — the honesty rule means everything runs live, including this curve.
- **C.** **All DL outputs** can be pre-trained and shown **without a label** — training time justifies skipping live-coding.
- **D.** A labeled pre-trained result is **identical to the `targets` "skip"** — both pre-computed, same rule.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-92 (Engage). Distinzione chiave da far atterrare prima del capstone.
:::

## The answer — A: one labeled exception

**✓ A.** Labeled, announced, shown as a didactic object; the killed CPU epoch was genuinely live.

- **✗ B** — *nothing is ever cached.* The rule is "don't show pre-cooked **as if live**"; a clearly labeled artifact is allowed.
- **✗ C** — *pre-train without a label.* Strips the rule of its key condition — undisclosed pre-training is exactly what's prohibited.
- **✗ D** — *same as `targets` skip.* Different: `targets` "skip" is **re-derivable** from unchanged inputs (reproducibility); the loss curve is a one-off GPU artifact that can't be reproduced live.

::: {.notes}
Voce docente (IT): Reveal min-92. La riproducibilità hash-checked di targets è un'altra cosa
dal pre-cotto etichettato.
:::
````

- [ ] **Step 5: Insert Go-to-code immediately BEFORE `# Step 03 · LLM as typed ETL`:**

````
## Go to code — `steps/02-deep-learning/` {.center}

Open `steps/02-deep-learning/`: train the MLP live, explain it with the same SHAP line, write (don't train) CNN/RNN/fused, run the GPU-vs-CPU demo.

- The MLP's `roc_auc` is single-split — **not** comparable to Basic's CV ~0.79 (apples to oranges).
- One labeled exception (the loss curve); everything else live.
- **Behind?** Copy `steps/03-ellmer/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 02 (l'hotspot). Break dopo questo step (uscita dall'hotspot).
Non vendere l'MLP come vincitore della foresta.
:::
````

- [ ] **Step 6: Render** → PASS. **Step 7: Visual verify** (min-60/66/80/92 pairs; the `r` code blocks in min-66 + min-80; `[5, 2]`/`$16 + …$` math; honesty-rule content slide intact with its callouts; go-to-code). **Step 8: Commit** `slides(advanced): Step 02 arc — WHY intro, min-60/66/80(Parsons)/92 formatives in-deck, go-to-code`.

---

## Task 4: Step 03 · LLM as typed ETL — WHY intro + min-112 + min-124 + go-to-code

**Files:** Modify `00-advanced-deck.qmd` — `# Step 03 · LLM as typed ETL` divider + its theory slide `## The schema is the contract`.

**Target order:** intro (WHY) → `## The schema is the contract` (KEEP) → min-112 Engage→Reveal → min-124 Engage→Reveal → Go-to-code.

- [ ] **Step 1: Rewrite the divider** — replace exactly:

```
**Objectives.** Turn an LLM into a reproducible ETL, not a chat.
```

with:

```
**Why this step.** A chat returns prose you must re-parse; an **ETL returns a record**. With a typed schema and `temperature = 0`, the LLM becomes a reproducible extractor — the same note always yields the same validated row.
```

(Leave the bullets + notes unchanged.)

- [ ] **Step 2: Insert min-112 pair, then min-124 pair, AFTER the `## The schema is the contract` slide's closing `:::`** (before `# Step 04 · Reproducibility capstone`):

`````
## Your turn — predict the typed record

This `type_object()` schema extracts from clinical notes:

```r
schema <- type_object(
  age               = type_integer("patient age in years"),
  ejection_fraction = type_number("ejection fraction %; NA if not stated"),
  on_betablocker    = type_boolean("TRUE if a beta-blocker is given/continued"),
  primary_dx        = type_enum(c("ischemic", "hypertensive", "valvular", "other"), "primary cardiac diagnosis")
)
```

(1) How many **fields**, and their **R types** after parsing? (2) A note says *"60-year-old male, EF 30%, no medications listed."* — `primary_dx` is **absent**. What does `ellmer` return for it?

::: {.notes}
Voce docente (IT): predict-output min-112 (Engage). Modello reale: gpt-5.4-nano.
:::

## The reveal — four fields, graceful absence

**Fields / R types:** `age` → `integer`; `ejection_fraction` → declared `type_number`, but **arrives as `integer`** for a whole-number JSON value (e.g. 30) or `double` if decimal; `on_betablocker` → `logical`; `primary_dx` → `character` (one enum value, or `NA`/`NULL` if absent). **Four fields.**

**Integer vs double subtlety:** JSON has no integer/float distinction for whole numbers; `EF = 30` parses to R **integer**. `stopifnot(is.double(rec$ejection_fraction))` would **fail** — coerce with `as.double(...)` when needed.

**Absent enum:** `ellmer` returns `NULL` (or `NA`), **no error** — the schema says what to look for, not that it must be present. That graceful handling is what makes it robust on messy notes.

::: {.notes}
Voce docente (IT): Reveal min-112. La sottigliezza integer-vs-double sorprende: type_number non
garantisce double; conta la rappresentazione JSON.
:::

## Your turn — temperature 0 + `map()`, together?

We set `temperature = 0` and wrap the extraction in `purrr::map()`. What do these two achieve together?

- **A.** `temperature = 0` = **determinism** (same input → same record → a reproducible ETL, not a chat); `purrr::map()` applies the extraction **element-by-element**, one record per note.
- **B.** A **lower temperature improves quality** — the LLM is more accurate at 0, always the right choice.
- **C.** **High temperature + `map()` runs on the GPU** — `map()` parallelises across cores, high temp enables GPU sampling.
- **D.** **Temperature is irrelevant** with a `type_object()` schema — valid JSON regardless.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-124 (Engage). Distrattori: B = temp = qualità; C = temp + map = GPU;
D = temp irrilevante con schema.
:::

## The answer — A: determinism + element-wise iteration

**✓ A.** `temperature = 0` makes the ETL reproducible; `map()` iterates note-by-note into one record each.

- **✗ B** — *temperature = quality.* It controls randomness, not capability; for extraction we want **zero** randomness.
- **✗ C** — *high temp + map = GPU.* Invented: `map()` iterates (sequentially, or parallel via `furrr`); neither it nor temperature touches the GPU.
- **✗ D** — *temperature irrelevant with a schema.* Even typed, at `temperature > 0` two calls can differ; `0` = greedy, deterministic.

::: {.notes}
Voce docente (IT): Reveal min-124. La cache etichettata (senza API key) è la stessa dottrina
dell'opzione-B: un record vero salvato prima, mostrato con etichetta, mai finto.
:::
`````

- [ ] **Step 3: Insert Go-to-code immediately BEFORE `# Step 04 · Reproducibility capstone`:**

````
## Go to code — `steps/03-ellmer/` {.center}

Open `steps/03-ellmer/`: define the typed schema, run **one** live extraction, read the batch `map` (written, not run).

- `temperature = 0` → deterministic ETL; the typed record is the contract.
- No API key? A labeled cached result from an earlier live run — never a faked record.
- **Behind?** Copy `steps/04-targets/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 03. Una sola estrazione live; il batch map è write-only.
:::
````

- [ ] **Step 4: Render** → PASS. **Step 5: Visual verify** (min-112 code block + integer/double prose; min-124 pair; go-to-code). **Step 6: Commit** `slides(advanced): Step 03 arc — WHY intro, min-112/124 formatives in-deck, go-to-code`.

---

## Task 5: Step 04 · Reproducibility capstone — WHY intro + min-138 + go-to-code

**Files:** Modify `00-advanced-deck.qmd` — `# Step 04 · Reproducibility capstone` divider + its theory slide `## Why a pipeline, not a hand-made cache`. Do NOT touch the `## Concept map — the whole workshop` slide or the closing slides after it.

**Target order:** intro (WHY) → `## Why a pipeline, not a hand-made cache` (KEEP) → min-138 Engage→Reveal → Go-to-code → `## Concept map — the whole workshop` (untouched).

- [ ] **Step 1: Rewrite the divider** — replace exactly:

```
**Objectives.** Make the whole story reproducible by construction — *and auditable*.
```

with:

```
**Why this step.** A pipeline a colleague cannot re-run is not reproducible. `targets` makes the whole explain→deep→LLM story re-derivable by construction: inspectable intermediate targets, a report the pipeline compiles itself, and an all-skip re-run that proves nothing drifted.
```

(Leave the bullets + notes unchanged.)

- [ ] **Step 2: Insert min-138 pair, then Go-to-code, AFTER the `## Why a pipeline, not a hand-made cache` slide's closing `:::`** (before `## Concept map — the whole workshop`):

````
## Your turn — predict the second `tar_make()`

We ran `tar_make()` and watched the pipeline build. Now we run `tar_make()` **again, unchanged**.

1. **Predict:** what status does every target report, and why?
2. We changed nothing — so is the second run just "using a cache"? What's the conceptual difference?

::: {.notes}
Voce docente (IT): predict-output min-138 (capstone check, Engage). Faccio predire PRIMA di eseguire.
:::

## The reveal — all-skip is reproducibility, not a cache

**Every target reports `skip`.**

The reason is **input-hash checking**: `targets` hashes each target's inputs (function source, upstream target objects, file dependencies). Nothing changed → hashes match → re-running would reproduce the same result → it skips. That's **reproducibility** (re-derivable from unchanged inputs), not a stored value.

Difference from a cache: change *any* input (data, code, a parameter) and the affected target + everything downstream go **stale** and rebuild. A cache returns a stored value regardless; `targets` re-derives or skips by content hash.

**Going further.** Swap `model/final_fit.rds` (a `format = "file"` target) → `model_file` re-hashes → `model` → the `explanation` bridge rebuild; `cohort` stays `skip`. Edit the VIMP knobs inside `explain_model()` → only `explanation` rebuilds. And the **GPU device** is an *ambient* input (`cuda_is_available()` inside the function body) — invisible to the DAG unless promoted to a `tar_target(device, ...)`.

::: {.notes}
Voce docente (IT): Reveal min-138. Provo col valore di ritorno, non col messaggio:
`tar_outdated()` == character(0). Il bridge `explanation` ricalcola DAVVERO la VIMP. Going
further = ex-stretch (stale propagation + device cieco).
:::

## Go to code — `steps/04-targets/` {.center}

**Follow along.** Open `steps/04-targets/`: read the DAG (`tar_visnetwork()`), `tar_make()`, then re-run → all-skip.

- Each analysis is a named, inspectable target (`cohort`, `model`, `explanation`); the pipeline compiles the report itself.
- The loop closes: Basic validated the model, Advanced re-derives its explanation, deterministically.

::: {.notes}
Voce docente (IT): chiusura Step 04 (demo → "follow along"). Chiude il loop Basic↔Advanced.
:::
````

- [ ] **Step 3: Render** → PASS. **Step 4: Visual verify** (min-138 pair; go-to-code; confirm `## Concept map …` + closing slides intact). **Step 5: Commit** `slides(advanced): Step 04 arc — WHY intro, min-138 capstone check in-deck, go-to-code`.

---

## Task 6: Race-proof the concept-map mermaid

Same fix already applied to Basic (commit `36d2102`): pin the diagram labels to a system font for both measurement and paint, so an unloaded webfont can't desync text from its box in embedded webviews (e.g. the Positron viewer).

**Files:** Modify `00-advanced-deck.qmd` (the `#sec-concept-map` `<style>` block) + `concept-graph.mmd`.

- [ ] **Step 1: In `concept-graph.mmd`, add `fontFamily` to the init.** Replace the first line:

```
%%{init: {'themeVariables': {'fontSize': '21px'}, 'flowchart': {'nodeSpacing': 44, 'rankSpacing': 46, 'padding': 12}}}%%
```

with:

```
%%{init: {'fontFamily': 'Arial, Helvetica, sans-serif', 'themeVariables': {'fontSize': '21px'}, 'flowchart': {'nodeSpacing': 44, 'rankSpacing': 46, 'padding': 12}}}%%
```

- [ ] **Step 2: In `00-advanced-deck.qmd`, add the label font-family rule to the concept-map `<style>` block.** Find the `<style>` block containing `#sec-concept-map svg {` and insert, immediately before the `#sec-concept-map svg {` line:

```
#sec-concept-map .nodeLabel, #sec-concept-map .nodeLabel *,
#sec-concept-map .edgeLabel, #sec-concept-map .edgeLabel * { font-family: Arial, Helvetica, sans-serif !important; }
```

(If that block carries the stale comment "No font !important override here — that desyncs…", replace that comment with: "Force the labels to the same system font mermaid measures with (init fontFamily in the .mmd) so an unloaded webfont can't desync text from its box in embedded webviews.")

- [ ] **Step 3: Render** → PASS.
- [ ] **Step 4: Verify (chrome-devtools).** Hard-reload `00-advanced-deck.html`, go to the concept-map slide, run a script: for `#sec-concept-map`, the computed `.nodeLabel` `font-family` must start with `Arial`, and every node must have label width ≤ box width (overflowingCount 0). Screenshot to confirm all node text is inside its box.
- [ ] **Step 5: Commit**

```
git add slides/workshops/mlt-r-advanced/00-advanced-deck.qmd slides/workshops/mlt-r-advanced/concept-graph.mmd
git commit -m "slides(advanced): race-proof concept-map mermaid font (system font, measure==paint)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Retire the standalone formatives + update the README map

**Files:** Delete `slides/workshops/mlt-r-advanced/formatives/min-*.md` (11) + their `min-*.html` / `min-*_files/`. Modify `formatives/README.md`.

- [ ] **Step 1: Delete sources + rendered output**

```bash
cd "c:/Users/corra/github/cl/mlt-overview/slides/workshops/mlt-r-advanced/formatives"
git rm -q min-10-live-check.md min-24-mcq-vimp.md min-38-predict-shap-coef.md min-46-mcq-shap.md min-60-mcq-mlp.md min-66-yourturn-shap-nn.md min-80-parsons-fused.md min-92-mcq-honesty.md min-112-predict-ellmer.md min-124-mcq-temperature.md min-138-predict-capstone.md
rm -f min-*.html && rm -rf min-*_files
ls -1   # expect only README.md
```

- [ ] **Step 2: Update `formatives/README.md`** — insert immediately after the H1 line (`# Formative — workshop Advanced (nota docente)`):

```markdown
> **Nota (2026-06-03):** il *contenuto* di queste formative ora vive **inline nel deck unico**
> (`../00-advanced-deck.qmd`) come coppie di slide **Engage → Reveal**, integrate al loro punto
> dell'arco per-step (intro→teoria→formative→go-to-code). Questo file resta la **mappa**
> formativa→step→minuto→nodo (e il razionale dei distrattori). Gli HTML standalone delle
> formative sono stati ritirati come deliverable.
```

- [ ] **Step 3: Confirm whole-project render emits only the deck** — `quarto render slides/workshops/mlt-r-advanced` → PASS; no `min-*.html` reappear under `formatives/`; `00-advanced-deck.html` present.
- [ ] **Step 4: Commit**

```
git add slides/workshops/mlt-r-advanced/formatives/
git commit -m "slides(advanced): retire standalone formative HTMLs; README becomes the map

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Full-deck visual sweep

- [ ] **Step 1:** `quarto render slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` → PASS.
- [ ] **Step 2: Whole-deck visual sweep (chrome-devtools, hard reload, 1648×1080).** Walk every slide: each step has exactly one WHY intro + one Go-to-code; every formative is a clean Engage→Reveal pair; the honesty-rule content slide + callouts intact; all `$…$`/`$$…$$` math renders; the concept-map mermaid renders **with all node text inside its boxes** (Arial); opening/closing slides unchanged. Re-check critical slides at ~1100px. Fix any issue, re-render, re-check.
- [ ] **Step 3: Commit any fixes** (skip if none): `slides(advanced): visual-verification fixes`.

---

## Self-review (planner checklist — done)

**1. Spec coverage:** §8 Advanced inherits → Tasks 1–5 (every step) + Task 6 (mermaid, matching Basic) + Task 7 (retire) + Task 8 (sweep). 11 formatives all placed: min-10 (T1), min-24/38/46 (T2), min-60/66/80/92 (T3), min-112/124 (T4), min-138 (T5). Honesty-rule slide kept as content (T3 target order). Parsons min-80 handled (distractor line (d) noted). **2. Placeholder scan:** every new slide's exact markdown inline; kept slides named exactly. **3. Type/name consistency:** target-order headings match authored `##` headings; `{#sec-…}` ids preserved (`sec-00-recap`, `sec-01-interpret`, `sec-02-deep-learning`, `sec-03-ellmer`, `sec-04-targets`); `#sec-concept-map` div id used for the font fix; commit prefix `slides(advanced):`.

---

## Execution handoff

Implement via **superpowers:subagent-driven-development** on `workshop-deck-redesign` (sequential — all step tasks edit the same file). Tasks 1→5 in order, then 6 (mermaid), then 7 (retire after 1–5), then 8 (sweep). After this plan: `/mlt-build` rebuilds deck + ZIP + portal for **both** workshops, then a final visual check of both decks. **Never `git push`.**
