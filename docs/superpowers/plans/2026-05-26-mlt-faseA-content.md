# MLT Toolkit — Fase A (Content Skills) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the project-local content pipeline — a read-only manifest helper, the `/mlt` orchestrator, and three skills (`mlt-objectives`, `mlt-narrative`, `mlt-subunits`) — that drive the existing storia-companion v2 atoms across the modular chapters to produce per-chapter objectives, narrative arcs, and optional sub-units.

**Architecture:** A tiny tested Python library (`manifest.py`) is the only "code": it reads `course/_manifest.yml`, lists enabled chapters, computes the next enabled chapter (for pre-hooks), and derives per-chapter artifact status from the filesystem. The manifest stays **read-only** to the toolkit (hand-edited source of truth; no YAML round-trip that would lose comments). The orchestrator and the three skills are Claude Code prompt files (`.claude/commands/`, `.claude/skills/`) that read state via `manifest.py`, invoke storia-companion v2 atoms (`sei-parole`, `bing-bang-bongo`, `arco-narrativo-didattico`) and reviewers (`narratore-critico`, `assessment-reviewer`), and write per-chapter `.md` (auto-rendered to math HTML by the Fase 0 hook). Validation is integration-based on a pilot chapter.

**Tech Stack:** Python 3 + pyyaml (read-only), pytest; Claude Code skills/commands; storia-companion v2 (must be installed — see Prereq).

**Reference spec:** `docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md` (§6.3–6.5, §6.8).

---

## Prerequisite (blocker)

storia-companion must be **v2** (skill `itembank`, atoms with current behaviour). Confirmed installed = v1. Before executing Task 3+, the user runs:
```
/plugin marketplace add c:/Users/corra/github/cordata/workshop-trieste
/plugin install storia-companion@storia-trieste-local
```
Tasks 1–2 (manifest helper + orchestrator) do **not** need storia and can proceed regardless.

---

## File Structure

- Create `.claude/skills/lib/manifest.py` — read-only manifest helper (shared by command + skills).
- Create `tests/skills/test_manifest.py` — pytest tests for `manifest.py`.
- Create `.claude/commands/mlt.md` — the `/mlt` orchestrator (phase/chapter aware, gates, vault status update).
- Create `.claude/skills/mlt-objectives/SKILL.md` — objectives + dual-mode live summative exercise per chapter.
- Create `.claude/skills/mlt-narrative/SKILL.md` — global spine + per-chapter 6-word/100-word/arc + explicit pre-hook.
- Create `.claude/skills/mlt-subunits/SKILL.md` — on-demand sub-units with mini-arc + formative proposed→solved.

Design note (deviation from spec §6.3/§6.5): skills do **not** write objectives/subunits back into `_manifest.yml` (pyyaml round-trip drops comments/flow style). Generated content lives in the per-chapter `.md`; `manifest.py` derives status from the filesystem. The manifest's `objectives:`/`subunits:` fields remain optional hand-edited hints.

---

## Task 1: Manifest helper (`manifest.py`) — TDD

**Files:**
- Create: `.claude/skills/lib/manifest.py`
- Test: `tests/skills/test_manifest.py`

- [ ] **Step 1: Write the failing tests**

`tests/skills/test_manifest.py`:

