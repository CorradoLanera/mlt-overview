---
name: mlt-pilot
description: Guided conductor for building the MLT course — reports where the course stands and walks you through the next step with confirmations, no flags to remember. Use when the user says "continue the MLT course", "andiamo avanti col corso", "riprendi il corso MLT", "next step of the course", "guidami nel corso", "cosa manca al corso MLT", or runs /mlt.
---

# mlt-pilot

Guided conductor. The teacher should NEVER need to remember commands or flags: you read the state, propose the
single most useful next step, let them confirm or choose, do it, then re-orient and propose the next.
Student-facing artifacts in **English**; teacher notes in **Italian**.

## Step 0 — orient (always do this first)

Run: `python -c "import sys; sys.path.insert(0,'.claude/skills/lib'); import manifest,json; m=manifest.load(); print(json.dumps(manifest.artifact_status(m),indent=2))"`
Also check globals: `course/_global/spine.md` and `course/_global/syllabus.md`. Build a compact status table:
each enabled chapter (manifest order) × {objectives, narrative, subunits(opt), storyboard, items, slides}.

## Completion model

- A chapter is **content-complete** when objectives + narrative + storyboard + items all exist (subunits optional).
- A chapter is **production-complete** when, on top, **slides** (`slides/chapters/<slug>.qmd`) exist.
- Course-level: the narrative **spine** (once) and the **syllabus** (after the chapters).
- Natural phase order: spine → per chapter [objectives → narrative → (subunits, optional) → storyboard → items → **slides**] → syllabus → student review.
- The slides phase comes **right after items** for the same chapter — propose it before moving to the next chapter.

## Propose the next step (one at a time)

Pick the single most useful next action (earliest enabled chapter missing the earliest phase; the global spine
before per-chapter narrative; syllabus last). Present it as a SHORT numbered choice, e.g.:

> MLT course — 0/10 chapters started.
> Suggested next: **Objectives for `01-introduction`** (25′).
> 1) Do it   2) A different chapter   3) A different phase   4) Stop here

Ask the teacher to pick (use AskUserQuestion if available, otherwise numbered prose). Honour the choice — never
assume. If the teacher gave an explicit phase/chapter (e.g. via /mlt arguments), jump straight there.

## Execute the chosen step → delegate

- **objectives** → invoke the `mlt-objectives` skill (one chapter).
- **narrative** → invoke `mlt-narrative` (writes the global spine first if missing, then the chapter; the
  pre-hook to the next enabled chapter is computed via `manifest.next_enabled`).
- **subunits** → invoke `mlt-subunits` (only when chosen).
- **storyboard** → invoke the storia-companion `storyboard-lezione` skill; input = the chapter's narrative +
  objectives; output `course/<slug>/storyboard.md`.
- **items** → invoke the storia-companion `itembank` skill with course conventions pinned: **English**; output
  dir `course/<slug>/items/`; **one item at a time**; after each item STOP and ask the teacher to confirm
  (coherence / cognitive level / clarity); on "procedi" **RE-READ** `item_NN_*.md` from disk (the teacher may
  have hand-edited it), update the `.md` and its `.html`, dedupe objectives, then the next; at the end
  consolidate `items_valutativi.md`; run `assessment-reviewer`.
- **slides** → invoke the `mlt-quarto-build` skill for the chapter: storyboard-driven beat expansion (each of
  the 6 beats becomes 1-N slides), anchor image per beat from `img/storyboard/sb-<NN>_<FF>.png`, supporting
  figures pulled from `img/`, formulas/text reused from `index.Rmd`/`index-full.Rmd`; refreshes
  `slides/slides.qmd` (manifest-driven master) and renders revealjs. Mandatory visual QA (chrome-devtools).
- **syllabus** → invoke `syllabus-2p` (writes `course/_global/syllabus.md`), then the `studente-confuso`
  sub-agent for the POV review (`course/_global/syllabus-revisione-studenti.md`).

(Requires storia-companion v2 for narrative/storyboard/items/syllabus steps. Slides require Quarto only.)

## Gate + advance

After each step: summarise what was produced, name the `.html` to open, and re-run Step 0 to propose the next
step. NEVER cross to the next step without the teacher's explicit OK.

## After a completed step

Append one entry (LIFO, newest on top) to the "Stato corrente" of
`C:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md` recording what was produced.
