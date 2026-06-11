# Practical Artificial Intelligence for Medical Data Analyses with R: Advanced

> Part of the **MLT course** (one repo, three modules) → see the repo-root README.

A ~4-hour, live-coded workshop in which we rebuild a validated clinical ML model live and push it
further: we interpret it with agnostic SHAP, go deeper with neural networks, extract structured
data from clinical notes with an LLM, and seal the entire pipeline in a reproducible `targets`
DAG. We work hands-on in RStudio, type every line together, and end with a pipeline we can
explain, extend, and re-run.

## What you will build

We rebuild live the **validated heart-failure random forest from the Basic workshop** (from the
bundled data), then we:

1. **Interpret** the model: permutation variable importance, then agnostic SHAP via `kernelshap`
   + `shapviz`, with a logistic regression as a sanity-check anchor (`permshap()`);
2. **Go deeper** with deep learning (`torch` / `luz` / `brulee`): train a small MLP live, then
   write and shape-check CNN, RNN, and fused architectures (written-not-trained, so class stays
   on schedule);
3. **Use an LLM as a typed, reproducible ETL** (`ellmer`): extract structured fields from
   synthetic clinical notes (`hf_notes.csv`) with a single live call, then wrap the batch in a
   `purrr::map` pipeline (written-not-run);
4. **Seal everything** in a `targets` pipeline: the final DAG demonstrates that the full arc
   from raw data to interpreted predictions is reproducible with a single `tar_make()`.

## Prerequisites

You must have completed the **Basic workshop** (Module 2). You should understand the validated
heart-failure model this workshop rebuilds: a tuned random forest, outcome `died` / `survived`,
validated with `last_fit` on held-out data, scored on AUC-ROC and AUC-PR. You do **not** need
the fitted model on disk: this project **bundles the data** (`data-raw/heart_failure.csv`) and
rebuilds the model live.

From the **Theory Overview** (Module 1), the relevant background is:

- what **model interpretability** is and why black-box predictions are not enough (ch. 4, revisited ch. 10);
- the basic idea of a **neural network** and how it differs from a linear model (ch. 5);
- the architectures for **unstructured data**: CNNs and RNNs (ch. 6);
- what an **LLM** is and why it can serve as a structured-extraction tool (ch. 7).

## How to start

You need R (>= 4.5) and RStudio.

1. In R, fetch the workshop materials:

   ```r
   usethis::use_course(
     "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced.zip"
   )
   ```

2. Open the project (`mlt-r-advanced.Rproj`) so its own `renv` activates, then restore the
   pinned package environment:

   ```r
   renv::restore()
   ```

That gives you exactly the package versions used to build the workshop.

### API key (for the LLM step)

Step 03 uses `ellmer` to call OpenAI. To run it live you need a key:

1. Copy `.Renviron.example` to `.Renviron` (already gitignored; it will never be committed).
2. Replace `sk-REPLACE_ME` with your key from <https://platform.openai.com/api-keys>.
3. Restart R so the variable is loaded.

If you do not set a key, the step falls back to a labeled cached extraction so the workshop
can continue without interruption.

## How the `steps/` folders work

The workshop is split into numbered step folders, `steps/NN-slug/`. Each folder is a
**complete, cumulative snapshot** of the project up to that point (not just a diff). The
solution to step N is simply step N+1.

If you fall behind during the live coding, do not panic: just open the **next** step folder
and continue from there. You will always have a clean, runnable starting point.

## Dataset

This workshop loads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients,
~32% event rate) from `data-raw/heart_failure.csv` (bundled) and **rebuilds the random forest
live** from that data: nothing is pre-fitted on disk. It also adds ~12 synthetic, de-identified
clinical notes in `data-raw/hf_notes.csv` for the LLM extraction step. No PHI is present in any
bundled file.
