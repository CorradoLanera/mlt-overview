## Official course information

| | |
|---|---|
| **Denomination** | Practical Artificial Intelligence for Medical Data Analyses with R — Advanced |
| **SSD** | MEDS-24/A — Statistica medica |
| **Instructors** | Corrado Lanera, Luca Vedovelli, Giulia Lorenzoni |
| **Hours / Credits** | 10 hours · 1 CFU |
| **Period** | Second semester |
| **Delivery** | Dual (in-person + remote, simultaneous) |
| **Language** | English |
| **Attendance** | Mandatory (80%) |
| **Exam** | Practical / in-class assessment (see *Assessment*) |
| **Prerequisites** | Basic R and ML — completion of the *Basic* workshop required |

## Course description

A ~4-hour, live-coded workshop in which we reopen a validated clinical ML model and push it further. Starting from the **validated heart-failure random forest built in the Basic workshop** (bundled in the project), we: interpret it with permutation variable importance and agnostic SHAP; go deeper with neural networks; use a large language model as a typed, reproducible ETL over clinical notes; and seal the whole pipeline in a reproducible `targets` DAG. We work hands-on in RStudio, type every line together, and end with a pipeline we can explain, extend, and re-run.

## Intended learning outcomes

By the end of the workshop, students can:

1. **Interpret** a fitted model with permutation variable importance and agnostic SHAP (`kernelshap` + `shapviz`), anchored by a logistic `permshap()` sanity-check.
2. **Train** a small MLP with `torch` / `luz`, and **read and shape-check** CNN, RNN, and fused architectures (written-not-trained, so class stays on schedule).
3. **Use** an LLM (`ellmer`) as a typed, reproducible ETL to extract structured fields from synthetic clinical notes.
4. **Assemble** a reproducible `targets` pipeline that re-runs the full arc — raw data to interpreted predictions — with a single `tar_make()`.
5. **Weigh** the interpretability / performance trade-off in a clinical-deployment context.

## Steps & schedule

The five steps and their contact time are on the [Schedule](schedule.qmd) page:

- Step 00 · Recap & setup — 30 min
- Step 01 · Open the black box — 45 min
- Step 02 · Deep learning, honestly — 70 min
- Step 03 · An LLM as a typed, reproducible ETL — 45 min
- Step 04 · Reproducibility capstone — 50 min

Total ≈ 240 min, within the 10 officially allocated hours.

## Dataset

The workshop reloads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients, ~32% event rate) from `data-raw/heart_failure.csv` (bundled) and the already-fitted random forest from `model/final_fit.rds` (bundled). It adds ~12 synthetic, de-identified clinical notes in `data-raw/hf_notes.csv` for the LLM extraction step. **No PHI** is present in any bundled file.

## Assessment

As for the Basic workshop, the official exam method is not yet fixed in the Offerta Formativa. The working model is **in-class formative assessment** — dual-mode checkpoints throughout — plus a hands-on **reproducibility capstone** (the `targets` DAG) as the culminating task.

## Prerequisites & learning path

You must have **completed the Basic workshop** (Module 2): the validated random forest it produces is the starting point here (bundled, so you do not need it on disk). From the **Theory Overview** the relevant background is model interpretability (ch. 4, revisited ch. 10), the neural network (ch. 5), CNN/RNN architectures (ch. 6), and what an LLM is (ch. 7). This is **Module 3**, the final module.

## Tools & materials

R (≥ 4.5) and RStudio; `tidymodels`, `vip`, `kernelshap`, `shapviz`, `torch`, `luz`, `brulee`, `ellmer`, `targets`, and `tarchetypes`. The LLM step optionally uses an `OPENAI_API_KEY` (set locally in `.Renviron`, never committed); without a key it falls back to a labeled cached extraction so the workshop can continue. Lecturer materials and package documentation complete the set. Materials are distributed as a per-cohort GitHub Release — see [Downloads](downloads.qmd).

*Nota docente:* il blurb ufficiale dell'Offerta (random forest / gradient boosting / unsupervised / feature engineering) è ormai datato rispetto all'arco erogato — interpretabilità con SHAP, deep learning con `torch`, ETL con LLM (`ellmer`), pipeline `targets`. Il contenuto erogato è quello corrente e intenzionale; l'header riporta i dati amministrativi ufficiali.
