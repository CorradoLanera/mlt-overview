# MLT R — Basic Workshop Build — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete, runnable `mlt-r-basic` repository — a ~4h live-coded "Practical AI for Medical Data Analyses with R – Basic" workshop delivered as one RStudio project with cumulative pre-compiled checkpoint folders.

**Architecture:** One self-contained project folder — `workshops/mlt-r-basic/` **inside the existing `mlt-overview` repo** — with its own `.Rproj` + `renv` (nested), and `steps/NN-slug/` folders each holding the **complete cumulative analysis state** at the end of that step (the answer key to step N is folder N+1). Each step driver is a Quarto `.qmd` with a `params$solved` flag that renders both the blanked "Your turn" version and the solved version from one source. Slides are a separate Quarto revealjs build under `slides/`. Everything is verified by **execution** (the code runs / the report renders / the metric appears), which is this project's analog of tests.

> **BUILD LOCATION (decided 2026-05-30 — overrides the spec's original "separate repo"):** build everything under
> `workshops/mlt-r-basic/` **within the `mlt-overview` repo** so the whole course stays integrated and versioned in
> one place. Therefore: **(a)** every `mlt-r-basic/` path and `cd mlt-r-basic` below means `workshops/mlt-r-basic/`;
> **(b)** there is **no separate `git init`** — all `git add`/`git commit` target the `mlt-overview` repo on branch
> `mlt-r-workshops-design`; **(c)** the workshop folder is its **own nested renv project** — always run R *from
> inside* `workshops/mlt-r-basic/` so its `.Rprofile` activates its renv (not the repo-root one); **(d)** distribution
> for `use_course` is a ZIP of this folder, produced later by a root hook (out of scope for this plan).

**Tech Stack:** R 4.5.x · `renv` · `here` · `rio` · `tidyverse` · `janitor` · `gtsummary` · `tidymodels` (`rsample`/`recipes`/`parsnip`/`workflows`/`workflowsets`/`tune`/`yardstick`/`dials`) · engines `glmnet`/`kknn`/`kernlab`/`ranger` · `future` (parallel tuning) · Quarto (revealjs + html) · dataset `medicaldata::indo_rct`.

---

## Verification model (read first)

This is course material, not a library, so the TDD loop is adapted: for each artifact the "failing test" is **defining the expected runnable outcome**, and "green" is **running it and observing that outcome**. Concretely, every content task ends with a verification step that either:

- runs an R expression in the step folder and checks a printed value/object exists (e.g. a tibble with N rows, a `roc_auc` estimate), or
- renders a `.qmd` with `quarto render` and checks the HTML is produced without error and contains the expected table/plot, or
- renders a step **twice** (`-P solved:true` and `-P solved:false`) and checks the solved version has code where the student version has `___` blanks.

No step is "done" until its verification command has been run and passed. Commit after each green step.

## File structure (created by this plan)

```
mlt-r-basic/
├── mlt-r-basic.Rproj            # one project for the whole workshop
├── .Rprofile                    # source("renv/activate.R")
├── .gitignore
├── renv.lock / renv/            # pinned environment (superset of all steps)
├── requirements.R               # pak::pak() the package set; renv::snapshot()
├── README.md                    # use_course one-liner + Posit Cloud link
├── CLAUDE.md                    # R style contract (delivery + lingua)
├── _manifest.yml                # steps + summative + formatives (source of truth)
├── _solved.R                    # helper: render a step .qmd in both solved/blank modes
├── slides/
│   ├── _quarto.yml              # revealjs project (1648x1080, speaker, countdown)
│   ├── theme.scss               # orange-accent theme (from overview)
│   ├── 00-basic-deck.qmd        # the single Basic deck (concept graph + param slides)
│   └── concept-graph.mmd        # validated Mermaid (spec §10.2)
├── data-raw/
│   └── indo_rct.csv             # committed seed of medicaldata::indo_rct
└── steps/
    ├── 00-setup/      00-setup.qmd   + data-raw/ data/ output/ R/
    ├── 01-import/     01-import.qmd  + (cumulative)
    ├── 02-eda/        02-eda.qmd     + (cumulative)
    ├── 03-logistic/   03-logistic.qmd+ (cumulative)
    ├── 04-zoo/        04-zoo.qmd     + (cumulative; saves output/final_fit.rds)
    └── 05-report/     05-report.qmd  + (cumulative; the deliverable report)
```

Each `steps/NN-slug/` is self-contained: its own `data-raw/indo_rct.csv` (duplicated, a few KB) so the folder runs standalone (the fall-behind guarantee), its own `R/` helpers as they exist at that step, and the driver `.qmd` whose knitr working directory is the folder (so paths are folder-relative).

---

## Phase 0 — Repository scaffold

### Task 0.1: Initialize the project + environment

**Files:**
- Create: `mlt-r-basic/mlt-r-basic.Rproj`, `.Rprofile`, `.gitignore`, `requirements.R`

- [ ] **Step 1: Create the project directory and `.Rproj`**

Create `mlt-r-basic/mlt-r-basic.Rproj`:

```
Version: 1.0
RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: No
EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8
RnwWeave: knitr
LaTeX: pdfLaTeX
```

- [ ] **Step 2: Create `.Rprofile` and `.gitignore`**

`.Rprofile`:
```r
source("renv/activate.R")
```

`.gitignore`:
```
.Rproj.user
.Rhistory
.RData
.Ruserdata
/steps/**/output/*.rds
!/steps/**/output/.keep
/*_files
/*_cache
.quarto/
```

- [ ] **Step 3: Create `requirements.R`**

```r
# requirements.R — install the Basic workshop package set, then snapshot.
# Run once during build: source("requirements.R")
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak(c(
  "here", "rio", "tidyverse", "janitor", "gtsummary",
  "tidymodels", "workflowsets", "glmnet", "kknn", "kernlab", "ranger",
  "future", "quarto", "medicaldata", "renv"
))
renv::snapshot()
```

- [ ] **Step 4: Initialize renv and install**

Run:
```bash
cd mlt-r-basic && Rscript -e "renv::init(bare = TRUE)" && Rscript requirements.R
```
Expected: `renv/`, `renv.lock` created; all packages install; `renv::snapshot()` writes the lockfile. If `glmnet`/`ranger` need compilation, that is acceptable at build time (never live in class).

- [ ] **Step 5: Verify the environment loads**

Run:
```bash
cd mlt-r-basic && Rscript -e "library(tidymodels); library(workflowsets); library(gtsummary); library(medicaldata); cat('ENV OK\n')"
```
Expected: prints `ENV OK` with no errors.

- [ ] **Step 6: Commit**

```bash
git add mlt-r-basic.Rproj .Rprofile .gitignore requirements.R renv.lock renv/activate.R renv/settings.json
git commit -m "Scaffold mlt-r-basic project + pinned renv environment"
```

### Task 0.2: Seed the dataset

**Files:**
- Create: `mlt-r-basic/data-raw/indo_rct.csv`, `R/seed-data.R`

- [ ] **Step 1: Write the seed script**

`R/seed-data.R`:
```r
# Seed the committed clinical dataset from {medicaldata}. Run once at build.
library(here)
library(rio)
indo_rct <- medicaldata::indo_rct
export(indo_rct, here("data-raw", "indo_rct.csv"))
cat("rows:", nrow(indo_rct), "event rate:",
    round(mean(indo_rct$outcome == "1_yes"), 3), "\n")
```

- [ ] **Step 2: Run it and verify the known facts**

Run:
```bash
cd mlt-r-basic && Rscript R/seed-data.R
```
Expected: prints `rows: 602 event rate: 0.131` and creates `data-raw/indo_rct.csv`.

- [ ] **Step 3: Commit**

```bash
git add data-raw/indo_rct.csv R/seed-data.R
git commit -m "Seed committed indo_rct.csv (602 rows, ~13% events)"
```

### Task 0.3: Author `CLAUDE.md`, `README.md`, `_manifest.yml`

**Files:**
- Create: `mlt-r-basic/CLAUDE.md`, `README.md`, `_manifest.yml`

- [ ] **Step 1: `CLAUDE.md` (style contract)**

```markdown
# CLAUDE.md — mlt-r-basic

Live-coded R workshop. Build conventions (spec §9, §8):

- Native pipe `|>` only (never `%>%`); `_` placeholder where needed.
- `<-` for objects, `=` only for function args. snake_case with type suffix (`indo_tbl`, `train`).
- ALL paths via `here::here()`. `library()` + `renv`, never bare `install.packages()` in step code.
- `{rio}::import()` for IO. ggplot: data in `|>`, layers with `+`, then `ggsave()`.
- One arg per line + trailing comma in multi-arg calls. `# Section ----` banners. 2 spaces. `set.seed(123)`.
- Student-facing text in ENGLISH; teacher/design notes in ITALIAN.
- DELIVERY: live-coding, NO pre-baked results shown as live. Each `steps/NN-slug/` is a complete cumulative
  snapshot; the solution of step N is step N+1.
```

- [ ] **Step 2: `README.md`**

```markdown
# Practical AI for Medical Data Analyses with R — Basic

A ~4h live-coded workshop: build and validate a clinical machine-learning model in R, the reproducible way.

## Get started (one line)

```r
usethis::use_course("CorradoLanera/mlt-r-basic")
```

This downloads the whole project and opens it. Then run `renv::restore()` once. No-install option: the numbered
Posit Cloud workspace (link shared in class).

## How it works

Open `mlt-r-basic.Rproj`. Each `steps/NN-slug/` folder is the **complete, runnable state** of the analysis at the
end of that step — if you fall behind, open the next folder and you are caught up. Dataset: `medicaldata::indo_rct`
(post-ERCP pancreatitis RCT).
```

- [ ] **Step 3: `_manifest.yml`**

```yaml
workshop:
  title: "Practical AI for Medical Data Analyses with R - Basic"
  slug: mlt-r-basic
  language: en
  total_minutes_gross: 240
  dataset: "medicaldata::indo_rct"
summative: "build -> tune (workflow_set) -> validate (last_fit) -> reproducible report"
steps:
  - { slug: 00-setup,    title: "Setup",                 mode: demo,     minutes: 10, include: true }
  - { slug: 01-import,   title: "Import & wrangle",      mode: hands-on, minutes: 32, include: true }
  - { slug: 02-eda,      title: "Clinical EDA",          mode: hands-on, minutes: 22, include: true }
  - { slug: 03-logistic, title: "Logistic spine",        mode: hands-on, minutes: 38, include: true }
  - { slug: 04-zoo,      title: "The zoo, tuned",        mode: hands-on, minutes: 68, include: true }
  - { slug: 05-report,   title: "Reproducible report",   mode: demo,     minutes: 13, include: true }
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md README.md _manifest.yml
git commit -m "Add style contract, README, and step manifest"
```

### Task 0.4: The `params$solved` render helper + step skeleton

**Files:**
- Create: `mlt-r-basic/_solved.R`, `steps/_template/_template.qmd`

- [ ] **Step 1: Define the solved/blank convention**

Each step `.qmd` declares `params: solved: true` and writes every "Your turn" chunk twice using a conditional:
the solved code runs when `params$solved`, and a blanked echo shows otherwise. Create `steps/_template/_template.qmd`:

````markdown
---
title: "Step NN — <title>"
format:
  html:
    embed-resources: true
    toc: true
params:
  solved: true
execute:
  warning: false
  message: false
---

```{r setup}
#| include: false
library(here)
```

## Your turn

```{r yourturn, eval=params$solved}
# SOLVED version runs when solved:true
```

```{r yourturn-blank, eval=!params$solved, echo=TRUE, code=readLines(here("yourturn-blank.R"))}
```
````

- [ ] **Step 2: Write the render helper `_solved.R`**

```r
# _solved.R — render a step driver in both modes. Usage: Rscript _solved.R steps/01-import/01-import.qmd
args <- commandArgs(trailingOnly = TRUE)
qmd  <- args[[1]]
quarto::quarto_render(qmd, execute_params = list(solved = TRUE),
                      output_file = sub("\\.qmd$", "-solved.html", basename(qmd)))
quarto::quarto_render(qmd, execute_params = list(solved = FALSE),
                      output_file = sub("\\.qmd$", "-blank.html", basename(qmd)))
cat("rendered both modes for", qmd, "\n")
```

- [ ] **Step 3: Commit**

```bash
git add _solved.R steps/_template/_template.qmd
git commit -m "Add params\$solved render helper and step template"
```

### Task 0.5: Slides project skeleton + theme + concept graph

**Files:**
- Create: `slides/_quarto.yml`, `slides/theme.scss`, `slides/concept-graph.mmd`, `slides/00-basic-deck.qmd`

- [ ] **Step 1: `slides/_quarto.yml`**

```yaml
project:
  type: default
format:
  revealjs:
    width: 1648
    height: 1080
    theme: [default, theme.scss]
    slide-number: true
    code-link: true
    chalkboard: true
    footer: "Practical AI for Medical Data Analyses with R — Basic"
```

- [ ] **Step 2: `slides/theme.scss`** — copy the orange-accent palette/fonts from the overview's `xaringan-themer.css` equivalents.

```scss
/*-- scss:defaults --*/
$body-color: #1a1a1a;
$link-color: #E8741E;      // orange accent (overview palette)
$presentation-heading-color: #E8741E;
$presentation-font-size-root: 32px;
```

- [ ] **Step 3: `slides/concept-graph.mmd`** — paste the validated Basic concept graph from spec §10.2 verbatim (25 nodes).

- [ ] **Step 4: `slides/00-basic-deck.qmd` skeleton** — title slide + a section per step + the four parameter slides (penalized-logistic `penalty/mixture`, kNN `neighbors`, SVM `cost/rbf_sigma`, RF `mtry/min_n`), each stating the knob's meaning + bias/variance impact, + a slide embedding `concept-graph.mmd`. Full slide prose is authored in Task 2.1; here create the file with section headers only.

- [ ] **Step 5: Verify the deck renders**

Run:
```bash
cd mlt-r-basic/slides && quarto render 00-basic-deck.qmd
```
Expected: `00-basic-deck.html` is produced with no error.

- [ ] **Step 6: Commit**

```bash
git add slides/
git commit -m "Scaffold Basic slides project (revealjs + orange theme + concept graph)"
```

---

## Phase 1 — Step content (cumulative checkpoint folders)

Pattern for every step task: (a) create the folder by copying the previous step's folder (so it is cumulative), (b) author the driver `.qmd` adding this step's beats, (c) run/render to verify, (d) commit. Each folder gets its own `data-raw/indo_rct.csv`, and `data/ output/ R/` with `.keep` files.

### Task 1.0: `steps/00-setup`

**Files:**
- Create: `steps/00-setup/00-setup.qmd`, `steps/00-setup/data-raw/indo_rct.csv`, `data/.keep`, `output/.keep`, `R/.keep`

- [ ] **Step 1: Create folder + copy data**

```bash
cd mlt-r-basic && mkdir -p steps/00-setup/{data-raw,data,output,R}
cp data-raw/indo_rct.csv steps/00-setup/data-raw/
touch steps/00-setup/data/.keep steps/00-setup/output/.keep steps/00-setup/R/.keep
```

- [ ] **Step 2: Author `00-setup.qmd`**

````markdown
---
title: "Step 00 — Setup"
format: { html: { embed-resources: true, toc: true } }
params: { solved: true }
execute: { warning: false, message: false }
---

We open the project, restore the pinned environment, and load the data the reproducible way.

```{r}
library(here)
library(rio)

indo_raw <- import(here("data-raw", "indo_rct.csv"), setclass = "tibble")
dim(indo_raw)
```
````

- [ ] **Step 3: Verify it renders and loads 602 rows**

Run:
```bash
cd mlt-r-basic/steps/00-setup && quarto render 00-setup.qmd
```
Expected: `00-setup.html` produced; the printed `dim` is `602  33`.

- [ ] **Step 4: Commit**

```bash
git add steps/00-setup
git commit -m "Step 00: project setup + here/rio data load"
```

### Task 1.1: `steps/01-import`

**Files:**
- Create: `steps/01-import/` (copy of 00) + `01-import.qmd` + `R/yourturn-01.R`

- [ ] **Step 1: Create cumulative folder**

```bash
cd mlt-r-basic && cp -r steps/00-setup steps/01-import
git rm -r --cached steps/01-import/00-setup.qmd 2>/dev/null; rm -f steps/01-import/00-setup.qmd
```

- [ ] **Step 2: Author `01-import.qmd` (solved path)**

````markdown
---
title: "Step 01 — Import & wrangle"
format: { html: { embed-resources: true, toc: true } }
params: { solved: true }
execute: { warning: false, message: false }
---

```{r}
library(here)
library(rio)
library(tidyverse)
library(janitor)

indo_raw <- import(here("data-raw", "indo_rct.csv"), setclass = "tibble")

indo <- indo_raw |>
  clean_names() |>
  select(outcome, age, risk, gender, sod, rx, type, site) |>
  filter(!is.na(age)) |>
  mutate(outcome = factor(outcome, levels = c("0_no", "1_yes")))

glimpse(indo)
```
````

- [ ] **Step 3: Author the blank "Your turn" `R/yourturn-01.R`** (the student version with `___` for the `select`/`filter`/`mutate` lines, per spec §10.3 min-30 formative).

- [ ] **Step 4: Verify both modes render**

Run:
```bash
cd mlt-r-basic && Rscript _solved.R steps/01-import/01-import.qmd
```
Expected: `01-import-solved.html` (8-col tibble, `outcome` a 2-level factor) and `01-import-blank.html` (blanks visible) both produced.

- [ ] **Step 5: Commit**

```bash
git add steps/01-import
git commit -m "Step 01: import + tidyverse wrangle (cumulative)"
```

### Task 1.2: `steps/02-eda`

**Files:**
- Create: `steps/02-eda/` (copy of 01) + `02-eda.qmd`

- [ ] **Step 1: Create cumulative folder** (`cp -r steps/01-import steps/02-eda`; remove `01-import.qmd`).

- [ ] **Step 2: Author `02-eda.qmd`** — carries the import block, then adds:

```{r}
library(gtsummary)

indo |>
  tbl_summary(
    by = outcome,
    include = c(age, risk, gender, sod, rx, type),
  )

age_plot <- indo |>
  ggplot(aes(x = outcome, y = age, fill = outcome)) +
  geom_boxplot() +
  theme_minimal()

ggsave(here("output", "age_by_outcome.png"), plot = age_plot, width = 6, height = 4)
age_plot
```

- [ ] **Step 3: Verify** — `quarto render steps/02-eda/02-eda.qmd`; expected: HTML with a stratified summary table showing the ~13% event split and a saved `output/age_by_outcome.png`.

- [ ] **Step 4: Commit** — `git add steps/02-eda && git commit -m "Step 02: clinical EDA (gtsummary + ggplot)"`.

### Task 1.3: `steps/03-logistic`

**Files:**
- Create: `steps/03-logistic/` (copy of 02) + `03-logistic.qmd` + `R/yourturn-03.R`

- [ ] **Step 1: Create cumulative folder**.

- [ ] **Step 2: Author `03-logistic.qmd`** — carries import + (optionally) EDA, then the tidymodels object-map with the plain `glm` baseline:

```{r}
library(tidymodels)
set.seed(123)

data_split <- initial_split(indo, prop = 0.75, strata = outcome)
train <- training(data_split)
test  <- testing(data_split)

base_rec <- recipe(outcome ~ ., data = train) |>
  step_dummy(all_nominal_predictors()) |>
  step_zv(all_predictors()) |>
  step_normalize(all_numeric_predictors())

log_spec <- logistic_reg() |> set_engine("glm")

log_wf <- workflow() |>
  add_recipe(base_rec) |>
  add_model(log_spec)

log_fit <- fit(log_wf, data = train)

log_fit |>
  augment(new_data = test) |>
  roc_auc(truth = outcome, .pred_1_yes, event_level = "second")
```

- [ ] **Step 3: Author the blank "Your turn" `R/yourturn-03.R`** (predict/bind/roc_auc with `___`, per spec §10.3 min-72 formative).

- [ ] **Step 4: Verify** — `Rscript _solved.R steps/03-logistic/03-logistic.qmd`; expected: both HTMLs render and the solved one prints a `roc_auc` estimate (a single `.estimate` between 0 and 1).

- [ ] **Step 5: Commit** — `git add steps/03-logistic && git commit -m "Step 03: logistic spine + tidymodels object-map"`.

### Task 1.4: `steps/04-zoo` (the core — workflowset tuning + validation)

**Files:**
- Create: `steps/04-zoo/` (copy of 03) + `04-zoo.qmd` + `R/yourturn-04.R`

- [ ] **Step 1: Create cumulative folder**.

- [ ] **Step 2: Author `04-zoo.qmd`** — carries the split + recipe from step 03, then the four tunable specs, the workflow_set, ONE workflow_map tune over shared folds, compare, finalize, last_fit, and **save the finalized fit for the Advanced workshop**:

```{r}
library(tidymodels)
library(workflowsets)
library(future)
plan(multisession)
set.seed(123)

# --- Four tunable model specs (engine-swap idiom) ----
penlog_spec <- logistic_reg(penalty = tune(), mixture = tune()) |> set_engine("glmnet")
knn_spec    <- nearest_neighbor(neighbors = tune()) |> set_engine("kknn")   |> set_mode("classification")
svm_spec    <- svm_rbf(cost = tune(), rbf_sigma = tune()) |> set_engine("kernlab") |> set_mode("classification")
rf_spec     <- rand_forest(mtry = tune(), min_n = tune()) |> set_engine("ranger")  |> set_mode("classification")

# --- Shared resamples + the set ----
folds <- vfold_cv(train, v = 5, strata = outcome)

wf_set <- workflow_set(
  preproc = list(rec = base_rec),
  models  = list(penlog = penlog_spec, knn = knn_spec, svm = svm_spec, rf = rf_spec),
)

# --- Tune ALL four in ONE call over the SAME folds ----
wf_res <- wf_set |>
  workflow_map(
    "tune_grid",
    resamples = folds,
    grid      = 8,
    metrics   = metric_set(roc_auc),
    verbose   = TRUE,
    seed      = 123,
  )

rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE)
autoplot(wf_res)

