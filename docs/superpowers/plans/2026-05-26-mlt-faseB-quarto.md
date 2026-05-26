# MLT Toolkit — Fase B (Quarto build) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the renovated Quarto **revealjs** deck for the MLT course **from the Fase A content artifacts** (storyboard-driven), with an orange theme, modular per the manifest, exportable to student PDF, and visually verified.

**Architecture (important reframing):** This is **not** a mechanical migration of `index.Rmd`. Fase A redesigns the flow, so the slides are **regenerated from the new flow**: each chapter's `course/<slug>/storyboard.md` (6 frames: Funzione / Visual / Testo a video / Voce docente) is the **blueprint** for that chapter's slides, with the narrative arc and objectives as supporting context. The old `index.Rmd` / `index-full.Rmd` and `img/` are treated as an **asset & content source** (reusable figures, formulas, explanations) — mined, not migrated. A master `slides/slides.qmd` includes only the chapters with `include: true` (toggle from the manifest), so the deck stays modular.

**Tech Stack:** Quarto 1.9.37 (revealjs), pandoc (bundled), `chrome-headless-shell` (for PDF), Python+pytest (the manifest→master generator), chrome-devtools MCP (visual QA).

**Reference spec:** `docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md` (§6.6). **Depends on:** Fase A (storyboards/narrative/objectives per chapter).

---

## Split: B1 (independent, build now) vs B2 (needs Fase A content)

- **B1** — orange revealjs theme + the tested `manifest → master .qmd` generator. Depends only on the manifest; buildable before any content exists.
- **B2** — the `mlt-quarto-build` skill that assembles each chapter's `slides/chapters/<slug>.qmd` from its storyboard, plus render + PDF + visual QA. Requires Fase A artifacts for the chapters being built.

---

## File Structure

- Create `slides/theme.scss` — orange revealjs theme (Quarto `scss:defaults`/`scss:rules`).
- Create `.claude/skills/lib/quartoyml.py` — `enabled_slugs(m)`, `build_slides_master(m) -> str` (master `.qmd` with revealjs header + `{{< include >}}` per enabled chapter).
- Test `tests/skills/test_quartoyml.py`.
- Create `.claude/skills/mlt-quarto-build/SKILL.md` — storyboard→slides assembler (B2).
- (B2 runtime) `slides/slides.qmd` (generated master) + `slides/chapters/<slug>.qmd` (generated per chapter).

---

## Task B1.1: Orange revealjs theme

**Files:**
- Create: `slides/theme.scss`

- [ ] **Step 1: Write the theme**

`slides/theme.scss` (palette continues `xaringan-themer.css`; orange is the dominant accent):

```scss
/*-- scss:defaults --*/
$body-bg: #ffffff;
$body-color: #1a1a1a;
$link-color: #E8741E;                 // orange accent
$selection-bg: #F9C99B;
$presentation-heading-font: "Cabin", "Noto Sans", sans-serif;
$presentation-font-size-root: 30px;
$font-family-sans-serif: "Noto Sans", system-ui, Arial, sans-serif;
$font-family-monospace: "Source Code Pro", Consolas, monospace;
$presentation-heading-color: #C75A12; // darker orange for headings
$code-block-bg: #f4f1ec;

/*-- scss:rules --*/
.reveal h1, .reveal h2 { letter-spacing: -0.01em; }
.reveal .slide-number { color: #E8741E; }
.reveal section img { border: 0; box-shadow: none; }
.reveal blockquote { border-left: 4px solid #E8741E; }
.reveal .title-slide h1 { color: #E8741E; }
.reveal table th { background: #E8741E; color: #fff; }
```

- [ ] **Step 2: Verify Quarto accepts the theme on a throwaway deck**

