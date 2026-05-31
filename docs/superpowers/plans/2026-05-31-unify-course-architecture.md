# Unified Course Architecture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `mlt-overview` into one repo / three modules (theory overview + practice basic + advanced) with a unified identity, reproducible legacy archive, shared brand styling, per-module renv, and a Release-asset distribution path — without reshuffling the tree or migrating the `/mlt` tooling.

**Architecture:** The physical layout stays (`course/` + `slides/` + `img/` for the overview; `workshops/mlt-r-*` for the two R workshops). Coherence is added *around* the tree: a hub README, a shared `styles/_brand.scss` SCSS partial referenced by every deck, a reproducible `_archive/legacy-xaringan/` (a frozen, restorable xaringan project), and a workshop-scoped distribution pipeline (a tested Python builder + a `/mlt-dist` command + a reminder hook). Per the spec, logic lives in small tested Python scripts (`scripts/`), while file moves / config / docs are verified by command + visual inspection.

**Tech Stack:** Python 3 (stdlib only: `zipfile`, `shutil`, `argparse`, `re`, `fnmatch`, `pathlib`), pytest (existing `tests/skills/` harness), Quarto reveal.js + dart-sass theming, R + renv, git, Claude Code hooks/commands.

**Spec:** [docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md](../specs/2026-05-31-unified-course-architecture-design.md)

---

## File Structure (created / modified)

**Created:**
- `scripts/archive_legacy_assets.py` — classify + move/copy the assets the xaringan sources reference (move-only-xaringan / copy-shared).
- `scripts/build_workshop_zip.py` — build a source-only distributable ZIP: prune, vendor brand SCSS, zip.
- `tests/skills/test_archive_legacy_assets.py` — unit tests for `extract_refs` + `classify`.
- `tests/skills/test_build_workshop_zip.py` — unit tests for `is_excluded` + `vendor_brand` + `build_zip`.
- `tests/skills/test_remind_workshop_dist.py` — unit tests for the reminder hook predicate.
- `styles/_brand.scss` — single source of truth for palette + fonts (`scss:defaults` + shared `scss:rules`).
- `.claude/hooks/remind-workshop-dist.py` — non-blocking PostToolUse reminder to regenerate dist.
- `.claude/commands/mlt-dist.md` — slash-command wrapping `build_workshop_zip.py`.
- `_archive/legacy-xaringan/` — frozen xaringan project (sources + renv + vendored assets + `.Rproj`).
- `README.md` — repo-root hub (currently overview-only; rewritten as the course hub).

**Modified:**
- `course/_manifest.yml` — repoint `base_source` to the archived `index.Rmd`.
- `.claude/skills/**` (mlt-quarto-build) — repoint the index-quarry input path to the archive.
- `slides/theme.scss` — strip the brand defaults; reference `../styles/_brand.scss`; keep overview rules.
- `slides/slides.qmd` — `theme:` list includes `../styles/_brand.scss`.
- `workshops/mlt-r-basic/slides/_quarto.yml` — remove `chalkboard`; `theme:` list references `../../../styles/_brand.scss`.
- `workshops/mlt-r-basic/slides/theme.scss` — strip duplicated brand; keep workshop rules.
- `.claude/CLAUDE.md` — absorb the EN/IT language rule as the universal contract; add 3-module map.
- `workshops/mlt-r-basic/CLAUDE.md` — trim to the R-authoring delta + pointer to root.
- `workshops/mlt-r-basic/README.md` — add "part of the MLT course →" pointer; switch `use_course()` to the Release URL.
- `.claude/settings.json` — register the reminder hook.
- `.gitignore` — ignore `dev/` and `dist/`.
- root renv (`renv.lock` / `.Rprofile` / `renv/`) — re-snapshot to post-Quarto footprint, or retire.

**Out of scope (Future Work — see end):** scaffolding `workshops/mlt-r-advanced/`; severing the `index.Rmd` quarry dependency; minting the Bitly short link.

---

## Conventions for every task

- Run pytest from the repo root: `python -m pytest tests/skills/<file>.py -v`
- The repo root is `c:\Users\corra\github\cl\mlt-overview`. All paths below are relative to it unless absolute.
- Commit messages in English, one logical change per commit, ending with the Co-Authored-By trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- You are on branch `unify-course-architecture` (already created). Stay on it.

---

## Task A: Reproducible legacy archive

**Files:**
- Create: `scripts/archive_legacy_assets.py`, `tests/skills/test_archive_legacy_assets.py`
- Create: `_archive/legacy-xaringan/` (populated by git mv + script + copies)
- Modify: `course/_manifest.yml`, the mlt-quarto-build skill file, `.gitignore`

### A.1 — Freeze the xaringan R environment into the archive (before any move)

- [ ] **Step 1: Create the archive dir and copy the current root renv environment into it**

Run:
```bash
mkdir -p _archive/legacy-xaringan/renv
cp renv.lock _archive/legacy-xaringan/renv.lock
cp .Rprofile _archive/legacy-xaringan/.Rprofile
cp renv/activate.R _archive/legacy-xaringan/renv/activate.R
cp renv/settings.json _archive/legacy-xaringan/renv/settings.json 2>/dev/null || true
```
(On Windows PowerShell: `New-Item -ItemType Directory -Force _archive/legacy-xaringan/renv` then `Copy-Item`.)

- [ ] **Step 2: Create the archive's `.Rproj` so RStudio treats it as a project root**

Create `_archive/legacy-xaringan/legacy-xaringan.Rproj`:
```
Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

RnwWeave: knitr
LaTeX: pdfLaTeX
```

- [ ] **Step 3: Add a README marker explaining the archive is frozen**

