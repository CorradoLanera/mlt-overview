---
description: Rebuild a workshop's generated tree (steps/ + full/ + _solved/) from its _authoring/ fragments, then gate it
---

Rebuild the generated student + teacher tree for the R workshop(s) from their fragment source, then
gate each against the structural parity checks. One command — no incantation to remember.

Arguments: $ARGUMENTS — optional workshop slug(s). **Empty = rebuild EVERY workshop** that has an
`_authoring/workshop.yml` (today: `mlt-r-basic`; later also `mlt-r-advanced`). A slug = just that one.

Steps:

1. Run (R 4.6): `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/rebuild.R $ARGUMENTS`
   It builds each workshop (`build.R` → `steps/` + `full/` + `_solved/` + per-step `renv.lock`, step 00
   has none) and then gates it (`parity.R` → `STRUCTURAL PARITY OK`). Exits non-zero if any workshop
   fails to build or fails parity.
2. Report which workshops were rebuilt and the final `REBUILD OK` line (or the failure).

Notes:

- `steps/`, `full/`, `_solved/` are gitignored (build on-demand); only `_authoring/` + `data-raw/` + the
  workshop `renv.lock` are committed.
- To build/gate a single workshop directly: `Rscript dev/mltbuild/build.R workshops/<slug>` then
  `Rscript dev/mltbuild/parity.R workshops/<slug>`.
- Engine unit tests: `Rscript dev/mltbuild/run-tests.R`.
- Authoring conventions (beat/hole/fragment grammar, `meta.yml`): `dev/mltbuild/README.md`.