```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "skills" / "lib"))
import manifest  # noqa: E402

SAMPLE = """\
course:
  title: "T"
  slug: demo
  language: en
chapters:
  - { slug: 01-a, title: "A", include: true,  minutes: 10 }
  - { slug: 02-b, title: "B", include: false, minutes: 10 }
  - { slug: 03-c, title: "C", include: true,  minutes: 10 }
  - { slug: 04-d, title: "D", include: true,  minutes: 10 }
"""


def _write(tmp_path):
    p = tmp_path / "_manifest.yml"
    p.write_text(SAMPLE, encoding="utf-8")
    return p


def test_load_returns_chapters(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert m["course"]["slug"] == "demo"
    assert len(m["chapters"]) == 4


def test_enabled_chapters_filters_include_false(tmp_path):
    m = manifest.load(_write(tmp_path))
    slugs = [c["slug"] for c in manifest.enabled_chapters(m)]
    assert slugs == ["01-a", "03-c", "04-d"]


def test_next_enabled_skips_disabled(tmp_path):
    m = manifest.load(_write(tmp_path))
    # after 01-a, the next *enabled* is 03-c (02-b is disabled)
    assert manifest.next_enabled(m, "01-a")["slug"] == "03-c"


def test_next_enabled_after_disabled_chapter(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "02-b")["slug"] == "03-c"


def test_next_enabled_last_is_none(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "04-d") is None


def test_next_enabled_unknown_is_none(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "99-x") is None


def test_artifact_status_reads_filesystem(tmp_path):
    m = manifest.load(_write(tmp_path))
    (tmp_path / "01-a" / "items").mkdir(parents=True)
    (tmp_path / "01-a" / "objectives.md").write_text("x", encoding="utf-8")
    (tmp_path / "01-a" / "items" / "item_01_a_mcq.md").write_text("x", encoding="utf-8")
    st = manifest.artifact_status(m, root=tmp_path)
    assert st["01-a"]["objectives"] is True
    assert st["01-a"]["narrative"] is False
    assert st["01-a"]["items"] == 1
    assert st["03-c"]["objectives"] is False
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python -m pytest tests/skills/test_manifest.py -q`
Expected: collection/ImportError — `manifest` not found.

- [ ] **Step 3: Implement `manifest.py`**

`.claude/skills/lib/manifest.py`:

```python
"""Read-only helpers over course/_manifest.yml.

The manifest is the hand-edited source of truth for course STRUCTURE
(slug/title/include/minutes). Generated content lives in per-chapter .md files;
status is derived from the filesystem here. Nothing in this module writes the
manifest (avoids pyyaml round-trip dropping comments/flow style).
"""
from __future__ import annotations
from pathlib import Path
import yaml


def load(path="course/_manifest.yml") -> dict:
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


def enabled_chapters(m: dict) -> list[dict]:
    return [c for c in m.get("chapters", []) if c.get("include")]


def next_enabled(m: dict, slug: str) -> dict | None:
    """First enabled chapter positioned after `slug` in the full order."""
    chapters = m.get("chapters", [])
    idx = next((i for i, c in enumerate(chapters) if c.get("slug") == slug), None)
    if idx is None:
        return None
    for c in chapters[idx + 1:]:
        if c.get("include"):
            return c
    return None


def chapter_dir(slug: str, root="course") -> Path:
    return Path(root) / slug


def artifact_status(m: dict, root="course") -> dict:
    """Per chapter: which artifacts exist (bool) and item count (int)."""
    out = {}
    for c in m.get("chapters", []):
        d = Path(root) / c["slug"]
        items_dir = d / "items"
        out[c["slug"]] = {
            "objectives": (d / "objectives.md").exists(),
            "narrative": (d / "narrative.md").exists(),
            "subunits": (d / "subunits.md").exists(),
            "storyboard": (d / "storyboard.md").exists(),
            "items": len(list(items_dir.glob("item_*.md"))) if items_dir.exists() else 0,
        }
    return out
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_manifest.py -q`
Expected: 7 passed.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/lib/manifest.py tests/skills/test_manifest.py
git commit -m "Add read-only manifest helper with tests"
```

---

## Task 2: `/mlt` orchestrator command

**Files:**
- Create: `.claude/commands/mlt.md`

- [ ] **Step 1: Write the command**

`.claude/commands/mlt.md`:

```markdown
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
```

- [ ] **Step 2: Smoke-test the orient step**

Run: `python -c "import sys; sys.path.insert(0,'.claude/skills/lib'); import manifest,json; m=manifest.load(); print(json.dumps(manifest.artifact_status(m),indent=2))" | head -20`
Expected: JSON status for all 10 chapters (all artifacts false, items 0).

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/mlt.md
git commit -m "Add /mlt orchestrator command"
```

---

## Task 3: `mlt-objectives` skill

**Files:**
- Create: `.claude/skills/mlt-objectives/SKILL.md`

- [ ] **Step 1: Write the skill**

`.claude/skills/mlt-objectives/SKILL.md`:

