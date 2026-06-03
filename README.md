# Machine Learning — An Applied Overview (MLT)

One course, three modules, for biomedical/clinical graduate students (UBEP, University of Padova).

Live site (slides, schedule, downloads): <https://corradolanera.github.io/mlt-overview/>.

## The three modules

| # | Module | What it is | Where | How to get it |
|---|--------|-----------|-------|---------------|
| 1 | **Theory Overview** | Storyboard-narrated reveal.js lectures (10 chapters) | `course/` + `slides/` | Published slides (GitHub Pages / PDF) |
| 2 | **Practice — Basic** | Live-coded R: build & validate a clinical ML model | `workshops/mlt-r-basic/` | `use_course()` — see its README |
| 3 | **Practice — Advanced** | Live-coded R: interpretability + deep learning | `workshops/mlt-r-advanced/` | `use_course()` — see its README |

## Learning path

**Overview → Basic → Advanced.** The Overview ends (ch. 10) by pre-hooking into the Basic
workshop; Basic pre-hooks into Advanced. Prerequisites are stated at the top of each module.

## Build & release — one pipeline, three audiences

The whole course rebuilds from a single idempotent entrypoint:

```sh
python scripts/build_all.py            # all workshops: rebuild -> decks -> ZIPs -> site
python scripts/build_all.py --release  # also assemble dev/release-assets/ (embed decks + ZIPs)
```

(Equivalently the `/mlt-build` command.) It chains, in dependency order:
`dev/mltbuild/rebuild.R` (fragment-build each workshop tree from `workshops/<slug>/_authoring/`)
→ `check-masking.R` → `quarto render` decks → `scripts/build_workshop_zip.py` (student ZIP +
teacher bundle, packaged from the generated on-disk tree) → `scripts/build_release.py` →
`scripts/build_site.py` (→ `docs/`). Only workshops with `_authoring/` are fragment-built; others
fall back to shipping their git-tracked tree.

- **Student** downloads `mlt-r-<lvl>.zip`: a bundle of per-step R projects (Model C). Source of
  truth is `_authoring/`; `steps/ full/ _solved/` are generated and gitignored.
- **Teacher** downloads `mlt-r-<lvl>-teacher.zip` (student tree + `_solved/` worked solutions),
  or reads them on the site (the tile's **Coding solutions** button).
- **Dev/author** edits `_authoring/` beats and re-runs `/mlt-build`; drift is zero.

After content changes, run `python scripts/build_site.py` (or `/mlt-build`) and commit `/docs`.

## Repository map

- `course/` — overview chapter content (`_manifest.yml` is the source of truth).
- `slides/` — the overview deck **and** the workshop deck sources (`slides/workshops/<slug>/`). Each workshop deck is a single hand-authored reveal.js file whose per-step arc is *WHY intro → interleaved theory/formative → "go to code"*, with the formatives embedded inline as **Engage → Reveal** slide pairs (no standalone formative HTMLs). Design: [`dev-docs/superpowers/specs/2026-06-03-workshop-deck-content-redesign-design.md`](dev-docs/superpowers/specs/2026-06-03-workshop-deck-content-redesign-design.md).
- `site/` — the public Quarto website sources (built into `docs/`).
- `docs/` — the published site served by GitHub Pages (`main` `/docs`).
- `styles/_brand.scss` — shared palette + fonts used by every deck.
- `workshops/` — the two self-contained R workshops (each with its own `renv`).
- `dist/` — built workshop ZIPs (git-ignored; published as GitHub Release assets).
- `scripts/build_site.py` — builds the live site into `docs/`; `scripts/build_release.py` — builds per-cohort Release assets.
- `_archive/legacy-xaringan/` — the frozen, reproducible pre-Quarto deck.
- `dev-docs/` — internal design specs & plans (not published).

## Authoring

See `.claude/CLAUDE.md` for the universal conventions (language, math, lists, visual
verification) and each workshop's `CLAUDE.md` for its R-authoring rules.

---

> **Resume the build (teacher):** reload Claude Code in this repo, then type *"andiamo avanti col corso MLT"*
> (or `/mlt`) and follow the guided steps — no commands to remember.
