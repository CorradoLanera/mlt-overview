# MLT Final Revision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every placeholder/inconsistency in the MLT course's collateral (workshop timelines, three module syllabi, broken Release deck links) and retire obsolete material (old portal), then rebuild the site and verify visually.

**Architecture:** Edit only *sources of truth* (`_authoring/<step>/meta.yml`, three new `syllabus.md`, `course/_manifest.yml`, site `.qmd`), never generated output (`site/_generated/*`, `docs/*`). A new pure, unit-tested step-timeline generator in `scripts/site_content.py` + `scripts/build_site.py` replaces the dead formatives-based one. The site rebuilds deterministically via `python scripts/build_site.py`. Release decks are uploaded out-of-band (gated).

**Tech Stack:** Python 3.14 (stdlib only — no PyYAML on the Python side; regex parsing, matching the existing `site_content.py` style), pytest, Quarto (revealjs + website), `gh` CLI, chrome-devtools MCP for visual verification.

**Spec:** [`dev-docs/superpowers/specs/2026-06-03-mlt-final-revision-design.md`](../specs/2026-06-03-mlt-final-revision-design.md)

> **Commit & push policy (overrides the skill's per-task commit):** Tasks below do **not** commit individually. All commits are batched in **Task 12 (Review & Commit)** and run only on the user's explicit go-ahead, one logical change per commit. **Claude never pushes** — the user pushes. The Release upload (Task 11) is likewise gated on explicit user go-ahead.

---

## File Structure

**New files**
- `course/_global/syllabus.md` — Theory module syllabus (auto-included by `build_site.py::_syllabus_partial`).
- `workshops/mlt-r-basic/syllabus.md` — Basic module syllabus.
- `workshops/mlt-r-advanced/syllabus.md` — Advanced module syllabus.
- `_archive/legacy-portal/README.md` — note explaining the archived portal is superseded.

**Modified**
- `scripts/site_content.py` — add `workshop_step_order`, `parse_step_meta`, `workshop_steps`; remove dead `timeline_from_formatives` + `_FORMATIVE_RE`.
- `scripts/build_site.py` — add `_workshop_steps_md`; use it in `write_partials` for schedule + `{key}-timeline.md`; remove dead `_timeline_md`.
- `workshops/mlt-r-basic/_authoring/{00-setup,01-import,02-eda,03-logistic,04-zoo,05-report}/meta.yml` — add `minutes:` + `summary:`.
- `workshops/mlt-r-advanced/_authoring/{00-recap,01-interpret,02-deep-learning,03-ellmer,04-targets}/meta.yml` — add `minutes:` + `summary:`.
- `tests/skills/test_site_content.py` — add tests for the 3 new helpers; remove the `timeline_from_formatives` test.
- `tests/skills/test_build_site.py` — rework `_mini_repo` (add `_authoring/` trees, drop formatives-min files) + the timeline assertions.
- `course/_manifest.yml` — `total_minutes_gross: 240` → `225`; comment clarifying `objectives:`/`subunits:` are filesystem-derived.
- `site/index.qmd`, `site/theory.qmd` — "≈240" → "≈225".
- `README.md` — reword the prerequisites line.
- `.claude/settings.json` — drop the `rebuild-portal.py` hook entry.
- `.claude/hooks/remind-workshop-dist.py` — already says `/mlt-build` (verify; no change needed unless a `/mlt-dist` string remains).

**Moved (via `git mv` in Task 12)**
- `portal.html` → `_archive/legacy-portal/portal.html`
- `scripts/build_portal.py` → `_archive/legacy-portal/build_portal.py`

**Newly tracked**
- `_archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv`

**Regenerated (output, not hand-edited)**
- `site/_generated/*`, `docs/*`

---

## Task 1: Create the working branch

**Files:** none (git).

- [ ] **Step 1: Branch off main**

Run:
```bash
git checkout -b mlt-final-revision
```
Expected: `Switched to a new branch 'mlt-final-revision'`.

---

## Task 2: WS1 — pure step-timeline helpers in `site_content.py` (TDD)

**Files:**
- Modify: `scripts/site_content.py`
- Test: `tests/skills/test_site_content.py`

- [ ] **Step 1: Write the failing tests** — append to `tests/skills/test_site_content.py`:

```python
def test_workshop_step_order_parses_flow_list():
    wf = 'slug: mlt-r-basic\nsteps: [00-setup, 01-import, 05-report]\n'
    assert sc.workshop_step_order(wf) == ["00-setup", "01-import", "05-report"]


def test_workshop_step_order_absent_returns_empty():
    assert sc.workshop_step_order("slug: x\n") == []


def test_parse_step_meta_pulls_title_minutes_summary():
    meta = 'type: append\ntitle: "Step 01 — Import & wrangle"\nminutes: 35\nsummary: "Import the data."\npackages: [rio]\n'
    m = sc.parse_step_meta(meta)
    assert m["title"] == "Step 01 — Import & wrangle"
    assert m["minutes"] == 35
    assert m["summary"] == "Import the data."


def test_parse_step_meta_missing_fields_are_none():
    m = sc.parse_step_meta('type: append\nslug: 00-setup\n')
    assert m == {"title": None, "minutes": None, "summary": None}


def test_workshop_steps_orders_and_skips_incomplete():
    wf = 'steps: [00-setup, 01-import, 99-bad]\n'
    metas = {
        "00-setup": {"title": "Step 00 — Setup", "minutes": 25, "summary": "Init."},
        "01-import": {"title": "Step 01 — Import", "minutes": 35, "summary": ""},
        "99-bad": {"title": None, "minutes": None, "summary": None},
    }
    steps = sc.workshop_steps(wf, metas)
    assert [s["slug"] for s in steps] == ["00-setup", "01-import"]
    assert steps[0] == {"slug": "00-setup", "title": "Step 00 — Setup",
                        "minutes": 25, "summary": "Init."}
    assert steps[1]["summary"] == ""
```

- [ ] **Step 2: Run to verify they fail**

Run: `python -m pytest tests/skills/test_site_content.py -k "workshop_step or parse_step or workshop_steps" -v`
Expected: FAIL — `AttributeError: module 'site_content' has no attribute 'workshop_step_order'`.

- [ ] **Step 3: Implement the helpers** — in `scripts/site_content.py`, add these regexes near `_FORMATIVE_RE` and the functions after `timeline_from_formatives`:

```python
_STEPS_RE = re.compile(r"^\s*steps:\s*\[([^\]]*)\]", re.MULTILINE)
_META_TITLE_RE = re.compile(r'^\s*title:\s*"([^"]*)"', re.MULTILINE)
_META_MINUTES_RE = re.compile(r"^\s*minutes:\s*(\d+)\s*$", re.MULTILINE)
_META_SUMMARY_RE = re.compile(r'^\s*summary:\s*"([^"]*)"', re.MULTILINE)


def workshop_step_order(workshop_yml: str) -> list[str]:
    """Slugs in `steps: [a, b, c]` order from a workshop.yml. [] if absent."""
    m = _STEPS_RE.search(workshop_yml)
    if not m:
        return []
    return [s.strip() for s in m.group(1).split(",") if s.strip()]


def parse_step_meta(meta_text: str) -> dict:
    """title/minutes/summary from a step meta.yml (stdlib only, no yaml dep)."""
    t = _META_TITLE_RE.search(meta_text)
    mins = _META_MINUTES_RE.search(meta_text)
    s = _META_SUMMARY_RE.search(meta_text)
    return {
        "title": t.group(1) if t else None,
        "minutes": int(mins.group(1)) if mins else None,
        "summary": s.group(1) if s else None,
    }


def workshop_steps(workshop_yml: str, metas: dict) -> list[dict]:
    """Ordered [{slug,title,minutes,summary}] for a workshop timeline.

    `metas`: {slug: parse_step_meta(...)}. Steps missing a title OR minutes are
    skipped (incomplete metadata -> not shown). Order from workshop.yml.
    """
    out = []
    for slug in workshop_step_order(workshop_yml):
        m = metas.get(slug)
        if not m or not m.get("title") or m.get("minutes") is None:
            continue
        out.append({
            "slug": slug,
            "title": m["title"],
            "minutes": m["minutes"],
            "summary": m.get("summary") or "",
        })
    return out
```

- [ ] **Step 4: Run to verify they pass**

Run: `python -m pytest tests/skills/test_site_content.py -k "workshop_step or parse_step or workshop_steps" -v`
Expected: PASS (5 tests).

---

## Task 3: WS1 — wire the renderer into `build_site.py`, retire the dead formatives path (TDD)

**Files:**
- Modify: `scripts/build_site.py`, `scripts/site_content.py`
- Test: `tests/skills/test_build_site.py`, `tests/skills/test_site_content.py`

- [ ] **Step 1: Update the `_mini_repo` fixture** in `tests/skills/test_build_site.py` — replace the two `formatives` blocks with `_authoring` trees. Specifically, **delete** these lines:

```python
    fm = tmp / "slides" / "workshops" / "mlt-r-basic" / "formatives"
    fm.mkdir(parents=True)
    (fm / "min-09-live-check.md").write_text("x", encoding="utf-8")
    (fm / "min-30-yourturn-wrangle.md").write_text("x", encoding="utf-8")
    (fm / "README.md").write_text("x", encoding="utf-8")
```
and
```python
    fa = tmp / "slides" / "workshops" / "mlt-r-advanced" / "formatives"
    fa.mkdir(parents=True)
    (fa / "min-10-live-check.md").write_text("x", encoding="utf-8")
```
and **add** (anywhere inside `_mini_repo`, before `return tmp`):

```python
    ab = tmp / "workshops" / "mlt-r-basic" / "_authoring"
    (ab / "00-setup").mkdir(parents=True)
    (ab / "01-import").mkdir(parents=True)
    (ab / "workshop.yml").write_text(
        "slug: mlt-r-basic\nsteps: [00-setup, 01-import]\n", encoding="utf-8")
    (ab / "00-setup" / "meta.yml").write_text(
        'title: "Step 00 — Setup"\nminutes: 25\nsummary: "Init the project."\n', encoding="utf-8")
    (ab / "01-import" / "meta.yml").write_text(
        'title: "Step 01 — Import"\nminutes: 35\nsummary: "Import the data."\n', encoding="utf-8")
    aa = tmp / "workshops" / "mlt-r-advanced" / "_authoring"
    (aa / "00-recap").mkdir(parents=True)
    (aa / "workshop.yml").write_text(
        "slug: mlt-r-advanced\nsteps: [00-recap]\n", encoding="utf-8")
    (aa / "00-recap" / "meta.yml").write_text(
        'title: "Step 00 — Recap"\nminutes: 30\nsummary: "Reopen the model."\n', encoding="utf-8")
```

- [ ] **Step 2: Update the timeline assertion** in `tests/skills/test_build_site.py` — replace the body of `test_basic_timeline_and_overview` with:

```python
def test_basic_timeline_and_overview(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    tl = (out / "basic-timeline.md").read_text(encoding="utf-8")
    assert "Step 00 — Setup" in tl and "25 min" in tl
    assert "Init the project." in tl
    assert "**Total contact time: 60 min.**" in tl
    ov = (out / "basic-overview.md").read_text(encoding="utf-8")
    assert "A model." in ov and "Some R." in ov
```

- [ ] **Step 3: Remove the dead `timeline_from_formatives` test** — delete `test_timeline_from_formatives_sorts_and_ignores_noise` from `tests/skills/test_site_content.py`.

- [ ] **Step 4: Run to verify the build-site tests now fail**

Run: `python -m pytest tests/skills/test_build_site.py -k timeline -v`
Expected: FAIL — `build_site` has no `_workshop_steps_md`; `basic-timeline.md` still contains the old `min N` table (assertion mismatch).

- [ ] **Step 5: Add `_workshop_steps_md` and wire it in** — in `scripts/build_site.py`, **replace** the `_timeline_md` function with:

```python
def _workshop_steps_md(root: Path, slug: str) -> str:
    """Step-level workshop timeline mirroring _theory_chapters_md.

    Reads workshops/<slug>/_authoring/workshop.yml (step order) + each step's
    meta.yml (title/minutes/summary). Placeholder if no complete-metadata steps.
    """
    adir = root / "workshops" / slug / "_authoring"
    wf = adir / "workshop.yml"
    if not wf.is_file():
        return "_Timeline to be published._\n"
    wtext = wf.read_text(encoding="utf-8", errors="replace")
    metas = {}
    for step in sc.workshop_step_order(wtext):
        mp = adir / step / "meta.yml"
        if mp.is_file():
            metas[step] = sc.parse_step_meta(mp.read_text(encoding="utf-8", errors="replace"))
    steps = sc.workshop_steps(wtext, metas)
    if not steps:
        return "_Timeline to be published._\n"
    out = ["## Steps", ""]
    total = 0
    for s in steps:
        total += s["minutes"]
        out.append(f"### {s['title']} · {s['minutes']} min")
        out.append("")
        if s["summary"]:
            out.append(s["summary"])
            out.append("")
    out.append(f"**Total contact time: {total} min.**")
    out.append("")
    return "\n".join(out)
```

Then in `write_partials`, change the two call sites from `_timeline_md(root, slug)` to `_workshop_steps_md(root, slug)`:
- in the `sched` loop: `_timeline_md(root, slug)` → `_workshop_steps_md(root, slug)`
- in the per-workshop loop: `_emit(f"{key}-timeline.md", _timeline_md(root, slug))` → `_emit(f"{key}-timeline.md", _workshop_steps_md(root, slug))`

- [ ] **Step 6: Remove the dead formatives helper** — in `scripts/site_content.py` delete `_FORMATIVE_RE` and the entire `timeline_from_formatives` function.

- [ ] **Step 7: Run the full Python suite**

Run: `python -m pytest tests/ -q`
Expected: PASS (no references to `timeline_from_formatives` remain; grep to confirm: `python -c "import site_content,sys; sys.exit('timeline_from_formatives' in dir(site_content))"` → exit 0).

---

## Task 4: WS1 — add `minutes`/`summary` to all 11 step `meta.yml`

**Files:** the 11 `workshops/<slug>/_authoring/<step>/meta.yml` files.

> Each edit inserts two lines immediately **after** the step's `title:` line. `read_meta()` in `dev/mltbuild/R/config.R` ignores unknown keys (verified), so the workshop build is unaffected.

- [ ] **Step 1: Basic — insert after each `title:` line**

| file | lines to insert |
|---|---|
| `00-setup/meta.yml` | `minutes: 25`<br>`summary: "Initialise a reproducible RStudio project from scratch with \`renv\` and \`here\`."` |
| `01-import/meta.yml` | `minutes: 35`<br>`summary: "Import the heart-failure data and wrangle it tidily, dropping the leaky follow-up column."` |
| `02-eda/meta.yml` | `minutes: 30`<br>`summary: "Explore the cohort with clinically meaningful summaries (\`gtsummary\`)."` |
| `03-logistic/meta.yml` | `minutes: 45`<br>`summary: "Fit a logistic-regression spine and score it on two metrics — AUC-ROC and AUC-PR."` |
| `04-zoo/meta.yml` | `minutes: 70`<br>`summary: "Tune and compare a small model zoo with a \`workflow_set\`, then validate the winner with \`last_fit\`."` |
| `05-report/meta.yml` | `minutes: 35`<br>`summary: "Wrap the whole analysis in a reproducible Quarto report."` |

(Basic total = 240 min.)

- [ ] **Step 2: Advanced — insert after each `title:` line**

| file | lines to insert |
|---|---|
| `00-recap/meta.yml` | `minutes: 30`<br>`summary: "Reopen the validated Basic random forest and warm up the \`torch\` backend."` |
| `01-interpret/meta.yml` | `minutes: 45`<br>`summary: "Open the black box with permutation importance and agnostic SHAP (\`kernelshap\` + \`shapviz\`)."` |
| `02-deep-learning/meta.yml` | `minutes: 70`<br>`summary: "Train a small MLP live with \`torch\`/\`luz\`, then write and shape-check CNN, RNN and fused nets."` |
| `03-ellmer/meta.yml` | `minutes: 45`<br>`summary: "Use an LLM as a typed, reproducible ETL to extract structured fields from clinical notes (\`ellmer\`)."` |
| `04-targets/meta.yml` | `minutes: 50`<br>`summary: "Seal the full arc in a \`targets\` DAG reproducible with a single \`tar_make()\`."` |

(Advanced total = 240 min.)

- [ ] **Step 3: Sanity-check parsing** (no build needed)

Run:
```bash
python -c "import sys; sys.path.insert(0,'scripts'); import site_content as sc; from pathlib import Path; [print(s['title'], s['minutes']) for s in sc.workshop_steps(Path('workshops/mlt-r-basic/_authoring/workshop.yml').read_text(encoding='utf-8'), {st: sc.parse_step_meta(Path(f'workshops/mlt-r-basic/_authoring/{st}/meta.yml').read_text(encoding='utf-8')) for st in sc.workshop_step_order(Path('workshops/mlt-r-basic/_authoring/workshop.yml').read_text(encoding='utf-8'))})]"
```
Expected: 6 lines, titles + `25 35 30 45 70 35`.

- [ ] **Step 4: Confirm the workshop build still parses meta.yml**

Run: `Rscript -e "source('dev/mltbuild/R/config.R'); str(read_workshop('workshops/mlt-r-basic/_authoring')$steps[[2]]$meta)"`
Expected: no error; the `meta` list prints (extra `minutes`/`summary` keys present and harmless). *(If `Rscript` is unavailable in this environment, skip — the key-ignoring behaviour was verified by reading `config.R`.)*

---

## Task 5: WS2 — Theory syllabus (`course/_global/syllabus.md`)

**Files:** Create `course/_global/syllabus.md`.

> Student-facing English; one *Nota docente* in Italian. Math in `$...$`. Blank line before every list. Auto-included by `_syllabus_partial(root,"theory")`.

- [ ] **Step 1: Write the file** with this structure and exact header facts (verbatim from the Offerta Formativa):

- **H2 "Official course information"** → a markdown table with rows: *Denomination* = "Machine Learning: Overview of machine learning techniques, algorithms, and applications"; *SSD* = MEDS-24/A — Statistica medica; *Instructors* = Ileana Baldi, Corrado Lanera; *Hours / Credits* = 10 hours · 1 CFU; *Period* = Year I, second semester; *Delivery* = Dual (in-person + remote); *Language* = English; *Attendance* = mandatory (80%); *Exam* = Moodle quiz; *Prerequisites* = none.
- **H2 "Course description"** → 1 paragraph describing the *delivered* 10-chapter arc (what ML is → classifiers → algorithm families → model selection/validation → deep learning → CNN/RNN → LLMs & Transformers → using ChatGPT → agents → best practices), framed for biomedical/clinical graduate students, with a clinical-applications emphasis.
- **H2 "Intended learning outcomes"** → an intro line ("By the end of the module, students can:") + a blank line + a numbered list of 6 module-level observable outcomes distilled from the per-chapter `course/<slug>/objectives.md`: (1) frame a clinical problem as ML via Task/Performance/Experience and distinguish ML from traditional programming; (2) classify learning paradigms (supervised/unsupervised/active/reinforcement); (3) reason about classifiers as decision-region partitioners and pick metrics fit for (imbalanced) clinical outcomes; (4) apply train/validation/test + $K$-fold cross-validation and diagnose overfitting/data leakage; (5) explain modern architectures (MLP, CNN, RNN, Transformer/LLM) at the level of *why each exists*; (6) judge agentic/LLM tool use by competence and reversibility, and plan an ML project starting from the simplest defensible model.
- **H2 "Topics & schedule"** → a sentence pointing to the [Schedule](../schedule.qmd) page + a compact bullet list of the 10 chapters with minutes (25/20/35/30/25/20/25/15/15/15; total 225 min of contact content within the 10 official hours).
- **H2 "Assessment"** → Moodle quiz (summative); plus in-class dual-mode formative/summative exercises (one per chapter), with one shared artifact visible to in-person and remote students at once.
- **H2 "Learning path"** → Overview → Basic → Advanced; this is Module 1.
- **H2 "Reading & materials"** → bullet list, only real works: James, Witten, Hastie & Tibshirani, *An Introduction to Statistical Learning* (ISL); Mitchell, *Machine Learning* (1997) — the $T/P/E$ definition; Vaswani et al. (2017), "Attention is all you need"; plus lecturer-provided slides.
- A final `*Nota docente:*` (Italian) noting that the official Offerta blurb is more conservative than the delivered content (which now includes deep learning, Transformers/LLMs, agents) and that the header facts are the contractual ones.

- [ ] **Step 2: Verify it is picked up** (after the build in Task 10) — `site/_generated/theory-syllabus.md` must contain "Official course information", not the placeholder. (Checked in Task 10.)

---

## Task 6: WS2 — Basic syllabus (`workshops/mlt-r-basic/syllabus.md`)

**Files:** Create `workshops/mlt-r-basic/syllabus.md`.

- [ ] **Step 1: Write the file** with this structure and exact header facts:

- **H2 "Official course information"** → table: *Denomination* = "Practical Artificial Intelligence for Medical Data Analyses with R — Basic"; *SSD* = MEDS-24/A — Statistica medica; *Instructors* = Corrado Lanera, Luca Vedovelli, Giulia Lorenzoni; *Hours / Credits* = 10 hours · 1 CFU; *Period* = first semester; *Delivery* = Dual; *Language* = English; *Attendance* = mandatory (80%); *Exam* = practical / in-class assessment (see Assessment); *Prerequisites* = basic statistics and programming.
- **H2 "Course description"** → 1 paragraph from the workshop README: a ~4-hour live-coded session building & validating a clinical ML model in R, reproducibly, from raw heart-failure data to a rendered report (import/wrangle → clinical EDA → logistic spine on two metrics → tuned model zoo → held-out validation → reproducible Quarto report).
- **H2 "Intended learning outcomes"** → intro line + blank line + numbered list (5): (1) initialise a reproducible R project (`renv`, `here`, `{rio}`); (2) import and wrangle clinical data tidily and recognise/remove outcome leakage; (3) summarise a cohort with clinically meaningful EDA; (4) fit and validate a supervised classifier with `tidymodels`, choosing metrics (AUC-ROC + AUC-PR) appropriate to a ~32%-event imbalanced outcome; (5) tune and compare candidate models and produce a reproducible report.
- **H2 "Steps & schedule"** → pointer to [Schedule](../schedule.qmd) + bullet list of the 6 steps with minutes (Setup 25 · Import & wrangle 35 · Clinical EDA 30 · Logistic spine 45 · Model zoo, tuned 70 · Reproducible report 35; total ~240 min within the 10 official hours).
- **H2 "Dataset"** → heart-failure clinical records (Chicco & Jurman 2020; 299 patients, ~32% event rate); outcome in-hospital death (`died`/`survived`); the follow-up-time column is deliberately dropped to avoid leakage.
- **H2 "Assessment"** → official exam field is unspecified; the working model is in-class formative checkpoints (~one every 10–15 min: live checks, MCQs with diagnostic distractors, "your turn" tasks) plus a culminating hands-on task, dual-mode. *(State this as the working assessment, pending the official exam method.)*
- **H2 "Prerequisites & learning path"** → from Theory Module 1 (classification vs regression — ch. 2; train/validation/test — ch. 4; imbalanced metrics & sealed test set — ch. 10); no prior R modelling needed. This is Module 2; it pre-hooks Advanced.
- **H2 "Tools & materials"** → R (≥ 4.5) + RStudio; `tidyverse`, `tidymodels`, `gtsummary`, `renv`; lecturer-provided materials; package documentation.
- A short `*Nota docente:*` (Italian) noting the official Offerta blurb mentions `caret`/linear regression but the delivered workshop uses `tidymodels`/logistic regression on heart-failure (the delivered stack is the current one).

---

## Task 7: WS2 — Advanced syllabus (`workshops/mlt-r-advanced/syllabus.md`)

**Files:** Create `workshops/mlt-r-advanced/syllabus.md`.

- [ ] **Step 1: Write the file** with this structure and exact header facts:

- **H2 "Official course information"** → table: *Denomination* = "Practical Artificial Intelligence for Medical Data Analyses with R — Advanced"; *SSD* = MEDS-24/A — Statistica medica; *Instructors* = Corrado Lanera, Luca Vedovelli, Giulia Lorenzoni; *Hours / Credits* = 10 hours · 1 CFU; *Period* = second semester; *Delivery* = Dual; *Language* = English; *Attendance* = mandatory (80%); *Exam* = practical / in-class assessment; *Prerequisites* = basic R and ML — must have completed the Basic workshop.
- **H2 "Course description"** → 1 paragraph from the README: a ~4-hour live-coded session that reopens the validated Basic random forest and pushes it further — interpret with agnostic SHAP, go deeper with neural networks, use an LLM as a typed ETL, and seal everything in a reproducible `targets` DAG.
- **H2 "Intended learning outcomes"** → intro line + blank line + numbered list (5): (1) interpret a fitted model with permutation variable importance and agnostic SHAP (`kernelshap` + `shapviz`), anchored by a logistic `permshap()` sanity-check; (2) train a small MLP with `torch`/`luz` and read/shape-check CNN, RNN and fused architectures; (3) use an LLM (`ellmer`) as a typed, reproducible ETL to extract structured fields from clinical notes; (4) assemble a reproducible `targets` pipeline runnable with a single `tar_make()`; (5) reason about the interpretability/performance trade-off in a clinical-deployment context.
- **H2 "Steps & schedule"** → pointer to [Schedule](../schedule.qmd) + bullet list of the 5 steps with minutes (Recap & setup 30 · Open the black box 45 · Deep learning, honestly 70 · LLM as typed ETL 45 · Reproducibility capstone 50; total ~240 min within the 10 official hours).
- **H2 "Dataset"** → reloads heart-failure records (Chicco & Jurman 2020; 299 patients, ~32%) + the bundled fitted random forest (`model/final_fit.rds`) + ~12 synthetic, de-identified clinical notes (`hf_notes.csv`) for the LLM step; no PHI in any bundled file.
- **H2 "Assessment"** → as Basic: official exam field unspecified; working model = in-class dual-mode formatives + a hands-on capstone.
- **H2 "Prerequisites & learning path"** → completed Basic workshop required; background from Theory ch. 4/5/6/7 (interpretability, neural nets, CNN/RNN, LLMs). This is Module 3 (final).
- **H2 "Tools & materials"** → R (≥ 4.5) + RStudio; `tidymodels`, `vip`, `kernelshap`, `shapviz`, `torch`, `luz`, `brulee`, `ellmer`, `targets`, `tarchetypes`; optional `OPENAI_API_KEY` for the live LLM step (cached fallback otherwise); lecturer materials + package docs.
- A short `*Nota docente:*` (Italian) noting the official Offerta blurb (RF/boosting/unsupervised/feature-engineering) is stale vs the delivered arc (SHAP interpretability + `torch` deep learning + `ellmer` LLM ETL + `targets`); the delivered content is current and intentional.

---

## Task 8: WS4 — Archive the old portal & disable its hook

**Files:** `.claude/settings.json`; new `_archive/legacy-portal/README.md`. (The `git mv` of `portal.html` + `scripts/build_portal.py` happens in Task 12 so the move + content land in one commit.)

- [ ] **Step 1: Pre-create the archive folder note** — create `_archive/legacy-portal/README.md`:

```markdown
# Legacy portal (archived)

`portal.html` + `build_portal.py` were the **pre-Quarto author dashboard** for the MLT course.
They are **superseded** by the public Quarto site (`site/` → `docs/`, GitHub Pages) built by
`scripts/build_site.py`. They are **not** part of the build/release pipeline (`scripts/build_all.py`)
and the `rebuild-portal.py` PostToolUse hook has been disabled. Kept here for history only — do not
wire back into the build.
```

- [ ] **Step 2: Disable the hook** — in `.claude/settings.json`, remove the object whose `command` runs `rebuild-portal.py`:

Delete this entry from the `PostToolUse[0].hooks` array:
```json
          {
            "type": "command",
            "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/rebuild-portal.py\""
          },
```
Leave the `md-to-html-math.py` and `remind-workshop-dist.py` entries intact. Verify the JSON is still valid:
```bash
python -c "import json; json.load(open('.claude/settings.json')); print('valid')"
```
Expected: `valid`.

- [ ] **Step 3: Verify nothing else references the portal**

Run: `git grep -n "build_portal\|portal\.html" -- ':!_archive' ':!dev-docs' ':!.claude/hooks/rebuild-portal.py'`
Expected: no matches outside archive/docs/the hook file itself. *(If any live reference appears, fix it before moving the files.)*

---

## Task 9: WS5 — Minor cleanups

**Files:** `site/index.qmd`, `site/theory.qmd`, `course/_manifest.yml`, `README.md`, `_archive/legacy-xaringan/data/...` (track).

- [ ] **Step 1: Fix contact-time prose**

- `site/index.qmd:12` — change `10 storyboard-narrated chapters (≈240 min).` → `10 storyboard-narrated chapters (≈225 min).`
- `site/theory.qmd:8` — change `Ten chapters, storyboard-narrated, ≈240 minutes of contact time.` → `Ten chapters, storyboard-narrated, ≈225 minutes of contact time.`

- [ ] **Step 2: Manifest** — in `course/_manifest.yml`:

- change `  total_minutes_gross: 240` → `  total_minutes_gross: 225` (matches the 10 chapters' sum; only the now-archived portal ever read it).
- add a comment line above the `chapters:` key: `# Per-chapter `objectives`/`subunits` completion is derived from the filesystem (skills/lib/manifest.py::artifact_status), not these arrays — left empty intentionally.`

- [ ] **Step 3: README prerequisites line** — in `README.md`, change `Prerequisites are stated at the top of each module.` → `Prerequisites are stated on each module page (pulled from the workshop READMEs into the site at build time).`

- [ ] **Step 4: Track the reproducible-archive CSV** (the move/add is committed in Task 12)

Run: `git add _archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv`
Then confirm: `git status --short _archive/legacy-xaringan/data/` → shows `A  ...PubMed_Timeline_Results_by_Year.csv`.

- [ ] **Step 5: Verify the remind hook copy** — confirm `.claude/hooks/remind-workshop-dist.py` already references `/mlt-build` (it does) and contains no `/mlt-dist` string:

Run: `git grep -n "mlt-dist" -- .claude/hooks/remind-workshop-dist.py`
Expected: no matches (no change needed).

---

## Task 10: Build the site & verify (functional + visual)

**Files:** regenerates `site/_generated/*` and `docs/*`.

- [ ] **Step 1: Run the full Python test suite**

Run: `python -m pytest tests/ -q`
Expected: PASS (all).

- [ ] **Step 2: Rebuild the site**

Run: `python scripts/build_site.py`
Expected: exits 0; prints `site built into …/docs`. *(This invokes `quarto render site` + re-renders the 3 decks non-embed into `docs/slides/`.)*

- [ ] **Step 3: Functional checks on generated partials**

Run:
```bash
python - <<'PY'
from pathlib import Path
g = Path("site/_generated")
sched = (g/"schedule.md").read_text(encoding="utf-8")
assert "Timeline to be published" not in sched, "workshop timeline still placeholder"
assert "Step 00 — Setup" in sched and "Step 00 — Recap" in sched
for k in ("theory","basic","advanced"):
    syl = (g/f"{k}-syllabus.md").read_text(encoding="utf-8")
    assert "preparation" not in syl.lower(), f"{k} syllabus still placeholder"
    assert "Official course information" in syl
print("partials OK")
PY
```
Expected: `partials OK`.

- [ ] **Step 4: Visual verification (mandatory, chrome-devtools)** — open each of these `docs/` pages and inspect at a ~1100px viewport:

- `docs/schedule.html` — Module 2 & 3 now list steps with minutes + summaries; theory unchanged; no "to be published".
- `docs/theory.html`, `docs/basic.html`, `docs/advanced.html` — the Syllabus section renders (header table, ILOs, math via `$...$` rendered, no raw `$`).
- `docs/downloads.html` — links present (the deck links will work once Task 11 uploads them).

Confirm: no overflow, math rendered, tables intact. Fix any rendering issue and re-run Step 2.

---

## Task 11: WS3 — Restore the broken Release deck links (GATED)

**Files:** none in-repo; assembles `dev/release-assets/` and uploads to the `coorte-2026` Release.

> **Outward-facing & durable (~176 MB upload). Run only on the user's explicit go-ahead.**

- [ ] **Step 1: Assemble the release bundle**

Run: `python scripts/build_release.py`
Expected: `dev/release-assets/` contains the 3 deck HTMLs + 4 ZIPs; prints sizes (theory deck ~155 MB).

- [ ] **Step 2: Upload the 3 missing decks** (ZIPs already present on the release)

Run:
```bash
gh release upload coorte-2026 \
  "dev/release-assets/mlt-overview-theory-deck.html" \
  "dev/release-assets/mlt-r-basic-deck.html" \
  "dev/release-assets/mlt-r-advanced-deck.html"
```
Expected: 3 assets uploaded. *(If a same-name asset exists, add `--clobber`.)*

- [ ] **Step 3: Verify all 7 assets + link liveness**

Run:
```bash
gh release view coorte-2026 --json assets --jq '.assets[].name'
curl -sI -L -o NUL -w "%{http_code}\n" "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-overview-theory-deck.html"
```
Expected: 7 asset names listed; HTTP `200` for the theory deck (repeat for the basic/advanced deck URLs).

---

## Task 12: Review & Commit (GATED — one logical change per commit)

**Files:** all of the above. **Run only after the user approves the diff. Claude does not push.**

- [ ] **Step 1: Show the full diff for review**

Run: `git status && git --no-pager diff --stat`

- [ ] **Step 2: Commit, one logical change at a time** (after approval):

```bash
# 1 — spec + plan
git add dev-docs/superpowers/specs/2026-06-03-mlt-final-revision-design.md dev-docs/superpowers/plans/2026-06-03-mlt-final-revision.md
git commit -m "docs(mlt): spec + plan for the final revision"

# 2 — WS1 step-level workshop timeline (generator + meta + tests)
git add scripts/site_content.py scripts/build_site.py tests/skills/test_site_content.py tests/skills/test_build_site.py workshops/mlt-r-basic/_authoring/*/meta.yml workshops/mlt-r-advanced/_authoring/*/meta.yml
git commit -m "feat(site): step-level workshop timelines from _authoring meta.yml"

# 3 — WS2 three module syllabi
git add course/_global/syllabus.md workshops/mlt-r-basic/syllabus.md workshops/mlt-r-advanced/syllabus.md
git commit -m "docs(site): concise academic syllabi for the three modules"

# 4 — WS4 archive the old portal + disable its hook
git mv portal.html _archive/legacy-portal/portal.html
git mv scripts/build_portal.py _archive/legacy-portal/build_portal.py
git add _archive/legacy-portal/README.md .claude/settings.json
git commit -m "chore: archive the pre-Quarto portal, disable its rebuild hook"

# 5 — WS5 collateral cleanups
git add site/index.qmd site/theory.qmd course/_manifest.yml README.md _archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv
git commit -m "chore(site): reconcile contact time, manifest note, README, track archive CSV"

# 6 — rebuilt site output
git add site/_generated docs
git commit -m "build(site): rebuild docs with workshop timelines + syllabi"
```

- [ ] **Step 3: Hand off push to the user**

State that commits are local on `mlt-final-revision`; the user pushes and (Task 11) uploads the Release assets.

---

## Self-Review

**Spec coverage:** WS1 → Tasks 2–4 + 10; WS2 → Tasks 5–7 + 10; WS3 → Task 11; WS4 → Tasks 8 + 12; WS5 → Task 9 + manifest decision; build+visual verify → Task 10; commits → Task 12. All spec sections map to a task. ✓

**Placeholder scan:** generator code, test code, meta.yml values, header-table facts, and exact edit strings are all concrete. Syllabus *prose* is specified by exact section list + verbatim header facts + distilled ILOs + concrete bibliography + acceptance checks (Task 10 Step 3) — authored at execution, not deferred-vague. ✓

**Type/name consistency:** `workshop_step_order`, `parse_step_meta`, `workshop_steps`, `_workshop_steps_md` names are used identically across Tasks 2/3/10 and tests; `metas` shape `{slug: {title,minutes,summary}}` consistent. Basic total 240 / Advanced total 240 / theory 225 used consistently in meta, syllabi, prose, and the `test_basic_timeline` assertion (60 in the 2-step fixture). ✓
