# CLAUDE.md — mlt-r-advanced

> R-authoring delta only. Language/math/lists/visual-verification live in the repo-root
> `.claude/CLAUDE.md` (auto-merged when authoring here).

Live-coded R workshop. Conventions:

- Native pipe `|>` only (never `%>%`); `_` placeholder where needed.
- `<-` for objects, `=` only for function args. snake_case with type suffix (`hf_tbl`, `train`).
- ALL paths via `here::here()`. `library()` + `renv`, never bare `install.packages()` in step code.
- `{rio}::import()` for IO. ggplot: data in `|>`, layers with `+`, then `ggsave()`.
- One arg per line + trailing comma in multi-arg calls. `# Section ----` banners. 2 spaces. `set.seed(123)`.
- DELIVERY: live-coding, NO pre-baked results shown as live. Each `steps/NN-slug/` is a complete
  cumulative snapshot; the solution of step N is step N+1.

## Advanced-specific notes

- TORCH: `torch_tensor(1)` to pre-warm the backend. The CNN (PneumoniaMNIST) and RNN (ECG5000) are
  TRAINED LIVE (torch/luz, real train/val curves, early-stopping U); the fused net is trained end-to-end
  on invented labels (the mechanics run, test AUC ~0.5). Train small so the U stays visible. The GPU-vs-CPU
  demo is authored write-only (no usable GPU on the build box; it runs in class on the NVIDIA/CUDA machine).
- INTERPRETABILITY: agnostic SHAP via **`kernelshap`** (CRAN, pure R) + `shapviz` — NOT fastshap (archived
  from CRAN 2026-05-27). Use `pred_fun(object, X, ...)` + `bg_X` background; `permshap()` for the exact
  logistic-anchor sanity-check. NOTE the explainer asymmetry: `vip(method="permute")` hands `pred_wrapper`
  the BARE ranger engine (close over the workflow); `kernelshap` passes `object` verbatim (a generic
  `pred_fun` works).
- ELLMER: one live typed extraction, then ALL notes via `parallel_chat_structured()` (live, concurrent);
  `batch_chat_structured()` sits beside it as a comment (Batch API, ~50% cost, async). Structured calls
  return INVISIBLY (reference the object by bare name to print). `OPENAI_API_KEY` via env only (`.Renviron`,
  gitignored), NEVER committed.
- TARGETS (§04 capstone): one `tar_make()` re-runs the WHOLE arc live — explore -> 4-model compare
  (workflow_set) -> RF -> VIMP -> SHAP -> brulee MLP learning curve -> ellmer extraction -> compiled report.
  Each analysis is a `tar_read()`-able target (rich `tar_visnetwork()`, real selective recompute). The
  engine:targets solution renders THREE tabs (student `_targets.R` / solved / report); `report.qmd` carries
  `<!--MLT-REPORT-START/END-->` markers the build slices into tab 3. The build surfaces `OPENAI_API_KEY`
  (workshop-root `.Renviron`) so the ellmer target is live.
- LIVE, NOT BAKED (delivery doctrine §8): nothing pre-baked is shown as live — nets, SHAP, ellmer, and the
  targets DAG all run live in the build. The only labeled non-live path is the ellmer fallback when no API
  key is set (a clearly-labeled example, never faked as live). `targets` re-showing a cached "skip" is
  reproducibility, not fakery.
