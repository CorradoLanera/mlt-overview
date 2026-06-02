---
description: Build a workshop's generated tree (steps/ + full/) from its _authoring/ fragments
---

Build the generated student/teacher tree for one R workshop from its fragment source.

Arguments: $ARGUMENTS (workshop slug, e.g. `mlt-r-basic`).

Steps:

1. Resolve `AUTH=workshops/<slug>/_authoring` (the `OUT` wiring into `workshops/<slug>` lands in plan 2).
2. Run the engine with R 4.6:
   `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/build.R "$AUTH"`
3. Report the generated `steps/`, `full/` (and, from plan 2 on, `_solved/` + per-step `renv.lock`).

Notes:
- The generated `steps/`, `full/`, `_solved/` are gitignored (build on-demand); only `_authoring/`
  and `data-raw/` are committed.
- HTML tabs, `renv.lock` generation, the Basic migration and parity-vs-oracle live in plan 2.
