---
description: (Deprecated) Build one workshop's deck + ZIP — use /mlt-build instead
---

**Deprecated.** This wraps the unified entrypoint for a single workshop. Prefer `/mlt-build`.

Arguments: $ARGUMENTS — a workshop slug (e.g. `mlt-r-basic`).

Steps:

1. Run: `python scripts/build_all.py --workshop $ARGUMENTS --no-site`
   It fragment-builds the workshop tree (if it has `_authoring/`), renders its deck, and packages
   the student ZIP + teacher bundle from the generated on-disk tree (NOT `git ls-files`). With no
   slug it builds every workshop.
2. Remind the user to run `/mlt-build --release` (or the full `/mlt-build`) before publishing a
   per-cohort GitHub Release.
