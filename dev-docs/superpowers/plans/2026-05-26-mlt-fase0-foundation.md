# MLT Toolkit — Fase 0 (Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the project-local foundation for the MLT course renovation: conventions, the modular course manifest + tree, a math-capable self-contained HTML render hook, and the vault↔repo wiring — so the Fase A content skills have a working substrate.

**Architecture:** Project-local `.claude/` in `mlt-overview`. A PostToolUse hook renders any `course/**/*.md` to a sibling self-contained `.html` by shelling out to `pandoc` (bundled with Quarto, a hard project dependency) with `--standalone --embed-resources --mathml`, so LaTeX `$...$` becomes offline MathML. The course structure lives in `course/_manifest.yml` (single source of truth, chapters toggleable via `include:`). Vault tracking uses the existing private-vault subfolder wired through `.claude/settings.local.json` (gitignored — the course repo may go public).

**Tech Stack:** Python 3 (stdlib only for the hook glue), pandoc 3.8.3 (via Quarto 1.9.37), YAML manifest, Claude Code hooks/commands, pytest for the hook tests.

**Reference spec:** `dev-docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md`

---

## File Structure

- Create `.claude/CLAUDE.md` — repo conventions (EN students / IT notes, math in `$...$`, blank line before lists, item naming, 3-level rubric, manifest as source of truth, visual verification).
- Create `.claude/hooks/lib/mdmath.py` — pure functions: `should_render(path)`, `derive_title(md_path)`, `render_to_html(md_path) -> str`, `write_sibling_html(md_path) -> Path`.
- Create `.claude/hooks/lib/theme.css` — orange-forward self-contained CSS (embedded by pandoc).
- Create `.claude/hooks/md-to-html-math.py` — hook entrypoint: read PostToolUse JSON from stdin, filter, call `write_sibling_html`.
- Create `.claude/settings.json` — register the PostToolUse hook (committed; no private paths).
- Create `.claude/settings.local.json` — vault `additionalDirectories` + least-privilege `deny` (gitignored).
- Create `tests/hooks/test_mdmath.py` — pytest tests for `mdmath.py`.
- Create `course/_manifest.yml` — modular chapter index.
- Create `course/` tree + `course/_sources/.gitkeep`, `course/_global/.gitkeep`.
- Create `README.md` — repo readme (course overview + how to build/toggle).
- Create `.claude/commands/mlt-scaffold.md` — regeneration/idempotent scaffold command.
- Modify `.gitignore` — ignore `settings.local.json`, `docs/StorIA_2026.pptx`, pandoc/quarto build artifacts, `*.tmp.md`.

---

## Task 1: Repo conventions (`.claude/CLAUDE.md`)

**Files:**
- Create: `.claude/CLAUDE.md`

- [ ] **Step 1: Write the conventions file**

```markdown
# CLAUDE.md — corso MLT (mlt-overview)

Repo del corso "Machine Learning — An Applied Overview" (UBEP). Rinnovazione: vedi
`dev-docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md`. Tracking nel vault:
`progetti/mlt-overview/` (privato).

## Convenzioni non negoziabili

- **Lingua:** artefatti rivolti agli studenti (slide, item, syllabus, testo-a-video) in **INGLESE**;
  note del docente, "voce del docente", commenti di design e note di lavoro in **ITALIANO**.
- **Matematica:** ogni formula, pedice, overline, simbolo stand-alone in `$...$` (mai combining-Unicode).
  L'HTML generato rende la matematica (MathML via pandoc).
- **Liste markdown:** sempre una riga vuota prima di un elenco puntato/numerato.
- **Item valutativi:** `item_<NN>_<slug>_<type>.md` + `.html` accanto; indice `items_valutativi.md` + `.html`.
- **Rubriche:** 3 livelli `base / good / excellent` (EN), descrittori osservabili, soglia di sufficienza.
- **Fonte di verità della struttura:** `course/_manifest.yml`. Aggiungere/togliere capitoli = editare `include:`.
- **Verifica visiva obbligatoria:** nessun HTML/slide è "pronto" senza ispezione visiva (chrome-devtools).

## Strumenti

- Skill atomiche riusate da `storia-companion` v2 (verifica: la skill è `itembank`, NON `itembank-bloom`).
- Skill/command project-local: `mlt-scaffold`, `mlt-objectives`, `mlt-narrative`, `mlt-subunits`,
  `mlt-quarto-build`, orchestratore `/mlt` (vedi spec).
- Hook `md-to-html-math.py`: ogni `course/**/*.md` scritto → `.html` self-contained con matematica.

## Stato build

- Fase 0 (fondazione): in corso. Fase A (contenuti), Fase B (Quarto/PDF): da fare.
```