Create `_archive/legacy-xaringan/README.md`:
```markdown
# Legacy xaringan deck (frozen)

This is the pre-Quarto xaringan version of the MLT overview, kept reproducible.

To rebuild it:

1. Open `legacy-xaringan.Rproj` in RStudio (activates this folder's own `renv`).
2. `renv::restore()` to install the pinned package set.
3. Knit `index.Rmd`.

It is no longer maintained. The live course is the Quarto build at the repo root
(`course/` + `slides/`). See `docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`.
```

- [ ] **Step 4: Commit**

```bash
git add _archive/legacy-xaringan/
git commit -m "Freeze xaringan renv + Rproj into _archive/legacy-xaringan"
```

### A.2 — Asset classifier: move-only-xaringan, copy-shared

- [ ] **Step 1: Write the failing test**

Create `tests/skills/test_archive_legacy_assets.py`:
```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import archive_legacy_assets as ala  # noqa: E402


def test_extract_refs_finds_markdown_html_url_and_knitr():
    text = (
        "![cap](img/MLvsTrad.png)\n"
        '<img src="img/Hierarchy_of_Evidence.png">\n'
        "background-image: url(img/100M-users.png)\n"
        'knitr::include_graphics("img/agents.gif")\n'
        '<link rel="stylesheet" href="xaringan-themer.css">\n'
        "[external](https://example.com/x.png)\n"
    )
    refs = ala.extract_refs(text)
    assert "img/MLvsTrad.png" in refs
    assert "img/Hierarchy_of_Evidence.png" in refs
    assert "img/100M-users.png" in refs
    assert "img/agents.gif" in refs
    assert "xaringan-themer.css" in refs
    # remote URLs are dropped
    assert "https://example.com/x.png" not in refs


def test_classify_splits_shared_and_xaringan_only():
    referenced = {"img/MLvsTrad.png", "img/old_only.png", "xaringan-themer.css"}
    live_blob = "see ![](../img/MLvsTrad.png) in a chapter and url(../img/other.png)"
    to_move, to_copy = ala.classify(referenced, live_blob)
    # MLvsTrad.png basename appears in the live blob -> shared -> copy
    assert "img/MLvsTrad.png" in to_copy
    # old_only.png + the xaringan css are not in the live blob -> move
    assert to_move == {"img/old_only.png", "xaringan-themer.css"}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/skills/test_archive_legacy_assets.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'archive_legacy_assets'`.

- [ ] **Step 3: Write the implementation**

Create `scripts/archive_legacy_assets.py`:
```python
#!/usr/bin/env python3
"""Classify and relocate the assets referenced by the legacy xaringan sources.

Assets referenced ONLY by the xaringan sources (index.Rmd / index-full.Rmd) are
git-moved into _archive/legacy-xaringan/ (decluttering img/). Assets also used by
the live tree (course/ slides/ workshops/) are copied (keeping the live build intact).

Usage:
  python scripts/archive_legacy_assets.py            # report only
  python scripts/archive_legacy_assets.py --apply    # perform git mv + copies
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ARCHIVE = Path("_archive/legacy-xaringan")
XARINGAN_SOURCES = [Path("index.Rmd"), Path("index-full.Rmd")]
LIVE_DIRS = [Path("course"), Path("slides"), Path("workshops")]
LIVE_TEXT_SUFFIXES = {".qmd", ".rmd", ".md", ".html", ".scss", ".css", ".yml", ".yaml"}

_REF_RE = re.compile(
    r'!\[[^\]]*\]\(([^)\s]+)\)'           # markdown image
    r'|src\s*=\s*["\']([^"\']+)["\']'      # html src
    r'|href\s*=\s*["\']([^"\']+)["\']'     # html href (css link)
    r'|url\(\s*["\']?([^)"\']+)["\']?\s*\)'  # css url()
    r'|include_graphics\(\s*["\']([^"\']+)["\']',  # knitr
    re.IGNORECASE,
)
_ASSET_EXT_RE = re.compile(r"\.(png|jpe?g|gif|svg|webp|css|mp4|webm|pdf)$", re.IGNORECASE)


def extract_refs(text: str) -> set[str]:
    """Local asset paths referenced in `text` (remote URLs and anchors dropped)."""
    refs: set[str] = set()
    for m in _REF_RE.finditer(text):
        for g in m.groups():
            if not g:
                continue
            g = g.strip().strip("'\"")
            if "://" in g or g.startswith("#") or g.startswith("data:"):
                continue
            if _ASSET_EXT_RE.search(g):
                refs.add(g.lstrip("./"))
    return refs


def classify(referenced: set[str], live_blob: str) -> tuple[set[str], set[str]]:
    """Split referenced assets into (to_move, to_copy).

    to_copy = basename also present in the live tree text; to_move = xaringan-only.
    """
    to_move: set[str] = set()
    to_copy: set[str] = set()
    for rel in referenced:
        base = rel.rsplit("/", 1)[-1]
        if base and base in live_blob:
            to_copy.add(rel)
        else:
            to_move.add(rel)
    return to_move, to_copy


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def _live_blob(root: Path) -> str:
    chunks = []
    for d in LIVE_DIRS:
        base = root / d
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if p.is_file() and p.suffix.lower() in LIVE_TEXT_SUFFIXES:
                chunks.append(_read(p))
    return "\n".join(chunks)


def _git_mv(root: Path, rel: str) -> None:
    src = root / rel
    dst = ARCHIVE_ABS(root) / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "mv", str(src), str(dst)], cwd=str(root), check=True)


def _copy(root: Path, rel: str) -> None:
    src = root / rel
    dst = ARCHIVE_ABS(root) / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def ARCHIVE_ABS(root: Path) -> Path:
    return root / ARCHIVE


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="perform git mv + copies")
    ap.add_argument("--root", default=".", help="repo root")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()

    referenced: set[str] = set()
    for src in XARINGAN_SOURCES:
        referenced |= extract_refs(_read(root / src))

    blob = _live_blob(root)
    to_move, to_copy = classify(referenced, blob)
    # never move/copy something that doesn't exist on disk
    to_move = {r for r in to_move if (root / r).exists()}
    to_copy = {r for r in to_copy if (root / r).exists()}

    print(f"to_move (xaringan-only): {len(to_move)}", file=sys.stderr)
    print(f"to_copy (shared):        {len(to_copy)}", file=sys.stderr)
    for r in sorted(to_move):
        print(f"  MOVE {r}", file=sys.stderr)
    for r in sorted(to_copy):
        print(f"  COPY {r}", file=sys.stderr)

    if args.apply:
        for r in sorted(to_copy):
            _copy(root, r)
        for r in sorted(to_move):
            _git_mv(root, r)
        print("applied.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python -m pytest tests/skills/test_archive_legacy_assets.py -v`
