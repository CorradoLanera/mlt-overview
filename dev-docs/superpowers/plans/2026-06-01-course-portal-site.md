# Public Course Portal Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `portal.html` (an author dashboard) into a clean, public **GitHub Pages** site that serves all three modules (theory + 2 workshops) with slides, schedule and downloads, built into `/docs`.

**Architecture:** A small **Quarto website** in `site/` renders thin wrapper pages to `/docs`. Page content is single-sourced: stdlib-only Python (`scripts/site_content.py`, unit-tested) extracts chapter objectives / timelines / README sections into `site/_generated/*.md` that the pages `{{< include >}}`. `scripts/build_site.py` orchestrates the live build (partials → `quarto render site` → the 3 decks rendered **non-embed** into `docs/slides/` → copy `img/` → write `.nojekyll`). A second script builds **embed** decks + ZIPs into `dev/release-assets/` for per-cohort GitHub Release assets. Pages serves `main` `/docs` — no CI. Internal design notes are relocated out of `/docs` first.

**Tech Stack:** Python 3 (stdlib only: `re`, `shutil`, `subprocess`, `argparse`, `pathlib`), pytest (`tests/skills/`), Quarto (website + reveal.js, dart-sass theming), git, GitHub Pages.

**Spec:** `../specs/2026-06-01-course-portal-site-design.md` (this plan + spec move to `dev-docs/superpowers/` in Task A).

---

## File Structure

**Created:**
- `scripts/site_content.py` — pure extraction helpers (manifest chapters, objectives, formative timeline, README sections).
- `scripts/build_site.py` — `write_partials()` (generates `site/_generated/`) + `main()` orchestration (render site + decks + img + `.nojekyll`).
- `scripts/build_release.py` — render embed decks + gather ZIPs into `dev/release-assets/`.
- `tests/skills/test_site_content.py` — unit tests for the 4 extraction helpers.
- `tests/skills/test_build_site.py` — unit test for `write_partials()` on a fixture mini-repo.
- `site/_quarto.yml`, `site/_brand.scss` — Quarto website config + brand.
- `site/{index,theory,basic,advanced,schedule,downloads}.qmd` — the 6 thin pages.
- `docs/` — the published site output (committed; created by the build).

**Modified:**
- `.gitignore` — add `site/_generated/`; confirm `docs/` (and `docs/slides`, `docs/img`) are NOT ignored.
- `.claude/CLAUDE.md` (project) — repoint `docs/superpowers/specs/…` references to `dev-docs/…`.
- root `README.md` — add the public-site URL + per-cohort release note.

**Moved (Task A):** `docs/superpowers/` → `dev-docs/superpowers/`; `docs/sources/` → `dev-docs/sources/`.

**Out of scope (user-only / future):** flipping the GitHub Pages setting (Settings → Pages → `main` `/docs`); cutting the cohort Release (`git tag` + asset upload); image optimisation of the `/docs/img` copy.

---

## Conventions for every task

- Repo root: `c:\Users\corra\github\cl\mlt-overview`. All paths relative to it unless absolute.
- Run pytest from the repo root: `python -m pytest tests/skills/<file>.py -v`.
- Commit messages in English, **one logical change per commit**, ending with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Claude never pushes; only the user pushes. Local commits are fine.
- (Optional) work on branch `portal-site`.
- Quarto/Python must be on PATH (`quarto --version`, `python --version` ≥ 3.10).

---

## Task A: Relocate internal design notes out of `/docs` + repoint

**Files:**
- Move: `docs/superpowers/` → `dev-docs/superpowers/`, `docs/sources/` → `dev-docs/sources/`
- Modify: `.claude/CLAUDE.md` (project), any other reference found by grep

- [ ] **Step 1: Move the two note trees out of `/docs` (history preserved)**

```bash
git mv docs/superpowers dev-docs/superpowers
git mv docs/sources     dev-docs/sources
```

(After this, this plan lives at `dev-docs/superpowers/plans/2026-06-01-course-portal-site.md` — re-open it there if your editor lost it.)

- [ ] **Step 2: Find every reference to the old paths**

Run: `git grep -n "docs/superpowers\|docs/sources"`
Expected: a short list. Known hits to fix in `.claude/CLAUDE.md` (project):
`Rinnovazione: vedi docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md` and
`Layout e contratto: docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`.

- [ ] **Step 3: Repoint `.claude/CLAUDE.md` (project)**

Edit the two lines, replacing the prefix `docs/superpowers/` with `dev-docs/superpowers/`:
```
Rinnovazione: vedi `dev-docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md`
```
```
Layout e contratto: `dev-docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`
```

- [ ] **Step 4: Repoint any remaining hits**

