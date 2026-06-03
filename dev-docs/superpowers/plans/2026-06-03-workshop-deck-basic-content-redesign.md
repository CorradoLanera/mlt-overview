# Workshop deck — Basic content redesign (plan 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Basic workshop deck (`slides/workshops/mlt-r-basic/00-basic-deck.qmd`) so each step follows the arc **intro-with-WHY → interleaved theory/formative mini-cycles → "go to code" closer**, with all 10 formatives integrated in-deck as **Engage → Reveal** slide pairs, and the standalone formative HTMLs retired.

**Architecture:** Pure content authoring in one hand-authored Quarto revealjs `.qmd`. No pipeline/`_quarto.yml`/script/hook changes. Each step's `# Step NN` divider becomes the WHY-led **intro**; existing theory slides are **kept** (some reordered); each formative becomes a **2-slide Engage→Reveal** pair inserted at its mapped interleave point; each step ends with a **Go to code** slide. The `# Hyperparameters, one algorithm at a time` divider is **dissolved** into the Step 04 intro. Finally the 10 `formatives/min-*.md` (+ their rendered `.html`/`_files`) are deleted and `formatives/README.md` is updated to a pure map.

**Tech Stack:** Quarto revealjs (`embed-resources`, canvas 1648×1080), `styles/_brand.scss` + `theme.scss` (orange/teal brand), pandoc MathML for `$...$`, Quarto CLI for render, chrome-devtools MCP for visual verification.

**Reference spec:** `dev-docs/superpowers/specs/2026-06-03-workshop-deck-content-redesign-design.md` (§3 per-step arc, §4 Engage→Reveal anatomy, §5 retire, §6 preserve, §7 Basic map).

**Source of formative content:** `slides/workshops/mlt-r-basic/formatives/{README.md, min-*.md}` (present until Task 7). The exact Engage/Reveal text for every formative is reproduced inline in this plan, so tasks remain self-contained even after deletion.

---

## Conventions used by this plan

- **Branch:** `workshop-deck-redesign` (already created; the design spec is committed there).
- **Render (per-task verify):** render the deck file only, not the whole project:
  `quarto render slides/workshops/mlt-r-basic/00-basic-deck.qmd`
  Expected: completes without error; writes `slides/workshops/mlt-r-basic/00-basic-deck.html`.
  (Do **not** `quarto render slides/workshops/mlt-r-basic` during step tasks — it would also re-render the still-present standalone formatives. Whole-project render returns only in Task 8 / `/mlt-build`.)
- **Visual verify (per-task):** with chrome-devtools MCP — `new_page` → `navigate_page` to the `file://` URL of `00-basic-deck.html` → `resize_page` to 1648×1080 → use `?print-pdf` or arrow-key navigation (`press_key`) to reach the new/changed slides → `take_screenshot` → inspect for overflow (text past the right edge), overlaps, low contrast, math not rendering, code blocks clipped. Also spot-check a narrow viewport (~1100px wide) per the project's universal visual gate. Fix and re-render until clean.
- **Language:** slide text in **English**; `::: {.notes}` speaker notes in **Italian** (project rule). Empty line before every markdown list. All math in `$...$`.
- **Formative slide convention (frozen in Task 1, the exemplar):**
  - **Engage** slide heading starts with `## Your turn — …` (MCQ/your-turn/predict) or `## Live check — …` (live-check); ends inviting a commitment ("Pick one — then we reveal it." / "Your turn — type it at the R prompt." / a `predict` prompt).
  - **Reveal** slide heading names the takeaway (`## The answer — A: …` for MCQ, `## My turn — …` for your-turn, `## The reveal — …` for predict, `## GREEN — …` for live-check). MCQ reveals mark `**✓ A.**` then `**✗ B/C/D**` each with the one-line *why-the-distractor-is-wrong*. Optional de-personalized `**Going further.**` paragraph at the end (the ex-`Stretch (Davide)`, no persona name).
  - Each formative slide gets `{data-menu-title="min-NN · <tag>"}` so the reveal-menu/search stays navigable.
- **Commits:** one logical change per commit; commit after each task passes render + visual verify. **Never `git push`** (the user pushes).
- **Do NOT touch:** the opening slides (title, find-me, credits, `# Build and validate…` day-overview, "The clinical question", "The variables"), the closing slides (concept map, "Next: open the model — Advanced", further reading, thank-you), `_quarto.yml`, `theme.scss`, `concept-graph.mmd`, any `scripts/`/hooks. Existing theory slides keep their current body unless a step task says otherwise.

## File structure

- **Modify:** `slides/workshops/mlt-r-basic/00-basic-deck.qmd` — the only authored file (Tasks 1–6).
- **Delete:** `slides/workshops/mlt-r-basic/formatives/min-*.md` (10 files) + their rendered `min-*.html` and `min-*_files/` dirs (Task 7).
- **Modify:** `slides/workshops/mlt-r-basic/formatives/README.md` — trim to a pure formative→step→minute→node map (Task 7).

---

## Task 0: Baseline render (confirm the deck builds before changes)

**Files:** none modified.

- [ ] **Step 1: Confirm branch**

Run: `git -C "c:/Users/corra/github/cl/mlt-overview" branch --show-current`
Expected: `workshop-deck-redesign`

- [ ] **Step 2: Baseline render of the current deck**

Run: `quarto render slides/workshops/mlt-r-basic/00-basic-deck.qmd`
Expected: PASS — writes `slides/workshops/mlt-r-basic/00-basic-deck.html` with no error. (This is the "before" state; it confirms the toolchain works so any later failure is from our edits.)

- [ ] **Step 3: Visual baseline (optional reference)**

Open `00-basic-deck.html` in chrome-devtools at 1648×1080; screenshot the Step 03 `## The tidymodels object-map` (mermaid) and Step 05 concept map to confirm diagrams render in this environment. No commit (no changes).

---

## Task 1: Step 01 — the REFERENCE exemplar (intro WHY + min-31 + min-30 + go-to-code)

This task **freezes the pattern** every later step copies: WHY-led intro, interleaved Engage→Reveal pairs, Go-to-code closer.