- [ ] **Step 2: Verify it exists and is non-empty**

Run: `test -s .claude/CLAUDE.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "Add repo CLAUDE.md with course conventions"
```

---

## Task 2: Course manifest + tree + README

**Files:**
- Create: `course/_manifest.yml`
- Create: `course/_global/.gitkeep`, `course/_sources/.gitkeep`
- Create: `README.md`

- [ ] **Step 1: Write the manifest**

```yaml
# course/_manifest.yml — single source of truth for the modular MLT course.
# Toggle a chapter with include: true/false. Order = teaching order.
course:
  title: "Machine Learning — An Applied Overview"
  slug: mlt-overview
  language: en
  total_minutes_gross: 240
  audience: "biomedical/clinical graduate students (UBEP, University of Padova)"
  base_source: index.Rmd        # index-full.Rmd mined for optional modules
  global:
    six_words: null
    hundred_words: null
    arc: null
chapters:
  - { slug: 01-introduction,       title: "What is Machine Learning?",      include: true,  minutes: 25, objectives: [], subunits: [] }
  - { slug: 02-classifiers,        title: "Classifiers",                    include: true,  minutes: 20, objectives: [], subunits: [] }
  - { slug: 03-algorithm-examples, title: "Algorithm examples",             include: true,  minutes: 35, objectives: [], subunits: [] }
  - { slug: 04-model-selection,    title: "Model selection & validation",   include: true,  minutes: 30, objectives: [], subunits: [] }
  - { slug: 05-deep-learning,      title: "Deep Learning",                  include: true,  minutes: 25, objectives: [], subunits: [] }
  - { slug: 06-unstructured-data,  title: "Unstructured data (CNN/RNN)",    include: true,  minutes: 20, objectives: [], subunits: [] }
  - { slug: 07-llm-transformers,   title: "LLMs & Transformers",            include: true,  minutes: 25, objectives: [], subunits: [] }
  - { slug: 08-chatgpt-usage,      title: "Using ChatGPT in practice",      include: true,  minutes: 15, objectives: [], subunits: [] }
  - { slug: 09-agents,             title: "Agents",                         include: true,  minutes: 15, objectives: [], subunits: [] }
  - { slug: 10-best-practices,     title: "Best practices for ML projects", include: true,  minutes: 15, objectives: [], subunits: [] }
```

- [ ] **Step 2: Create the support folders**

Run: `mkdir -p course/_global course/_sources && touch course/_global/.gitkeep course/_sources/.gitkeep`
Expected: no output, folders created.

- [ ] **Step 3: Verify the manifest parses as YAML**

Run: `python -c "import yaml,sys; d=yaml.safe_load(open('course/_manifest.yml',encoding='utf-8')); print(len(d['chapters']),'chapters')"`
Expected: `10 chapters`
(If `yaml` is missing: `python -m pip install pyyaml` once.)

- [ ] **Step 4: Write the README**

```markdown
# Machine Learning — An Applied Overview

Introductory ML overview for biomedical/clinical graduate students (UBEP, University of Padova).
~4h gross. From the T-P-E framework to classifiers, model selection, deep learning, LLMs and agents,
with an applied clinical slant.

## Structure (modular)

The course is chapter-based. The single source of truth is [`course/_manifest.yml`](course/_manifest.yml):
each chapter has an `include:` toggle and an estimated duration. Add or drop a module by editing one line.

Per-chapter artifacts live in `course/<NN-slug>/`: learning objectives, narrative arc, optional
sub-units, storyboard, and an evaluative item bank with rubrics. Global narrative spine and syllabus
live in `course/_global/`.

## Build (planned, Fase B)

Slides are being migrated from xaringan (`index.Rmd`) to Quarto revealjs. Once migrated:

- render slides: `quarto render` (only chapters with `include: true`);
- export student PDF: requires `quarto install chrome-headless-shell`.

## Authoring

Student-facing content is in **English**; teacher notes are in Italian. Math is written in `$...$`.
Writing any `course/**/*.md` auto-generates a self-contained `.html` (with rendered math) next to it.
```

- [ ] **Step 5: Commit**

```bash
git add course/_manifest.yml course/_global/.gitkeep course/_sources/.gitkeep README.md
git commit -m "Add modular course manifest, tree and README"
```

