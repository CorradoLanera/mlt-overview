# Formative · min 138 · predict-output (after Step 04, capstone check)

- **Type:** predict-output (predict before the reveal)
- **Concept-graph nodes checked:** `TARGETS` — targets = reproducibility signature; `DAG` — tar_visnetwork DAG; `SKIP` — tar_make then re-run all-skip

## Prompt

We just ran `tar_make()` on the full pipeline and watched the targets build. Now
we run `tar_make()` **a second time without changing anything**.

1. **Predict:** what status does every target report, and why?
2. We changed nothing — so is the second run just "using a cache"? Explain the
   conceptual difference.

## Expected answer

**Every target reports `skip`.**

The reason is **input-hash checking, not a cache trick**: `{targets}` hashes the
inputs of every target (the source code of the function, the upstream target
objects, and any file dependencies). Because nothing changed, the hashes match the
stored values. `targets` therefore knows that re-running the function would produce
the same result, so it skips — this is **reproducibility** (the pipeline is
re-derivable from unchanged inputs), not the same as serving a static pre-baked
number.

The difference from "pre-cooked": if *any* input changes (data file, function
code, a parameter), the affected target and all its downstream dependencies go
**stale** and rebuild automatically. A true cache just returns a stored value
regardless; `targets` re-derives or skips based on content hashes.

## Stretch (Davide)

**Which targets go stale if you replace `model/final_fit.rds` (the bundled Basic RF)
or edit the VIMP settings inside `explain_model()`?**

`model_file` is a `format = "file"` target, so swapping `final_fit.rds` re-hashes
`model_file`; `{targets}` propagates stale-ness to `model` (which calls
`reload_model()`) and then to the `explanation` bridge (which consumes `model` +
`cohort`) — `explanation` rebuilds, while `cohort_file` / `cohort` stay `skip`. The
VIMP knobs (`method = "permute"`, `metric = "roc_auc"`, `nsim = 10`) live inside
`explain_model()` in `R/pipeline-fns.R`: editing them changes that function's source
hash, so only `explanation` rebuilds (nothing is downstream of it). Note there is
**no** SHAP/`kernelshap` target in this pipeline — the bridge is permutation VIMP via
`vip::vi()`; the `bg_X` / `kernelshap()` interpretability code lives in **step 01**,
not in this DAG.

**Why does the GPU device not appear in the DAG unless promoted to a target?**

`{targets}` tracks only what is explicitly declared as a target or file dependency.
The GPU device is detected at runtime via `torch::cuda_is_available()` inside the
function body — it is an **ambient, implicit input** invisible to the dependency
graph. If the function is run on a CPU-only machine, the same code path executes
(with different performance), the hash of the *function source* is unchanged, and
`targets` sees no reason to invalidate. To make the GPU device a tracked input,
you would need to promote it explicitly: e.g. define a target
`tar_target(device, if (cuda_is_available()) "cuda" else "cpu")` and pass `device`
as an argument to the computation function. Only then does a change in GPU
availability propagate through the DAG.