**Files:**
- Modify: `slides/workshops/mlt-r-basic/00-basic-deck.qmd` — the `# Step 01 · Import & wrangle` section (currently lines ~210–337: the divider + the four theory slides "The tidyverse", "The native pipe", "Reshaping with verbs", "Tidy data — and the leakage trap").

**Target slide order for Step 01 after this task:**

```
# Step 01 · Import & wrangle        (intro, rewritten WHY)
## The tidyverse — one grammar for data         (KEEP)
## The native pipe `|>`                          (KEEP)
## Your turn — what does this pipeline do?       (NEW  min-31 Engage)
## The answer — A: functional, returns a new tibble (NEW min-31 Reveal)
## Reshaping with verbs — `dplyr`, `janitor`, `forcats` (KEEP)
## Tidy data — and the leakage trap              (KEEP)
## Your turn — build the analysis cohort         (NEW  min-30 Engage)
## My turn — the wrangle, one chain              (NEW  min-30 Reveal)
## Go to code — `steps/01-import/`               (NEW  closer)
```

- [ ] **Step 1: Rewrite the Step 01 divider to lead with WHY**

Replace the current divider block (the `# Step 01 · Import & wrangle {#sec-01-import .center}` heading, its `<!-- … -->` comment, the `**Objectives.**` paragraph + bullets, and its `::: {.notes}` block) with:

````markdown
# Step 01 · Import & wrangle {#sec-01-import .center}

<!-- Step 01 (hands-on, 32 min): tidyverse primer; clean/recode with dplyr/tidyr and `|>`; outcome to factor; drop leaky `time`. -->

**Why this step.** Raw clinical data lies in two ways: messy names and types, and a column that *secretly encodes the outcome*. We tidy the first and **dodge the second — leakage** — before any model sees the data.

- A tidyverse primer: the native pipe `|>`, verbs that return a **new** tibble.
- Clean and recode with `dplyr`/`tidyr` + `janitor`; **drop the leaky `time`**; make the outcome an **event-first** factor.

::: {.notes}
Voce docente (IT): intro Step 01 (hands-on, ~32 min, il picco di carico-sintassi per chi parte
da zero). L'intro guida col PERCHÉ (i due modi in cui i dati grezzi ingannano: nomi/tipi +
leakage), non con un elenco asettico. Rete fall-behind con `steps/01-import/`. Le 4 slide di
teoria che seguono coprono i concetti che poi le formative verificano.
:::
````

- [ ] **Step 2: Insert the min-31 Engage→Reveal pair after the `## The native pipe` slide**

Immediately after the `## The native pipe \`|>\`` slide's closing `:::` (its notes block), insert:

````markdown
## Your turn — what does this pipeline do? {data-menu-title="min-31 · pipe semantics"}

```r
hf_raw |> clean_names() |> select(ejection_fraction, age) |> filter(age > 60)
```

Which statement best describes what happens?