```markdown
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
- Chapter content cues from `index.Rmd` (the matching section) — read, don't invent.

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
not a warm-up.

## Verify

Invoke the `assessment-reviewer` sub-agent on (objectives + exercise) to check objective↔exercise coherence
and observability before finalising. Apply its fixes.

## Output

Write `course/<slug>/objectives.md` (the Fase 0 hook renders `objectives.html` with math). Do NOT edit the
manifest. Report a one-line summary and stop for the teacher's confirmation (the /mlt gate).
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `python -c "import re,sys; t=open('.claude/skills/mlt-objectives/SKILL.md',encoding='utf-8').read(); assert t.startswith('---') and 'name: mlt-objectives' in t and 'description:' in t; print('ok')"`
Expected: `ok`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/mlt-objectives/SKILL.md
git commit -m "Add mlt-objectives skill (dual-mode live summative exercise)"
```

---

## Task 4: `mlt-narrative` skill

**Files:**
- Create: `.claude/skills/mlt-narrative/SKILL.md`

- [ ] **Step 1: Write the skill**

`.claude/skills/mlt-narrative/SKILL.md`:

```markdown
---
name: mlt-narrative
description: Build the MLT narrative spine — global six-word + 100-word + arc, and per-chapter six-word, 100-word, and a hook-challenge-resolution-payoff arc with an explicit pre-hook to the next enabled chapter. Use for "narrative for chapter X", "spine narrativa", "arco del capitolo", or /mlt --phase narrative.
---

# mlt-narrative

Orchestrates the storia-companion v2 atoms across the MLT chapters. Student-facing prose in **English**;
design glosses in **Italian**. Requires storia-companion v2 installed.

## Global spine (write `course/_global/spine.md`), once

- **Six words**: invoke `sei-parole` for the whole-course theme (ML overview for clinicians). Pick the best
  with `narratore-critico`.
- **100 words, 3 acts**: invoke `bing-bang-bongo` for the whole course.
- **Course arc**: invoke `arco-narrativo-didattico` for the whole course (Hook → Challenge → Resolution → Payoff).

## Per chapter (write `course/<slug>/narrative.md`)

For each target enabled chapter (use `manifest.enabled_chapters`):

1. **Six words** (`sei-parole`) for the chapter theme — best variant via `narratore-critico`.
2. **100 words, 3 acts** (`bing-bang-bongo`) for the chapter.
3. **Arc** (`arco-narrativo-didattico`): full Hook → Challenge/Data → Resolution → Payoff prose for the chapter.
4. **Pre-hook**: an explicit 1-2 sentence bridge to the NEXT enabled chapter. Compute it with
   `manifest.next_enabled(m, slug)`; if it returns None (last chapter), write a pre-hook toward "what comes
   next" (the applied follow-up workshops). For the **Agents** chapter, the pre-hook may point to those
   workshops (see `docs/sources/agents-from-storia-workshop.md`).

## Output

Write `course/_global/spine.md` and each `course/<slug>/narrative.md` (hook renders the HTML). Report per
chapter and stop at the /mlt gate.
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `python -c "t=open('.claude/skills/mlt-narrative/SKILL.md',encoding='utf-8').read(); assert t.startswith('---') and 'name: mlt-narrative' in t; print('ok')"`
Expected: `ok`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/mlt-narrative/SKILL.md
git commit -m "Add mlt-narrative skill (spine + per-chapter arc + pre-hook)"
```

---

## Task 5: `mlt-subunits` skill

**Files:**
- Create: `.claude/skills/mlt-subunits/SKILL.md`

- [ ] **Step 1: Write the skill**

`.claude/skills/mlt-subunits/SKILL.md`:

```markdown
---
name: mlt-subunits
description: Split a chapter into sub-learning-units, each with its own mini hook-challenge-resolution-payoff arc and a formative exercise pair (proposed at the start, solved at the end). On-demand per chapter. Use for "sub-units for chapter X", "sotto-unità", "formative proposto/risolto", or /mlt --phase subunits.
---

# mlt-subunits

On-demand, for ONE chapter at a time. Student-facing text **English**; teacher notes **Italian**.

## Collect

- Chapter slug/title (manifest) + its `objectives.md` and `narrative.md` if present (read them).

## Produce (write `course/<slug>/subunits.md`)

Split the chapter into 2-4 **sub-learning-units**. For each sub-unit:

1. **Mini-arc**: Hook → Challenge/Data → Resolution → Payoff (2-4 sentences each), aligned to the chapter arc.
2. **Formative exercise pair** (formative = for learning, not graded):
   - **Proposed** (at the sub-unit start): a short task the students attempt first.
   - **Solved** (at the sub-unit end): the worked solution + what the attempt should reveal.

Keep each sub-unit self-contained. Math in `$...$`.

## Output

Write `course/<slug>/subunits.md` (hook renders the HTML). Report and stop at the /mlt gate. Do NOT edit the manifest.
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `python -c "t=open('.claude/skills/mlt-subunits/SKILL.md',encoding='utf-8').read(); assert t.startswith('---') and 'name: mlt-subunits' in t; print('ok')"`
Expected: `ok`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/mlt-subunits/SKILL.md
git commit -m "Add mlt-subunits skill (sub-units + formative proposed/solved)"
```

