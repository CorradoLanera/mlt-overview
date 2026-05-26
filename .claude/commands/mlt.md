---
description: Orchestrate the MLT content pipeline over the modular manifest, one phase at a time with confirmation gates. Supports --phase and --chapter.
argument-hint: "[--phase objectives|narrative|subunits|storyboard|items|syllabus] [--chapter <slug>]"
---

You are the conductor of the MLT content pipeline. Read state, never guess.

## Step 0 — orient (always)

Run: `python -c "import sys; sys.path.insert(0,'.claude/skills/lib'); import manifest,json; m=manifest.load(); print(json.dumps(manifest.artifact_status(m),indent=2))"`
Show the user a table: each enabled chapter (include:true) with minutes and which artifacts already exist
(objectives/narrative/subunits/storyboard/items). Parse `$ARGUMENTS` for `--phase` and `--chapter`.

## Phase order

objectives → narrative → subunits (optional) → storyboard → items → syllabus.
If `--phase` is given, run only that phase. If `--chapter <slug>` is given, restrict to that chapter.
Otherwise iterate enabled chapters in manifest order for the chosen phase.

## Running a phase

- **objectives** → invoke the `mlt-objectives` skill for each target chapter.
- **narrative** → invoke the `mlt-narrative` skill (it handles global spine + per-chapter + pre-hooks).
- **subunits** → invoke `mlt-subunits` ONLY for chapters the user names (on-demand).
- **storyboard** → invoke the storia-companion `storyboard-lezione` skill per chapter/sub-unit, writing to
  `course/<slug>/storyboard.md`. Pass the chapter's narrative + objectives as input.
- **items** → invoke the storia-companion `itembank` skill per chapter, with course conventions pinned:
  English; output dir `course/<slug>/items/`; one item at a time; after each item STOP and ask the teacher
  to confirm; on "procedi" RE-READ the item_NN_*.md from disk (it may have been hand-edited), update it and
  its .html, dedupe objectives, then next; consolidate `items_valutativi.md` at the end; assessment-reviewer.
- **syllabus** → invoke storia-companion `syllabus-2p` (writes `course/_global/syllabus.md`), then the
  `studente-confuso` sub-agent for the POV review (`course/_global/syllabus-revisione-studenti.md`).

## Gates

Between phases (and between chapters within a phase) STOP and summarise what was produced; wait for the
teacher's OK before continuing. Never cross a gate autonomously.

## After a completed phase

Append one entry (LIFO, newest on top) to the "Stato corrente" of
`C:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md` recording what was produced.
Keep student-facing artifacts in English; teacher notes in Italian.