# --- Pick the winner, finalize, validate on the untouched test set ----
best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(wflow_id)
best_res    <- extract_workflow_set_result(wf_res, best_id)
best_params <- select_best(best_res, metric = "roc_auc")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(best_params)

final_fit <- last_fit(final_wf, split = data_split, metrics = metric_set(roc_auc, accuracy))
collect_metrics(final_fit)
collect_predictions(final_fit) |>
  roc_curve(outcome, .pred_1_yes, event_level = "second") |>
  autoplot()

# Hand-off artifact for the Advanced workshop (reloaded there):
saveRDS(final_fit, here("output", "final_fit.rds"))
```

- [ ] **Step 3: Author the blank "Your turn" `R/yourturn-04.R`** — the culminating task (spec §10.1): `rank_results` → `extract_workflow_set_result` → `select_best` → `finalize_workflow` → `last_fit` → report both CV and test AUC, with `___` blanks.

- [ ] **Step 4: Verify it runs end-to-end (this is the heaviest compute; keep grid=8, v=5)**

Run:
```bash
cd mlt-r-basic && Rscript _solved.R steps/04-zoo/04-zoo.qmd
```
Expected: renders; `collect_metrics(final_fit)` shows a test `roc_auc` and `accuracy`; `output/final_fit.rds` exists. Confirm wall-clock of the `workflow_map` is bounded (tens of seconds with `plan(multisession)`); if SVM dominates, reduce its grid via a per-model `option_add`.

- [ ] **Step 5: Commit** — `git add steps/04-zoo && git commit -m "Step 04: 4-model workflow_set tuned + validated; save final_fit.rds"`.

### Task 1.5: `steps/05-report`

**Files:**
- Create: `steps/05-report/` (copy of 04) + `05-report.qmd`

- [ ] **Step 1: Create cumulative folder**.

- [ ] **Step 2: Author `05-report.qmd`** — a self-contained narrative report (`embed-resources: true`, `code-fold: true`) that reads `output/final_fit.rds` (cached, so render is fast and shows no pre-baked-as-live numbers — it reloads what was computed live in step 04), presents the baseline table, the model comparison, the test ROC curve + AUC, and closes with a `renv::snapshot()` note. Use `#| cache: true` on the heavy chunk OR `readRDS(here("output","final_fit.rds"))` to avoid re-tuning on render.