---

## Task 6: Pilot integration validation (01-introduction)

**Files:** none (produces `course/01-introduction/objectives.md` + `narrative.md` as real artifacts).

> Requires storia-companion v2 (Prereq). This is an interactive, model-driven validation, not a scripted test.

- [ ] **Step 1: Reload settings so the new skills/command are discovered**

Restart the Claude Code session (settings/skills are loaded at startup), cwd = repo.

- [ ] **Step 2: Run objectives on the pilot**

Invoke `/mlt --phase objectives --chapter 01-introduction`. Confirm it writes `course/01-introduction/objectives.md`
with 2-4 English objectives + the 6-row dual-mode exercise table, and that `objectives.html` is generated.

- [ ] **Step 3: Run narrative on the pilot**

Invoke `/mlt --phase narrative --chapter 01-introduction`. Confirm `course/01-introduction/narrative.md` has
six-word + 100-word + arc + a pre-hook naming chapter `02-classifiers` (the next enabled chapter).

- [ ] **Step 4: Visual verification**

Open `course/01-introduction/objectives.html` and `narrative.html` with the `chrome-devtools` MCP at ~1100px;
confirm the dual-mode table renders, math (if any) renders, orange theme, no overflow.

- [ ] **Step 5: Confirm manifest untouched + status reflects artifacts**

Run: `git diff --stat course/_manifest.yml` (expect: no changes) and
`python -c "import sys;sys.path.insert(0,'.claude/skills/lib');import manifest,json;print(json.dumps(manifest.artifact_status(manifest.load())['01-introduction']))"`
Expected: manifest unchanged; status shows objectives=true, narrative=true.

- [ ] **Step 6: Commit the pilot artifacts**

```bash
git add course/01-introduction/objectives.md course/01-introduction/objectives.html course/01-introduction/narrative.md course/01-introduction/narrative.html
git commit -m "Add pilot content for 01-introduction (objectives + narrative)"
```

---

## Self-Review

**Spec coverage:**
- §6.3 mlt-objectives (dual-mode live summative exercise) → Task 3 (6-row modality matrix). ✓
- §6.4 mlt-narrative (batch 6w/100w/arc + global spine + explicit pre-hook) → Task 4 (uses `next_enabled`). ✓
- §6.5 mlt-subunits (sub-units + formative proposed→solved) → Task 5. ✓
- §6.8 /mlt orchestrator (phase/chapter, gates, vault status) → Task 2. ✓
- §6.7 items reuse (English, re-read-from-disk, stop-and-confirm) → encoded in Task 2 `items` phase (reuses storia `itembank`; no new skill). ✓
- §6 storyboard/syllabus reuse → encoded in Task 2 (`storyboard-lezione`, `syllabus-2p` + `studente-confuso`). ✓
- Manifest write-back (§6.3/§6.5) → **intentionally dropped** (design note); status via filesystem (`manifest.py`). Documented.

**Placeholder scan:** none — every SKILL.md body and test is concrete. ✓

**Type/name consistency:** `load`, `enabled_chapters`, `next_enabled`, `chapter_dir`, `artifact_status` defined in Task 1 and referenced identically in Tasks 2, 4, 6. ✓

**Caveats:**
- Tasks 3–6 require storia-companion **v2** (Prereq). Tasks 1–2 do not.
- Skills/commands are discovered at session start: Task 6 Step 1 (reload) is required before the pilot.
- `manifest.py` is import-only (no `__main__`); the orchestrator's Step 0 uses the inline `python -c` form as the canonical status invocation.
```
