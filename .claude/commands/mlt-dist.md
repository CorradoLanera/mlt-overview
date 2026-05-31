---
description: Render a workshop's deck and build its source-only distributable ZIP
---

Build the distributable ZIP for one R workshop (or all, if none is named): render its
slides deck, then assemble a source-only ZIP (git-tracked R-project + the rendered deck).

Arguments: $ARGUMENTS (optional workshop slug, e.g. `mlt-r-basic`).

Steps:

1. Determine target(s): if a slug was given, use `workshops/<slug>`; otherwise every
   immediate subdirectory of `workshops/` that contains a `.Rproj`.
2. For each target `<slug>`:
   a. Render the deck so the shipped HTML is fresh and self-contained:
      `quarto render slides/workshops/<slug>/` (the deck uses `embed-resources: true`).
      If `slides/workshops/<slug>/` has no deck `.qmd`, skip rendering (deck-less workshop).
   b. Build the ZIP:
      `python scripts/build_workshop_zip.py workshops/<slug>`
      It ships the git-tracked R-project source (minus `CLAUDE.md`) plus the rendered deck
      injected under `<slug>/slides/`, into `dist/<slug>.zip`. It exits non-zero if no
      rendered deck is found — so always render first (step a).
3. Report each ZIP's path + size. Remind the user to attach the ZIP(s) to a per-cohort
   GitHub Release (tag e.g. `workshops-2026`) so the
   `releases/latest/download/<slug>.zip` URL in the workshop README resolves.

Notes:

- Do NOT commit the ZIPs — `dist/` is gitignored.
- Slide sources live in `slides/workshops/<slug>/`; the workshop folder ships only the
  rendered deck, never the slide source. No SCSS vendoring is needed (the deck is
  `embed-resources`, self-contained).
- `/mlt` (the course conductor) stays overview-scoped; this command is workshop-scoped.