---

## Task 3: Math render library (`mdmath.py`) — TDD

**Files:**
- Create: `.claude/hooks/lib/mdmath.py`
- Create: `.claude/hooks/lib/theme.css`
- Test: `tests/hooks/test_mdmath.py`

- [ ] **Step 1: Write the theme CSS (embedded by pandoc)**

`.claude/hooks/lib/theme.css`:

```css
:root { --accent:#E8741E; --ink:#1a1a1a; --bg:#ffffff; --muted:#6b6b6b; --code:#f4f1ec; }
@media (prefers-color-scheme: dark){ :root{ --ink:#ececec; --bg:#16130f; --muted:#a89e92; --code:#211c16; } }
html{font-family:"Noto Sans",system-ui,Arial,sans-serif;color:var(--ink);background:var(--bg);line-height:1.5}
body{max-width:48rem;margin:2rem auto;padding:0 1.2rem}
h1,h2,h3{font-family:"Cabin","Noto Sans",sans-serif;line-height:1.2}
h1{color:var(--accent);border:0}
h2{border-bottom:2px solid var(--accent);padding-bottom:.2rem}
a{color:var(--accent)}
table{border-collapse:collapse;width:100%;margin:1rem 0}
th,td{border:1px solid #ddd;padding:.4rem .6rem;text-align:left}
th{background:var(--accent);color:#fff}
pre,code{font-family:"Source Code Pro",Consolas,monospace}
pre{background:var(--code);padding:.8rem;border-radius:6px;overflow:auto}
code{background:var(--code);padding:.1rem .3rem;border-radius:4px}
blockquote{border-left:4px solid var(--accent);margin:1rem 0;padding:.2rem 1rem;color:var(--muted)}
math{font-size:1.05em}
```

- [ ] **Step 2: Write the failing tests**

`tests/hooks/test_mdmath.py`:

```python
import shutil, sys
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "hooks" / "lib"))
import mdmath  # noqa: E402

pandoc_missing = shutil.which("pandoc") is None and not mdmath.find_pandoc()
skip_no_pandoc = pytest.mark.skipif(pandoc_missing, reason="pandoc not found")


def test_should_render_only_course_md():
    assert mdmath.should_render("course/01-introduction/narrative.md") is True
    assert mdmath.should_render("course/_global/spine.md") is True
    assert mdmath.should_render("README.md") is False
    assert mdmath.should_render("course/01-introduction/slides.qmd") is False
    assert mdmath.should_render(".claude/CLAUDE.md") is False


def test_derive_title_from_first_heading(tmp_path):
    p = tmp_path / "x.md"
    p.write_text("# Hello World\n\nbody\n", encoding="utf-8")
    assert mdmath.derive_title(p) == "Hello World"


def test_derive_title_falls_back_to_filename(tmp_path):
    p = tmp_path / "item_01_knn_mcq.md"
    p.write_text("no heading here\n", encoding="utf-8")
    assert mdmath.derive_title(p) == "item_01_knn_mcq"


@skip_no_pandoc
def test_render_inline_math_to_mathml(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\nThe loss is $E = mc^2$ here.\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    assert "<math" in html  # pandoc --mathml emits MathML elements


@skip_no_pandoc
def test_render_is_self_contained(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\n![x](nonexistent-but-ok.png)\n\ntext\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    # no external resource fetches (CDN scripts/styles)
    assert 'src="http' not in html
    assert 'href="http' not in html.split("<body")[0]  # head has no remote links


@skip_no_pandoc
def test_render_table_and_code(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\n```r\nx <- 1\n```\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    assert "<table" in html
    assert "<code" in html


@skip_no_pandoc
def test_write_sibling_html(tmp_path):
    p = tmp_path / "narrative.md"
    p.write_text("# Title\n\n$a_1$\n", encoding="utf-8")
    out = mdmath.write_sibling_html(p)
    assert out == p.with_suffix(".html")
    assert out.exists()
    assert "<math" in out.read_text(encoding="utf-8")
```

- [ ] **Step 3: Run the tests to confirm they fail**

Run: `python -m pytest tests/hooks/test_mdmath.py -v`
Expected: import error / FAIL — `mdmath` module not found yet (or functions undefined).

- [ ] **Step 4: Implement `mdmath.py`**

`.claude/hooks/lib/mdmath.py`:

