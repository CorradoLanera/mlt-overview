# Machine Learning — An Applied Overview (MLT)

One course, three modules, for biomedical/clinical graduate students (UBEP, University of Padova).

## The three modules

| # | Module | What it is | Where | How to get it |
|---|--------|-----------|-------|---------------|
| 1 | **Theory Overview** | Storyboard-narrated reveal.js lectures (10 chapters) | `course/` + `slides/` | Published slides (GitHub Pages / PDF) |
| 2 | **Practice — Basic** | Live-coded R: build & validate a clinical ML model | `workshops/mlt-r-basic/` | `use_course()` — see its README |
| 3 | **Practice — Advanced** | Live-coded R: interpretability + deep learning | `workshops/mlt-r-advanced/` *(coming)* | `use_course()` — see its README |

## Learning path

**Overview → Basic → Advanced.** The Overview ends (ch. 10) by pre-hooking into the Basic
workshop; Basic pre-hooks into Advanced. Prerequisites are stated at the top of each module.

## Repository map

- `course/` — overview chapter content (`_manifest.yml` is the source of truth).
- `slides/` — the rendered overview deck.
- `styles/_brand.scss` — shared palette + fonts used by every deck.
- `workshops/` — the two self-contained R workshops (each with its own `renv`).
- `dist/` — built workshop ZIPs (git-ignored; published as GitHub Release assets).
- `_archive/legacy-xaringan/` — the frozen, reproducible pre-Quarto deck.
- `dev-docs/superpowers/` — design specs and implementation plans.

## Authoring

See `.claude/CLAUDE.md` for the universal conventions (language, math, lists, visual
verification) and each workshop's `CLAUDE.md` for its R-authoring rules.

---

> **Resume the build (teacher):** reload Claude Code in this repo, then type *"andiamo avanti col corso MLT"*
> (or `/mlt`) and follow the guided steps — no commands to remember.
