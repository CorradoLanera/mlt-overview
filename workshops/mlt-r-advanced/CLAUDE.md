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

- TORCH: `torch_tensor(1)` to pre-warm the backend; train the MLP small (<= 30 epochs). CNN/RNN/fused
  nets are WRITTEN-not-trained (a Parsons reorder + a `forward()` shape-check), never a multi-minute train.
  The GPU-vs-CPU demo is authored write-only (no usable GPU on the build machine; it runs in class on the
  NVIDIA/CUDA teaching machine).
- INTERPRETABILITY: agnostic SHAP via **`kernelshap`** (CRAN, pure R) + `shapviz` — NOT fastshap (archived
  from CRAN 2026-05-27). Use `pred_fun(object, X, ...)` + `bg_X` background; `permshap()` for the exact
  logistic-anchor sanity-check.
- ELLMER: one live typed extraction; `OPENAI_API_KEY` via env only (`.Renviron`, gitignored), NEVER committed;
  the batch `purrr::map` is written-not-run.
- HONESTY (delivery doctrine §8): nothing pre-baked is shown as live. The ONLY labeled exception is the
  option-B fused-net loss curve ("I trained this earlier on GPU"). `targets` re-showing a cached "skip" is
  reproducibility, not fakery.
