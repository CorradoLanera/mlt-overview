# CLAUDE.md — mlt-r-basic

Live-coded R workshop. Conventions:
- Native pipe `|>` only (never `%>%`); `_` placeholder where needed.
- `<-` for objects, `=` only for function args. snake_case with type suffix (`indo_tbl`, `train`).
- ALL paths via `here::here()`. `library()` + `renv`, never bare `install.packages()` in step code.
- `{rio}::import()` for IO. ggplot: data in `|>`, layers with `+`, then `ggsave()`.
- One arg per line + trailing comma in multi-arg calls. `# Section ----` banners. 2 spaces. `set.seed(123)`.
- Student-facing text in ENGLISH; teacher/design notes in ITALIAN.
- DELIVERY: live-coding, NO pre-baked results shown as live. Each `steps/NN-slug/` is a complete cumulative snapshot; the solution of step N is step N+1.
