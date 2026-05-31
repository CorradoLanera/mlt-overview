# Formative · min 10 · live-check (after Step 00)

- **Type:** live-check (GREEN / RED show of hands or poll)
- **Concept-graph nodes checked:** `BASIC` — Basic's validated tidymodels workflow; `PRED` — 1-row predict on finalized model; `WARM` — Pre-warm torch session

## Prompt

Run these three checks and signal **GREEN** if all pass, **RED** if any fails:

1. Does `predict(fitted_wf, hf_tbl[1, ], type = "prob")` return a **1-row tibble** (no error, no retrain)?
2. Does **`torch_tensor(1)`** run **without triggering a download** — i.e. the backend loads instantly because torch was pre-warmed?
3. Is the loaded model the **finalized workflow from Basic** (the one that passed `last_fit()` on the test set)?

## Expected answer (GREEN)

All three pass:

- `predict()` on the extracted `fitted_wf` workflow returns predictions immediately — the model is already baked in, no `fit()` call needed;
- `torch_tensor(1)` executes without downloading libtorch because the session was pre-warmed before the workshop (e.g. by running `library(torch)` during setup);
- the object in memory is the finalized `last_fit` workflow saved in Basic's step 04 (bundled here as `model/final_fit.rds`), reloaded with `readRDS()` then `extract_workflow()`.

If **RED on torch**: run `library(torch)` now and wait for the backend initialisation message — this is normal on first load per session, but must not happen mid-workshop.
If **RED on the model**: reload from the checkpoint file before continuing — everything in step 01 depends on having the finalized object.
