## Official course information

| | |
|---|---|
| **Denomination** | Practical Artificial Intelligence for Medical Data Analyses with R — Basic |
| **SSD** | MEDS-24/A — Statistica medica |
| **Instructors** | Corrado Lanera, Luca Vedovelli, Giulia Lorenzoni |
| **Hours / Credits** | 10 hours · 1 CFU |
| **Period** | First semester |
| **Delivery** | Dual (in-person + remote, simultaneous) |
| **Language** | English |
| **Attendance** | Mandatory (80%) |
| **Exam** | Practical / in-class assessment (see *Assessment*) |
| **Prerequisites** | Basic statistics and programming |

## Course description

A ~4-hour, live-coded workshop in which we build and validate a clinical machine-learning model in R — reproducibly, from raw data to a rendered report. Working hands-on in RStudio, we type every line together: we import and wrangle a real heart-failure dataset (dropping a leaky column along the way), explore it with clinically meaningful summaries, fit a logistic-regression spine scored on **two** metrics (AUC-ROC and AUC-PR), tune and compare a small "zoo" of models with a `workflow_set`, validate the winner on held-out data with `last_fit`, and wrap everything in a reproducible Quarto report. The day turns the disciplines met in the Theory Overview into working code.

## Intended learning outcomes

By the end of the workshop, students can:

1. **Initialise** a reproducible R project from scratch — `renv` for pinned packages, `here` for paths, `{rio}` for I/O.
2. **Import and wrangle** clinical data tidily, and **recognise and remove** outcome leakage (the dropped follow-up column).
3. **Summarise** a clinical cohort with meaningful exploratory tables (`gtsummary`).
4. **Fit and validate** a supervised classifier with `tidymodels`, **choosing** metrics — AUC-ROC *and* AUC-PR — appropriate to a ~32%-event imbalanced outcome.
5. **Tune and compare** candidate models with a `workflow_set`, validate the winner with `last_fit`, and **produce** a reproducible Quarto report.

## Steps & schedule

The six steps and their contact time are on the [Schedule](schedule.qmd) page:

- Step 00 · Setup — 25 min
- Step 01 · Import & wrangle — 35 min
- Step 02 · Clinical EDA — 30 min
- Step 03 · Logistic spine — 45 min
- Step 04 · The zoo, tuned — 70 min
- Step 05 · Reproducible report — 35 min

Total ≈ 240 min, within the 10 officially allocated hours.

## Dataset

The **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients, ~32% event rate), seeded into `data-raw/heart_failure.csv`. The outcome is in-hospital death (`died` / `survived`). We deliberately drop the follow-up-time column, which would *leak* the outcome — the first data-hygiene lesson of the day.

## Assessment

The official exam method for this workshop is not yet fixed in the Offerta Formativa. The working model is **in-class formative assessment**: short checkpoints roughly every 10–15 minutes (live environment checks, MCQs with diagnostic distractors, and "your turn" coding tasks), plus a culminating hands-on task in which the class tunes and validates the model end-to-end. All checkpoints run dual-mode, with in-person and remote students converging on shared artifacts.

## Prerequisites & learning path

From the **Theory Overview** (Module 1) you should arrive with: what supervised classification is and how it differs from regression (ch. 2); the train / validation / test split and why holding out data prevents overfitting (ch. 4); and why accuracy misleads on imbalanced outcomes and why the test set stays sealed until the end (ch. 10). No prior experience with R modelling is needed — we type every line together, live. This is **Module 2**; it pre-hooks into the *Advanced* workshop.

## Tools & materials

R (≥ 4.5) and RStudio; the `tidyverse`, `tidymodels`, `gtsummary`, and `renv` packages; lecturer-provided materials and package documentation. Materials are distributed as a per-cohort GitHub Release (a bundle of per-step R projects) — see [Downloads](downloads.qmd).

*Nota docente:* il blurb ufficiale dell'Offerta cita `caret` e la regressione lineare; il workshop erogato usa `tidymodels` e la regressione logistica sul dataset heart-failure. Lo stack erogato (tidymodels) è quello corrente e intenzionale; l'header riporta comunque i dati amministrativi ufficiali.
