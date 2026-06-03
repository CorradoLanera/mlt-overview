---
description: Build every consumable MLT artifact in dependency order (one idempotent entrypoint)
---

Regenerate the whole pipeline from one command: fragment-build each workshop tree, render the
decks, package the student ZIP + teacher bundle from disk, and rebuild the public site.

Arguments: $ARGUMENTS — optional flags forwarded to the orchestrator:
`--workshop <slug>` (repeatable; default = every workshop with a `.Rproj`), `--release` (also
assemble `dev/release-assets/`), `--no-site`, `--skip-masking`.

Steps:

1. Run (R must be on PATH as the 4.6 toolchain; set `MLT_RSCRIPT` to override, e.g.
   `MLT_RSCRIPT="/c/Program Files/R/R-4.6.0/bin/Rscript.exe"`):
   `python scripts/build_all.py $ARGUMENTS`
   It chains: `rebuild.R` → `check-masking.R` → `quarto render` decks → `build_workshop_zip.py`
   (student + teacher, from the generated on-disk tree) → `build_release.py` (with `--release`)
   → `build_site.py`. Only fragment-built workshops (those with `_authoring/`) get rebuilt + masked;
   non-migrated workshops still get their deck render + ZIP via the git-tracked fallback.
2. Report the final `[build-all] done` line (or the failing stage).

Notes:

- Idempotent: re-running converges to the same state.
- `/mlt-dist` is a deprecated single-workshop alias of this command.
- The generated `steps/ full/ _solved/` trees are gitignored; this command materializes and ships
  them — never commit them.
