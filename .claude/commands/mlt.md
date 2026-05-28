---
description: Guided MLT course conductor — no flags needed. Reports where the course stands and walks you through the next step. Optional --phase/--chapter to jump.
argument-hint: "[--phase objectives|narrative|subunits|storyboard|items|slides|syllabus] [--chapter <slug>]"
---

Invoke the `mlt-pilot` skill to run the guided MLT pipeline: orient (read `course/_manifest.yml` status) →
propose the single next step → let the teacher confirm or choose → execute via the phase skills → re-orient.

If `$ARGUMENTS` contains `--phase` and/or `--chapter`, pass them to `mlt-pilot` as constraints (jump straight
to that phase/chapter). Otherwise run fully guided — the teacher should not need to remember any flags.