Expected: PASS (2 passed).

- [ ] **Step 5: Commit**

```bash
git add scripts/archive_legacy_assets.py tests/skills/test_archive_legacy_assets.py
git commit -m "Add legacy-asset classifier (move xaringan-only, copy shared)"
```

### A.3 — Move the xaringan sources and run the classifier

- [ ] **Step 1: Dry-run the classifier and read the MOVE/COPY report**

Run: `python scripts/archive_legacy_assets.py`
Expected: prints `to_move`/`to_copy` counts and the per-asset list to stderr. Eyeball that nothing in `to_move` is something the live course still needs (if it is, it would have matched the live blob — but confirm no surprises).

- [ ] **Step 2: Apply the classifier (moves/copies assets into the archive)**

Run: `python scripts/archive_legacy_assets.py --apply`
Expected: `applied.` Assets relocated under `_archive/legacy-xaringan/` preserving their `img/...` subpaths.

- [ ] **Step 3: Move the xaringan source files themselves**

Run:
```bash
git mv index.Rmd        _archive/legacy-xaringan/index.Rmd
git mv index-full.Rmd   _archive/legacy-xaringan/index-full.Rmd
git mv index.html       _archive/legacy-xaringan/index.html
git mv index_files      _archive/legacy-xaringan/index_files
git mv xaringan-themer.css _archive/legacy-xaringan/xaringan-themer.css
```
(`xaringan-themer.css` may already have been moved by the classifier — if `git mv` errors "does not exist", skip it.)

- [ ] **Step 4: Verify every asset `index.Rmd` references now resolves inside the archive**

Run:
```bash
python - <<'PY'
import sys; from pathlib import Path
sys.path.insert(0, "scripts"); import archive_legacy_assets as ala
arc = Path("_archive/legacy-xaringan")
refs = ala.extract_refs((arc/"index.Rmd").read_text(encoding="utf-8", errors="replace"))
refs |= ala.extract_refs((arc/"index-full.Rmd").read_text(encoding="utf-8", errors="replace"))
missing = [r for r in sorted(refs) if not (arc/r).exists()]
print("MISSING:", missing)
assert not missing, f"{len(missing)} referenced assets are not in the archive"
print("OK: all referenced assets resolve inside the archive")
PY
```
Expected: `OK: all referenced assets resolve inside the archive`. If any are MISSING, copy them in manually (`cp img/<name> _archive/legacy-xaringan/img/<name>`) and re-run.

- [ ] **Step 5: Commit**

```bash
git add -A _archive/legacy-xaringan/ img/
git commit -m "Archive legacy xaringan sources + their assets (move-only / copy-shared)"
```

### A.4 — Repoint the manifest + mlt-quarto-build to the archived quarry, and gitignore dev/

- [ ] **Step 1: Find the current base_source reference in the manifest**

Run: `python -m pytest -q 2>NUL & findstr /n "base_source index.Rmd" course\_manifest.yml`
(or simply open `course/_manifest.yml`). Locate the `base_source:` field and any `index-full.Rmd` reference.

- [ ] **Step 2: Repoint the manifest**

In `course/_manifest.yml`, change the source paths to the archived location, e.g.:
```yaml
base_source: _archive/legacy-xaringan/index.Rmd
optional_source: _archive/legacy-xaringan/index-full.Rmd
```
(Match the existing key names — only the path value changes.)

- [ ] **Step 3: Repoint mlt-quarto-build's index-quarry input**

Find the skill's references to `index.Rmd` / `index-full.Rmd`:
Run: `findstr /s /n /i "index.Rmd index-full.Rmd" .claude\skills\*`
Update each occurrence to `_archive/legacy-xaringan/index.Rmd` / `_archive/legacy-xaringan/index-full.Rmd`.

- [ ] **Step 4: Gitignore dev/ (QA screenshots) and confirm it stops being tracked going forward**

Append to `.gitignore`:
```gitignore
# Transient QA screenshots — not a deliverable
dev/
```
(Leave already-committed `dev/` history intact; this only stops future churn. If you want it out of the working tree too, that is a separate explicit decision — not done here.)

- [ ] **Step 5: Verify the manifest still loads**