- **A.** The tibble flows in as the *first argument* of each verb, and each verb returns a *brand-new copy* — `hf_raw` is unchanged until you assign.
- **B.** The verbs edit `hf_raw` *in place* (like Stata's `keep if` / `drop`) — afterwards `hf_raw` itself has fewer rows and columns.
- **C.** `select(ejection_fraction, age)` fails — `ejection_fraction` and `age` are not objects in the global environment.
- **D.** The pipe forwards the *last object you created*, not the left-hand side.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-31 (Engage), dopo la teoria del pipe. Distrattori diagnostici:
B = modello mentale in-place/Stata; C = NSE non capita; D = il pipe inoltra l'ultimo oggetto.
Far votare PRIMA di scoprire la risposta (presenza: alzata di mano; remoto: poll).
:::

## The answer — A: functional, returns a new tibble {data-menu-title="min-31 · reveal"}

**✓ A.** The left-hand value enters the *first argument*; every verb returns a **new** tibble. `hf_raw` is untouched until you assign with `<-`.

- **✗ B** — *in-place / Stata mental model.* dplyr is functional: it returns a new object, the input stays intact.
- **✗ C** — *NSE not understood.* dplyr evaluates bare column names inside the data frame's scope (tidy/NSE), not as global variables.
- **✗ D** — *pipe forwards the LHS* — the value on its left — into the first argument, not "the most recent object".

::: {.notes}
Voce docente (IT): Reveal min-31. Il punto: pipeline funzionale, copia nuova, NSE. Se la sala
sceglie B è il misconcetto Stata da ri-spiegare prima del your-turn wrangle.
:::
````

- [ ] **Step 3: Insert the min-30 Engage→Reveal pair after the `## Tidy data — and the leakage trap` slide**

Immediately after the `## Tidy data — and the leakage trap` slide's closing `:::`, insert:

````markdown
## Your turn — build the analysis cohort {data-menu-title="min-30 · wrangle"}

From the imported `hf_raw`, build `hf` with a **single `|>` chain**:

1. `clean_names()` — snake_case the names.
2. `select(-time)` — drop the follow-up duration (it leaks the outcome).
3. Make `outcome` a two-level factor, **event first** (`"died"`, `"survived"`) from `death_event`; then drop `death_event`.
4. Make the 0/1 flags (`anaemia, diabetes, high_blood_pressure, sex, smoking`) factors.
5. `glimpse()` — confirm **12 columns** and the factor.

*Your turn — type it at the R prompt.* (take ~3 minutes)

::: {.notes}
Voce docente (IT): your-turn min-30 (Engage), il task integrativo dello step. Lo studente lo
scrive AL PROMPT R sul proprio laptop (o apre `steps/01-import/` se è rimasto indietro). Timer
~3 min. "Type it" = la doctrine live: si scrive, non si incolla. Poi il my-turn lo risolve.
:::

## My turn — the wrangle, one chain {data-menu-title="min-30 · reveal"}

```r
hf <- hf_raw |>
  clean_names() |>
  select(-time) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "died", "survived"),
      levels = c("died", "survived"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor)) |>
  glimpse()
```

Each verb takes the tibble first and returns a **new** tibble — the chain never mutates `hf_raw`.

**Going further.** Why is `time` leakage? It is follow-up days *until death-or-censoring* — partly a function of the outcome (patients who die early have small `time`). A model handed `time` "predicts" death by reading its own answer: deceptively high in training, collapses in prospective use. A predictor must be knowable **at the moment you would predict**.

::: {.notes}
Voce docente (IT): Reveal/my-turn min-30. Si live-coda la catena. "Going further" = ex-stretch
(Davide), de-personalizzato: il leakage si riconosce col ragionamento clinico, non col codice.
:::
````

- [ ] **Step 4: Insert the Go-to-code closer at the end of Step 01 (before `# Step 02`)**

Immediately before the `# Step 02 · Clinical EDA` divider, insert:

````markdown
## Go to code — `steps/01-import/` {.center}

Now **do it in the project**: open `steps/01-import/` and run the wrangle end to end.

- Type it, run it — the snapshot in `steps/01-import/` is your safety net.
- The *solution* of this step is the *start* of the next.
- **Fell behind?** Copy `steps/02-eda/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 01 → hands-on nel progetto. Pattern "Go to code" di
riferimento: cosa fare nel folder + rete checkpoint (la soluzione dello step N è l'inizio
di N+1) + bridge al prossimo. Per gli step demo diventa "follow along".
:::
````

- [ ] **Step 5: Render**

Run: `quarto render slides/workshops/mlt-r-basic/00-basic-deck.qmd`
Expected: PASS, no errors; `00-basic-deck.html` regenerated.

- [ ] **Step 6: Visual verify (chrome-devtools)**

Open `00-basic-deck.html` at 1648×1080; navigate through the new Step 01 intro, the two Engage→Reveal pairs, and the Go-to-code slide. Confirm: the `r` code block in "My turn" is fully visible (no clipping), MCQ options fit without overflow, headings + `✓/✗` render, no overlap. Re-check at ~1100px wide. Fix any overflow (shorten lines / `.smaller` if needed) and re-render until clean.

- [ ] **Step 7: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 01 arc — WHY intro, min-31/min-30 formatives in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Step 00 — intro WHY + min-09 live-check + go-to-code

**Files:** Modify `00-basic-deck.qmd` — the `# Step 00 · Setup` section (divider + `## A reproducible project — renv, here, rio`).

**Target order:** intro (WHY) → `## A reproducible project — renv, here, rio` (KEEP) → min-09 Engage → min-09 Reveal → Go-to-code.

- [ ] **Step 1: Rewrite the Step 00 divider to lead with WHY**

Replace the `# Step 00 · Setup {#sec-00-setup .center}` divider's objective paragraph + bullets + notes with:

````markdown
# Step 00 · Setup {#sec-00-setup .center}

<!-- Step 00 (demo, 10 min): open `.Rproj`, `renv::restore`, load with `here` + `rio`. -->

**Why first.** Every number we produce today is only as trustworthy as the project that produced it. So we start from a **healthy, reproducible environment** — before touching the data.

- Open the `.Rproj`; let `renv::restore()` rebuild the pinned library.
- Load data through `here::here()` (stable paths) and `rio::import()`.

::: {.notes}
Voce docente (IT): demo (~10 min). Intro col PERCHÉ: l'ambiente sano è la precondizione di
tutto. `renv` è già in restore in background dall'opening. Live-check al minuto 9.
:::
````

- [ ] **Step 2: Insert min-09 Engage→Reveal after `## A reproducible project — renv, here, rio`**

````markdown
## Live check — is your project healthy? {data-menu-title="min-09 · live-check"}

Run three checks. Signal **GREEN** if all pass, **RED** if any fails:

1. Is your **`.Rproj`** open (the project, not a loose script)?
2. Does **`renv::status()`** report the library **in sync** with the lockfile?
3. Does **`here::here()`** point to the **project root**?

::: {.notes}
Voce docente (IT): live-check min-09 (Engage). Presenza: alzata di mano GREEN/RED; remoto: poll.
:::

## GREEN — a healthy environment {data-menu-title="min-09 · reveal"}

All three pass:

- the `.Rproj` is open → the working directory is anchored to the project;
- `renv::status()` says *"The project is already synchronized with the lockfile"*;
- `here::here()` returns the project-root path (where `.Rproj` / `.here` lives).

**RED on any?** Fix it now — re-open the `.Rproj`, run `renv::restore()`, or check the `.here` sentinel — before the hands-on starts.

::: {.notes}
Voce docente (IT): Reveal min-09. Un ambiente sano è la precondizione: se RED, si risolve ora.
:::
````

- [ ] **Step 3: Insert Go-to-code before `# Step 01`**

````markdown
## Go to code — `steps/00-setup/` {.center}

**Follow along.** Open `steps/00-setup/`, run `renv::restore()`, load the data with `here` + `rio`.

- Live check at minute 9: GREEN / RED.
- The folder is your snapshot — fall behind anywhere today and copy the next one.

::: {.notes}
Voce docente (IT): chiusura Step 00 (demo → "follow along"). Mentre parlo, `renv::restore()`
ha già scaldato in background.
:::
````

- [ ] **Step 4: Render** — `quarto render slides/workshops/mlt-r-basic/00-basic-deck.qmd` → PASS.
- [ ] **Step 5: Visual verify** — Step 00 intro + min-09 pair + go-to-code at 1648×1080 and ~1100px; no overflow.
- [ ] **Step 6: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 00 arc — WHY intro, min-09 live-check in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Step 02 — intro WHY + min-50 MCQ + go-to-code

**Files:** Modify `00-basic-deck.qmd` — the `# Step 02 · Clinical EDA` section (divider + `## gtsummary`, `## ggplot2`, `## Where today's model fits — learning paradigms`).

**Target order:** intro (WHY) → `## gtsummary` (KEEP) → `## ggplot2` (KEEP) → min-50 Engage → min-50 Reveal → `## Where today's model fits — learning paradigms` (KEEP, bridge to Step 03) → Go-to-code.

- [ ] **Step 1: Rewrite the Step 02 divider to lead with WHY**

````markdown
# Step 02 · Clinical EDA {#sec-02-eda .center}

<!-- Step 02 (hands-on, 22 min): tbl_summary(by = outcome); one ggplot; read imbalance -> metric choice. -->

**Why this step.** Before modelling, *read the cohort* — a model is only as honest as your grasp of its data. The shape we find here, especially the **class imbalance**, drives the metric choice for the rest of the day.

- `gtsummary::tbl_summary(by = outcome)` — a clinical Table 1.
- One `ggplot` of a predictor against the outcome; **read the ~32% imbalance** $\to$ the dual metric.

::: {.notes}
Voce docente (IT): hands-on elastico (~22 min, comprimibile). Intro col PERCHÉ: l'imbalance
~32% visto qui è il seme del ragionamento "accuracy inganna → due metriche".
:::
````

- [ ] **Step 2: Insert min-50 Engage→Reveal after `## ggplot2 — the grammar of graphics`**

````markdown
## Your turn — why watch AUC-PR too? {data-menu-title="min-50 · metric"}

Death occurs in about **32%** of patients, and we score every model with **both** AUC-ROC **and** AUC-PR. Why watch **AUC-PR alongside** AUC-ROC, not AUC-ROC alone?

- **A.** AUC-PR focuses on the *death* class; its no-skill baseline is the *prevalence* ($\approx 0.32$), not 0.5 — so it exposes poor performance on the patients we care about that a flattering AUC-ROC can hide.
- **B.** AUC-ROC and AUC-PR always rank models the same way — AUC-PR is a redundant second opinion.
- **C.** Like AUC-ROC, AUC-PR's no-skill baseline is always 0.5.
- **D.** Under imbalance AUC-ROC cannot be computed; AUC-PR is its only valid replacement.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-50 (Engage). Distrattori: B = metriche intercambiabili; C = baseline
PR = 0.5; D = imbalance "rompe" la ROC. Si vota prima del reveal.
:::

## The answer — A: AUC-PR is anchored to prevalence {data-menu-title="min-50 · reveal"}

**✓ A.** AUC-PR scores the positive (death) class; its no-skill line is the prevalence ($\approx 0.32$), so it stays meaningful as the event gets rarer.

- **✗ B** — *interchangeable.* The two can and do disagree — that is the whole reason to watch both.
- **✗ C** — *PR baseline is 0.5.* No: the AUC-PR no-skill line is the prevalence itself; a "0.6" at 32% is far less impressive than it looks.
- **✗ D** — *imbalance breaks AUC-ROC.* AUC-ROC is perfectly computable under imbalance — it just does not, alone, speak about the minority class.

::: {.notes}
Voce docente (IT): Reveal min-50. La lezione: due metriche complementari; la PR è ancorata
alla prevalenza. Atterra prima dello step 03/04 dove si leggono ROC+PR.
:::
````

- [ ] **Step 3: Insert Go-to-code before `# Step 03`** (after the `## Where today's model fits — learning paradigms` slide)

````markdown
## Go to code — `steps/02-eda/` {.center}

Open `steps/02-eda/`: build the Table 1 and one plot, and read the imbalance.

- Keep it short — EDA is elastic; the metric lesson is the keeper.
- **Behind?** Copy `steps/03-logistic/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 02. La slide "learning paradigms" resta come ponte verso lo
step 03 (supervised). Il folder 02-eda è comprimibile se si è in ritardo.
:::
````

- [ ] **Step 4: Render** → PASS.
- [ ] **Step 5: Visual verify** — Step 02 intro + min-50 pair + go-to-code; math (`\approx`, `\to`) renders; no overflow.
- [ ] **Step 6: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 02 arc — WHY intro, min-50 metric MCQ in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Step 03 — intro WHY + min-72 + min-88 + go-to-code

**Files:** Modify `00-basic-deck.qmd` — the `# Step 03 · Logistic spine` section (divider + `## tidymodels — one spine`, `## The tidymodels object-map`, `## The five packages — and the functions we use`).

**Target order:** intro (WHY) → the three KEEP theory slides → min-72 Engage → min-72 Reveal → min-88 Engage → min-88 Reveal → Go-to-code (then the existing `# Hyperparameters…`/Step 04 follows — restructured in Task 5).

- [ ] **Step 1: Rewrite the Step 03 divider to lead with WHY**

````markdown
# Step 03 · Logistic spine {#sec-03-logistic .center}

<!-- Step 03 (hands-on, 38 min): object-map rsample -> recipes -> parsnip -> workflows -> yardstick; glm baseline. -->

**Why this step.** Four algorithms are coming — and we do *not* want four bespoke pipelines. We lay **one reusable spine** now, on a model we can read (`glm`), so Step 04 changes only **one line**.

- Walk the object-map `rsample` $\to$ `recipes` $\to$ `parsnip` $\to$ `workflows` $\to$ `yardstick`.
- Fit a plain `glm` baseline; score it with `yardstick` — **AUC-ROC and AUC-PR**.

::: {.notes}
Voce docente (IT): hands-on (~38 min), picco di profondità (la object-map). Intro col PERCHÉ:
una spina riusabile + glm come ancora di riconoscimento, non nuova astrazione. Break dopo lo step.
:::
````

- [ ] **Step 2: Insert min-72 Engage→Reveal after `## The five packages — and the functions we use`**

````markdown
## Your turn — do the two routes agree? {data-menu-title="min-72 · glm = workflow"}

You fit a plain `glm` logistic two ways: (a) a bare `glm`-engine `logistic_reg()`, and (b) the same model wrapped in a `workflow()` (recipe + spec). Score both on the test set with **both** metrics:

```r
hf_metrics <- metric_set(roc_auc, pr_auc)
... |> augment(new_data = test) |> hf_metrics(truth = outcome, .pred_died)
```

(No `event_level` needed — `died` is the first level.) **Do the two routes give the same AUC-ROC and AUC-PR? Why, in one sentence?**

::: {.notes}
Voce docente (IT): your-turn min-72 (Engage). Lo studente lo prova al prompt; ~2-3 min.
:::

## My turn — same model, more scaffolding {data-menu-title="min-72 · reveal"}

**Yes — identical** across both routes. The `workflow` does not change the statistical model; it only **bundles** the recipe and the spec so the *same* logistic regression is fit on the *same* preprocessed data. The estimator is identical $\to$ the numbers match.

**Going further.** What does recipe + workflow *buy* you over a bare `glm`? It makes preprocessing **part of the model** (dummy-coding, normalization, zero-variance removal travel with the fit), re-applied identically at prediction time — no leakage, no "I forgot to scale the test set" — and the whole thing becomes one swappable, tunable object: exactly what lets Step 04 swap engines and tune four models at once.

::: {.notes}
Voce docente (IT): Reveal/my-turn min-72. "Same model, more scaffolding". Going further =
ex-stretch: cosa compra recipe+workflow vs glm nudo.
:::
````

- [ ] **Step 3: Insert min-88 Engage→Reveal right after the min-72 Reveal**

````markdown
## Your turn — logistic → random forest, minimal change? {data-menu-title="min-88 · engine-swap"}

You built a logistic-regression workflow. To turn it into a **random forest** workflow on the *same* data, what is the **minimal** change?

- **A.** Change *only the model spec* — swap `logistic_reg() |> set_engine("glm")` for `rand_forest() |> set_engine("ranger")`. Split, recipe, workflow scaffold stay identical.
- **B.** Rewrite the recipe and the train/test split to suit the new algorithm.
- **C.** Abandon the tidymodels scaffold and call `ranger::ranger()` directly with its own formula.
- **D.** Keep `logistic_reg()` and just change `set_mode()` from `"classification"` to `"regression"`.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-88 (Engage), pre-break. Distrattori: B = riscrivi recipe/split per
algoritmo; C = torni a funzioni package-specifiche; D = confonde MODE con ENGINE.
:::

## The answer — A: change only the spec {data-menu-title="min-88 · reveal"}

**✓ A.** One line — the `parsnip` spec. The split, recipe and workflow are model-agnostic.

- **✗ B** — *rewrite recipe/split per algorithm.* Preprocessing and split are shared; bespoke pipelines defeat the engine-swap idiom.
- **✗ C** — *back to package-specific functions.* `parsnip` is the unified front-end; calling `ranger()` directly loses the one-line swap.
- **✗ D** — *confuses MODE with ENGINE.* Mode = classification vs regression; it does not turn logistic into a forest.

::: {.notes}
Voce docente (IT): Reveal min-88. L'idiom engine-swap: "1 cosa, 4 manopole", non 4 pipeline.
Prepara lo step 04.
:::
````

- [ ] **Step 4: Insert Go-to-code before the `# Hyperparameters…` / Step 04 block**

````markdown
## Go to code — `steps/03-logistic/` {.center}

Open `steps/03-logistic/`: lay the spine and fit the `glm` baseline.

- Build the object-map once — Step 04 only swaps the `parsnip` line.
- **Behind?** Copy `steps/04-zoo/` and you are back in sync.

*Break next — then the zoo.*

::: {.notes}
Voce docente (IT): chiusura Step 03 + annuncio del break. Dopo il break si entra nello step 04
(picco di ampiezza) con la teoria già "compilata".
:::
````

- [ ] **Step 5: Render** → PASS.
- [ ] **Step 6: Visual verify** — Step 03 intro + min-72 + min-88 + go-to-code; the `r` block in min-72 Engage fits; tables on the kept theory slides unchanged.
- [ ] **Step 7: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 03 arc — WHY intro, min-72/min-88 formatives in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Step 04 — dissolve "Hyperparameters" into the intro; min-118 + min-150 + min-165 + go-to-code

This is the structural restructure. Currently the order is:
`# Hyperparameters, one algorithm at a time {.center}` (definition) → 4 param slides → `# Step 04 · The model zoo… {#sec-04-zoo}` (zoo intro + workflowset image) → `## Tuning machinery…` → `## Two metrics — and why a single split lies`.

**Target order after this task:**

```
# Step 04 · The model zoo, tuned & validated {#sec-04-zoo .center}   (NEW intro: zoo + hyperparameter definition + workflowset image)
## Penalized logistic — `penalty` / `mixture`     (KEEP, moved up)
## $k$-NN — `neighbors`                            (KEEP, moved up)
## SVM (RBF) — `cost` / `rbf_sigma`                (KEEP, moved up)
## Random forest — `mtry` / `min_n` / `trees`      (KEEP, moved up)
## Your turn — how does k shape bias & variance?   (NEW min-118 Engage)
## The answer — A: k is the bias–variance dial     (NEW min-118 Reveal)
## Tuning machinery — `workflow_set`, `tune_grid`, CV   (KEEP)
## Two metrics — and why a single split lies        (KEEP)
## Your turn — the culminating task                 (NEW min-150 Engage)
## My turn — one fair race, one honest read         (NEW min-150 Reveal)
## Your turn — predict the order                     (NEW min-165 Engage)
## The reveal — A flatters; B vs C is noise          (NEW min-165 Reveal)
## Go to code — `steps/04-zoo/`                       (NEW closer)
```

- [ ] **Step 1: Delete the standalone `# Hyperparameters, one algorithm at a time {.center}` divider**

Remove that heading, its body paragraph ("A **hyperparameter** is a setting you fix *before* fitting…"), and its `::: {.notes}` block. Its content is folded into the new Step 04 intro (next step). The four `## …` param slides that followed it stay (they become the first theory chunk of Step 04).

- [ ] **Step 2: Replace the `# Step 04 · The model zoo, tuned & validated {#sec-04-zoo}` divider with a WHY intro that absorbs the hyperparameter definition**

Replace the current Step 04 divider block (heading, the `<!-- … -->` comment, the "The **zoo** = the four model families…" paragraph + bullets, the workflowset `<p>…</p>` image block, and its notes) with:

````markdown
# Step 04 · The model zoo, tuned & validated {#sec-04-zoo .center}

<!-- Step 04 (hands-on, 68 min): hyperparameters one at a time -> workflow_set + workflow_map; tune over vfold_cv; rank_results; finalize; last_fit. -->

**Why this step.** Same spine, four families — penalized logistic, $k$-NN, RBF-SVM, random forest — brought together to compete **fairly, once**. First, the dials we will turn.

A **hyperparameter** is a setting you fix *before* fitting — unlike the ordinary parameters (coefficients, split points) that the fit *learns* from the data. We take them **one algorithm at a time** — *what it is* $\to$ *what it controls* $\to$ *its effect on bias / variance / overfitting* — then tune all four together over one shared cross-validation.

<p style="text-align:center; margin:0.8em 0 0 0;">
<img src="../../../img/horststyle/workflowset.jpg" style="max-height:300px; border-radius:8px;"/>
<span style="display:block; font-size:0.5em; color:#888;">The four families racing on one shared 5-fold CV — illustration generated with Images2.0</span>
</p>

::: {.notes}
Voce docente (IT): hands-on, il CUORE (~68 min, picco di ampiezza). L'intro FONDE l'ex-divider
"Hyperparameters" (definizione iperparametro vs parametro) con il framing "zoo = 4 famiglie in
gara". Le 4 slide-parametro che seguono introducono PARAM/BV un algoritmo per volta. Convenzione
EVENT-FIRST → niente `event_level` nel codice.
:::
````

- [ ] **Step 3: Insert min-118 Engage→Reveal after the `## Random forest — \`mtry\` / \`min_n\` / \`trees\`` slide** (end of the four param slides)

````markdown
## Your turn — how does k shape bias & variance? {data-menu-title="min-118 · kNN"}

For $k$-nearest-neighbours, how does the number of neighbours **`k`** affect bias and variance?

- **A.** Small `k` (1–3) $\to$ low bias, **high variance** (boundary follows local noise, overfits); large `k` $\to$ **high bias**, low variance (smoothed, may underfit). `k` is the bias–variance dial.
- **B.** Larger `k` is always better — more neighbours = more information = higher accuracy.
- **C.** `k` only controls computation speed; it does not change predictions or bias/variance.
- **D.** Small `k` $\to$ high bias, low variance; large `k` $\to$ low bias, high variance (the reverse of A).

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-118 (Engage), dopo le 4 slide-parametro. Distrattori: B = più k sempre
meglio; C = k solo velocità; D = direzione bias-variance invertita.
:::

## The answer — A: k is the bias–variance dial {data-menu-title="min-118 · reveal"}

**✓ A.** Small `k` overfits (low bias, high variance); large `k` over-smooths (high bias, low variance). The good `k` is **interior** $\to$ we tune it.

- **✗ B** — *more k is always better.* Treats `k` as a score to maximize; very large `k` underfits.
- **✗ C** — *k is only a speed setting.* It governs flexibility, hence the tradeoff.
- **✗ D** — *direction inverted.* A flexible small-`k` model is high-variance, not high-bias.

::: {.notes}
Voce docente (IT): Reveal min-118. Atterra PARAM→BV un algoritmo per volta; il range di k è
1..n_train, l'ottimo è interno → si tuna.
:::
````

- [ ] **Step 4: Insert min-150 Engage→Reveal after the `## Two metrics — and why a single split lies` slide**

````markdown
## Your turn — the culminating task {data-menu-title="min-150 · culminating"}

From the `workflow_set` of the four algorithms (or `steps/04-zoo/` if behind):

1. Tune all four in **one** call on the **same** resamples: `workflow_map("tune_grid", resamples = folds, grid = 8, metrics = metric_set(roc_auc, pr_auc))` over one `vfold_cv(v = 5)`.
2. `rank_results()` / `autoplot()` $\to$ **name the winner** by CV AUC-ROC.
3. `select_best("roc_auc")` $\to$ `finalize_workflow()` $\to$ **`last_fit()`** on the untouched test set (once), with `metric_set(roc_auc, pr_auc, accuracy)`.
4. Report the CV AUC **and** the test AUC-ROC/AUC-PR; one sentence on why a single ~75-patient split is not trustworthy.

*Your turn — compose the blocks you built in 03–04.*

::: {.notes}
Voce docente (IT): your-turn min-150 (Engage), il culminating task (§10.1). È COMPORRE blocchi
già verificati, non scrivere da zero. Chi è indietro parte da `steps/04-zoo/`.
:::

## My turn — one fair race, one honest read {data-menu-title="min-150 · reveal"}

- **One** `folds` object reused for all four workflows.
- Name the winner (here: **random forest**, ranger); watch **both** metrics for the ~32% imbalance ("always survived" $\approx$ 68% accurate, useless; AUC-PR baseline = prevalence, not 0.5).
- `last_fit()` **once**; read the AUC in **clinical** terms (discrimination of mortality risk).
- **A single split is noisy:** a plain `glm` can score high on one test split, yet in 5-fold CV no linear model reaches the forest — so we trust the **CV ranking**, not one number on a small cohort.

**Going further.** Add a *5th engine* with a one-line swap into the same `workflow_map`. And when does `rank_results` top-by-mean mislead? When CV intervals overlap $\to$ use the **one-standard-error rule** (the simplest model within 1 SE of the best). On this small cohort the SEs are wide — a perfect occasion to make the point.

> **Numbers are read live.** Exact AUCs depend on the seed and the run; what is stable is the **pattern** — CV is the honest ranking, one number on a small cohort is luck.

::: {.notes}
Voce docente (IT): Reveal/my-turn min-150. Niente numeri hard-coded (si leggono dal vivo).
"Going further" = ex-stretch: 5° engine + regola 1-SE quando le CV si sovrappongono.
:::
````

- [ ] **Step 5: Insert min-165 Engage→Reveal right after the min-150 Reveal**

````markdown
## Your turn — predict the order {data-menu-title="min-165 · predict"}

Three AUC-ROC values for the winning **random forest**:

- **A** = resubstitution AUC (scored on the **training** data it was fit on)
- **B** = cross-validated AUC (mean over the 5 folds)
- **C** = test AUC (`last_fit()` on the **held-out** test set)

**Which is clearly the largest? Can you be sure whether B > C or C > B?**

::: {.notes}
Voce docente (IT): predict-output min-165 (Engage). Far predire l'ordine PRIMA del reveal: se la
sala dice A=B=C, l'optimism gap non è atterrato.
:::

## The reveal — A flatters; B vs C is noise {data-menu-title="min-165 · reveal"}

$$\text{A (resubstitution)} \;\gg\; \{\text{B (CV)},\; \text{C (test)}\}$$

**A is by far the largest** — a forest scored on its own rows nearly memorizes them (AUC $\approx 1$); **never quote it.** You **cannot** be sure of B vs C: both are honest-ish estimates, and on a small cohort their gap is mostly **noise** — here the single test split can land *above* the CV, the opposite of the textbook "test is lowest".

That flip **is** the lesson: on ~75 test patients one number is unreliable $\to$ we select on **cross-validation**, and read `last_fit()` once *alongside* it, never instead of it.

::: {.notes}
Voce docente (IT): Reveal min-165. La sorpresa C>B è il momento didattico: il gap CV-vs-test è
rumore di campionamento su N piccolo, non un ordine garantito.
:::
````

- [ ] **Step 6: Insert Go-to-code before `# Step 05`**

````markdown
## Go to code — `steps/04-zoo/` {.center}

Open `steps/04-zoo/`: tune the four, rank them, finalize, `last_fit()` **once**.

- One `folds` object for all four; read the AUCs **live**.
- **Behind?** Copy `steps/05-report/` and you are back in sync.

::: {.notes}
Voce docente (IT): chiusura Step 04. Il parallelo `future` è opzionale (a N=299 il tuning è di
~secondi). I numeri si leggono dall'esecuzione live.
:::
````

- [ ] **Step 7: Render** → PASS.
- [ ] **Step 8: Visual verify** — the new Step 04 intro (image not oversized, definition fits), the 4 param tables unchanged, min-118/min-150/min-165 pairs, the `$$…$$` display math in min-165, the blockquote in min-150, go-to-code. Confirm the old `# Hyperparameters` divider is gone and nothing references it.
- [ ] **Step 9: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 04 arc — dissolve Hyperparameters into intro; min-118/150/165 in-deck; go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Step 05 — intro WHY + min-175 MCQ + go-to-code

**Files:** Modify `00-basic-deck.qmd` — the `# Step 05 · Reproducible report` section (divider + `## Why "one render" *is* reproducibility`). Do **not** touch the closing slides that follow (`## Concept map`, `## Next: open the model — Advanced`, further reading, thank-you).

**Target order:** intro (WHY) → `## Why "one render" *is* reproducibility` (KEEP) → min-175 Engage → min-175 Reveal → Go-to-code → (closing slides unchanged).

- [ ] **Step 1: Rewrite the Step 05 divider to lead with WHY**

````markdown
# Step 05 · Reproducible report {#sec-05-report}

<!-- Step 05 (demo, 13 min): render the report that RUNS the whole analysis; renv::snapshot; pre-hook to Advanced. -->

**Why this step.** A result a colleague cannot re-run is not a result. We ship the deliverable as a report that is reproducible **because it runs the analysis** — every number produced by the same render that prints it.

- The report `.qmd` runs the whole pipeline in one render: split $\to$ recipe $\to$ tune $\to$ finalize $\to$ `last_fit` $\to$ tables & curves.
- Close with `renv::snapshot()`: pinned env + `here` + `set.seed` $\to$ a peer re-runs it and gets the same report.

::: {.notes}
Voce docente (IT): demo (~13 min). Intro col PERCHÉ: riproducibile PERCHÉ gira (numeri ⇔ codice).
Il report NON ricarica una cache: fa le analisi al render (a N=299 il tune è di ~secondi).
:::
````

- [ ] **Step 2: Insert min-175 Engage→Reveal after `## Why "one render" *is* reproducibility`**

````markdown
## Your turn — what makes it reproducible? {data-menu-title="min-175 · repro"}

A colleague should reproduce **every number and figure** on their own machine. What actually makes that possible?

- **A.** The combination: a pinned environment (`renv` lockfile) + stable paths (`here::here()`) + a fixed seed (`set.seed`) + a report that **re-renders the analysis** deterministically. All together.
- **B.** Just email the script — if they have the `.R`/`.qmd`, they can run it.
- **C.** Just `set.seed(123)` — a fixed seed alone guarantees identical output on any machine.
- **D.** Save the final number (the test AUC) in a text file.

*Pick one — then we reveal it.*

::: {.notes}
Voce docente (IT): MCQ min-175 (Engage). Distrattori: B = basta lo script; C = basta il seed;
D = salvare il numero = riproducibile.
:::

## The answer — A: the whole combination {data-menu-title="min-175 · reveal"}

**✓ A.** Environment + paths + seed + an executable report, **together**.

- **✗ B** — *emailing the script is enough.* Code depends on package versions, file paths and data that differ across machines.
- **✗ C** — *`set.seed` alone.* A seed fixes the random stream, not the package versions; a different `glmnet`/`ranger` can still change the numbers.
- **✗ D** — *saving the number = reproducible.* Recording a result is not being able to **re-derive** it.

::: {.notes}
Voce docente (IT): Reveal min-175. La riproducibilità è la combinazione; il singolo pezzo non
basta. Pre-hook a `targets` (capstone Advanced) per analisi pesanti.
:::
````

- [ ] **Step 3: Insert Go-to-code before `## Concept map — the whole afternoon`**

````markdown
## Go to code — `steps/05-report/` {.center}

**Follow along.** Render `steps/05-report/` — the report that *runs* the analysis — then `renv::snapshot()`.

- One render = the numbers and the code that made them are the same object.
- This validated `final_fit` is exactly what **Advanced reopens** on day one.

::: {.notes}
Voce docente (IT): chiusura Step 05 (demo → "follow along"). Ponte all'Advanced: il workflow
finalizzato di Basic è ciò che l'Advanced ricarica al giorno uno (pre-hook).
:::
````

- [ ] **Step 4: Render** → PASS.
- [ ] **Step 5: Visual verify** — Step 05 intro + min-175 pair + go-to-code; then confirm the closing slides (concept map mermaid, "Next: Advanced", further reading, thank-you) are intact and unchanged.
- [ ] **Step 6: Commit**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): Step 05 arc — WHY intro, min-175 repro MCQ in-deck, go-to-code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Retire the standalone formatives + update the README map

