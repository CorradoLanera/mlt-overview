# Formative · min 150 · your-turn — THE CULMINATING TASK (after Step 04)

- **Type:** your-turn (the summative culminating task, §10.1) + `{countdown}`, then my-turn
- **Concept-graph nodes checked:** `WFSET` $\to$ `TUNE` $\to$ `CV` $\to$ `COMPARE` $\to$ `BEST` $\to$ `LASTFIT` $\to$ `OPT` (the whole tune $\to$ validate spine)

## Prompt

On your own laptop (or the `steps/04-…/` folder if you fell behind), starting from
the `workflow_set` of the four algorithms already built:

1. Tune all four in **one** call on the **same** resamples:
   `workflow_map("tune_grid", resamples = folds, grid = 8, metrics = metric_set(roc_auc, pr_auc))`
   over a single `vfold_cv(v = 5)`.
2. `rank_results()` / `autoplot()` $\to$ **name the winner** by CV AUC-ROC.
3. `extract_workflow_set_result()` $\to$ `select_best("roc_auc")` $\to$
   `extract_workflow()` |> `finalize_workflow()` $\to$ **`last_fit()` on the untouched
   test set** (once), with `metric_set(roc_auc, pr_auc, accuracy)`.
4. Report the CV AUC **and** the test AUC-ROC/AUC-PR, and say **one sentence** on why
   a single split is not trustworthy on ~75 test patients.
5. Try the **engine-swap**: change **one line** to replace an algorithm and re-insert
   it into the set.

## Expected answer / success criteria (observable)

- **One** `folds` object reused for all four workflows.
- Names the winner (here: **random forest**, ranger) and justifies watching **both**
  metrics for the ~32%-event imbalance (accuracy ~68% by always predicting
  "survived"; AUC-PR's baseline is the prevalence, not 0.5).
- `last_fit()` on the test set **exactly once**; reports the test AUC-ROC (~0.87) and
  AUC-PR (~0.75) alongside the CV AUC-ROC (~0.79).
- States the **noise of a single split** in one sentence: the plain glm scored ~0.88
  on one test split, yet in 5-fold cross-validation no linear model reaches the
  forest's ~0.79 — so we trust the CV ranking, not a single number on a small cohort.
- Demonstrates the **one-line engine-swap**.
- Reads the AUC in **clinical** terms (discrimination of mortality risk).

## Stretch (Davide)

Add a **5th engine** via a one-line swap into the same `workflow_map`; and identify
**when `rank_results` ranking-by-mean misleads** — overlapping CV intervals across
models call for the **one-standard-error rule** (pick the simplest model within 1 SE
of the best) rather than blindly taking the top mean. On this small cohort, the SEs
are wide — a perfect occasion to make the point.