Run: `python -m pytest tests/skills/test_manifest.py -v`
Expected: PASS (unchanged — the loader doesn't validate `base_source`, but this confirms no YAML syntax was broken).

- [ ] **Step 6: Commit**

```bash
git add course/_manifest.yml .claude/skills .gitignore
git commit -m "Repoint base_source + mlt-quarto-build quarry to _archive; gitignore dev/"
```

---

## Task B: Shared brand SCSS partial (overview side)

**Files:**
- Create: `styles/_brand.scss`
- Modify: `slides/theme.scss`, `slides/slides.qmd`

### B.1 — Extract the brand partial

- [ ] **Step 1: Read the current overview theme to capture exact token values**

Open `slides/theme.scss`. Note the existing values: link `#E8741E`, heading `#C75A12`, selection `#F9C99B`, inverse bg `#1F4257`, inverse fg `#f4f1ec`, fonts Cabin / Noto Sans / Source Code Pro, base size `30px`.

- [ ] **Step 2: Create `styles/_brand.scss` with the shared defaults + brand rules**

Create `styles/_brand.scss`:
```scss
/*-- scss:defaults --*/
// === MLT shared brand — single source of truth (overview + workshops) ===
$brand-orange:      #E8741E;
$brand-orange-dark: #C75A12;
$brand-orange-tint: #F9C99B;
$brand-teal:        #1F4257;
$brand-ink:         #1a1a1a;
$brand-paper:       #ffffff;
$brand-light:       #f4f1ec;

$body-bg:    $brand-paper;
$body-color: $brand-ink;
$link-color: $brand-orange;
$selection-bg: $brand-orange-tint;

$font-family-sans-serif: "Noto Sans", system-ui, Arial, sans-serif;
$font-family-monospace:  "Source Code Pro", Consolas, monospace;
$presentation-heading-font: "Cabin", "Noto Sans", sans-serif;
$presentation-heading-color: $brand-orange-dark;
$presentation-font-size-root: 30px;

/*-- scss:rules --*/
// Shared brand accents reused by every deck.
.reveal h1, .reveal h2, .reveal h3 { color: $brand-orange-dark; }
.reveal blockquote { border-left: 4px solid $brand-orange; }
.reveal table thead th { background: $brand-orange; color: #fff; }
.reveal .slide-number { color: $brand-orange; }
```

- [ ] **Step 3: Slim `slides/theme.scss` to overview-only rules**

Edit `slides/theme.scss`: delete the brand defaults/rules now in the partial (colors, fonts, table/blockquote/heading accents) and keep only overview-specific rules (e.g. the `.inverse` dark-title slide styling, `.center`, `.smaller`). The file should no longer redeclare the palette/fonts.

- [ ] **Step 4: Add the brand partial to the deck's theme list**

In `slides/slides.qmd` front matter, change the theme to include the partial first:
```yaml
format:
  revealjs:
    theme: [default, ../styles/_brand.scss, theme.scss]
```

- [ ] **Step 5: Render and visually verify the overview deck is unchanged**

Run: `quarto render slides/slides.qmd`
Then open `slides/slides.html` and **visually verify** (chrome-devtools MCP at 1920×1080 + a narrow viewport) that colors, fonts, headings, tables, blockquotes, inverse title slides render exactly as before. This is the mandatory visual gate — the build "succeeding" is not enough.

- [ ] **Step 6: Commit**

```bash
git add styles/_brand.scss slides/theme.scss slides/slides.qmd
git commit -m "Extract shared brand SCSS partial; overview deck references it"
```

---

## Task C: Slim or retire the overview/root renv

**Files:**
- Modify (or remove): `renv.lock`, `.Rprofile`, `renv/`, `mlt-overview.Rproj`

### C.1 — Decide: does the overview execute R?

- [ ] **Step 1: Detect executable R chunks in overview sources**

Run: `findstr /s /n /r "```{r" slides\*.qmd course\*.qmd course\**\*.qmd`
(or `grep -rEn '```\{r' slides course`)
Expected: a list of executable R chunks, or none.

- [ ] **Step 2: Branch on the result**

- **If NO executable R chunks** → proceed to **C.2 (retire)**.
- **If there ARE executable R chunks** → proceed to **C.3 (slim)**.

### C.2 — Retire the root renv (overview is pure-Quarto)

- [ ] **Step 1: Remove the root renv machinery (it is already frozen in the archive)**

Run:
```bash
git rm -r renv renv.lock .Rprofile
git rm mlt-overview.Rproj
```
(The xaringan-era copies live safely in `_archive/legacy-xaringan/` — Task A.1. The history is preserved.)

- [ ] **Step 2: Verify the overview still renders without R**

Run: `quarto render slides/slides.qmd`
Expected: render succeeds. Visually verify `slides/slides.html`.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Retire root renv: overview is a pure-Quarto (R-free) build"
```

Then **skip C.3** and continue to Task D.

### C.3 — Slim the root renv (overview runs some R)

- [ ] **Step 1: Re-snapshot to the real footprint**

In R at the repo root:
```r
renv::snapshot(type = "implicit", prompt = FALSE)
```
This rewrites `renv.lock` to only the packages the overview `.qmd` actually load — dropping `xaringan`/`countdown`/`servr`.

- [ ] **Step 2: Verify the overview renders with the slimmed env**

Run: `quarto render slides/slides.qmd`
Expected: render succeeds. Visually verify `slides/slides.html`.

- [ ] **Step 3: Commit**

```bash
git add renv.lock
git commit -m "Slim root renv to post-Quarto footprint (drop xaringan deps)"
```

---

## Task D: Docs — hub README + CLAUDE.md dedup

**Files:**
- Modify: `README.md`, `.claude/CLAUDE.md`, `workshops/mlt-r-basic/CLAUDE.md`, `workshops/mlt-r-basic/README.md`

### D.1 — Root README becomes the course hub

- [ ] **Step 1: Rewrite `README.md` as the 3-module hub**

Replace `README.md` with (adjust the one-line module descriptions to taste, keep the structure):
```markdown
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
- `docs/superpowers/` — design specs and implementation plans.

## Authoring

See `.claude/CLAUDE.md` for the universal conventions (language, math, lists, visual
verification) and each workshop's `CLAUDE.md` for its R-authoring rules.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "Rewrite root README as the three-module course hub"
```

### D.2 — Absorb the language rule + 3-module map into the universal CLAUDE.md

- [ ] **Step 1: Confirm the root `.claude/CLAUDE.md` owns the language rule**

It already states the EN/IT rule. Add a short "Course = 3 modules" note so it is the canonical map. Append under the conventions:
```markdown
## Architettura (3 moduli)

Un repo, un corso, tre moduli: **teoria/overview** (`course/` + `slides/`),
**pratica base** (`workshops/mlt-r-basic/`), **pratica advanced** (`workshops/mlt-r-advanced/`, da creare).
Layout e contratto: `docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`.
I `CLAUDE.md` dei workshop contengono **solo** il delta R-authoring; lingua/matematica/liste/verifica
visiva valgono da qui per tutti i moduli.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "Make root CLAUDE.md the universal contract + 3-module map"
```

### D.3 — Trim the workshop CLAUDE.md to the R-authoring delta

- [ ] **Step 1: Edit `workshops/mlt-r-basic/CLAUDE.md`**

Remove the line duplicating the language rule ("Student-facing text in ENGLISH; teacher/design notes in ITALIAN") and add a pointer at the top:
```markdown
# CLAUDE.md — mlt-r-basic

> R-authoring delta only. Language/math/lists/visual-verification live in the repo-root
> `.claude/CLAUDE.md` (auto-merged when authoring here).

Live-coded R workshop. Conventions:
- Native pipe `|>` only (never `%>%`); `_` placeholder where needed.
- `<-` for objects, `=` only for function args. snake_case with type suffix (`hf_tbl`, `train`).
- ALL paths via `here::here()`. `library()` + `renv`, never bare `install.packages()` in step code.
- `{rio}::import()` for IO. ggplot: data in `|>`, layers with `+`, then `ggsave()`.
- One arg per line + trailing comma in multi-arg calls. `# Section ----` banners. 2 spaces. `set.seed(123)`.
- DELIVERY: live-coding, NO pre-baked results shown as live. Each `steps/NN-slug/` is a complete
  cumulative snapshot; the solution of step N is step N+1.
```

- [ ] **Step 2: Commit**

```bash
git add workshops/mlt-r-basic/CLAUDE.md
git commit -m "Trim workshop CLAUDE.md to R-authoring delta + pointer to root"
```

### D.4 — Workshop README: pointer up + Release-based use_course()

- [ ] **Step 1: Edit `workshops/mlt-r-basic/README.md`**

Add a first line under the title:
```markdown
> Part of the **MLT course** (one repo, three modules) → see the repo-root README.
```
And change the fetch instruction from the old separate-repo form to the Release-asset URL:
```r
usethis::use_course(
  "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip"
)
```
(The `releases/latest/download/<asset>` form is a stable URL that resolves once the first release exists — see Task E and Future Work.)

- [ ] **Step 2: Commit**

```bash
git add workshops/mlt-r-basic/README.md
git commit -m "Workshop README: pointer up + Release-asset use_course() URL"
```

---

## Task E: Distribution pipeline

**Files:**
- Modify: `workshops/mlt-r-basic/slides/_quarto.yml`, `workshops/mlt-r-basic/slides/theme.scss`
- Create: `scripts/build_workshop_zip.py`, `tests/skills/test_build_workshop_zip.py`
- Create: `.claude/commands/mlt-dist.md`
- Create: `.claude/hooks/remind-workshop-dist.py`, `tests/skills/test_remind_workshop_dist.py`
- Modify: `.claude/settings.json`, `.gitignore`

### E.1 — Remove chalkboard; point the workshop deck at the shared brand

- [ ] **Step 1: Edit `workshops/mlt-r-basic/slides/_quarto.yml`**

Remove the `chalkboard: true` line. Keep `embed-resources: true` and `code-link: true`. Set the theme list to reference the shared partial (authoring path):
```yaml
format:
  revealjs:
    theme: [default, ../../../styles/_brand.scss, theme.scss]
    embed-resources: true
    code-link: true
```
(Keep the existing `width: 1648`, `height: 1080`, `footer`, etc.)

- [ ] **Step 2: Slim `workshops/mlt-r-basic/slides/theme.scss`**

Delete any palette/font redeclarations now provided by `_brand.scss`; keep only workshop-specific rules (wide-canvas/code tweaks).

- [ ] **Step 3: Render + visually verify the workshop deck**

Run: `quarto render workshops/mlt-r-basic/slides/00-basic-deck.qmd`
Open `00-basic-deck.html` and **visually verify** (chrome-devtools) that branding matches the overview and nothing relied on chalkboard.

- [ ] **Step 4: Commit**

```bash
git add workshops/mlt-r-basic/slides/_quarto.yml workshops/mlt-r-basic/slides/theme.scss
git commit -m "Workshop deck: drop chalkboard, adopt shared brand SCSS"
```

### E.2 — The ZIP builder (TDD)

- [ ] **Step 1: Write the failing tests**

Create `tests/skills/test_build_workshop_zip.py`:
```python
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_workshop_zip as bwz  # noqa: E402


def test_is_excluded_drops_library_cache_and_authoring():
    assert bwz.is_excluded("renv/library/foo/DESCRIPTION") is True
    assert bwz.is_excluded("renv/staging/1/pkg") is True
    assert bwz.is_excluded("slides/.quarto/idx.json") is True
    assert bwz.is_excluded("slides/00-basic-deck_files/x.js") is True
    assert bwz.is_excluded("CLAUDE.md") is True
    assert bwz.is_excluded(".Rhistory") is True
    assert bwz.is_excluded("dist/mlt-r-basic.zip") is True


def test_is_excluded_keeps_source():
    assert bwz.is_excluded("renv.lock") is False
    assert bwz.is_excluded("renv/activate.R") is False
    assert bwz.is_excluded("steps/01-import/01-import.qmd") is False
    assert bwz.is_excluded("slides/00-basic-deck.html") is False
    assert bwz.is_excluded("slides/theme.scss") is False
    assert bwz.is_excluded("README.md") is False


def test_vendor_brand_copies_partial_and_rewrites_theme(tmp_path):
    slides = tmp_path / "slides"
    slides.mkdir()
    (slides / "_quarto.yml").write_text(
        "format:\n  revealjs:\n    theme: [default, ../../../styles/_brand.scss, theme.scss]\n",
        encoding="utf-8",
    )
    brand = tmp_path / "_brand_src.scss"
    brand.write_text("/*-- scss:defaults --*/\n$x: 1;\n", encoding="utf-8")

    bwz.vendor_brand(tmp_path, brand)

    assert (slides / "_brand.scss").read_text(encoding="utf-8").startswith("/*-- scss:defaults")
    rewritten = (slides / "_quarto.yml").read_text(encoding="utf-8")
    assert "../../../styles/_brand.scss" not in rewritten
    assert "theme: [default, _brand.scss, theme.scss]" in rewritten


def test_build_zip_prunes_and_vendors(tmp_path):
    ws = tmp_path / "mlt-r-basic"
    (ws / "renv" / "library" / "pkg").mkdir(parents=True)
    (ws / "renv" / "library" / "pkg" / "DESCRIPTION").write_text("x", encoding="utf-8")
    (ws / "renv").mkdir(exist_ok=True)
    (ws / "renv" / "activate.R").write_text("# activate", encoding="utf-8")
    (ws / "renv.lock").write_text("{}", encoding="utf-8")
    (ws / "CLAUDE.md").write_text("authoring", encoding="utf-8")
    (ws / "slides").mkdir()
    (ws / "slides" / "_quarto.yml").write_text(
        "format:\n  revealjs:\n    theme: [default, ../../../styles/_brand.scss, theme.scss]\n",
        encoding="utf-8",
    )
    (ws / "slides" / "00-basic-deck.html").write_text("<html></html>", encoding="utf-8")
    brand = tmp_path / "_brand_src.scss"
    brand.write_text("/*-- scss:defaults --*/\n$x: 1;\n", encoding="utf-8")
    out = tmp_path / "dist" / "mlt-r-basic.zip"
    out.parent.mkdir()

    bwz.build_zip(ws, brand, out)

    names = set(zipfile.ZipFile(out).namelist())
    assert "mlt-r-basic/renv.lock" in names
    assert "mlt-r-basic/renv/activate.R" in names
    assert "mlt-r-basic/slides/00-basic-deck.html" in names
    assert "mlt-r-basic/slides/_brand.scss" in names           # vendored
    assert "mlt-r-basic/CLAUDE.md" not in names                # authoring excluded
    assert not any("renv/library" in n for n in names)         # heavy lib excluded
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_workshop_zip.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'build_workshop_zip'`.

- [ ] **Step 3: Implement `scripts/build_workshop_zip.py`**

Create `scripts/build_workshop_zip.py`:
```python
#!/usr/bin/env python3
"""Build a source-only distributable ZIP for an MLT workshop.

Prunes to source-only, vendors the shared brand SCSS partial into the workshop's
slides/ (rewriting the theme path), and zips with a top-level <slug>/ folder so
usethis::use_course() unpacks cleanly. The shipped deck HTML must already be
rendered with embed-resources:true so its *_files/ dir can be excluded.

Usage:
  python scripts/build_workshop_zip.py workshops/mlt-r-basic
  python scripts/build_workshop_zip.py workshops/mlt-r-basic --out dist/mlt-r-basic.zip
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

DEFAULT_BRAND = Path("styles/_brand.scss")
_EXCLUDE_NAMES = {".Rhistory", ".DS_Store", "Thumbs.db", "CLAUDE.md"}
_EXCLUDE_PART_DIRS = {".quarto", ".Rproj.user", ".git"}


def is_excluded(rel_posix: str) -> bool:
    """True if the relative POSIX path should be left out of the ZIP."""
    parts = rel_posix.split("/")
    name = parts[-1]
    if rel_posix == "renv/library" or rel_posix.startswith("renv/library/"):
        return True
    if rel_posix == "renv/staging" or rel_posix.startswith("renv/staging/"):
        return True
    if rel_posix == "dist" or rel_posix.startswith("dist/"):
        return True
    if any(p in _EXCLUDE_PART_DIRS for p in parts):
        return True
    if any(p.endswith("_files") for p in parts):
        return True
    if name in _EXCLUDE_NAMES:
        return True
    return False


def vendor_brand(staging: Path, brand_src: Path) -> None:
    """Copy the shared brand partial into staging/slides and rewrite the theme path."""
    slides = staging / "slides"
    if not slides.is_dir():
        return
    shutil.copy2(brand_src, slides / "_brand.scss")
    qfile = slides / "_quarto.yml"
    if qfile.exists():
        text = qfile.read_text(encoding="utf-8")
        text = text.replace("../../../styles/_brand.scss", "_brand.scss")
        qfile.write_text(text, encoding="utf-8")


def _kept_files(workshop_dir: Path) -> list[Path]:
    out = []
    for p in sorted(workshop_dir.rglob("*")):
        if p.is_file() and not is_excluded(p.relative_to(workshop_dir).as_posix()):
            out.append(p)
    return out


def build_zip(workshop_dir: Path, brand_src: Path, out_zip: Path, slug: str | None = None) -> Path:
    workshop_dir = Path(workshop_dir)
    slug = slug or workshop_dir.name
    out_zip = Path(out_zip)
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        staging = Path(td) / slug
        for f in _kept_files(workshop_dir):
            dest = staging / f.relative_to(workshop_dir)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
        vendor_brand(staging, brand_src)
        with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(staging.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(staging.parent).as_posix())
    return out_zip


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workshop_dir")
    ap.add_argument("--brand", default=str(DEFAULT_BRAND))
    ap.add_argument("--out", default=None)
    args = ap.parse_args(argv)
    ws = Path(args.workshop_dir)
    out = Path(args.out) if args.out else Path("dist") / f"{ws.name}.zip"
    build_zip(ws, Path(args.brand), out)
    size_mb = out.stat().st_size / 1_000_000
    print(f"built {out} ({size_mb:.1f} MB)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_build_workshop_zip.py -v`
Expected: PASS (4 passed).

- [ ] **Step 5: Commit**

```bash
git add scripts/build_workshop_zip.py tests/skills/test_build_workshop_zip.py
git commit -m "Add source-only workshop ZIP builder (prune + vendor brand)"
```

### E.3 — gitignore dist/ and smoke-build the real ZIP

- [ ] **Step 1: Gitignore dist/**

Append to `.gitignore`:
```gitignore
# Built workshop ZIPs — published as GitHub Release assets, not committed
dist/
```

- [ ] **Step 2: Build the real Basic workshop ZIP and inspect it**

Run: `python scripts/build_workshop_zip.py workshops/mlt-r-basic`
Expected: `built dist/mlt-r-basic.zip (N.N MB)` — a few MB, not hundreds.
Then list contents:
```bash
python -c "import zipfile;[print(n) for n in zipfile.ZipFile('dist/mlt-r-basic.zip').namelist()[:40]]"
```
Confirm: `mlt-r-basic/renv.lock` present, `mlt-r-basic/slides/_brand.scss` present, no `renv/library/`, no `CLAUDE.md`, no `_files/`.

- [ ] **Step 3: Commit (the .gitignore only — the ZIP is ignored)**

```bash
git add .gitignore
git commit -m "Gitignore dist/ (workshop ZIPs ship as Release assets)"
```

### E.4 — The /mlt-dist slash-command

- [ ] **Step 1: Create `.claude/commands/mlt-dist.md`**

```markdown
---
description: Build source-only distributable ZIP(s) for the R workshop(s)
---

Build the distributable ZIP for one workshop (or all, if none is named).

Steps:
1. Determine target(s): if the user named a workshop slug, use `workshops/<slug>`; otherwise
   every immediate subdirectory of `workshops/` that contains an `.Rproj`.
2. For each target, ensure its deck is rendered with `embed-resources: true`
   (the shipped HTML must be self-contained — re-render with `quarto render` if stale).
3. Run: `python scripts/build_workshop_zip.py workshops/<slug>`
4. Report the output path + size for each ZIP, and remind the user to attach them to a
   per-cohort GitHub Release (tag e.g. `workshops-2026`) so the
   `releases/latest/download/<slug>.zip` URL in the workshop README resolves.

Do NOT commit the ZIPs (dist/ is gitignored). Arguments: $ARGUMENTS (optional workshop slug).
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/mlt-dist.md
git commit -m "Add /mlt-dist command to build workshop ZIPs"
```

### E.5 — The reminder hook (TDD the predicate)

- [ ] **Step 1: Write the failing test**

Create `tests/skills/test_remind_workshop_dist.py`:
```python
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location(
    "remind_workshop_dist", ROOT / ".claude" / "hooks" / "remind-workshop-dist.py"
)
rwd = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rwd)


def test_reminds_on_workshop_source():
    assert rwd.should_remind("workshops/mlt-r-basic/steps/01-import/01-import.qmd") is True
    assert rwd.should_remind("workshops/mlt-r-basic/R/seed-data.R") is True


def test_reminds_on_shared_brand():
    assert rwd.should_remind("styles/_brand.scss") is True


def test_ignores_cache_zip_and_rendered():
    assert rwd.should_remind("workshops/mlt-r-basic/slides/.quarto/idx.json") is False
    assert rwd.should_remind("workshops/mlt-r-basic/slides/00-basic-deck_files/x.js") is False
    assert rwd.should_remind("dist/mlt-r-basic.zip") is False
    assert rwd.should_remind("course/01-introduction/narrative.md") is False
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_remind_workshop_dist.py -v`
Expected: FAIL (file not found / module load error).

- [ ] **Step 3: Implement `.claude/hooks/remind-workshop-dist.py`**

```python
#!/usr/bin/env python3
"""PostToolUse hook: remind to regenerate workshop dist when source changes.

Fires (non-blocking) when the just-written path is workshop source under
workshops/** OR the shared brand partial styles/_brand.scss (whose change
invalidates the inlined copy in every workshop ZIP). Ignores caches, the
built ZIP, and rendered sidecar dirs. Reads the hook payload JSON from stdin;
never blocks: exits 0 on any error.
"""
import json
import sys


def extract_path(payload: dict):
    ti = payload.get("tool_input") or {}
    return ti.get("file_path") or ti.get("path") or ti.get("notebook_path")


def should_remind(path: str) -> bool:
    norm = str(path).replace("\\", "/")
    parts = norm.split("/")
    if norm == "styles/_brand.scss" or norm.endswith("/styles/_brand.scss"):
        return True
    if "workshops/" not in f"/{norm}":
        return False
    if any(p in {".quarto", ".Rproj.user", ".git"} for p in parts):
        return False
    if any(p.endswith("_files") for p in parts):
        return False
    if norm.endswith(".zip"):
        return False
    return True


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = extract_path(payload)
    if path and should_remind(path):
        print(
            "[remind] workshop source changed → regenerate the dist ZIP via /mlt-dist "
            "before publishing a release.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tests/skills/test_remind_workshop_dist.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Register the hook in `.claude/settings.json`**

Add a third entry to the existing `PostToolUse` `hooks` array (after `rebuild-portal.py`):
```json
{
  "type": "command",
  "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/remind-workshop-dist.py\""
}
```
The full file becomes:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/md-to-html-math.py\"" },
          { "type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/rebuild-portal.py\"" },
          { "type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/remind-workshop-dist.py\"" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add .claude/hooks/remind-workshop-dist.py tests/skills/test_remind_workshop_dist.py .claude/settings.json
git commit -m "Add non-blocking reminder hook to regenerate workshop dist"
```

---

## Task F: Inter-module narrative pre-hook (Overview → Basic)

**Files:**
- Modify: `course/10-best-practices/narrative.md`, `workshops/mlt-r-basic/README.md`

### F.1 — Formalize the Overview ch.10 → Basic pre-hook + Basic prerequisites

- [ ] **Step 1: Add a pre-hook to the overview's last chapter narrative**

In `course/10-best-practices/narrative.md`, add a pre-hook (English student-facing line + Italian design note, per the language rule) that points forward to the Basic workshop — e.g. in the Payoff/pre-hook section:
```markdown
**Pre-hook → Practice (Basic).** You now know *why* a clinical ML model must be validated and
reproducible. Next you build one yourself, line by line, in R — from raw data to a re-runnable report.

<!-- nota design (IT): aggancio macro-arco Overview → Basic; il workshop riprende esattamente
     questo payoff come proprio hook. -->
```
(Writing this `.md` triggers the math→HTML hook; let it render the sibling `.html`.)

- [ ] **Step 2: State the prerequisite in the Basic workshop README**

In `workshops/mlt-r-basic/README.md`, add a short "Prerequisites" section:
```markdown
## Prerequisites

From the **Theory Overview** (Module 1): what supervised classification is, why validation and
reproducibility matter, and the train/validate/test idea. No prior R modelling experience needed.
```

- [ ] **Step 3: Commit**

```bash
git add course/10-best-practices/narrative.md course/10-best-practices/narrative.html workshops/mlt-r-basic/README.md
git commit -m "Formalize Overview ch.10 -> Basic pre-hook + Basic prerequisites"
```

---

## Final verification

- [ ] **Step 1: Run the whole test suite**

Run: `python -m pytest tests/skills -v`
Expected: all pass (existing manifest/quartoyml tests + the 3 new test files).

- [ ] **Step 2: Re-render and visually verify both decks**

Run: `quarto render slides/slides.qmd` and `quarto render workshops/mlt-r-basic/slides/00-basic-deck.qmd`
Visually verify both (chrome-devtools) — branding consistent, no regressions, no chalkboard dependency.

- [ ] **Step 3: Rebuild the dist ZIP and confirm size/contents**

Run: `python scripts/build_workshop_zip.py workshops/mlt-r-basic`
Confirm a few-MB ZIP with source + `renv.lock` + vendored `_brand.scss`, no library/cache/authoring files.

- [ ] **Step 4: Confirm the legacy archive is self-resolving**

Re-run the archive asset-resolution check from Task A.3 Step 4. Expected: `OK`.

---

## Self-review (done while writing this plan)

**Spec coverage:** §3 layout → Tasks A/B/D/E create `styles/`, `dist/`, `_archive/`, hub README. §4 docs → Task D. §5 distribution → Task E (recipe, builder, `/mlt-dist`, reminder). §6 archive → Task A (incl. move/copy assets + frozen renv + repoint). §7 style → Tasks B + E.1 (brand partial; `/mlt` untouched — no task extends it, by design). §8 renv → Task C. §9.1 (dist absorbs SCSS) → E.2 `vendor_brand`. §9.2 (hook watches `_brand.scss`) → E.5 `should_remind`. §9.3 (meta-index = prose) → D.1 README, no `_course.yml`. Tweak A → E.1. Tweak B → A.1. All covered.

**Placeholder scan:** No TBD/TODO. The Release URL uses the real `releases/latest/download/` form (resolves once the first release exists — flagged in Future Work, not a code placeholder). Conditional renv (Task C) has both branches written out concretely.

**Type/name consistency:** `is_excluded`, `vendor_brand`, `build_zip`, `_kept_files` (build_workshop_zip); `extract_refs`, `classify` (archive_legacy_assets); `should_remind`, `extract_path` (hook) — names match between each implementation and its test. The vendored theme rewrite string (`../../../styles/_brand.scss` → `_brand.scss`) matches the authoring path set in E.1.

---

## Future Work (out of scope for this plan)

- **Scaffold `workshops/mlt-r-advanced/`** when its content exists (its own `.Rproj` + renv + steps), then add the Basic → Advanced pre-hook and run `/mlt-dist` for it.
- **Sever the `index.Rmd` quarry dependency** once every overview chapter is built (Phase A complete): drop `base_source` and the index-mining input from the manifest + `mlt-quarto-build`, making storyboards/narratives the sole source.
- **Mint the Bitly short link** to the workshop Release asset and swap it into the workshop README for a friendlier `use_course()` URL.
- **First GitHub Release** (`workshops-2026`) with the built ZIP attached, to make `releases/latest/download/mlt-r-basic.zip` live.
