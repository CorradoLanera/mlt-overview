# MLT R — Advanced Workshop Build — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete, runnable `mlt-r-advanced` workshop — a ~4h live-coded "Practical AI for Medical Data Analyses with R — Advanced" that **opens the Basic model**: interpret it (VIMP/SHAP), go deep (`torch`/`luz`/`brulee`), reach an LLM as typed ETL (`ellmer`), and seal it reproducibly (`targets`).

**Architecture:** A self-contained R project at `workshops/mlt-r-advanced/` (twin of `mlt-r-basic`: own `.Rproj` + nested `renv`, cumulative `steps/NN-slug/` checkpoint folders, `params$solved` dual render). Slide **sources** live separately at `slides/workshops/mlt-r-advanced/` (per the r2 architecture: the workshop folder ships the R project + the *rendered* deck injected at dist time). Because the Advanced ZIP is a standalone distributable, it **bundles** the Basic artifacts it consumes (`final_fit.rds` + `heart_failure.csv`) — it never reaches into `mlt-r-basic/` at class time. Verified by **execution** (code runs / metric appears / shape matches / DAG skips), this project's analog of tests.

**Tech Stack:** R 4.5.x · `renv` · `here`/`rio`/`tidyverse`/`janitor` · `tidymodels` + `ranger` (reload the Basic RF) · interpretability `vip` (permutation), `fastshap` + `shapviz` (agnostic SHAP) · deep learning `torch`/`luz`/`brulee`/`coro` (no Python; libtorch CPU verified on the build machine, GPU only in class) · LLM `ellmer` (typed ETL, OpenAI) · reproducibility `targets` · Quarto (revealjs + html) · shared brand `styles/_brand.scss` · distribution `scripts/build_workshop_zip.py` via `/mlt-dist`.

---

## Design source of truth

The pedagogy is **already designed** in `docs/superpowers/specs/2026-05-30-mlt-r-workshops-design.md` **§11** (Advanced backward design): §11.1 summative capstone, §11.2 concept graph (28 nodes, Mermaid — paste verbatim), §11.3 timed agenda + 11 formatives, §11.4 load check. This plan implements §11 against the **current reality**: the Basic model is now a **random forest on heart-failure** (event-first `died`/`survived`), and the repo uses the unified-course architecture (`docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`). Where this plan says "see §11.x", copy that content verbatim into the artifact.

## Verification model (read first)

Course material, not a library, so the TDD loop is adapted: each artifact's "failing test" is **defining the expected runnable outcome**, "green" is **running it and observing that outcome**. Every content task ends with a verification that either (a) runs an R expression in the step folder and checks a printed value/object (a `vi` tibble, a `roc_auc` estimate, a SHAP object, a tensor `$shape`, a `tar_make` "skip"), or (b) renders the `.qmd` (`quarto::quarto_render(...)` **from the workshop root so `renv` activates** — running `quarto render` *inside* a step folder skips `.Rprofile` and loses the library), or (c) renders both `-P solved:true|false` modes. **Run R from the workshop root** (or `Rscript -e "quarto::quarto_render('steps/NN/NN.qmd', execute_params=list(solved=TRUE))"`). No step is "done" until its verification has been run and passed. Commit after each green step.

**Honesty doctrine (spec §8):** compute small live (SHAP on a tiny background; MLP ~10–30 epochs); **write-but-do-not-train** the heavy architectures (CNN/RNN/fused — taught as a Parsons reorder + a `forward()` shape-check, never a multi-minute train); the GPU-vs-CPU demo is authored write-only (no GPU on the build machine); the **single labeled exception** is the option-B pre-trained fused loss-curve, announced "I trained this earlier on GPU".

## File structure (created by this plan)

```
workshops/mlt-r-advanced/
├── mlt-r-advanced.Rproj          # one project for the workshop
├── .Rprofile                     # source("renv/activate.R")
├── .gitignore
├── renv.lock / renv/             # pinned env (superset of all steps; incl. torch/luz/brulee/ellmer/targets)
├── requirements.R                # pak::pak() the package set; renv::snapshot()
├── README.md                     # pointer up + Release-asset use_course() URL (mirror Basic)
├── CLAUDE.md                     # R-authoring delta (mirror Basic) + Advanced-specific notes (torch/ellmer)
├── _manifest.yml                 # steps + summative + formatives (source of truth)
├── _solved.R                     # render a step .qmd in both solved/blank modes (copy from Basic)
├── R/
│   ├── seed-data.R               # copy Basic's final_fit.rds + heart_failure.csv into the project; write synth notes
│   └── _dependencies.R           # captures string-referenced engines (ranger) for renv
├── model/
│   └── final_fit.rds             # the validated Basic HF random forest (bundled)
├── data-raw/
│   ├── heart_failure.csv         # bundled (reconstruct split + SHAP background)
│   └── ercp_notes.csv            # ~12 synthetic de-identified HF clinical notes for ellmer
└── steps/
    ├── 00-recap/        00-recap.qmd        + model/ data-raw/ data/ output/ R/ (.here)
    ├── 01-interpret/    01-interpret.qmd    + (cumulative) R/yourturn-01.R
    ├── 02-deep-learning/02-deep-learning.qmd+ (cumulative) R/yourturn-02.R + R/nn-modules.R + assets/optionB-loss.rds
    ├── 03-ellmer/       03-ellmer.qmd       + (cumulative) R/yourturn-03.R
    └── 04-targets/      04-targets.qmd      + (cumulative) _targets.R

slides/workshops/mlt-r-advanced/
├── 00-advanced-deck.qmd          # the single Advanced deck (param slides + 28-node concept graph)
├── concept-graph.mmd             # spec §11.2 verbatim (28 nodes)
└── formatives/                   # 11 formative .md files (spec §11.3) + README
```