For each remaining line from Step 2 (e.g. cross-references inside specs/plans, `scripts/build_portal.py`, root `README.md`), replace `docs/superpowers` → `dev-docs/superpowers` and `docs/sources` → `dev-docs/sources`. Re-run `git grep -n "docs/superpowers\|docs/sources"` → expect **no live hits** (only this plan's own historical mentions, which are fine).

- [ ] **Step 5: Verify `/docs` no longer holds notes**

Run: `ls docs` → expect it to be empty or absent (it will be (re)created as the site output in later tasks).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Relocate internal design notes out of /docs (→ dev-docs/) + repoint references"
```

---

## Task B: Content-extraction helpers (`scripts/site_content.py`) — TDD

**Files:**
- Create: `scripts/site_content.py`, `tests/skills/test_site_content.py`

- [ ] **Step 1: Write the failing tests**

Create `tests/skills/test_site_content.py`:
```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import site_content as sc  # noqa: E402

MANIFEST = """\
course:
  title: "MLT"
chapters:
  - { slug: 01-introduction, title: "What is Machine Learning?", include: true,  minutes: 25, objectives: [] }
  - { slug: 02-classifiers,  title: "Classifiers",               include: true,  minutes: 20, objectives: [] }
  - { slug: 99-cut,          title: "Cut chapter",               include: false, minutes: 10, objectives: [] }
"""

OBJECTIVES = """\
# 01 — title

## Learning objectives

By the end of this chapter, students can:

1. **Frame** a clinical problem as ML.
2. **Contrast** ML with traditional programming.

*Nota docente:* tre obiettivi per stare nei 25'.

## Summative live exercise

(internal stuff)
"""


def test_chapters_from_manifest_parses_included_in_order():
    chs = sc.chapters_from_manifest(MANIFEST)
    assert [c["slug"] for c in chs] == ["01-introduction", "02-classifiers", "99-cut"]
    assert chs[0] == {"slug": "01-introduction", "title": "What is Machine Learning?",
                      "include": True, "minutes": 25}
    assert chs[2]["include"] is False


def test_extract_objectives_keeps_en_list_stops_at_nota_docente():
    out = sc.extract_objectives(OBJECTIVES)
    assert "**Frame**" in out and "**Contrast**" in out
    assert "Nota docente" not in out
    assert "Summative" not in out


def test_extract_objectives_absent_returns_empty():
    assert sc.extract_objectives("# x\n\nno section here\n") == ""


def test_timeline_from_formatives_sorts_and_ignores_noise():
    names = ["min-30-yourturn-wrangle.md", "min-09-live-check.md", "README.md",
             "min-165-predict-output.md"]
    rows = sc.timeline_from_formatives(names)
    assert [r["minute"] for r in rows] == [9, 30, 165]
    assert rows[0]["label"] == "live check"


def test_readme_section_extracts_body_until_next_heading():
    md = "# t\n\n## Prerequisites\n\nNeed R.\nAnd RStudio.\n\n## Dataset\n\nheart failure\n"
    assert sc.readme_section(md, "Prerequisites") == "Need R.\nAnd RStudio."
    assert sc.readme_section(md, "Missing") == ""
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_site_content.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'site_content'`.

- [ ] **Step 3: Implement `scripts/site_content.py`**

Create `scripts/site_content.py`:
```python
#!/usr/bin/env python3
"""Pure content-extraction helpers for the public course site build.

Stdlib only, no I/O: each function takes text (or a list of names) and returns
plain data / markdown ready to be written into site/_generated/*.md. Unit-tested.
"""
from __future__ import annotations

import re

_CHAPTER_RE = re.compile(
    r"slug:\s*([A-Za-z0-9-]+)\s*,"
    r'\s*title:\s*"([^"]+)"\s*,'
    r"\s*include:\s*(true|false)\s*,"
    r"\s*minutes:\s*(\d+)",
)


def chapters_from_manifest(text: str) -> list[dict]:
    """Parse the `chapters:` list of course/_manifest.yml into ordered dicts."""
    idx = text.find("\nchapters:")
    scan = text[idx:] if idx != -1 else text
    out = []
    for m in _CHAPTER_RE.finditer(scan):
        out.append({
            "slug": m.group(1),
            "title": m.group(2),
            "include": m.group(3) == "true",
            "minutes": int(m.group(4)),
        })
    return out


def extract_objectives(md_text: str) -> str:
    """Markdown of the `## Learning objectives` block only (English).

    Stops at the first `*Nota docente:*` line or the next `## ` heading, so
    Italian teacher notes and the summative exercise are excluded. "" if absent.
    """
    lines = md_text.splitlines()
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().lower().startswith("## learning objectives"):
            start = i + 1
            break
    if start is None:
        return ""
    body = []
    for ln in lines[start:]:
        s = ln.strip()
        if s.startswith("## ") or s.startswith("*Nota docente"):
            break
        body.append(ln)
    return "\n".join(body).strip()


def timeline_from_formatives(names: list[str]) -> list[dict]:
    """Map `min-NN-<slug>.md` filenames → [{minute, label}] sorted by minute."""
    rx = re.compile(r"min-(\d+)-(.+)\.md$")
    rows = []
    for n in names:
        base = n.replace("\\", "/").split("/")[-1]
        m = rx.search(base)
        if not m:
            continue
        rows.append({"minute": int(m.group(1)), "label": m.group(2).replace("-", " ")})
    rows.sort(key=lambda r: r["minute"])
    return rows


def readme_section(md_text: str, heading: str) -> str:
    """Body under `## <heading>` up to the next `## ` (or EOF). "" if absent."""
    lines = md_text.splitlines()
    target = f"## {heading}".lower()
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().lower() == target:
            start = i + 1
            break
    if start is None:
        return ""
    body = []
    for ln in lines[start:]:
        if ln.strip().startswith("## "):
            break
        body.append(ln)
    return "\n".join(body).strip()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_site_content.py -v`
Expected: PASS (5 passed).

- [ ] **Step 5: Commit**

```bash
git add scripts/site_content.py tests/skills/test_site_content.py
git commit -m "Add site_content.py extraction helpers (manifest, objectives, timeline, readme)"
```

---

## Task C: Partial generator (`scripts/build_site.py::write_partials`) — TDD

**Files:**
- Create: `scripts/build_site.py` (this task writes `write_partials` + module scaffolding; Task E adds `main`)
- Create: `tests/skills/test_build_site.py`

- [ ] **Step 1: Write the failing test (fixture mini-repo)**

Create `tests/skills/test_build_site.py`:
```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_site as bs  # noqa: E402


def _mini_repo(tmp: Path) -> Path:
    (tmp / "course" / "01-introduction").mkdir(parents=True)
    (tmp / "course" / "_manifest.yml").write_text(
        'chapters:\n'
        '  - { slug: 01-introduction, title: "Intro", include: true, minutes: 25, objectives: [] }\n',
        encoding="utf-8",
    )
    (tmp / "course" / "01-introduction" / "objectives.md").write_text(
        "## Learning objectives\n\n1. **Frame** it.\n\n*Nota docente:* hidden.\n", encoding="utf-8"
    )
    fm = tmp / "slides" / "workshops" / "mlt-r-basic" / "formatives"
    fm.mkdir(parents=True)
    (fm / "min-09-live-check.md").write_text("x", encoding="utf-8")
    (fm / "min-30-yourturn-wrangle.md").write_text("x", encoding="utf-8")
    (fm / "README.md").write_text("x", encoding="utf-8")
    (tmp / "workshops" / "mlt-r-basic").mkdir(parents=True)
    (tmp / "workshops" / "mlt-r-basic" / "README.md").write_text(
        "# Basic\n\n## What you will build\n\nA model.\n\n## Prerequisites\n\nSome R.\n",
        encoding="utf-8",
    )
    # advanced (minimal, so its partials are generated too)
    fa = tmp / "slides" / "workshops" / "mlt-r-advanced" / "formatives"
    fa.mkdir(parents=True)
    (fa / "min-10-live-check.md").write_text("x", encoding="utf-8")
    (tmp / "workshops" / "mlt-r-advanced").mkdir(parents=True)
    (tmp / "workshops" / "mlt-r-advanced" / "README.md").write_text(
        "# Adv\n\n## What you will build\n\nInterpretability.\n", encoding="utf-8"
    )
    return tmp


def test_write_partials_emits_expected_files(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    written = bs.write_partials(root, out)
    names = {p.name for p in written}
    for expected in {
        "theory-chapters.md", "schedule.md",
        "basic-overview.md", "basic-timeline.md", "basic-syllabus.md",
        "advanced-overview.md", "advanced-timeline.md", "advanced-syllabus.md",
        "theory-syllabus.md",
    }:
        assert expected in names
        assert (out / expected).exists()


def test_theory_chapters_has_objectives_no_nota_and_total(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    text = (out / "theory-chapters.md").read_text(encoding="utf-8")
    assert "Intro" in text and "**Frame**" in text
    assert "Nota docente" not in text
    assert "25 min" in text


def test_basic_timeline_and_overview(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    tl = (out / "basic-timeline.md").read_text(encoding="utf-8")
    assert "min 9" in tl and "min 30" in tl
    ov = (out / "basic-overview.md").read_text(encoding="utf-8")
    assert "A model." in ov and "Some R." in ov


def test_syllabus_placeholder_when_absent(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    syl = (out / "theory-syllabus.md").read_text(encoding="utf-8")
    assert "preparation" in syl.lower() or "preparazione" in syl.lower()
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_site.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'build_site'`.

- [ ] **Step 3: Implement `scripts/build_site.py` (write_partials + scaffolding)**

Create `scripts/build_site.py`:
```python
#!/usr/bin/env python3
"""Build the live public site into /docs.

Two parts:
  - write_partials(root, out): generate site/_generated/*.md from course sources (unit-tested).
  - main(): orchestrate the full build (partials → quarto render site → 3 decks non-embed
    into docs/slides → copy img → write .nojekyll). See Task E for main().

Stdlib only; Quarto invoked via subprocess. Deterministic: same inputs → same /docs.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import site_content as sc  # noqa: E402

WORKSHOPS = [("mlt-r-basic", "basic"), ("mlt-r-advanced", "advanced")]
# Candidate syllabus source paths (forward-compatible; first existing wins).
SYLLABUS_SOURCES = {
    "theory":   ["course/_global/syllabus.md", "course/_global/syllabus-overview.md"],
    "basic":    ["workshops/mlt-r-basic/syllabus.md"],
    "advanced": ["workshops/mlt-r-advanced/syllabus.md"],
}
_SYLLABUS_PLACEHOLDER = "_Syllabus in preparation — it will appear here once finalised._\n"


def _syllabus_partial(root: Path, key: str) -> str:
    for rel in SYLLABUS_SOURCES.get(key, []):
        p = root / rel
        if p.exists():
            return p.read_text(encoding="utf-8", errors="replace")
    return _SYLLABUS_PLACEHOLDER


def _theory_chapters_md(root: Path) -> str:
    manifest = (root / "course" / "_manifest.yml").read_text(encoding="utf-8", errors="replace")
    out = ["## Chapters", ""]
    total = 0
    for ch in sc.chapters_from_manifest(manifest):
        if not ch["include"]:
            continue
        total += ch["minutes"]
        num = ch["slug"].split("-")[0]
        out.append(f"### {num} · {ch['title']} · {ch['minutes']} min")
        out.append("")
        obj_file = root / "course" / ch["slug"] / "objectives.md"
        obj = sc.extract_objectives(obj_file.read_text(encoding="utf-8", errors="replace")) \
            if obj_file.exists() else ""
        out.append(obj if obj else "_Objectives to be published._")
        out.append("")
    out.append(f"**Total contact time: {total} min.**")
    out.append("")
    return "\n".join(out)


def _timeline_md(root: Path, slug: str) -> str:
    fdir = root / "slides" / "workshops" / slug / "formatives"
    names = [p.name for p in fdir.glob("*.md")] if fdir.is_dir() else []
    rows = sc.timeline_from_formatives(names)
    if not rows:
        return "_Timeline to be published._\n"
    out = ["| Minute | Checkpoint |", "|---|---|"]
    for r in rows:
        out.append(f"| min {r['minute']} | {r['label']} |")
    return "\n".join(out) + "\n"


def _overview_md(root: Path, slug: str) -> str:
    readme = (root / "workshops" / slug / "README.md").read_text(encoding="utf-8", errors="replace")
    chunks = []
    for h in ("What you will build", "Dataset", "Prerequisites"):
        body = sc.readme_section(readme, h)
        if body:
            chunks.append(f"## {h}\n\n{body}")
    return ("\n\n".join(chunks) if chunks else "_Overview to be published._") + "\n"


def write_partials(root: Path, out_dir: Path) -> list[Path]:
    root = Path(root)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    def _emit(name: str, text: str) -> None:
        p = out_dir / name
        p.write_text(text, encoding="utf-8")
        written.append(p)

    _emit("theory-chapters.md", _theory_chapters_md(root))
    _emit("theory-syllabus.md", _syllabus_partial(root, "theory"))

    sched = ["## Module 1 · Theory Overview", "", _theory_chapters_md(root)]
    for slug, key in WORKSHOPS:
        label = "Basic" if key == "basic" else "Advanced"
        sched += [f"## Module {2 if key=='basic' else 3} · Practice — {label} (≈4h)", "",
                  _timeline_md(root, slug), ""]
    _emit("schedule.md", "\n".join(sched))

    for slug, key in WORKSHOPS:
        _emit(f"{key}-overview.md", _overview_md(root, slug))
        _emit(f"{key}-timeline.md", _timeline_md(root, slug))
        _emit(f"{key}-syllabus.md", _syllabus_partial(root, key))

    return written


# --- orchestration (implemented in Task E) ---------------------------------

def main(argv=None) -> int:  # pragma: no cover  (filled in Task E)
    raise SystemExit("build_site.main is implemented in Task E")


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_build_site.py -v`
Expected: PASS (4 passed).

- [ ] **Step 5: Commit**

```bash
git add scripts/build_site.py tests/skills/test_build_site.py
git commit -m "Add build_site.write_partials (generates site/_generated from sources)"
```

---

## Task D: Scaffold the Quarto website (`site/`)

**Files:**
- Create: `site/_quarto.yml`, `site/_brand.scss`, `site/index.qmd`, `site/theory.qmd`, `site/basic.qmd`, `site/advanced.qmd`, `site/schedule.qmd`, `site/downloads.qmd`
- Modify: `.gitignore`

- [ ] **Step 1: Create `site/_quarto.yml`**

```yaml
project:
  type: website
  output-dir: ../docs
  render:
    - "*.qmd"

website:
  title: "Machine Learning — An Applied Overview"
  description: "UBEP course · three modules · biomedical/clinical graduate students"
  site-url: "https://corradolanera.github.io/mlt-overview/"
  repo-url: "https://github.com/CorradoLanera/mlt-overview"
  navbar:
    background: primary
    left:
      - { text: "Home",     href: index.qmd }
      - { text: "Theory",   href: theory.qmd }
      - { text: "Basic",    href: basic.qmd }
      - { text: "Advanced", href: advanced.qmd }
      - { text: "Schedule", href: schedule.qmd }
      - { text: "Downloads", href: downloads.qmd }
    right:
      - { icon: github, href: "https://github.com/CorradoLanera/mlt-overview" }
  page-footer:
    center: "UBEP · University of Padova — Machine Learning: An Applied Overview"

format:
  html:
    theme: [cosmo, _brand.scss]
    toc: false
    page-layout: full
lang: en
```

- [ ] **Step 2: Create `site/_brand.scss`**

```scss
/*-- scss:defaults --*/
$primary:   #E8741E;
$secondary: #1F4257;
$body-color: #1a1a1a;
$link-color: #C75A12;
$font-family-sans-serif: "Noto Sans", system-ui, Arial, sans-serif;
$headings-font-family:   "Cabin", "Noto Sans", sans-serif;
$font-family-monospace:  "Source Code Pro", Consolas, monospace;

/*-- scss:rules --*/
.module-cards { display: flex; gap: 1rem; flex-wrap: wrap; margin: 1.5rem 0; }
.module-card  { flex: 1 1 260px; border: 1px solid #e5e7eb; border-radius: 12px;
                padding: 1.1rem 1.2rem; background: #fff; }
.module-card h3 { color: #C75A12; margin-top: 0; }
.btn-deck { display: inline-block; margin: .2rem .4rem .2rem 0; padding: .35rem .8rem;
            border-radius: 8px; background: #E8741E; color: #fff !important; text-decoration: none; }
.btn-dl   { display: inline-block; margin: .2rem .4rem .2rem 0; padding: .35rem .8rem;
            border-radius: 8px; border: 1px solid #1F4257; color: #1F4257 !important; text-decoration: none; }
```

- [ ] **Step 3: Create `site/index.qmd`**

`````markdown
---
title: "Machine Learning — An Applied Overview"
---

A course for **biomedical/clinical graduate students** (UBEP, University of Padova).
One course, **three modules**, taught in sequence.

::: {.module-cards}
::: {.module-card}
### Theory Overview
10 storyboard-narrated chapters (≈240 min).

[Open slides](slides/slides.html){.btn-deck} [Details](theory.qmd){.btn-dl}
:::
::: {.module-card}
### Practice — Basic
Live-coded R: build & validate a clinical ML model.

[Open deck](slides/workshops/mlt-r-basic/00-basic-deck.html){.btn-deck} [Details](basic.qmd){.btn-dl}
:::
::: {.module-card}
### Practice — Advanced
Live-coded R: interpretability + deep learning.

[Open deck](slides/workshops/mlt-r-advanced/00-advanced-deck.html){.btn-deck} [Details](advanced.qmd){.btn-dl}
:::
:::

## Learning path

**Overview → Basic → Advanced.** The Overview ends (ch. 10) by pre-hooking into the Basic
workshop; Basic pre-hooks into Advanced. Prerequisites are stated on each module page.

## How the course works

The Theory Overview is delivered as reveal.js slides (also downloadable as one self-contained
file per cohort). The two R workshops are ~4-hour live-coding sessions: fetch a ZIP, restore the
pinned package environment, and type every line together. See **[Schedule](schedule.qmd)** for the
full plan and **[Downloads](downloads.qmd)** to get the materials.
`````

- [ ] **Step 4: Create `site/theory.qmd`**

`````markdown
---
title: "Theory Overview"
---

[Open the slides ↗](slides/slides.html){.btn-deck}
[Download self-contained deck](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-overview-theory-deck.html){.btn-dl}

Ten chapters, storyboard-narrated, ≈240 minutes of contact time.

{{< include _generated/theory-chapters.md >}}

## Syllabus

{{< include _generated/theory-syllabus.md >}}
`````

- [ ] **Step 5: Create `site/basic.qmd`**

`````markdown
---
title: "Practice — Basic (R)"
---

[Open the deck ↗](slides/workshops/mlt-r-basic/00-basic-deck.html){.btn-deck}
[Download deck](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic-deck.html){.btn-dl}
[Download workshop ZIP](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip){.btn-dl}

{{< include _generated/basic-overview.md >}}

## Timeline

{{< include _generated/basic-timeline.md >}}

## How to get & run it

You need R (≥ 4.5) and RStudio.

```r
usethis::use_course(
  "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip"
)
```

Open `mlt-r-basic.Rproj` (its `renv` activates), then `renv::restore()`.

## Syllabus

{{< include _generated/basic-syllabus.md >}}
`````

- [ ] **Step 6: Create `site/advanced.qmd`**

`````markdown
---
title: "Practice — Advanced (R)"
---

[Open the deck ↗](slides/workshops/mlt-r-advanced/00-advanced-deck.html){.btn-deck}
[Download deck](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced-deck.html){.btn-dl}
[Download workshop ZIP](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced.zip){.btn-dl}

{{< include _generated/advanced-overview.md >}}

## Timeline

{{< include _generated/advanced-timeline.md >}}

## How to get & run it

You need R (≥ 4.5) and RStudio.

```r
usethis::use_course(
  "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced.zip"
)
```

Open `mlt-r-advanced.Rproj`, then `renv::restore()`. The LLM step (`ellmer`) needs an OpenAI
API key (optional — it falls back to a cached extraction): copy `.Renviron.example` → `.Renviron`
and set your key.

## Syllabus

{{< include _generated/advanced-syllabus.md >}}
`````

- [ ] **Step 7: Create `site/schedule.qmd`**

`````markdown
---
title: "Schedule & Planning"
---

The full plan across the three modules — for students, and for instructors evaluating the programme.

{{< include _generated/schedule.md >}}
`````

- [ ] **Step 8: Create `site/downloads.qmd`**

`````markdown
---
title: "Downloads"
---

All materials for the current cohort are published as **GitHub Release assets** (one release per
cohort, e.g. tag `coorte-2026`).

## Latest assets

- [Theory deck (self-contained)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-overview-theory-deck.html)
- [Basic deck (self-contained)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic-deck.html)
- [Advanced deck (self-contained)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced-deck.html)
- [Basic workshop project (ZIP)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip)
- [Advanced workshop project (ZIP)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced.zip)

## Running a workshop

You need R (≥ 4.5) and RStudio. Fetch a workshop with `usethis::use_course(<zip-url>)`, open its
`.Rproj`, then `renv::restore()` to install the pinned packages.

## Per-cohort model

Each cohort gets its own Release (tag `coorte-AAAA`) with decks + workshop ZIPs frozen at that
point. This site always shows the **latest** rendered slides; the Release assets are the **offline,
citable snapshot**.
`````

- [ ] **Step 9: Ignore the generated partials**

Append to `.gitignore`:
```gitignore
# Generated site partials (rebuilt by scripts/build_site.py)
site/_generated/
```

- [ ] **Step 10: Generate partials + render the site shell**

```bash
python -c "import sys; sys.path.insert(0,'scripts'); import build_site as b; from pathlib import Path; b.write_partials(Path('.'), Path('site/_generated'))"
quarto render site
```
Expected: `docs/index.html`, `docs/theory.html`, … created with navbar + brand. (Decks/img links 404 for now — added in Task E.)

- [ ] **Step 11: Visual check (Home)**

Serve and inspect: `python -m http.server -d docs 8099` then chrome-devtools at `http://localhost:8099/` (~1100px): navbar present, 3 module cards render, brand colours applied. Stop the server.

- [ ] **Step 12: Commit (sources only; `/docs` committed in Task G)**

```bash
git add site/ .gitignore
git commit -m "Scaffold public Quarto website (site/) — 6 pages + brand + nav"
```

---

## Task E: Render decks non-embed + assets into `/docs` (`build_site.main`)

**Files:**
- Modify: `scripts/build_site.py` (replace the placeholder `main`)

- [ ] **Step 1: Replace the `main` placeholder with the orchestration**

In `scripts/build_site.py`, replace the `# --- orchestration ---` block (the placeholder `main`) with:
```python
# --- orchestration ----------------------------------------------------------

DOCS = Path("docs")


def _run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)


def _copy_into(src: Path, dst_dir: Path) -> None:
    dst_dir.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst_dir / src.name, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst_dir / src.name)


def render_theory_deck(root: Path) -> None:
    """Render slides/slides.qmd non-embed; copy html + _files into docs/slides/."""
    _run(["quarto", "render", "slides/slides.qmd", "-M", "embed-resources:false"], cwd=root)
    docs_slides = root / DOCS / "slides"
    docs_slides.mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / "slides" / "slides.html", docs_slides / "slides.html")
    files = root / "slides" / "slides_files"
    if files.is_dir():
        shutil.copytree(files, docs_slides / "slides_files", dirs_exist_ok=True)


def render_workshop_deck(root: Path, slug: str) -> None:
    """Render a workshop deck non-embed; copy into docs/slides/workshops/<slug>/."""
    wdir = root / "slides" / "workshops" / slug
    _run(["quarto", "render", str(wdir), "-M", "embed-resources:false"], cwd=root)
    dst = root / DOCS / "slides" / "workshops" / slug
    dst.mkdir(parents=True, exist_ok=True)
    for p in wdir.glob("*.html"):
        shutil.copy2(p, dst / p.name)
    for d in wdir.glob("*_files"):
        if d.is_dir():
            shutil.copytree(d, dst / d.name, dirs_exist_ok=True)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Build the live public site into /docs")
    ap.add_argument("--root", default=".")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()

    # 1. partials
    write_partials(root, root / "site" / "_generated")
    # 2. render the website (Quarto writes ../docs)
    _run(["quarto", "render", "site"], cwd=root)
    # 3. decks (non-embed) into docs/slides
    render_theory_deck(root)
    for slug, _key in WORKSHOPS:
        render_workshop_deck(root, slug)
    # 4. images referenced by the theory deck
    shutil.copytree(root / "img", root / DOCS / "img", dirs_exist_ok=True)
    # 5. disable Jekyll so *_files/ and site_libs/ are served verbatim
    (root / DOCS / ".nojekyll").write_text("", encoding="utf-8")

    big = [str(p) for p in (root / DOCS).rglob("*") if p.is_file() and p.stat().st_size > 100_000_000]
    if big:
        print("WARNING: files >100MB in docs/: " + ", ".join(big), file=sys.stderr)
    print(f"site built into {root / DOCS}", file=sys.stderr)
    return 0
```
(Delete the old placeholder `def main` and its `pragma: no cover` body.)

- [ ] **Step 2: Re-run the unit tests (write_partials must still pass)**

Run: `python -m pytest tests/skills/test_build_site.py tests/skills/test_site_content.py -v`
Expected: PASS (unchanged — `main` is not unit-tested).

- [ ] **Step 3: Full build**

Run: `python scripts/build_site.py`
Expected: `site built into …/docs`, no `WARNING: files >100MB`. `docs/slides/slides.html`,
`docs/slides/workshops/mlt-r-basic/00-basic-deck.html`, `docs/img/UBEP.png`, `docs/.nojekyll` exist.

- [ ] **Step 4: Verify no file exceeds the GitHub limit**

Run: `find docs -type f -size +100M` (PowerShell: `Get-ChildItem docs -Recurse -File | ? Length -gt 100MB`).
Expected: empty.

- [ ] **Step 5: Commit (script only)**

```bash
git add scripts/build_site.py
git commit -m "build_site: render decks non-embed + img + .nojekyll into /docs"
```

---

## Task F: Per-cohort release builder (`scripts/build_release.py`)

**Files:**
- Create: `scripts/build_release.py`, `tests/skills/test_build_release.py`

- [ ] **Step 1: Write the failing test (asset-name map is pure + testable)**

Create `tests/skills/test_build_release.py`:
```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_release as br  # noqa: E402


def test_asset_names_are_contractual():
    assert br.DECK_ASSETS["theory"] == "mlt-overview-theory-deck.html"
    assert br.DECK_ASSETS["basic"] == "mlt-r-basic-deck.html"
    assert br.DECK_ASSETS["advanced"] == "mlt-r-advanced-deck.html"
    assert br.ZIP_ASSETS == ["mlt-r-basic.zip", "mlt-r-advanced.zip"]
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_release.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'build_release'`.

- [ ] **Step 3: Implement `scripts/build_release.py`**

Create `scripts/build_release.py`:
```python
#!/usr/bin/env python3
"""Assemble per-cohort GitHub Release assets into dev/release-assets/ (gitignored).

Renders the 3 decks self-contained (embed-resources:true) under contractual names,
and copies the workshop ZIPs from dist/ (build them first via /mlt-dist). The user
then tags the cohort and uploads these assets. Stdlib only; Quarto via subprocess.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

OUT = Path("dev/release-assets")
DECK_ASSETS = {
    "theory":   "mlt-overview-theory-deck.html",
    "basic":    "mlt-r-basic-deck.html",
    "advanced": "mlt-r-advanced-deck.html",
}
ZIP_ASSETS = ["mlt-r-basic.zip", "mlt-r-advanced.zip"]
_DECK_SRC = {
    "theory":   "slides/slides.qmd",
    "basic":    "slides/workshops/mlt-r-basic",
    "advanced": "slides/workshops/mlt-r-advanced",
}


def _run(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=str(cwd), check=True)


def _rendered_html(root: Path, key: str) -> Path:
    src = _DECK_SRC[key]
    if key == "theory":
        return root / "slides" / "slides.html"
    return next((root / src).glob("*.html"))


def build(root: Path) -> list[Path]:
    out = root / OUT
    out.mkdir(parents=True, exist_ok=True)
    made: list[Path] = []
    for key, src in _DECK_SRC.items():
        _run(["quarto", "render", src, "-M", "embed-resources:true"], root)
        dst = out / DECK_ASSETS[key]
        shutil.copy2(_rendered_html(root, key), dst)
        made.append(dst)
    for z in ZIP_ASSETS:
        srcz = root / "dist" / z
        if srcz.exists():
            shutil.copy2(srcz, out / z)
            made.append(out / z)
        else:
            print(f"WARNING: {srcz} missing — run /mlt-dist first", file=sys.stderr)
    return made


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    made = build(root)
    print("release assets in dev/release-assets/:", file=sys.stderr)
    for p in made:
        print(f"  {p.name} ({p.stat().st_size/1_000_000:.1f} MB)", file=sys.stderr)
    print("Next (manual): git tag coorte-AAAA → create the Release → upload these assets.",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_build_release.py -v`
Expected: PASS (1 passed).

- [ ] **Step 5: Smoke-build the release assets**

Run: `python scripts/build_release.py` (run `/mlt-dist` first if `dist/*.zip` are stale).
Expected: 3 embed HTML (each openable offline) + 2 ZIP in `dev/release-assets/`; `git status` does not track them (`dev/` ignored).

- [ ] **Step 6: Commit (script + test only)**

```bash
git add scripts/build_release.py tests/skills/test_build_release.py
git commit -m "Add build_release.py (per-cohort embed decks + ZIPs → dev/release-assets/)"
```

---

## Task G: Publish — `.gitignore` check + first `/docs` commit

**Files:**
- Modify: `.gitignore` (only if a rule shadows `docs/`)

- [ ] **Step 1: Confirm the published outputs are NOT ignored**

Run: `git check-ignore -v docs/slides/slides.html docs/img/UBEP.png docs/index.html`
Expected: **no output** (none ignored). The existing `slides/slides.html` / workshop `*.html` rules are path-anchored to the source tree, not `docs/`. If anything IS matched, add a negation at the end of `.gitignore`, e.g. `!docs/`.

- [ ] **Step 2: Rebuild fresh**

Run: `python scripts/build_site.py`
Then: `find docs -type f -size +100M` → empty.

- [ ] **Step 3: Commit the published site**

```bash
git add docs
git commit -m "Publish initial public site build to /docs"
```

- [ ] **Step 4: Confirm a clean rebuild is deterministic**

Run: `python scripts/build_site.py` again, then `git status --short docs` → ideally no diff (or only Quarto-stamp noise). Note any non-determinism for follow-up.

---

## Task H: Visual verification gate (mandatory)

**Files:** none (inspection only)

- [ ] **Step 1: Serve the built site**

Run: `python -m http.server -d docs 8099`

- [ ] **Step 2: Inspect every page (chrome-devtools MCP)**

At `http://localhost:8099/` view Home, Theory, Basic, Advanced, Schedule, Downloads at ~1100px and at 1920×1080: navbar works, no overflow, cards/links correct, brand consistent. Confirm **no Italian `*Nota docente:*` text leaked** into Theory/Schedule.

- [ ] **Step 3: Open the three decks**

`slides/slides.html` (theory images load from `/docs/img`, MathJax renders), `slides/workshops/mlt-r-basic/00-basic-deck.html`, `…/mlt-r-advanced/00-advanced-deck.html` — first slide + a few navigations each.

- [ ] **Step 4: Fix + rebuild until the loop converges**

Apply targeted fixes (page content, `_brand.scss`, extraction), re-run `python scripts/build_site.py`, re-inspect. Stop the server when done.

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "Fix portal site visual issues found in review"
```

---

## Task I: README pointer + author-tool note + manual steps

**Files:**
- Modify: root `README.md`; (optional) `portal.html`

- [ ] **Step 1: Add the site link to the root README**

Under the modules table in `README.md`, add:
```markdown
## Public site

Browse the course at **<https://corradolanera.github.io/mlt-overview/>** (slides, schedule,
downloads). Per-cohort materials (self-contained decks + workshop ZIPs) ship as **GitHub Release
assets** (tag `coorte-AAAA`); build them with `python scripts/build_release.py`.
```

- [ ] **Step 2: Mark `portal.html` as an internal author tool (optional)**

If keeping `portal.html`, add an HTML comment at the top: `<!-- Internal author dashboard — NOT the public site. The public site is built into /docs by scripts/build_site.py. -->`

- [ ] **Step 3: Record the manual steps (user-only)**

Add to the README's public-site section a note:
```markdown
> One-time: GitHub → Settings → Pages → Deploy from a branch → `main` / `/docs`.
> Per cohort: `python scripts/build_release.py` → `git tag coorte-AAAA` → create the Release → upload the 5 assets.
```

- [ ] **Step 4: Commit**

```bash
git add README.md portal.html
git commit -m "Document public site URL + release-per-cohort workflow"
```

---

## Final verification

- [ ] **Step 1: Full test suite**

Run: `python -m pytest tests/skills -v`
Expected: all pass (existing tests + `test_site_content.py`, `test_build_site.py`, `test_build_release.py`).

- [ ] **Step 2: Clean rebuild + size guard**

Run: `python scripts/build_site.py` then `find docs -type f -size +100M` → empty.

- [ ] **Step 3: Visual gate green** (Task H) for all 6 pages + 3 decks; no IT leakage.

- [ ] **Step 4: Repoint check** — `git grep -n "docs/superpowers\|docs/sources"` shows no live references.

---

## Self-review (run while writing this plan)

**Spec coverage:** §2.1 dual-build → Task E (live non-embed in /docs) + Task F (embed assets). §2.2 clean scope → Task B/C extract objectives only + exclude `*Nota docente:*`; internal artifacts never copied to /docs (they live under `course/`, not `site/`/`docs/`). §2.3 landing+nav → Task D `_quarto.yml` navbar + index cards. §2.4 serving A → output-dir ../docs, Task G commit, manual Pages setting (Task I). §2.5 syllabus → `_syllabus_partial` (placeholder when absent), pages include it. §2.6 relocation → Task A. §6 build → Tasks C+E. §7 release → Task F. §8 page content → Tasks C+D. §9 brand+visual gate → Task D `_brand.scss` + Task H. §10 gitignore → Task D step 9 + Task G step 1. §13 success criteria → Final verification. All covered.

**Placeholder scan:** No TBD/TODO. Syllabus "to be published"/placeholder text is intentional runtime content, not a plan gap. Release URLs use the real `releases/latest/download/` form (resolve once the first Release exists — a user-only step, flagged).

**Type/name consistency:** `chapters_from_manifest`, `extract_objectives`, `timeline_from_formatives`, `readme_section` (site_content) match their tests. `write_partials`, `render_theory_deck`, `render_workshop_deck`, `main`, `WORKSHOPS`, `SYLLABUS_SOURCES` (build_site) match across Tasks C/E. `DECK_ASSETS`, `ZIP_ASSETS`, `build` (build_release) match the test. Generated filenames (`theory-chapters.md`, `{key}-overview.md`, `{key}-timeline.md`, `{key}-syllabus.md`, `theory-syllabus.md`, `schedule.md`) match the `{{< include >}}` paths in the pages and the assertions in `test_build_site.py`.

---

## Future Work (out of scope)

- Wire real syllabus paths once `/mlt` generates the 3 syllabi (update `SYLLABUS_SOURCES`).
- Optional `/mlt-site` slash-command wrapping `build_site.py` (mirror `/mlt-dist`).
- Optimise the `/docs/img` copy (compress PNG/GIF or git-lfs) if repo size becomes a concern.
- First Release (`coorte-2026`) so `releases/latest/download/…` URLs go live.
