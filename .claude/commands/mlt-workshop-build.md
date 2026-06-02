---
description: Build a workshop's generated tree (steps/ + full/ + _solved/) from its _authoring/ fragments
---

Build the generated student + teacher tree for one R workshop from its fragment source, then
gate it against the structural parity checks.

Arguments: $ARGUMENTS (workshop slug, e.g. `mlt-r-basic`).

Steps:

1. `WS=workshops/$ARGUMENTS`. Confirm `$WS/_authoring/workshop.yml` exists.
2. Build (R 4.6): `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/build.R "$WS"`
   → writes `$WS/{steps,full,_solved}` + per-step `renv.lock` (step 00 has none).
3. Structural parity: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/parity.R "$WS"`
   → must print `STRUCTURAL PARITY OK` (renders + expected output kinds; numbers are not pinned).
4. Report the generated `steps/`, `full/`, `_solved/`.

Notes:

- `steps/`, `full/`, `_solved/` are gitignored (build on-demand); only `_authoring/` + `data-raw/`
  + the workshop `renv.lock` are committed.
- Engine unit tests: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/run-tests.R`.
- Advanced (`mlt-r-advanced`, targets/transform) lands in a later plan.