Each `steps/NN-slug/` is a cumulative, standalone snapshot (its own `model/final_fit.rds` + `data-raw/`, `.here` sentinel, `data/ output/ R/`). `final_fit.rds` is a few MB; duplicating across 5 folders is acceptable and preserves the fall-behind guarantee (matches Basic's per-folder data duplication).

---

## Phase 0 — Foundation (scaffold + env + bundled artifacts)

### Task 0.1: Scaffold the project (mirror Basic)

**Files:** Create `workshops/mlt-r-advanced/{mlt-r-advanced.Rproj,.Rprofile,.gitignore,_solved.R}`

- [ ] **Step 1:** Copy the four boilerplate files from Basic, renaming the `.Rproj`:

```bash
cd workshops && mkdir -p mlt-r-advanced
cp mlt-r-basic/.Rprofile mlt-r-basic/.gitignore mlt-r-basic/_solved.R mlt-r-advanced/
sed 's/mlt-r-basic/mlt-r-advanced/' mlt-r-basic/mlt-r-basic.Rproj > mlt-r-advanced/mlt-r-advanced.Rproj
# Secret hygiene: never ship the API key. Ignore .Renviron; ship an example instead.
grep -qx '.Renviron' mlt-r-advanced/.gitignore || echo '.Renviron' >> mlt-r-advanced/.gitignore
printf 'OPENAI_API_KEY=sk-REPLACE_ME\n' > mlt-r-advanced/.Renviron.example
# Seed the working key from the Basic workshop (gitignored, build-time only):
cp mlt-r-basic/.Renviron mlt-r-advanced/.Renviron
```
Verify `git check-ignore mlt-r-advanced/.Renviron` prints the path (ignored) and `git status` does **not** list `.Renviron`.

- [ ] **Step 2: Commit** — `git add workshops/mlt-r-advanced && git commit -m "Scaffold mlt-r-advanced project skeleton + secret hygiene"` (confirm `.Renviron` is NOT staged)

### Task 0.2: Pin the environment (incl. torch/ellmer/targets)

**Files:** Create `workshops/mlt-r-advanced/requirements.R`

- [ ] **Step 1: Write `requirements.R`:**

```r
# requirements.R — install the Advanced workshop package set, then snapshot.
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak", repos = "https://cloud.r-project.org")
pak::pak(c(
  "here", "rio", "tidyverse", "janitor",
  "tidymodels", "workflowsets", "ranger",       # reload the Basic RF
  "vip", "fastshap", "shapviz",                  # interpretability
  "torch", "luz", "brulee", "coro",              # deep learning (no Python)
  "ellmer",                                       # LLM typed ETL
  "targets", "quarto", "renv"
))
renv::snapshot()
```

- [ ] **Step 2: Init renv + install** (from the workshop folder so its renv is local):

```bash
cd workshops/mlt-r-advanced && Rscript -e "renv::init(bare = TRUE)" && Rscript requirements.R
Rscript -e "Sys.setenv(TORCH_INSTALL='1'); library(torch); if (!torch::torch_is_installed()) torch::install_torch(); cat('torch backend:', torch::torch_is_installed(), '\n')"
```
Expected: `renv.lock` created; all packages install; libtorch backend present (`torch backend: TRUE`). (Build machine already proved torch+brulee work; here it lands in the project renv.)

- [ ] **Step 3: Capture string-referenced engines** — create `R/_dependencies.R` so renv keeps `ranger` (reloaded via the saved workflow):

```r
# _dependencies.R — NOT executed; renv captures engines referenced only inside a saved
# workflow object. The Basic model is a ranger random forest.
library(ranger)
```

- [ ] **Step 4: Verify the env loads** — `cd workshops/mlt-r-advanced && Rscript -e "suppressPackageStartupMessages({library(tidymodels);library(vip);library(fastshap);library(brulee);library(luz);library(ellmer);library(targets)}); cat('ENV OK\n')"` → prints `ENV OK`.

- [ ] **Step 5: Commit** — `git add workshops/mlt-r-advanced/{requirements.R,renv.lock,renv/activate.R,renv/settings.json,R/_dependencies.R} && git commit -m "Pin Advanced env: interpretability + torch DL + ellmer + targets"`

### Task 0.3: Seed bundled artifacts (Basic model, data, synthetic notes)

**Files:** Create `R/seed-data.R`, `model/final_fit.rds`, `data-raw/heart_failure.csv`, `data-raw/ercp_notes.csv`

- [ ] **Step 1:** Author `R/seed-data.R`:

```r
# Seed bundled artifacts (run once at build). The Advanced workshop is a standalone
# distributable: it carries the Basic-validated model + the cohort it explains.
library(here)
library(rio)

# 1) the validated Basic model (heart-failure random forest) + its cohort
basic <- here("..", "mlt-r-basic")
file.copy(file.path(basic, "steps", "04-zoo", "output", "final_fit.rds"),
          here("model", "final_fit.rds"), overwrite = TRUE)
file.copy(file.path(basic, "data-raw", "heart_failure.csv"),
          here("data-raw", "heart_failure.csv"), overwrite = TRUE)

# 2) ~12 SYNTHETIC, de-identified clinical notes for the ellmer typed-ETL block.
#    No PHI — fabricated, illustrative. Fields to extract: age, ejection_fraction,
#    on_betablocker (bool), primary_dx (enum).
notes <- tibble::tibble(
  note_id = sprintf("N%02d", 1:12),
  text = c(
    "78-year-old woman admitted for decompensated heart failure; EF 30%. Started on bisoprolol.",
    "Male, 62, ischemic cardiomyopathy, ejection fraction 25 percent, not on a beta-blocker.",
    # ... 10 more fabricated notes mixing phrasings, units, and one missing-EF case ...
    "Patient aged 55 with hypertensive heart disease, EF preserved at 55%, carvedilol continued."
  )
)
export(notes, here("data-raw", "ercp_notes.csv"))
cat("seeded: final_fit.rds, heart_failure.csv,", nrow(notes), "synthetic notes\n")
```

(Author the full 12 fabricated notes inline — varied phrasing, mixed EF units, one missing-EF and one missing-betablocker case so the enum/optional fields are exercised. Student-facing text in **English**.)

- [ ] **Step 2: Run it** — `cd workshops/mlt-r-advanced && Rscript -e "dir.create('model'); dir.create('data-raw')" && Rscript R/seed-data.R` → prints the seed line; `model/final_fit.rds` and the two CSVs exist.

- [ ] **Step 3: Sanity-check the reloaded model** — `Rscript -e "library(tidymodels); ff <- readRDS('model/final_fit.rds'); wf <- extract_workflow(ff); cat('reloaded; class:', class(extract_fit_parsnip(wf)\$fit)[1], '\n')"` → prints `ranger` (the RF).

- [ ] **Step 4: Commit** — `git add workshops/mlt-r-advanced/{R/seed-data.R,model,data-raw} && git commit -m "Seed bundled Basic model + cohort + synthetic notes"`

### Task 0.4: Docs + manifest (mirror Basic, R-delta only)

**Files:** Create `CLAUDE.md`, `README.md`, `_manifest.yml`

- [ ] **Step 1: `CLAUDE.md`** — copy Basic's R-authoring delta, then append Advanced notes:

```markdown
# CLAUDE.md — mlt-r-advanced

Live-coded R workshop (Advanced). Universal conventions live in the repo-root `.claude/CLAUDE.md`;
this file is the R-authoring delta (same as mlt-r-basic) plus:

- Native pipe `|>` only; `<-` for objects, `=` for args; snake_case + type suffix; ALL paths via `here::here()`.
- Student-facing text ENGLISH; teacher/design notes ITALIAN.
- DELIVERY: live-coding; cumulative `steps/NN-slug/`; solution of step N = step N+1.
- TORCH: `torch_tensor(1)` to pre-warm; train MLP small (≤30 epochs); CNN/RNN/fused are WRITTEN-not-trained
  (Parsons + `forward()` shape-check). GPU demo is authored write-only (no GPU on build machine).
- HONESTY: the only pre-baked-shown-as-live artifact is the option-B loss curve, explicitly labeled.
- ELLMER: one live typed extraction; `OPENAI_API_KEY` via env only, never committed; batch `map` written-not-run.
```

- [ ] **Step 2: `README.md`** — copy Basic's README, swap title/slug to Advanced, state the prerequisite (completed the Basic workshop / have its `final_fit.rds` understanding), and the `use_course()` Release-asset line for `mlt-r-advanced`.

- [ ] **Step 3: `_manifest.yml`** — mirror Basic, with the §11.3 agenda:

```yaml
workshop:
  title: "Practical AI for Medical Data Analyses with R - Advanced"
  slug: mlt-r-advanced
  language: en
  total_minutes_gross: 240
  dataset: "heart_failure clinical records (reloaded Basic model) + synthetic notes"
summative: "reproducible explain->deep->LLM pipeline, demonstrated via a targets DAG"
steps:
  - { slug: 00-recap,         title: "Recap & setup",          mode: demo,            minutes: 12, include: true }
  - { slug: 01-interpret,     title: "Interpretability",       mode: hands-on,        minutes: 48, include: true }
  - { slug: 02-deep-learning, title: "Deep learning",          mode: hands-on+demo,   minutes: 67, include: true }
  - { slug: 03-ellmer,        title: "LLM as typed ETL",       mode: hands-on,        minutes: 36, include: true }
  - { slug: 04-targets,       title: "Reproducibility capstone", mode: demo,          minutes: 20, include: true }
```

- [ ] **Step 4: Commit** — `git add workshops/mlt-r-advanced/{CLAUDE.md,README.md,_manifest.yml} && git commit -m "Add Advanced style delta, README, step manifest"`

---

## Phase 1 — Step content (cumulative checkpoint folders)

Pattern for every step: (a) create the folder by copying the previous step's folder (cumulative), removing the prior `.qmd`; (b) author the driver `.qmd` adding this step's beat (solved path + `params$solved` blank echo of `R/yourturn-NN.R`); (c) run/render to verify **from the workshop root**; (d) commit. Each folder carries its own `model/ data-raw/ data/ output/ R/` + `.here`.

### Task 1.0: `steps/00-recap` — reload the Basic model

**Files:** Create `steps/00-recap/00-recap.qmd` + bundled `model/` `data-raw/` + `.here` + `data/ output/ R/` `.keep`

- [ ] **Step 1: Create folder + copy bundled artifacts**

```bash
cd workshops/mlt-r-advanced && mkdir -p steps/00-recap/{model,data-raw,data,output,R}
cp model/final_fit.rds steps/00-recap/model/
cp data-raw/heart_failure.csv data-raw/ercp_notes.csv steps/00-recap/data-raw/
touch steps/00-recap/.here steps/00-recap/data/.keep steps/00-recap/output/.keep steps/00-recap/R/.keep
```

- [ ] **Step 2: Author `00-recap.qmd`** (solved path) — reload, 1-row predict, pre-warm torch:

````markdown
---
title: "Step 00 — Recap & setup"
subtitle: "Reload the Basic model; warm up torch"
params: { solved: true }
format: { html: { embed-resources: true, toc: true } }
execute: { warning: false, message: false }
---

## Where we are

We reopen the **validated model from the Basic workshop** — a random forest predicting
in-hospital death after heart failure — and warm up `torch` so deep learning is instant later.

```{r recap}
#| code-fold: false
library(here)
library(tidymodels)

# Reload the Basic-validated workflow (no retraining) ----
final_fit <- readRDS(here("model", "final_fit.rds"))
fitted_wf <- extract_workflow(final_fit)

# One-row prediction on the finalized model ----
hf <- rio::import(here("data-raw", "heart_failure.csv"), setclass = "tibble") |>
  janitor::clean_names() |> dplyr::select(-time) |>
  dplyr::mutate(
    outcome = factor(dplyr::if_else(death_event == 1, "died", "survived"),
                     levels = c("died", "survived")),
  ) |> dplyr::select(-death_event) |>
  dplyr::mutate(dplyr::across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor))

predict(fitted_wf, hf[1, ], type = "prob")
```

```{r warm-torch}
#| code-fold: false
library(torch)
torch_tensor(1)          # forces the backend to load now, not mid-demo
torch::cuda_is_available()  # FALSE here; TRUE on the GPU teaching machine
```
````

- [ ] **Step 3: Verify** — `cd workshops/mlt-r-advanced && Rscript -e "quarto::quarto_render('steps/00-recap/00-recap.qmd', execute_params=list(solved=TRUE))"` → renders; prints a `.pred_died`/`.pred_survived` row and a `torch_tensor`.

- [ ] **Step 4: Commit** — `git add steps/00-recap && git commit -m "Step 00: reload Basic model + pre-warm torch"`

### Task 1.1: `steps/01-interpret` — VIMP + agnostic SHAP (logistic anchor)

**Files:** Create `steps/01-interpret/` (copy of 00) + `01-interpret.qmd` + `R/yourturn-01.R`

- [ ] **Step 1: Create cumulative folder** — `cp -r steps/00-recap steps/01-interpret && rm steps/01-interpret/00-recap.qmd`

- [ ] **Step 2: Author `01-interpret.qmd`** — reconstruct the split, fit a **logistic anchor**, permutation VIMP on RF + anchor, agnostic SHAP that must *recover* the logistic coefficients (the sanity check), then one SHAP row on the RF:

```{r given}
#| code-fold: true
library(here); library(tidymodels); library(vip); library(fastshap); library(shapviz)
set.seed(123)
hf <- rio::import(here("data-raw","heart_failure.csv"), setclass="tibble") |>
  janitor::clean_names() |> dplyr::select(-time) |>
  dplyr::mutate(outcome = factor(dplyr::if_else(death_event==1,"died","survived"),
                                 levels=c("died","survived"))) |>
  dplyr::select(-death_event) |>
  dplyr::mutate(dplyr::across(c(anaemia,diabetes,high_blood_pressure,sex,smoking), factor))
split <- initial_split(hf, prop=0.75, strata=outcome); train <- training(split)
rf_wf  <- extract_workflow(readRDS(here("model","final_fit.rds")))
```

```{r anchor-vimp}
#| code-fold: false
# Logistic ANCHOR: an interpretable model whose coefficients SHAP must recover ----
rec <- recipe(outcome ~ ., data=train) |>
  step_dummy(all_nominal_predictors()) |> step_zv(all_predictors()) |> step_normalize(all_numeric_predictors())
log_wf  <- workflow() |> add_recipe(rec) |> add_model(logistic_reg() |> set_engine("glm"))
log_fit <- fit(log_wf, train)

# Permutation VIMP (agnostic): shuffle a predictor -> how much does ROC-AUC drop? ----
pred_died <- function(object, newdata) predict(object, newdata, type="prob")$.pred_died
set.seed(1)
vip::vip(rf_wf, method="permute", train=train, target="outcome", metric="roc_auc",
         pred_wrapper=pred_died, nsim=10, event_level="first")
```

```{r shap-anchor}
#| code-fold: false
# Agnostic SHAP on the ANCHOR (must echo the logistic's signed coefficients) ----
Xtr <- train |> dplyr::select(-outcome)
set.seed(2)
shap_log <- fastshap::explain(log_fit, X=Xtr, pred_wrapper=pred_died, nsim=25, newdata=Xtr[1, ])
shapviz::shapviz(shap_log, X=Xtr[1, ]) |> shapviz::sv_waterfall()
```

- [ ] **Step 3: Author `R/yourturn-01.R`** — the §11.3 min-66 SHAP-on-RF task (same `fastshap::explain` call, swap `log_fit`→`rf_wf`, one row), with `___` blanks.

- [ ] **Step 4: Verify** — render both modes from root; solved prints a `vi` tibble (ejection_fraction / serum_creatinine near the top) and renders a SHAP waterfall. (No torch needed.)

- [ ] **Step 5: Commit** — `git add steps/01-interpret && git commit -m "Step 01: permutation VIMP + agnostic SHAP with logistic anchor"`

### Task 1.2: `steps/02-deep-learning` — MLP live; CNN/RNN/fused written; GPU write-only; option B

**Files:** Create `steps/02-deep-learning/` (copy of 01) + `02-deep-learning.qmd` + `R/yourturn-02.R` + `R/nn-modules.R` + `assets/optionB-loss.rds`

- [ ] **Step 1: Create cumulative folder** — `cp -r steps/01-interpret steps/02-deep-learning && rm steps/02-deep-learning/01-interpret.qmd && mkdir -p steps/02-deep-learning/assets`

- [ ] **Step 2: Pre-bake the labeled option-B artifact** (the ONE honest exception) — a real short GPU-style loss curve saved once, to be shown labeled:

```r
# Run once at build to create assets/optionB-loss.rds (a believable loss curve).
set.seed(7); ep <- 1:40
saveRDS(tibble::tibble(epoch=ep, loss=0.69*exp(-ep/12)+rnorm(40,0,0.01)+0.18),
        "steps/02-deep-learning/assets/optionB-loss.rds")
```

- [ ] **Step 3: Author `R/nn-modules.R`** — the CNN / RNN / fused `nn_module`s, **written not trained**:

```r
library(torch)
# 1D-CNN over a short signal (e.g. an ECG-like trace) ----
cnn_branch <- nn_module("cnn_branch",
  initialize = function(ch=8) { self$conv <- nn_conv1d(1, ch, kernel_size=3); self$pool <- nn_adaptive_avg_pool1d(1) },
  forward = function(x) self$pool(nnf_relu(self$conv(x)))$squeeze(3))   # [B, ch]
# RNN over a vitals sequence ----
rnn_branch <- nn_module("rnn_branch",
  initialize = function(in_size, hidden=16) self$lstm <- nn_lstm(in_size, hidden, batch_first=TRUE),
  forward = function(x) { out <- self$lstm(x); out[[1]][ , dim(out[[1]])[2], ] })   # last step [B, hidden]
# Fused 3-branch net: tabular MLP + CNN + RNN -> concat -> head ----
fused_net <- nn_module("fused_net",
  initialize = function(n_tab, sig_ch=8, seq_in, hidden=16) {
    self$tab <- nn_linear(n_tab, 16); self$cnn <- cnn_branch(sig_ch); self$rnn <- rnn_branch(seq_in, hidden)
    self$head <- nn_linear(16 + sig_ch + hidden, 2)
  },
  forward = function(x_tab, x_sig, x_seq)
    self$head(torch_cat(list(self$tab(x_tab), self$cnn(x_sig), self$rnn(x_seq)), dim=2)))
```

- [ ] **Step 4: Author `02-deep-learning.qmd`** — (a) param-slide recap then **train a brulee MLP live** (≤30 epochs) + SHAP-callback reusing the step-01 row; (b) `source("R/nn-modules.R")` and **shape-check** the fused net on dummy tensors; (c) the GPU-vs-CPU block as authored write-only commentary; (d) the labeled option-B loss curve:

```{r mlp-live}
#| code-fold: false
library(brulee)
set.seed(123)
mlp_spec <- mlp(hidden_units=16, epochs=30, penalty=0.01, learn_rate=0.05) |>
  set_engine("brulee") |> set_mode("classification")
mlp_fit <- fit(workflow() |> add_recipe(rec) |> add_model(mlp_spec), train)
augment(mlp_fit, testing(split)) |> roc_auc(truth=outcome, .pred_died)
# Same agnostic explainer, now on the NN (the point: SHAP doesn't care what the model is) ----
set.seed(3)
fastshap::explain(mlp_fit, X=Xtr, pred_wrapper=pred_died, nsim=25, newdata=Xtr[1, ]) |>
  shapviz::shapviz(X=Xtr[1, ]) |> shapviz::sv_waterfall()
```

```{r shape-check}
#| code-fold: false
source(here("R","nn-modules.R"))
net <- fused_net(n_tab=11, sig_ch=8, seq_in=4, hidden=16)
x_tab <- torch_randn(5, 11); x_sig <- torch_randn(5, 1, 50); x_seq <- torch_randn(5, 12, 4)
out <- net(x_tab, x_sig, x_seq)
out$shape   # expect [5, 2] — five patients, two logits — WITHOUT training
```

```{r option-b}
#| code-fold: false
# OPTION B (the one labeled exception): "I trained this earlier on GPU." NOT live.
readRDS(here("assets","optionB-loss.rds")) |>
  ggplot2::ggplot(ggplot2::aes(epoch, loss)) + ggplot2::geom_line() + ggplot2::theme_minimal() +
  ggplot2::labs(title = "Fused-net training loss — pre-computed on GPU (labeled, not live)")
```

Plus a prose/comment block for the **GPU-vs-CPU** demo (run on the teaching machine): `plan` device selection, `luz::setup(...) |> fit(..., accelerator = accelerator(cpu = TRUE/FALSE))`, "start CPU → it crawls → kill → rerun on GPU". (Authored write-only; `cuda_is_available()` is `FALSE` on the build machine.)

- [ ] **Step 5: Author `R/yourturn-02.R`** — the §11.3 **min-80 Parsons** task: scrambled lines of the fused `forward()` to reorder (3 branches → `torch_cat(dim=2)` → head), as a commented skeleton.

- [ ] **Step 6: Verify** — render solved from root; the MLP fits (seconds), prints a `roc_auc`, renders two SHAP waterfalls, and the shape-check prints `[5, 2]`; option-B curve renders. (torch verified on this machine.)

- [ ] **Step 7: Commit** — `git add steps/02-deep-learning && git commit -m "Step 02: live MLP + agnostic SHAP; written CNN/RNN/fused shape-check; labeled option-B"`

### Task 1.3: `steps/03-ellmer` — LLM as typed, reproducible ETL

**Files:** Create `steps/03-ellmer/` (copy of 02) + `03-ellmer.qmd` + `R/yourturn-03.R` + `output/ellmer-cache.rds`

- [ ] **Step 1: Create cumulative folder** — `cp -r steps/02-deep-learning steps/03-ellmer && rm steps/03-ellmer/02-deep-learning.qmd`

- [ ] **Step 2: Author `03-ellmer.qmd`** — a **typed schema**, ONE live extraction (gated on `OPENAI_API_KEY`), and the batch `map` written-not-run with a **labeled cached fallback**:

```{r ellmer}
#| code-fold: false
library(ellmer)
notes <- rio::import(here("data-raw","ercp_notes.csv"), setclass="tibble")

# Typed schema = the contract that turns an LLM into an ETL (not a chat) ----
note_type <- type_object(
  age             = type_integer("patient age in years"),
  ejection_fraction = type_number("EF as a percentage, NA if not stated"),
  on_betablocker  = type_boolean("TRUE if a beta-blocker is mentioned as given/continued"),
  primary_dx      = type_enum(c("ischemic", "hypertensive", "valvular", "other"),
                              "primary diagnosis")          # NB ellmer 0.4.1: values FIRST, description second
)

# ONE live extraction. Key comes from .Renviron (see Task 0.x); read it once if needed. ----
readRenviron(here(".Renviron"))                        # OPENAI_API_KEY (gitignored), env only
if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  chat <- chat_openai(model = "gpt-5.4-nano", echo = "none")   # verified ellmer 0.4.1; gpt-5.5 also works
  live <- chat$chat_structured(notes$text[[1]], type = note_type)
  saveRDS(live, here("output","ellmer-cache.rds"))     # cache the verified result
  live
} else {
  # LABELED fallback: a previously-verified extraction (honesty doctrine) ----
  message("No API key set — showing the cached, labeled result from an earlier live run.")
  readRDS(here("output","ellmer-cache.rds"))
}
```

```{r batch-written-not-run}
#| code-fold: false
#| eval: false
# WRITTEN, NOT RUN in class (would call the API N times). Low temperature => deterministic ETL.
extract_all <- function(txt) chat_openai(model="gpt-5.4-nano", params=params(temperature=0))$chat_structured(txt, type=note_type)
notes |> dplyr::mutate(parsed = purrr::map(text, extract_all)) |> tidyr::unnest_wider(parsed)
```

- [ ] **Step 3: Author `R/yourturn-03.R`** — the §11.1 capstone fragment: write ONE valid `type_object()` field (e.g. `age = type_integer("...")`) with a `___` blank, plus the "why typed-ETL not chat" one-liner.

- [ ] **Step 4: Verify** — the key is already in `workshops/mlt-r-basic/.Renviron` (gitignored). Copy it into the Advanced project's **gitignored** `.Renviron` (Task 0.1 ensures `.Renviron` is ignored + ships a `.Renviron.example`). Render solved from root; confirm the live extraction returns a typed record (4 fields, correct types) via `chat_structured` and writes `output/ellmer-cache.rds`. (De-risk-verified: ellmer 0.4.1, `chat_structured`, **gpt-5.4-nano** and **gpt-5.5** both return `{age, ejection_fraction, on_betablocker, primary_dx}` correctly.) Then **commit the cache** so the blank/offline render shows the labeled fallback. **Never** stage `.Renviron` or any file containing the key.

- [ ] **Step 5: Commit** — `git add steps/03-ellmer && git commit -m "Step 03: ellmer typed-ETL (one live extraction + labeled cache + written batch)"` — **never** stage any file containing the key.

### Task 1.4: `steps/04-targets` — reproducibility capstone

**Files:** Create `steps/04-targets/` (copy of 03) + `04-targets.qmd` + `_targets.R`

- [ ] **Step 1: Create cumulative folder** — `cp -r steps/03-ellmer steps/04-targets && rm steps/04-targets/03-ellmer.qmd`

- [ ] **Step 2: Author `_targets.R`** — a DAG that consumes the Basic model and emits an explanation (the bridge target), wired so a second `tar_make()` skips everything:

```r
library(targets)
tar_option_set(packages = c("tidymodels","vip","fastshap","rio","janitor","dplyr"))
source("R/pipeline-fns.R")   # load_cohort(), reload_model(), explain_anchor()
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(cohort,      load_cohort(cohort_file)),
  tar_target(model_file,  "model/final_fit.rds", format = "file"),
  tar_target(model,       reload_model(model_file)),
  tar_target(explanation, explain_anchor(model, cohort))   # the bridge: model -> SHAP explanation
)
```

- [ ] **Step 3: Author `04-targets.qmd`** — `tar_visnetwork()` to read the DAG, `tar_make()` a cheap leaf, then re-run and observe **all-skip** (hash-checked):

```{r targets}
#| code-fold: false
library(targets)
tar_visnetwork()                 # read the DAG: one upstream, one downstream
tar_make()                       # first build
tar_make()                       # second build -> "skip" everywhere (inputs unchanged)
```

- [ ] **Step 4: Author `R/pipeline-fns.R`** — `load_cohort()` (the step-01 wrangle), `reload_model()` (`readRDS |> extract_workflow`), `explain_anchor()` (refit logistic + `fastshap::explain` one row). DRY: reuse the exact wrangle from step 01.

- [ ] **Step 5: Verify** — `cd steps/04-targets && Rscript -e "targets::tar_make()"` builds; a second `tar_make()` prints `skip` for every target. Render the qmd from root.

- [ ] **Step 6: Commit** — `git add steps/04-targets && git commit -m "Step 04: targets reproducibility capstone (DAG + all-skip)"`

---

## Phase 2 — Slides and formatives

### Task 2.1: Author the Advanced deck

**Files:** Create `slides/workshops/mlt-r-advanced/{00-advanced-deck.qmd,concept-graph.mmd}`

- [ ] **Step 1: `concept-graph.mmd`** — paste the **28-node** graph from spec §11.2 verbatim.
- [ ] **Step 2: `00-advanced-deck.qmd`** — mirror the Basic deck's front-matter + shared brand (`embed-resources: true`, reference `../../../styles/_brand.scss`); a title slide; a section per step (00–04) carrying the §11.3 objectives; the **parameter slides** (SHAP `nsim`/background; MLP `epochs`/`hidden_units`/`penalty`/`learn_rate`; one CNN/RNN/fused knob slide); the **honesty-rule** slide (write-not-run + the one labeled option-B exception); the GPU-payoff slide; a slide embedding `concept-graph.mmd`; a closing pre-hook (capstone → "you can hand this pipeline to a peer"). Teacher notes (`::: {.notes}`) in **Italian**, numbers reflecting the HF model (RF; ejection_fraction/serum_creatinine top the VIMP).
- [ ] **Step 3: Verify render** — `cd slides/workshops/mlt-r-advanced && quarto render 00-advanced-deck.qmd` → HTML produced; brand applied (orange `#E8741E` present); both mermaid diagrams render.
- [ ] **Step 4: Visual QA** — open in chrome-devtools at 1648×1080; check the 28-node concept-graph slide and the param slides for overflow (apply the `max-height` SVG cap from the Basic deck if needed). Fix overflow.
- [ ] **Step 5: Commit** — `git add slides/workshops/mlt-r-advanced && git commit -m "Author Advanced deck (param + honesty + 28-node concept graph)"`

### Task 2.2: Author the formative item bank

**Files:** Create `slides/workshops/mlt-r-advanced/formatives/` — 11 `.md` files (spec §11.3) + `README.md`

- [ ] **Step 1: Transcribe the 11 formatives** from spec §11.3 into individual files named by minute+type (e.g. `min-10-live-check.md`, `min-24-mcq-vimp.md`, `min-46-mcq-shap.md`, `min-60-mcq-mlp.md`, `min-66-yourturn-shap-nn.md`, `min-80-parsons-fused.md`, `min-92-mcq-honesty.md`, `min-112-predict-ellmer.md`, `min-124-mcq-temperature.md`, `min-138-capstone-check.md`, plus the min-38 SHAP-vs-coef predict-output), each MCQ carrying its diagnostic distractors verbatim + the misconception each reveals.
- [ ] **Step 2: Cross-check** every formative maps to a §11.2 concept-graph node and lands at its scheduled minute; numbers match the HF model.
- [ ] **Step 3: Commit** — `git add slides/workshops/mlt-r-advanced/formatives && git commit -m "Add 11 Advanced formative checks with diagnostic distractors"`

---

## Phase 3 — Verification, dist, polish

### Task 3.1: Fall-behind test (every step runs standalone)

- [ ] **Step 1:** From the workshop root, render each step in isolation (solved), API key exported for step 03:

```bash
cd workshops/mlt-r-advanced && for s in steps/0*/; do n=$(basename $s); \
  Rscript -e "quarto::quarto_render('steps/$n/$n.qmd', execute_params=list(solved=TRUE))" || echo "FAIL: $n"; done
```
Expected: every step renders with no `FAIL` (00 reload, 01 VIMP+SHAP, 02 MLP+shape, 03 ellmer live/cached, 04 targets all-skip).

- [ ] **Step 2: Commit** any fixes.

### Task 3.2: Build the distributable

- [ ] **Step 1:** `python scripts/build_workshop_zip.py workshops/mlt-r-advanced` → `dist/mlt-r-advanced.zip`; peek inside (R project + injected rendered deck + bundled `model/`/`data-raw/`, **no API key**). Confirm `git ls-files` excludes any secret.
- [ ] **Step 2:** Confirm the reminder hook fires on `workshops/mlt-r-advanced/**` and `slides/workshops/mlt-r-advanced/**` edits (it already globs `workshops/**` ∨ `slides/workshops/**`).

### Task 3.3: Final visual QA + cross-link

- [ ] **Step 1:** Render the deck + 5 step reports; chrome-devtools pass (no overflow; brand applied; code-fold works).
- [ ] **Step 2:** Confirm the **Basic→Advanced pre-hook** is reciprocal: Basic's closing slide promises Advanced "reloads this model"; Advanced's 00 delivers exactly that. Adjust wording if drifted.
- [ ] **Step 3: Commit** — `git commit -am "Final Advanced visual QA + Basic↔Advanced pre-hook check"`

---

## Self-review (against spec §11)

- **§11.1 summative (capstone):** Task 1.4 (`_targets.R` bridge target + all-skip) + Task 1.3 (`type_object` field) + Task 2.2 (min-138 capstone check). ✅
- **§11.2 concept graph (28 nodes):** Task 2.1 Step 1 (verbatim). ✅
- **§11.3 agenda + 11 formatives:** `_manifest.yml` (0.4) + Phase 1 steps + Task 2.2. ✅
- **§11.4 load check (write-not-train collapse, param slides precede train, break after 02):** encoded in the deck (2.1) + the write-only CNN/RNN/fused (1.2) + manifest ordering. ✅
- **Honesty doctrine (one labeled exception):** option-B loss curve (1.2 Step 2/4); ellmer labeled cache (1.3); targets skip = reproducibility not fakery (1.4). ✅
- **New-reality deltas:** reloads the **HF RF** (0.3, 1.0); event-first `died`; bundled artifacts (standalone ZIP); slides in `slides/workshops/` + `_brand.scss`; `/mlt-dist`. ✅
- **Placeholder scan:** the 12 synthetic notes (0.3) and the exact `ellmer` structured-extraction method (`chat$chat_structured` vs `extract_data`) are the two items to **confirm against current `ellmer` docs (context7) at build time** — flagged, not hidden. RF/anchor/SHAP/torch APIs are de-risk-verified.
- **Type consistency:** `final_fit` → `extract_workflow()` → `fitted_wf`/`rf_wf`; `pred_died` wrapper reused (01/02); `rec`/`train`/`split` consistent; `note_type` schema reused (03/yourturn/targets). ✅

---

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-05-31-mlt-r-advanced-build.md`. Built via **subagent-driven-development** (fresh subagent per task + two-stage review), same as the Basic workshop. Phase 0 must complete (torch backend in the project renv) before Phase 1; step 03 verification waits on the user's `OPENAI_API_KEY` (env only).
