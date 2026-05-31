---
name: mlt-objectives
description: Define 2-4 observable learning objectives and ONE live, dual-mode (in-person + remote) summative exercise for a chapter of the MLT course. Use when the user says "objectives for chapter X", "esercizio sommativo duale", "obiettivi del capitolo", or runs /mlt --phase objectives.
---

# mlt-objectives

For a given MLT chapter, produce learning objectives and a summative exercise designed to run **live** in a
**dual classroom** (in-person + remote at the same time). Student-facing text in **English**; teacher design
notes in **Italian**.

## Collect

- Chapter slug + title + minutes from `course/_manifest.yml` (via `.claude/skills/lib/manifest.py`).
- Chapter content cues from `_archive/legacy-xaringan/index.Rmd` (the matching section) — read, don't invent.

## Produce (write `course/<slug>/objectives.md`)

1. **Learning objectives** — 2-4, each an observable performance (verb + content), English. No "the student knows".
2. **One summative live exercise**, dual-mode, as a table with exactly these rows:

   | Field | Content |
   |---|---|
   | Objective verified | which objective(s) |
   | In-person action | what co-located students do (cards, table groups, board) |
   | Remote equivalent | how remote students do the same (poll, chat, shared doc, breakout) |
   | Shared artifact | what stays visible to everyone (shared whiteboard/slido/doc) |
   | Timing | minutes + where in the arc |
   | Success criterion | what observable signal shows the objective is met live |

Keep it doable inside the chapter's `minutes`. The exercise is summative (checks the chapter's objectives),
not a warm-up. Math in `$...$`.

## Verify

Invoke the `assessment-reviewer` sub-agent on (objectives + exercise) to check objective↔exercise coherence
and observability before finalising. Apply its fixes.

## Output

Write `course/<slug>/objectives.md` (the Fase 0 hook renders `objectives.html` with math). Do NOT edit the
manifest. Report a one-line summary and stop for the teacher's confirmation (the /mlt gate).