- [ ] **Step 3: Verify** — `quarto render steps/05-report/05-report.qmd`; expected: a single self-contained HTML with the final AUC and ROC curve, rendered in well under 90s (no re-tuning).

- [ ] **Step 4: Commit** — `git add steps/05-report && git commit -m "Step 05: reproducible Quarto report (cached)"`.

---

## Phase 2 — Slides and formative materials

### Task 2.1: Author the Basic deck

**Files:**
- Modify: `slides/00-basic-deck.qmd`

- [ ] **Step 1: Write the full slide content** following the agenda + objectives in spec §10.3: a title slide; the supervised-vs-unsupervised bridge sentence; the tidymodels object-map diagram; the four parameter slides (each: knob name → meaning → bias/variance/overfitting impact, per spec §10.3 step-04 row); the optimism-gap slide; a slide embedding `concept-graph.mmd`; a closing pre-hook to Advanced.
- [ ] **Step 2: Verify render** — `quarto render slides/00-basic-deck.qmd`; expected: HTML deck, concept graph renders.
- [ ] **Step 3: Visual QA** — open the deck in chrome-devtools at 1080p; check no overflow on the parameter slides and the concept-graph slide (per spec §16). Fix overflow (shrink graph / split slide).
- [ ] **Step 4: Commit** — `git add slides/00-basic-deck.qmd && git commit -m "Author Basic deck (param slides + concept graph)"`.

