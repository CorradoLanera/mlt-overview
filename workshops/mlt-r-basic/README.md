# Practical Artificial Intelligence for Medical Data Analyses with R — Basic

> Part of the **MLT course** (one repo, three modules) → see the repo-root README.

A ~4-hour, live-coded workshop in which we build and validate a clinical machine-learning
model in R, reproducibly, from raw data to a rendered report. We work hands-on in RStudio,
type every line together, and end with a model we can trust and a report we can re-run.

## What you will build

Starting from a real heart-failure clinical-records dataset, we import and wrangle the data
(dropping a leaky column along the way), explore it with clinically meaningful summaries, fit
a logistic-regression spine scored on **two** metrics (AUC-ROC and AUC-PR), then tune and
compare a small "zoo" of models with a `workflow_set`, validate the winner on held-out data
with `last_fit`, and wrap everything in a reproducible Quarto report.

## Prerequisites

From the **Theory Overview** (Module 1), you should arrive with:

- what supervised **classification** is, and how it differs from regression (ch. 2);
- the **train / validation / test** split and why holding out data prevents overfitting (ch. 4);
- why **accuracy misleads on imbalanced outcomes** and why the test set stays sealed until the
  end (ch. 10) — this workshop puts exactly those disciplines into code.

No prior experience with R modelling is needed: we type every line together, live.

## How to start

You need R (>= 4.5) and RStudio.

1. In R, fetch the workshop materials:

   ```r
   usethis::use_course(
     "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip"
   )
   ```

2. Open the project (`mlt-r-basic.Rproj`) so its own `renv` activates, then restore the
   pinned package environment:

   ```r
   renv::restore()
   ```

That gives you exactly the package versions used to build the workshop.

## How the `steps/` folders work

The workshop is split into numbered step folders, `steps/NN-slug/`. Each folder is a
**complete, cumulative snapshot** of the project up to that point — not just a diff. The
solution to step N is simply step N+1.

If you fall behind during the live coding, do not panic: just open the **next** step folder
and continue from there. You will always have a clean, runnable starting point.

## Dataset

We use the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients, ~32%
event rate), seeded once into `data-raw/heart_failure.csv`. The outcome is in-hospital
death (`died` / `survived`). We deliberately drop the follow-up-time column, which would
*leak* the outcome — the first data-hygiene lesson of the day.