**Files:**
- Delete: `slides/workshops/mlt-r-basic/formatives/min-09-live-check.md`, `min-30-yourturn-wrangle.md`, `min-31-mcq-pipe.md`, `min-50-mcq-metric.md`, `min-72-yourturn-glm.md`, `min-88-mcq-engine-swap.md`, `min-118-mcq-knn.md`, `min-150-yourturn-culminating.md`, `min-165-predict-output.md`, `min-175-mcq-repro.md` — plus any rendered `min-*.html` and `min-*_files/` under `formatives/`.
- Modify: `slides/workshops/mlt-r-basic/formatives/README.md` — keep as the map (already accurate); add a one-line note that the content now lives in the deck.

- [ ] **Step 1: Delete the 10 source `.md` and their rendered outputs**

```bash
cd "c:/Users/corra/github/cl/mlt-overview/slides/workshops/mlt-r-basic/formatives"
git rm min-09-live-check.md min-30-yourturn-wrangle.md min-31-mcq-pipe.md min-50-mcq-metric.md min-72-yourturn-glm.md min-88-mcq-engine-swap.md min-118-mcq-knn.md min-150-yourturn-culminating.md min-165-predict-output.md min-175-mcq-repro.md
```

Then remove any rendered artifacts that are not git-tracked (untracked `.html`/`_files`):