### Task 2.2: Author the formative item bank

**Files:**
- Create: `slides/formatives/` — one `.md` per formative from spec §10.3 (10 items), MCQs carrying their diagnostic distractors verbatim.

- [ ] **Step 1: Transcribe the 10 formatives** from spec §10.3 into individual files (e.g. `min-09-live-check.md`, `min-31-mcq-pipe.md`, …), each with the prompt, the correct answer, and for MCQs each distractor tagged with the misconception it reveals.
- [ ] **Step 2: Cross-check** every formative maps to a concept-graph node (spec §10.2) and lands at its scheduled minute.
- [ ] **Step 3: Commit** — `git add slides/formatives && git commit -m "Add 10 formative checks with diagnostic distractors"`.

---

## Phase 3 — Verification & polish (W3)

### Task 3.1: Fall-behind test (every folder runs standalone)

- [ ] **Step 1: From a clean R session, render each step folder in isolation**

Run:
```bash
cd mlt-r-basic && for s in steps/0*/; do Rscript -e "quarto::quarto_render('${s}$(basename $s).qmd')" || echo "FAIL: $s"; done
```
Expected: every step renders with no `FAIL` line — proving a student who opens any folder cold is caught up.

- [ ] **Step 2: Commit any fixes** — `git commit -am "Fix standalone-render issues per fall-behind test"` (only if changes).