```python
"""Render a course Markdown file to a self-contained HTML with rendered math.

Uses pandoc (bundled with Quarto) for robust Markdown + LaTeX handling:
--standalone --embed-resources inlines everything; --mathml turns $...$ into
offline MathML (no CDN, no JS). Glue is pure stdlib.
"""
from __future__ import annotations
import os, re, shutil, subprocess
from pathlib import Path

LIB = Path(__file__).resolve().parent
THEME_CSS = LIB / "theme.css"


def find_pandoc() -> str | None:
    """Locate pandoc: PATH, then the Quarto bundle on Windows."""
    p = shutil.which("pandoc")
    if p:
        return p
    candidates = [
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Quarto" / "bin" / "tools" / "pandoc.exe",
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Quarto" / "bin" / "tools" / "x86_64" / "pandoc.exe",
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    return None


def should_render(path: str) -> bool:
    """True only for Markdown files under course/ (POSIX-normalised)."""
    norm = str(path).replace("\\", "/")
    return "/course/" in f"/{norm}" and norm.endswith(".md")


def derive_title(md_path: Path) -> str:
    """First ATX H1, else the filename stem."""
    try:
        for line in Path(md_path).read_text(encoding="utf-8").splitlines():
            m = re.match(r"^#\s+(.+?)\s*$", line)
            if m:
                return m.group(1)
    except OSError:
        pass
    return Path(md_path).stem


def render_to_html(md_path: Path) -> str:
    """Return self-contained HTML for md_path. Raises if pandoc is unavailable."""
    pandoc = find_pandoc()
    if not pandoc:
        raise RuntimeError("pandoc not found (expected via Quarto install)")
    md_path = Path(md_path)
    cmd = [
        pandoc, str(md_path),
        "--from", "gfm+tex_math_dollars",
        "--to", "html5",
        "--standalone", "--embed-resources", "--mathml",
        "--metadata", f"title={derive_title(md_path)}",
        "--css", str(THEME_CSS),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                         cwd=str(md_path.parent))
    if res.returncode != 0:
        raise RuntimeError(f"pandoc failed: {res.stderr.strip()}")
    return res.stdout


def write_sibling_html(md_path: Path) -> Path:
    """Write <file>.html next to <file>.md; return its Path."""
    md_path = Path(md_path)
    out = md_path.with_suffix(".html")
    out.write_text(render_to_html(md_path), encoding="utf-8")
    return out
```

- [ ] **Step 5: Run the tests to confirm they pass**

Run: `python -m pytest tests/hooks/test_mdmath.py -v`
Expected: all PASS (or `test_render_*` SKIPPED only if pandoc truly absent — it should be present via Quarto).

- [ ] **Step 6: Commit**

```bash
git add .claude/hooks/lib/mdmath.py .claude/hooks/lib/theme.css tests/hooks/test_mdmath.py
git commit -m "Add math-capable self-contained HTML renderer (pandoc/MathML) with tests"
```

---

## Task 4: Hook entrypoint + registration

**Files:**
- Create: `.claude/hooks/md-to-html-math.py`
- Create: `.claude/settings.json`

- [ ] **Step 1: Write the hook entrypoint**

`.claude/hooks/md-to-html-math.py`:

```python
#!/usr/bin/env python3
"""PostToolUse hook: render course/**/*.md to a sibling self-contained .html.

Reads the hook payload JSON from stdin, extracts the written file path, and (if it
is a course Markdown file) regenerates its HTML. Never blocks: exits 0 on any error.
"""
import json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
import mdmath  # noqa: E402


def extract_path(payload: dict) -> str | None:
    ti = payload.get("tool_input") or {}
    return ti.get("file_path") or ti.get("path") or ti.get("notebook_path")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = extract_path(payload)
    if not path or not mdmath.should_render(path):
        return 0
    try:
        if Path(path).exists():
            out = mdmath.write_sibling_html(Path(path))
            print(f"[md-to-html-math] rendered {out}", file=sys.stderr)
    except Exception as e:  # non-blocking by design
        print(f"[md-to-html-math] skipped ({e})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Register the hook**

`.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/md-to-html-math.py\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Smoke-test the entrypoint end-to-end**

Run:
```bash
echo '{"tool_input":{"file_path":"course/_sources/_hooktest.md"}}' > /tmp/hp.json
printf '# Hook Test\n\nInline $\\alpha_1$ and a table:\n\n| a | b |\n|---|---|\n| 1 | 2 |\n' > course/_sources/_hooktest.md
python .claude/hooks/md-to-html-math.py < /tmp/hp.json
grep -c "<math" course/_sources/_hooktest.html
```
Expected: stderr line `rendered .../course/_sources/_hooktest.html`; final number `>= 1`.

