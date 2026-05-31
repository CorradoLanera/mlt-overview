# CLAUDE.md — mlt-r-basic

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