Run:
```bash
printf -- '---\ntitle: "Theme test"\nformat:\n  revealjs:\n    theme: [default, theme.scss]\n---\n\n## Slide\n\nInline $a_1$ and a point.\n' > slides/_themetest.qmd
quarto render slides/_themetest.qmd --to revealjs 1>/dev/null 2>slides/_themetest.err; echo "exit=$?"; head -3 slides/_themetest.err
test -f slides/_themetest.html && echo "rendered OK"
rm -f slides/_themetest.qmd slides/_themetest.html slides/_themetest.err; rm -rf slides/_themetest_files
```
Expected: `exit=0`, `rendered OK` (KaTeX/MathJax handled by Quarto's revealjs math).

- [ ] **Step 3: Commit**

```bash
git add slides/theme.scss
git commit -m "Add orange revealjs theme for the MLT deck"
```

---

## Task B1.2: Manifest → master deck generator (`quartoyml.py`) — TDD

**Files:**
- Create: `.claude/skills/lib/quartoyml.py`
- Test: `tests/skills/test_quartoyml.py`

- [ ] **Step 1: Write the failing tests**

`tests/skills/test_quartoyml.py`:

```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "skills" / "lib"))
import quartoyml  # noqa: E402

M = {
    "course": {"title": "MLT", "slug": "mlt", "language": "en"},
    "chapters": [
        {"slug": "01-a", "title": "A", "include": True},
        {"slug": "02-b", "title": "B", "include": False},
        {"slug": "03-c", "title": "C", "include": True},
    ],
}


def test_enabled_slugs_order_and_filter():
    assert quartoyml.enabled_slugs(M) == ["01-a", "03-c"]


def test_master_includes_only_enabled_in_order():
    out = quartoyml.build_slides_master(M)
    assert "{{< include chapters/01-a.qmd >}}" in out
    assert "{{< include chapters/03-c.qmd >}}" in out
    assert "02-b" not in out
    assert out.index("01-a.qmd") < out.index("03-c.qmd")


def test_master_has_revealjs_header_and_theme():
    out = quartoyml.build_slides_master(M)
    assert out.startswith("---")
    assert "format:" in out and "revealjs:" in out
    assert "theme:" in out and "theme.scss" in out
    assert 'title: "MLT"' in out
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python -m pytest tests/skills/test_quartoyml.py -q`
Expected: ImportError — `quartoyml` not found.

- [ ] **Step 3: Implement `quartoyml.py`**

`.claude/skills/lib/quartoyml.py`:

```python
"""Generate the master revealjs deck (slides/slides.qmd) from the manifest.

Only chapters with include: true are listed, in manifest order, via Quarto
include shortcodes. Per-chapter slides/chapters/<slug>.qmd are produced by the
mlt-quarto-build skill (Fase B2) from each chapter's storyboard.
"""
from __future__ import annotations


def enabled_slugs(m: dict) -> list[str]:
    return [c["slug"] for c in m.get("chapters", []) if c.get("include")]


def build_slides_master(m: dict) -> str:
    course = m.get("course", {})
    title = course.get("title", "Course")
    header = (
        "---\n"
        f'title: "{title}"\n'
        "format:\n"
        "  revealjs:\n"
        "    theme: [default, theme.scss]\n"
        "    slide-number: true\n"
        "    incremental: false\n"
        "    html-math-method: mathjax\n"
        "---\n\n"
    )
    body = "\n".join(f"{{{{< include chapters/{s}.qmd >}}}}" for s in enabled_slugs(m))
    return header + body + "\n"
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_quartoyml.py -q`
Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/lib/quartoyml.py tests/skills/test_quartoyml.py
git commit -m "Add manifest->master revealjs generator with tests"
```

---

## Task B2.1: `mlt-quarto-build` skill (storyboard → slides) — needs Fase A

**Files:**
- Create: `.claude/skills/mlt-quarto-build/SKILL.md`

- [ ] **Step 1: Write the skill**

`.claude/skills/mlt-quarto-build/SKILL.md`:

```markdown
---
name: mlt-quarto-build
description: Assemble a chapter's Quarto revealjs slides FROM its storyboard (not by migrating index.Rmd), reusing images and formulas from the old deck, then (re)generate the modular master from the manifest. Use for "build slides for chapter X", "genera le slide Quarto", "render the deck", or /mlt --phase quarto.
---

# mlt-quarto-build

Generate the new revealjs slides for ONE chapter from the Fase A artifacts. The flow follows the **storyboard**,
not the old slide order. `index.Rmd` / `index-full.Rmd` and `img/` are an ASSET source. Student-facing text in
**English**; speaker notes (Voce docente) in **Italian**. Math in `$...$`.

## Collect

- Chapter slug/title/minutes from `course/_manifest.yml`.
- `course/<slug>/storyboard.md` (REQUIRED — the 6-frame blueprint), plus `narrative.md` and `objectives.md`.
- Reusable assets: scan `img/` for figures matching the chapter's topics; scan `index.Rmd`/`index-full.Rmd`
  for reusable formulas/explanations for the same concept.

## Produce `slides/chapters/<slug>.qmd`

- One section title slide: `# <Chapter title>`.
- For each storyboard frame (Hook visivo · Contesto · Sfida/Dati · Nodo/Impatto · Metodo/Soluzione · Payoff/Domanda finale):
  - a slide `## <short frame label>`;
  - **Testo a video** → the visible slide content (concise, English; keep math in `$...$`);
  - **Visual** → if a matching figure exists in `img/`, embed it `![](../../img/<file>)`; otherwise insert a
    placeholder image line plus an HTML comment with an English image-generation prompt taken from the storyboard;
  - **Voce docente** → speaker notes block `::: {.notes}` … `:::` (Italian);
  - the **Payoff/Domanda finale** frame carries the chapter's pre-hook (from `narrative.md`) toward the next chapter.

## Regenerate the modular master + render

1. Write/refresh `slides/slides.qmd` using `quartoyml.build_slides_master(manifest.load())` (only enabled chapters).
2. Render: `quarto render slides/slides.qmd --to revealjs`.
3. **Visual QA** (mandatory): open the rendered chapter with chrome-devtools at 1920×1080 and at a narrow
   viewport; check overflow, cut-off images, contrast, math rendering. Fix and re-render until clean.

## Output

`slides/chapters/<slug>.qmd` + refreshed `slides/slides.qmd`. Report and stop at the gate.
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `python -c "t=open('.claude/skills/mlt-quarto-build/SKILL.md',encoding='utf-8').read(); assert t.startswith('---') and 'name: mlt-quarto-build' in t; print('ok')"`
Expected: `ok`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/mlt-quarto-build/SKILL.md
git commit -m "Add mlt-quarto-build skill (storyboard-driven slide assembly)"
```

---

## Task B2.2: PDF export setup + pilot render (needs a built chapter)

**Files:** none.

- [ ] **Step 1: Install the headless browser for PDF (one-time)**

Run: `quarto install chrome-headless-shell`
Expected: success (Quarto downloads chrome-headless-shell).

- [ ] **Step 2: Build + render the pilot chapter**

After Fase A produced `course/01-introduction/storyboard.md`, invoke the `mlt-quarto-build` skill for
`01-introduction`. Confirm `slides/chapters/01-introduction.qmd` and `slides/slides.qmd` exist and
`quarto render slides/slides.qmd --to revealjs` succeeds.

- [ ] **Step 3: Export PDF**

Run: `quarto render slides/slides.qmd --to pdf`
Expected: `slides/slides.pdf` produced (revealjs→PDF via chrome-headless-shell).

- [ ] **Step 4: Visual QA (mandatory)**

Open the rendered revealjs and the PDF with chrome-devtools at 1920×1080; inspect the pilot chapter for
overflow, cut-off figures, low contrast, math rendering. Iterate until clean (global visual-verification rule).

- [ ] **Step 5: Update README build section + commit**

```bash
git add slides/ README.md
git commit -m "Build pilot Quarto slides for 01-introduction + PDF export"
```

---

## Self-Review

**Spec coverage (§6.6):**
- xaringan→Quarto: reframed as storyboard-driven regeneration (B2.1) with `index.Rmd`/`img/` as asset source. ✓
- `_quarto.yml`/master from manifest, only enabled chapters: B1.2 (`build_slides_master`). ✓
- Orange theme from `xaringan-themer.css`: B1.1. ✓
- PDF export (`chrome-headless-shell`): B2.2. ✓
- Visual verification (chrome-devtools): B2.1 Step 3 + B2.2 Step 4. ✓

**Placeholder scan:** none — code/tests/skill body are concrete. ✓

**Type/name consistency:** `enabled_slugs`, `build_slides_master` defined in B1.2 and used in B2.1 Step 1. `manifest.load` reused from Fase A. ✓

**Dependency note:** B1 (theme + generator) is independent and built first; B2 requires Fase A storyboards for the target chapters and a session that can see the new skill (reload).