- [ ] **Step 4: Clean the smoke-test artifacts**

Run: `rm -f course/_sources/_hooktest.md course/_sources/_hooktest.html`
Expected: removed.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/md-to-html-math.py .claude/settings.json
git commit -m "Add PostToolUse hook rendering course Markdown to math HTML"
```

---

## Task 5: Vault wiring (local, gitignored) + .gitignore

**Files:**
- Create: `.claude/settings.local.json`
- Modify/Create: `.gitignore`

- [ ] **Step 1: Read project-scaffold to prefer the canonical wiring**

Run: `cat ~/.claude/skills/*/SKILL.md 2>/dev/null | head -1; ls ~/.claude/skills | grep -i scaffold`
Then read the `project-scaffold` SKILL.md it points to. If `project-scaffold` can wire an **existing** project note, prefer it. Otherwise apply Step 2 manually (the vault project note `progetti/mlt-overview/` already exists from the planning session).

- [ ] **Step 2: Write the local settings (vault subfolder + least-privilege)**

`.claude/settings.local.json` (paths use the real vault location):

```json
{
  "additionalDirectories": [
    "C:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview",
    "C:/Users/corra/github/cl/obsidian-vault/_inbox"
  ],
  "permissions": {
    "deny": [
      "Read(C:/Users/corra/github/cl/obsidian-vault/aree/**)",
      "Read(C:/Users/corra/github/cl/obsidian-vault/journal/**)",
      "Read(C:/Users/corra/github/cl/obsidian-vault/risorse/**)",
      "Read(C:/Users/corra/github/cl/obsidian-vault/archivio/**)",
      "Read(C:/Users/corra/github/cl/obsidian-vault/meta/**)",
      "Read(C:/Users/corra/github/cl/obsidian-vault/.obsidian/**)"
    ]
  }
}
```

- [ ] **Step 3: Write/Update `.gitignore`**

Append (create if missing) — the course repo may go public, so the private-vault path and the heavy temporary deck must never be committed:

```gitignore
# Local-only Claude settings (vault paths — private)
.claude/settings.local.json
# Temporary workshop deck (to be deleted by the author)
docs/StorIA_2026.pptx
# Scratch
*.tmp.md
docs/_*.tmp*
# Quarto/pandoc build artifacts
/_site/
/_book/
/.quarto/
# Python
__pycache__/
.pytest_cache/
```

- [ ] **Step 4: Verify local settings are ignored**

Run: `git check-ignore .claude/settings.local.json docs/StorIA_2026.pptx`
Expected: both paths echoed back (ignored).

- [ ] **Step 5: Commit (.gitignore only — settings.local.json is ignored)**

```bash
git add .gitignore
git commit -m "Ignore local vault settings, temp deck and build artifacts"
```

---

## Task 6: Setup verifications (storia v2 + source diff)

**Files:** none (verification + notes).

- [ ] **Step 1: Verify storia-companion is v2 (itembank, not itembank-bloom)**

In the Claude session, confirm the available skill is `storia-companion:itembank` (v2: per-item `.md` + `items_valutativi.md` + 3-level rubric). If only `itembank-bloom` (v1) is invocable, update the plugin:
```
/plugin marketplace add c:/Users/corra/github/cordata/workshop-trieste
/plugin install storia-companion@storia-trieste-local
```
Expected: invoking "fammi un itembank" routes to `itembank` (markdown per-item), not the CSV v1.

- [ ] **Step 2: Diff index.Rmd vs index-full.Rmd to find mineable optional modules**

Run: `git diff --no-index -- index.Rmd index-full.Rmd | wc -l; diff <(grep -n "^# \|^## \|^---$" index.Rmd) <(grep -n "^# \|^## \|^---$" index-full.Rmd) | head -60`
Record in the vault project note (Stato corrente) which extra sections in `index-full.Rmd` are candidates for optional `include: false` modules.

- [ ] **Step 3: Note the stray `index.Rmd` frontmatter line for the author**

A spurious duplicate `---` was observed at the top of `index.Rmd` (breaks YAML). Do **not** silently change it: confirm with the author, then `git checkout -- index.Rmd` (if unwanted) or fix the frontmatter.

---

## Task 7: `mlt-scaffold` command + Fase 0 integration check

**Files:**
- Create: `.claude/commands/mlt-scaffold.md`

- [ ] **Step 1: Write the scaffold command (idempotent regeneration)**

`.claude/commands/mlt-scaffold.md`:

```markdown
---
description: (Re)generate the course tree and per-chapter folders from course/_manifest.yml without overwriting existing content.
---

Read `course/_manifest.yml`. For every chapter (regardless of `include:`), ensure the folder
`course/<slug>/` exists with empty subfolders `items/` and `rubriche/`. Never overwrite an existing
`.md`/`.qmd`/`.html`; only create what is missing and report a summary table (created vs already-present).
Do not touch `index.Rmd`, `index-full.Rmd`, `img/`, or `data/`. Student-facing stubs in English.
```

- [ ] **Step 2: Materialise per-chapter folders for included chapters**

Run:
```bash
python - <<'PY'
import yaml, pathlib
m = yaml.safe_load(open("course/_manifest.yml", encoding="utf-8"))
for ch in m["chapters"]:
    base = pathlib.Path("course")/ch["slug"]
    for sub in (base, base/"items", base/"rubriche"):
        sub.mkdir(parents=True, exist_ok=True)
    (base/".gitkeep").touch()
print("ensured", len(m["chapters"]), "chapter folders")
PY
```
Expected: `ensured 10 chapter folders`.

- [ ] **Step 3: Integration check — write a course .md with math and confirm the hook renders it**

Run:
```bash
printf '# Pilot check\n\nThe kNN rule assigns the class of the majority of the $k$ nearest points, where the distance is $d(x,y)=\\sqrt{\\sum_i (x_i-y_i)^2}$.\n\n- step one\n- step two\n' > course/01-introduction/_pilot.md
python -m pytest tests/hooks/test_mdmath.py -q
echo "--- now render via the lib directly ---"
python -c "import sys,pathlib; sys.path.insert(0,'.claude/hooks/lib'); import mdmath; print(mdmath.write_sibling_html(pathlib.Path('course/01-introduction/_pilot.md')))"
grep -c "<math" course/01-introduction/_pilot.html
```
Expected: tests pass; a `.html` path printed; math count `>= 2`.

- [ ] **Step 4: Visual verification (chrome-devtools)**

Open `course/01-introduction/_pilot.html` with the `chrome-devtools` MCP, screenshot at ~1100px width, and confirm: the H1 is orange, the two formulas render as proper math (square root visible), the list shows. Note any overflow. (This satisfies the global visual-verification rule.)

- [ ] **Step 5: Clean the pilot artifacts**

Run: `rm -f course/01-introduction/_pilot.md course/01-introduction/_pilot.html`
Expected: removed.

- [ ] **Step 6: Commit**

```bash
git add .claude/commands/mlt-scaffold.md course/*/.gitkeep
git commit -m "Add mlt-scaffold command and per-chapter folders"
```

---

## Self-Review

**Spec coverage (Fase 0 scope of the spec):**
- §3 conventions → Task 1 (CLAUDE.md). ✓
- §4 manifest + tree → Task 2. ✓
- §6.1 mlt-scaffold → Task 7. ✓
- §6.2 math render-hook → Tasks 3-4 (the spec's KaTeX/MathJax is realised as pandoc `--mathml`, offline; recorded as the chosen approach). ✓
- §9 vault wiring → Task 5 (settings.local.json + .gitignore; adaptive to project-scaffold). ✓
- §10 README → Task 2. ✓
- §11.1 storia v2 check + §14.2 index diff → Task 6. ✓
- Fase A/B skills (mlt-objectives, mlt-narrative, mlt-subunits, mlt-quarto-build, /mlt) → **out of scope for this plan**, deferred to separate Fase A / Fase B plans (per scope-check). Noted.

**Placeholder scan:** no TBD/TODO; every code/step has concrete content. ✓

**Type/name consistency:** `should_render`, `derive_title`, `render_to_html`, `write_sibling_html`, `find_pandoc` are defined in Task 3 and used identically in Tasks 4 and 7. ✓

**Known environment caveats:**
- `python` must resolve to Python 3 (Windows). If `python` is Py2/missing, use `py -3` consistently.
- `/tmp/hp.json` in Task 4 Step 3 is the Bash-tool POSIX tmp; on pure PowerShell use `$env:TEMP`.
- pandoc is expected via Quarto; `find_pandoc()` covers PATH + the Quarto bundle. If both fail, render tests SKIP (not fail) and the hook degrades to no-op (non-blocking).