```bash
cd "c:/Users/corra/github/cl/mlt-overview"
pwsh -NoProfile -Command "Get-ChildItem 'slides/workshops/mlt-r-basic/formatives' -Filter 'min-*.html' | Remove-Item -Force; Get-ChildItem 'slides/workshops/mlt-r-basic/formatives' -Directory -Filter 'min-*_files' | Remove-Item -Recurse -Force"
```

Expected: `formatives/` now contains only `README.md` (+ `.gitignore` if any).

- [ ] **Step 2: Update `formatives/README.md`**

At the top of `formatives/README.md`, immediately after the H1 title line, insert this note (keep the existing mapping table and design sections — they remain the source-of-truth map):

```markdown
> **Nota (2026-06-03):** il *contenuto* di queste formative ora vive **inline nel deck unico**
> (`../00-basic-deck.qmd`) come coppie di slide **Engage → Reveal**, integrate al loro punto
> dell'arco per-step. Questo file resta la **mappa** formativa→step→minuto→nodo (e il razionale
> dei distrattori). Gli HTML standalone delle formative sono stati ritirati.
```

- [ ] **Step 3: Confirm a whole-project render now emits only the deck**

Run: `quarto render slides/workshops/mlt-r-basic`
Expected: PASS — renders `00-basic-deck.html` only; **no** `min-*.html` reappear (the sources are gone). (This is the first whole-project render since Task 0; it confirms problem #1 is fixed without any pipeline change.)

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/corra/github/cl/mlt-overview"
git add slides/workshops/mlt-r-basic/formatives/
git commit -m "slides(basic): retire standalone formative HTMLs; README becomes the map

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Full-deck visual verification pass

**Files:** none modified unless fixes are needed (then `00-basic-deck.qmd`).

- [ ] **Step 1: Final render**

Run: `quarto render slides/workshops/mlt-r-basic/00-basic-deck.qmd` → PASS.

- [ ] **Step 2: Whole-deck visual sweep (chrome-devtools)**

Open `00-basic-deck.html` at 1648×1080 and walk **every** slide start to finish (arrow keys / `?print-pdf`). Verify per the project's universal gate:

- no text past the right edge; no clipped code blocks; no overlapping elements;
- every formative is a clean **Engage → Reveal** pair at the right place; every step has exactly **one** WHY intro and **one** Go-to-code closer;
- all `$…$`/`$$…$$` math renders (no raw LaTeX, no combining-Unicode);
- the Step 03 object-map mermaid and Step 05 concept-map mermaid still render and fit;
- opening and closing slides unchanged.

Re-check critical slides at ~1100px wide. Fix any issue in `00-basic-deck.qmd`, re-render, re-check until clean.

- [ ] **Step 3: Commit any fixes** (skip if none)

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "slides(basic): visual-verification fixes (overflow/spacing/math)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 4: Handoff note**

Basic deck is the **reference pattern** complete. Next: Plan 2 (Advanced) applies the identical arc to `00-advanced-deck.qmd` + its 11 formatives (incl. the Parsons min-80), then `/mlt-build` rebuilds deck + ZIP + portal for both. Do **not** run `/mlt-build` yet (it is the final step after Advanced).

---

## Self-review (planner checklist — done)

**1. Spec coverage:**

- §3 per-step arc (intro WHY + interleaved theory/formative + go-to-code) → Tasks 1–6 (every step).
- §4 Engage→Reveal anatomy (commitment beat; ✓/✗ with why; Going further; `data-menu-title`; EN slide / IT notes) → frozen in Task 1, applied in 2–6.
- §5 retire standalone HTML + strip personas → Task 7 (deletes) + Tasks 1/3/5 (`Going further` replaces `Stretch (Davide)`; no persona names authored anywhere).
- §6 preserve module-level + README map + doctrine → "Do NOT touch" convention + Task 7 Step 2.
- §7 Basic map incl. interleave placements + Hyperparameters dissolution → Tasks 1–6 target-order blocks; Task 5 Steps 1–2.
- Visual-verification gate → every task's verify step + Task 8.

**2. Placeholder scan:** every NEW slide's exact markdown (heading, body, math, code, notes) is reproduced inline; no "TBD"/"similar to"/"add notes". Kept theory slides are named exactly and left as-is.

**3. Type/name consistency:** headings referenced in "target order" match the authored `##` headings; `data-menu-title` tags consistent (`min-NN · tag`); `{#sec-…}` ids preserved on dividers (`#sec-00-setup`, `#sec-01-import`, `#sec-02-eda`, `#sec-03-logistic`, `#sec-04-zoo`, `#sec-05-report`); commit messages all use the `slides(basic):` prefix.

---

## Execution handoff

Implement via **superpowers:subagent-driven-development** on branch `workshop-deck-redesign` (fresh subagent per task, two-stage review between tasks). Task 1 must land first (it freezes the pattern); Tasks 2–6 are independent step-edits; Task 7 must run after 1–6 (it deletes the sources the earlier tasks transcribe from); Task 8 is the final sweep. **Never `git push`.**
