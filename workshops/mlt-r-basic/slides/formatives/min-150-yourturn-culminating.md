# Formative · min 150 · your-turn — THE CULMINATING TASK (after Step 04)

- **Type:** your-turn (the summative culminating task, §10.1) + `{countdown}`, then my-turn
- **Concept-graph nodes checked:** `WFSET` → `TUNE` → `CV` → `COMPARE` → `BEST` → `LASTFIT` → `OPT` (the whole tune→validate spine)

## Prompt

On your own laptop (or the `steps/04-…/` folder if you fell behind), starting from
the `workflow_set` of the four algorithms already built:

1. Tune all four in **one** call on the **same** resamples:
   `workflow_map("tune_grid", resamples = folds, grid = 8, metrics = metric_set(roc_auc))`
   over a single `vfold_cv(v = 5)`.
2. `rank_results()` / `autoplot()` → **name the winner** by CV ROC-AUC.
3. `extract_workflow_set_result()` → `select_best("roc_auc")` →
   `extract_workflow()` |> `finalize_workflow()` → **`last_fit()` on the untouched
   test set** (once).
4. Report **both** the CV AUC **and** the test AUC, and say **one sentence** on why
   the test number is the honest one and the single fit was optimistic.
5. Try the **engine-swap**: change **one line** to replace an algorithm and re-insert
   it into the set.

## Expected answer / success criteria (observable)

- **One** `folds` object reused for all four workflows.
- Names the winner (here: **penalized logistic regression**, glmnet) and justifies
  **ROC-AUC > accuracy** for the ~13%-event imbalance (a "predict always no" model is
  ~87% accurate but useless).
- `last_fit()` on the test set **exactly once**; reports the test AUC (~0.538) as the
  honest estimate alongside the CV AUC (~0.628).
- States the **optimism gap** in one sentence (CV flatters; the held-out test is the
  honest read on a small, imbalanced cohort).
- Demonstrates the **one-line engine-swap**.
- Reads the AUC in **clinical** terms (discrimination of PEP risk).

## Stretch (Davide)

Add a **5th engine** via a one-line swap into the same `workflow_map`; and identify
**when `rank_results` ranking-by-mean misleads** — overlapping CV intervals across
models call for the **one-standard-error rule** (pick the simplest model within 1 SE
of the best) rather than blindly taking the top mean.
