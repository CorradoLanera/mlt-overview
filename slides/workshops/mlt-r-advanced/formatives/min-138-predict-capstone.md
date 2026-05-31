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

**Which downstream targets go stale if you change `bg_X` or the sampling settings
of the SHAP target?**

The SHAP computation target depends on `bg_X` (the background dataset) and the
sampling parameters passed to `kernelshap()`. Both are inputs to that target's
function. Changing either invalidates the SHAP target's hash. `{targets}` then
propagates stale-ness downstream: any target that consumes the SHAP result
(e.g. the waterfall plot target, the summary table target, the report target)
also becomes stale and will rebuild on the next `tar_make()`. Targets that do
**not** depend on SHAP (e.g. the data ingestion target, the model-fit target)
are unaffected — they remain `skip`.

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