### Task 3.2: Timing dry-run

- [ ] **Step 1:** Walk the agenda (spec §10.3) against a wall clock, live-typing each step's code from blank, to confirm the ~240-min budget holds (Basic target ~183 teaching + break + overhead). Note any step that overran; the EDA step (02) is the documented elastic buffer.
- [ ] **Step 2:** Record findings in `slides/timing-notes.md` (IT, teacher notes). Commit.

### Task 3.3: Final visual QA + README link check

- [ ] **Step 1:** Render the full deck + the 6 step reports; open each in chrome-devtools; confirm no overflow, the orange theme applies, code-fold works.
- [ ] **Step 2:** Confirm the `use_course` README one-liner resolves once the repo is pushed (deferred until publish decision, spec §19.5).
- [ ] **Step 3: Commit** — `git commit -am "Final visual QA pass"`.

---

## Self-review (completed against the spec)

- **Spec coverage:** §6 delivery mechanism → Tasks 0.1/0.4 + Phase 1 folders. §8 no-pre-baked → step 05 cached render (Task 1.5) + verification model. §9 style → CLAUDE.md (0.3). §10.1 summative → Task 1.4 step 3 (the culminating "Your turn"). §10.2 concept graph → Task 0.5/2.1. §10.3 agenda+formatives → Phase 1 + Task 2.2. §10.4 load (param slides one-at-a-time) → Task 2.1. §12 data (verified) → Task 0.2. §13 env → Task 0.1. §16 visual QA → Tasks 2.1/3.3. **No gaps found.**
- **Placeholder scan:** R for the load-bearing steps (03, 04) is complete and API-verified (context7 `/tidymodels/workflowsets`). Slide prose (Task 2.1) and the blanked `yourturn-*.R` files reference exact spec sections rather than inlining — acceptable because the source content is fully authored in the committed spec.
- **Type/name consistency:** object names are consistent across steps — `indo_raw` → `indo` → `data_split`/`train`/`test` → `base_rec` → `wf_set`/`wf_res` → `final_fit` (saved as `output/final_fit.rds`, reloaded by Advanced). `event_level = "second"` used everywhere `1_yes` is scored.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-30-mlt-r-basic-build.md`. The Advanced workshop is a **sibling plan** to author next (it begins by reloading `steps/04-zoo/output/final_fit.rds` from this build).
