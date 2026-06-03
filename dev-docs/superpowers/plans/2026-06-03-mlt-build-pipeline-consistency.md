# MLT Build/Release Pipeline Consistency (W1) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every consumable MLT artifact regenerate from one idempotent entrypoint (`/mlt-build` → `scripts/build_all.py`), shipping the fragment-built tree (Model C per-step R projects), a teacher bundle, and a portal "Coding solutions" page — replacing the stale, git-ls-files-based pipeline.

**Architecture:** A Python orchestrator chains `rebuild.R` (engine) → deck render → from-disk ZIP + teacher bundle → `build_release.py` → `build_site.py`. The R engine (`dev/mltbuild/`) gains per-step project scaffolding so each step opens as its own RStudio+renv project (00-setup stays bare). Each stage remains independently runnable; `build_all` only adds ordering + freshness gates.

**Tech Stack:** R 4.6 (`dev/mltbuild/`, testthat), Python 3 stdlib (`scripts/`, pytest), Quarto CLI, renv.

**Spec:** `dev-docs/superpowers/specs/2026-06-03-mlt-build-pipeline-consistency-design.md`

**Conventions:** Student-facing strings in English; design/work notes in Italian. NEVER `git push` (local commits only). One logical change per commit. R engine changes use TDD + the engine's two-stage review.

---

## File Structure

**Engine (R) — Phase 0**
- Modify `dev/mltbuild/R/config.R` — `read_workshop()` resolves `renv_dir`.
- Create `dev/mltbuild/R/rproj.R` — `.Rproj` template + `write_step_project()`.
- Modify `dev/mltbuild/R/materialize.R` — call `write_step_project()` per step + full.
- Modify `dev/mltbuild/tests/testthat/test-materialize.R` — per-step project tests.
- Create `dev/mltbuild/tests/testthat/fixtures/wkfix/renv/activate.R` + `settings.json` — fixture renv source.

**Packaging (Python) — Phase 1**
- Modify `scripts/build_workshop_zip.py` — fragment detection, from-disk `student_payload`/`teacher_payload`, teacher zip; keep git-ls-files fallback.
- Modify `tests/skills/test_build_workshop_zip.py` — fragment + teacher + fallback tests.

**Portal (Python) — Phase 2**
- Modify `scripts/site_content.py` — `solutions_tabset_md()` (pure).
- Modify `scripts/build_site.py` — copy `_solved/` into `docs/solutions/<slug>/`, emit `_generated/<key>-solutions.md`, render solutions pages.
- Create `site/basic-solutions.qmd`, `site/advanced-solutions.qmd`.
- Modify `site/basic.qmd`, `site/advanced.qmd`, `site/downloads.qmd` — 4th "Coding solutions" button.
- Modify `tests/skills/test_site_content.py`, `tests/skills/test_build_site.py` — tests.

**Orchestrator + release (Python) — Phase 3**
- Create `scripts/build_all.py` — `plan_commands()` + `main()`.
- Create `tests/skills/test_build_all.py`.
- Modify `scripts/build_release.py` — teacher zips in `ZIP_ASSETS` + freshness assertion.
- Modify `tests/skills/test_build_release.py`.
- Create `.claude/commands/mlt-build.md`.

**Hooks + glue + docs — Phase 4**
- Modify `.claude/hooks/remind-workshop-dist.py` — message → `/mlt-build`.
- Modify `scripts/build_portal.py` — `EXTERNAL_ARTIFACTS = []`.
- Modify `.claude/commands/mlt-dist.md` — deprecated wrapper.
- Modify `README.md`, `dev/mltbuild/README.md`, `workshops/mlt-r-basic/README.md`.
- Modify vault tracking note.

**Hygiene + verification — Phase 5**
- `git add` untracked image dirs; commit deck WIP; `git rm --cached workshops/mlt-r-basic/_solved.R`.
- Full `/mlt-build` run + artifact assertions + chrome-devtools spot-check.

---

## Phase 0 — Engine: per-step project scaffolding (Model C)

### Task 0.1: Fixture renv source + failing test for per-step projects

**Files:**
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/renv/activate.R`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/renv/settings.json`
- Modify: `dev/mltbuild/tests/testthat/test-materialize.R` (append a new test)

- [ ] **Step 1: Add the fixture renv source files**

`dev/mltbuild/tests/testthat/fixtures/wkfix/renv/activate.R`:
```r
# fixture renv bootstrap (stub copied by write_step_project)
invisible(TRUE)
```

`dev/mltbuild/tests/testthat/fixtures/wkfix/renv/settings.json`:
```json
{ "snapshot.type": "all" }
```

- [ ] **Step 2: Write the failing test** (append to `dev/mltbuild/tests/testthat/test-materialize.R`)

```r
test_that("materialize scaffolds per-step R projects (00-setup bare, others renv)", {
  out <- tempfile("wkout-")
  wk  <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  materialize_workshop(wk, out)

  # 00-setup: bare .Rproj only — renv NOT activated here (student runs renv::init())
  expect_true(file.exists(file.path(out, "steps", "00-setup", "00-setup.Rproj")))
  expect_false(file.exists(file.path(out, "steps", "00-setup", ".Rprofile")))
  expect_false(dir.exists(file.path(out, "steps", "00-setup", "renv")))

  # 02-eda has packages ("janitor") -> full renv project
  s2 <- file.path(out, "steps", "02-eda")
  expect_true(file.exists(file.path(s2, "02-eda.Rproj")))
  expect_equal(readLines(file.path(s2, ".Rprofile")), 'source("renv/activate.R")')
  expect_true(file.exists(file.path(s2, "renv", "activate.R")))
  expect_true(file.exists(file.path(s2, "renv", "settings.json")))
  expect_true(file.exists(file.path(s2, "renv", ".gitignore")))

  # full/ -> full renv project
  expect_true(file.exists(file.path(out, "full", "full.Rproj")))
  expect_true(file.exists(file.path(out, "full", "renv", "activate.R")))
})
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/run-tests.R`
Expected: FAIL on the new test (`00-setup.Rproj` does not exist) — existing tests still pass.

### Task 0.2: Implement `renv_dir` resolution + `write_step_project()`

**Files:**
- Modify: `dev/mltbuild/R/config.R:30-39`
- Create: `dev/mltbuild/R/rproj.R`
- Modify: `dev/mltbuild/R/materialize.R:29-50`

- [ ] **Step 1: Add `renv_dir` to `read_workshop()`** — replace lines 30-39 of `dev/mltbuild/R/config.R`:

```r
  # data-raw lives under _authoring/data-raw, else at the workshop root (parent of _authoring).
  cand <- c(file.path(authoring_dir, "data-raw"),
            file.path(dirname(authoring_dir), "data-raw"))
  data_raw_dir <- cand[dir.exists(cand)][1]
  # canonical renv/ (activate.R + settings.json) to seed per-step projects:
  # under the authoring dir (fixtures) or at the workshop root (real layout).
  renv_cand <- c(file.path(authoring_dir, "renv"),
                 file.path(dirname(authoring_dir), "renv"))
  renv_dir <- renv_cand[dir.exists(renv_cand)][1]
  list(
    slug = wk$slug, r_version = wk$r_version, ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset, authoring_dir = authoring_dir,
    data_raw_dir = data_raw_dir, renv_dir = renv_dir,
    steps = steps
  )
```

- [ ] **Step 2: Create `dev/mltbuild/R/rproj.R`**

```r
# Per-step R-project scaffolding: make each generated step openable as an
# RStudio + renv project. A step with no cumulative packages (00-setup) ships a
# BARE .Rproj only — that is where the student runs renv::init() from scratch.
# Steps with packages (and full/) ship a complete renv project so opening them
# auto-activates renv and `renv::restore()` installs the pinned environment.

RPROJ_TEMPLATE <- c(
  "Version: 1.0", "",
  "RestoreWorkspace: No", "SaveWorkspace: No", "AlwaysSaveHistory: No", "",
  "EnableCodeIndexing: Yes", "UseSpacesForTab: Yes", "NumSpacesForTab: 2",
  "Encoding: UTF-8", "",
  "RnwWeave: knitr", "LaTeX: pdfLaTeX"
)

RENV_GITIGNORE <- c("library/", "local/", "cellar/", "lock/",
                    "python/", "sandbox/", "staging/")

# step_dir: the materialized step (or full/) directory.
# renv_src_dir: the workshop's canonical renv/ (NA in degenerate setups).
# with_renv: TRUE for steps/full that own packages; FALSE for the bare 00-setup.
write_step_project <- function(step_dir, renv_src_dir, with_renv) {
  slug <- basename(step_dir)
  .write_lines(RPROJ_TEMPLATE, file.path(step_dir, paste0(slug, ".Rproj")))
  if (!isTRUE(with_renv)) return(invisible())
  if (is.na(renv_src_dir) || !dir.exists(renv_src_dir))
    stop("write_step_project: renv source dir not found for ", step_dir)
  .write_lines('source("renv/activate.R")', file.path(step_dir, ".Rprofile"))
  renv_out <- file.path(step_dir, "renv")
  dir.create(renv_out, recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(renv_src_dir, "activate.R"),
            file.path(renv_out, "activate.R"), overwrite = TRUE)
  settings_src <- file.path(renv_src_dir, "settings.json")
  if (file.exists(settings_src))
    file.copy(settings_src, file.path(renv_out, "settings.json"), overwrite = TRUE)
  .write_lines(RENV_GITIGNORE, file.path(renv_out, ".gitignore"))
  invisible()
}
```

- [ ] **Step 3: Wire it into `materialize.R`** — replace the per-step loop body and the full/ block (lines 29-50) of `dev/mltbuild/R/materialize.R`:

```r
  for (n in seq_along(wk$steps) - 1L) {           # 0-based
    step  <- wk$steps[[n + 1L]]
    slug  <- step$slug
    sdir  <- file.path(out_dir, "steps", slug)
    if (identical(step$meta$type, "transform-terminal")) {
      .write_lines(render_report(step$template, frags), file.path(sdir, "report.qmd"))
    } else if (identical(step$meta$type, "append")) {
      ai <- sum(vapply(metas[seq_len(n + 1L)], function(m) identical(m$type, "append"), logical(1))) - 1L
      .write_lines(assemble_step(append_beats, ai), file.path(sdir, paste0(slug, ".R")))
    } else {
      stop("unknown step type for '", slug, "': ", step$meta$type)
    }
    pk <- packages_through(metas, n)
    .write_lines(pk, file.path(sdir, "packages.txt"))
    .write_lines(character(0), file.path(sdir, ".here"))
    .copy_data_raw(wk$data_raw_dir, sdir)
    write_step_project(sdir, wk$renv_dir, with_renv = length(pk) > 0L)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(append_beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$data_raw_dir, full_dir)
  write_step_project(full_dir, wk$renv_dir, with_renv = TRUE)
  invisible(out_dir)
```

- [ ] **Step 4: Run the engine test suite to verify all pass**

Run: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/run-tests.R`
Expected: PASS (the new test + all pre-existing tests; ≥ 88 total).

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/config.R dev/mltbuild/R/rproj.R dev/mltbuild/R/materialize.R \
        dev/mltbuild/tests/testthat/test-materialize.R \
        dev/mltbuild/tests/testthat/fixtures/wkfix/renv
git commit -m "feat(mltbuild): scaffold per-step R projects (Model C; 00-setup bare)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 0.3: Rebuild the real Basic workshop and verify the Model C tree

**Files:** none (regenerates gitignored trees on disk).

- [ ] **Step 1: Rebuild + gate Basic**

Run: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/rebuild.R mlt-r-basic`
Expected: `BUILD OK` then `STRUCTURAL PARITY OK` then `REBUILD OK`.

- [ ] **Step 2: Verify the on-disk Model C tree**

Run:
```bash
ls workshops/mlt-r-basic/steps/00-setup/*.Rproj
test ! -e workshops/mlt-r-basic/steps/00-setup/.Rprofile && echo "00 bare OK"
ls workshops/mlt-r-basic/steps/03-logistic/.Rprofile \
   workshops/mlt-r-basic/steps/03-logistic/renv/activate.R \
   workshops/mlt-r-basic/steps/03-logistic/renv.lock \
   workshops/mlt-r-basic/full/full.Rproj
```
Expected: 00-setup has a `.Rproj` and is bare; 03-logistic + full/ are complete renv projects with their lock. No commit (trees are gitignored).

---

## Phase 1 — Packaging: fragment-aware ZIP + teacher bundle

### Task 1.1: Fragment detection + from-disk student payload (failing tests)

**Files:**
- Modify: `tests/skills/test_build_workshop_zip.py` (append tests + a fragment-workshop fixture)

- [ ] **Step 1: Add a fragment-workshop builder + tests** (append to `tests/skills/test_build_workshop_zip.py`)

```python
def _make_fragment_workshop(tmp_path):
    """A fragment-built workshop: has _authoring/ + a generated (gitignored) tree."""
    ws = tmp_path / "mlt-r-basic"
    (ws / "_authoring" / "00-setup").mkdir(parents=True)
    (ws / "_authoring" / "00-setup" / "beat.R").write_text("# beat", encoding="utf-8")
    (ws / "README.md").write_text("# ws", encoding="utf-8")
    (ws / "CLAUDE.md").write_text("authoring", encoding="utf-8")
    (ws / "_manifest.yml").write_text("slug: mlt-r-basic\n", encoding="utf-8")
    (ws / "requirements.R").write_text("# reqs", encoding="utf-8")
    (ws / "R").mkdir()
    (ws / "R" / "seed-data.R").write_text("# seed", encoding="utf-8")
    (ws / "data-raw").mkdir()
    (ws / "data-raw" / "heart_failure.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    # generated (gitignored) tree — Model C
    s0 = ws / "steps" / "00-setup"
    s0.mkdir(parents=True)
    (s0 / "00-setup.R").write_text("# step 0", encoding="utf-8")
    (s0 / "00-setup.Rproj").write_text("Version: 1.0\n", encoding="utf-8")
    (s0 / ".here").write_text("", encoding="utf-8")
    (s0 / "data-raw").mkdir()
    (s0 / "data-raw" / "heart_failure.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    s1 = ws / "steps" / "01-import"
    (s1 / "renv").mkdir(parents=True)
    (s1 / "01-import.R").write_text("library(rio)\n", encoding="utf-8")
    (s1 / "01-import.Rproj").write_text("Version: 1.0\n", encoding="utf-8")
    (s1 / ".Rprofile").write_text('source("renv/activate.R")', encoding="utf-8")
    (s1 / "renv.lock").write_text("{}", encoding="utf-8")
    (s1 / "renv" / "activate.R").write_text("# activate", encoding="utf-8")
    (s1 / "renv" / ".gitignore").write_text("library/\n", encoding="utf-8")
    (s1 / "renv" / "library").mkdir()  # runtime junk that must NOT ship
    (s1 / "renv" / "library" / "pkg.txt").write_text("x", encoding="utf-8")
    (s1 / "01-import.html").write_text("<html>", encoding="utf-8")  # stray render, must NOT ship
    full = ws / "full"
    (full / "renv").mkdir(parents=True)
    (full / "full.R").write_text("# full", encoding="utf-8")
    (full / "renv.lock").write_text("{}", encoding="utf-8")
    sol = ws / "_solved"
    sol.mkdir()
    (sol / "00-setup.html").write_text("<html>solved0</html>", encoding="utf-8")
    (sol / "01-import.html").write_text("<html>solved1</html>", encoding="utf-8")
    return ws


def test_is_fragment_workshop(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    assert bwz.is_fragment_workshop(frag) is True
    nonfrag = tmp_path / "mlt-r-advanced"
    nonfrag.mkdir()
    assert bwz.is_fragment_workshop(nonfrag) is False


def test_student_payload_fragment_from_disk(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    rels = {arc for _src, arc in bwz.student_payload(frag)}
    assert "steps/00-setup/00-setup.R" in rels
    assert "steps/00-setup/00-setup.Rproj" in rels
    assert "steps/01-import/renv.lock" in rels
    assert "steps/01-import/renv/activate.R" in rels
    assert "full/full.R" in rels
    assert "data-raw/heart_failure.csv" in rels
    assert "README.md" in rels
    # excluded:
    assert not any(a.startswith("_solved/") for a in rels)        # teacher-only
    assert "renv.lock" not in rels                                # NO root lock
    assert not any(a.startswith("renv/") for a in rels)           # no root renv project
    assert not any(a.startswith("_authoring/") for a in rels)     # authoring source
    assert "CLAUDE.md" not in rels and "_manifest.yml" not in rels
    assert "requirements.R" not in rels
    assert not any(a.startswith("R/") for a in rels)              # maintainer helpers
    assert not any("renv/library" in a for a in rels)             # runtime junk
    assert "steps/01-import/01-import.html" not in rels           # stray render


def test_teacher_payload_adds_solved(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    rels = {arc for _src, arc in bwz.teacher_payload(frag)}
    assert "_solved/00-setup.html" in rels and "_solved/01-import.html" in rels
    assert "steps/01-import/01-import.R" in rels   # superset of student tree
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_workshop_zip.py -q`
Expected: FAIL (`is_fragment_workshop`/`student_payload`/`teacher_payload` not defined).

### Task 1.2: Implement payload functions + branchable `build_zip`

**Files:**
- Modify: `scripts/build_workshop_zip.py`

- [ ] **Step 1: Add the fragment payload machinery** — insert after `included_source()` (after line 61) in `scripts/build_workshop_zip.py`:

```python
# --- fragment-aware payload (Model C) --------------------------------------

# Student-shippable top-level entries of a fragment-built workshop.
_FRAGMENT_TOP_FILES = {"README.md"}
_FRAGMENT_TOP_DIRS = ("steps", "full", "data-raw")
# Path segments / names / suffixes that must never ship from the on-disk tree.
_DENY_SEGMENTS = (
    "renv/library", "renv/staging", "renv/local", "renv/cellar",
    "renv/python", "renv/sandbox", ".quarto", ".Rproj.user",
)
_DENY_NAMES = {".Rhistory", ".RData", ".Ruserdata"}
_DENY_SUFFIXES = (".html", ".rds")   # stray renders / model blobs inside steps/full


def is_fragment_workshop(workshop_dir) -> bool:
    """A workshop is fragment-built iff it owns an _authoring/ source tree."""
    return (Path(workshop_dir) / "_authoring").is_dir()


def _walk_shippable(base: Path):
    """Yield files under base, skipping runtime junk / stray renders."""
    for p in sorted(base.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(base).as_posix()
        if any(seg in rel for seg in _DENY_SEGMENTS):
            continue
        if p.name in _DENY_NAMES:
            continue
        if any(rel.endswith(suf) for suf in _DENY_SUFFIXES):
            continue
        yield p, rel


def student_payload(workshop_dir):
    """[(abs_src, rel_arc)] for the student ZIP.

    Fragment-built: the GENERATED on-disk tree (steps/ full/ data-raw/ + README),
    NOT git ls-files (the tree is gitignored). Non-migrated: git-tracked source.
    """
    workshop_dir = Path(workshop_dir)
    if not is_fragment_workshop(workshop_dir):
        return [(workshop_dir / rel, rel) for rel in included_source(workshop_dir)]
    out = []
    for name in sorted(_FRAGMENT_TOP_FILES):
        p = workshop_dir / name
        if p.is_file():
            out.append((p, name))
    for d in _FRAGMENT_TOP_DIRS:
        base = workshop_dir / d
        if base.is_dir():
            for src, rel in _walk_shippable(base):
                out.append((src, f"{d}/{rel}"))
    return out


def teacher_payload(workshop_dir):
    """Student payload + the _solved/ teacher tree (fragment-built only)."""
    workshop_dir = Path(workshop_dir)
    out = list(student_payload(workshop_dir))
    sol = workshop_dir / "_solved"
    if sol.is_dir():
        for src, rel in _walk_shippable(sol):
            out.append((src, f"_solved/{rel}"))
    return out
```

- [ ] **Step 2: Refactor `build_zip()` to consume a payload** — replace `build_zip()` (lines 72-99) with:

```python
def build_zip(workshop_dir, deck_dir, out_zip, slug=None, teacher=False) -> Path:
    workshop_dir = Path(workshop_dir)
    deck_dir = Path(deck_dir)
    slug = slug or workshop_dir.name
    out_zip = Path(out_zip)
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    payload = teacher_payload(workshop_dir) if teacher else student_payload(workshop_dir)
    with tempfile.TemporaryDirectory() as td:
        staging = Path(td) / slug
        # 1. payload (source tree, Model C for fragment-built workshops)
        for src, rel in payload:
            if not Path(src).is_file():
                continue
            dest = staging / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
        # 2. inject the rendered deck(s) under <slug>/slides/
        decks = rendered_decks(deck_dir)
        if decks:
            (staging / "slides").mkdir(parents=True, exist_ok=True)
            for d in decks:
                shutil.copy2(d, staging / "slides" / d.name)
        # 3. zip with a single top-level <slug>/ folder
        with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(staging.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(staging.parent).as_posix())
    return out_zip
```

- [ ] **Step 3: Build the teacher bundle in `main()`** — replace `main()` (lines 102-124) with:

```python
def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workshop_dir")
    ap.add_argument("--deck-dir", default=None,
                    help="slides source dir holding the rendered deck "
                         "(default: <repo-root>/slides/workshops/<slug>)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args(argv)
    ws = Path(args.workshop_dir).resolve()
    root = _repo_root(ws)
    deck_dir = (Path(args.deck_dir).resolve() if args.deck_dir
                else root / "slides" / "workshops" / ws.name)
    out = (Path(args.out).resolve() if args.out
           else root / "dist" / f"{ws.name}.zip")
    decks = rendered_decks(deck_dir)
    if not decks:
        print(f"ERROR: no rendered deck in {deck_dir}. "
              f"Render it first (e.g. `quarto render {deck_dir}`).", file=sys.stderr)
        return 2
    build_zip(ws, deck_dir, out)
    print(f"built {out} ({out.stat().st_size/1_000_000:.1f} MB; student)", file=sys.stderr)
    if is_fragment_workshop(ws):
        tout = out.parent / f"{ws.name}-teacher.zip"
        build_zip(ws, deck_dir, tout, teacher=True)
        print(f"built {tout} ({tout.stat().st_size/1_000_000:.1f} MB; teacher)", file=sys.stderr)
    return 0
```

- [ ] **Step 4: Run the packaging tests**

Run: `python -m pytest tests/skills/test_build_workshop_zip.py -q`
Expected: PASS (new fragment/teacher tests + the pre-existing non-fragment tests via the fallback path).

- [ ] **Step 5: Commit**

```bash
git add scripts/build_workshop_zip.py tests/skills/test_build_workshop_zip.py
git commit -m "feat(dist): fragment-aware ZIP from disk + teacher bundle

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2 — Portal: "Coding solutions" page + 4th tile button

### Task 2.1: Pure `solutions_tabset_md()` helper (failing test)

**Files:**
- Modify: `tests/skills/test_site_content.py` (append)
- Modify: `scripts/site_content.py`

- [ ] **Step 1: Write the failing test** (append to `tests/skills/test_site_content.py`)

```python
def test_solutions_tabset_md_one_tab_per_step():
    md = sc.solutions_tabset_md("mlt-r-basic", ["00-setup", "01-import", "05-report"])
    assert "::: {.panel-tabset}" in md
    assert "## 00-setup" in md and "## 05-report" in md
    assert 'src="solutions/mlt-r-basic/00-setup.html"' in md
    assert md.count("<iframe") == 3
    assert md.strip().endswith(":::")


def test_solutions_tabset_md_empty_when_no_steps():
    assert sc.solutions_tabset_md("mlt-r-basic", []) == ""
```

(If `tests/skills/test_site_content.py` does not yet `import site_content as sc`, add at the top: `import sys; from pathlib import Path; ROOT = Path(__file__).resolve().parents[2]; sys.path.insert(0, str(ROOT / "scripts")); import site_content as sc`.)

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_site_content.py -q -k solutions`
Expected: FAIL (`solutions_tabset_md` not defined).

- [ ] **Step 3: Implement** — append to `scripts/site_content.py`:

```python
def solutions_tabset_md(slug: str, steps: list[str]) -> str:
    """Quarto panel-tabset embedding one iframe per step's _solved HTML.

    Each iframe points at solutions/<slug>/<step>.html (copied into docs/ by
    build_site). "" when there are no steps.
    """
    if not steps:
        return ""
    out = ["::: {.panel-tabset}", ""]
    for step in steps:
        out.append(f"## {step}")
        out.append("")
        out.append(
            f'<iframe src="solutions/{slug}/{step}.html" '
            f'style="width:100%;height:75vh;border:1px solid #ddd;" '
            f'title="{slug} {step} solution"></iframe>'
        )
        out.append("")
    out.append(":::")
    return "\n".join(out)
```

- [ ] **Step 4: Run to verify pass**

Run: `python -m pytest tests/skills/test_site_content.py -q -k solutions`
Expected: PASS.

### Task 2.2: Copy `_solved/` into docs + emit solutions partials + render pages

**Files:**
- Modify: `scripts/build_site.py`
- Create: `site/basic-solutions.qmd`, `site/advanced-solutions.qmd`
- Modify: `tests/skills/test_build_site.py` (append)

- [ ] **Step 1: Write the failing test** (append to `tests/skills/test_build_site.py`)

```python
def test_solutions_partial_and_copy(tmp_path):
    root = _mini_repo(tmp_path)
    sol = root / "workshops" / "mlt-r-basic" / "_solved"
    sol.mkdir(parents=True)
    (sol / "00-setup.html").write_text("<html>s0</html>", encoding="utf-8")
    (sol / "01-import.html").write_text("<html>s1</html>", encoding="utf-8")
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    part = (out / "basic-solutions.md").read_text(encoding="utf-8")
    assert "## 00-setup" in part and "## 01-import" in part
    # advanced has no _solved -> placeholder, not an error
    adv = (out / "advanced-solutions.md").read_text(encoding="utf-8")
    assert adv.strip() != ""

    docs = tmp_path / "docs"
    bs.copy_solutions(root, docs)
    assert (docs / "solutions" / "mlt-r-basic" / "00-setup.html").exists()
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_site.py -q -k solutions`
Expected: FAIL (`basic-solutions.md` missing / `copy_solutions` undefined).

- [ ] **Step 3: Implement the partial + copy** — in `scripts/build_site.py`:

(a) Add a solved-steps reader + partial emission. Insert after `_overview_md()` (after line 84):

```python
_SOLUTIONS_PLACEHOLDER = "_Coding solutions will appear here once the workshop is built._\n"


def _solved_steps(root: Path, slug: str) -> list[str]:
    """Sorted step names that have a rendered _solved/<step>.html."""
    sol = root / "workshops" / slug / "_solved"
    if not sol.is_dir():
        return []
    return sorted(p.stem for p in sol.glob("*.html"))


def _solutions_md(root: Path, slug: str) -> str:
    steps = _solved_steps(root, slug)
    md = sc.solutions_tabset_md(slug, steps)
    return md + "\n" if md else _SOLUTIONS_PLACEHOLDER
```

(b) Emit the partials inside `write_partials()` — add inside the `for slug, key in WORKSHOPS:` loop (after line 111, i.e. after the syllabus emit):

```python
        _emit(f"{key}-solutions.md", _solutions_md(root, slug))
```

(c) Add `copy_solutions()` near the deck helpers (after `render_workshop_deck`, after line 170):

```python
def copy_solutions(root: Path, docs: Path) -> None:
    """Copy each workshop's _solved/*.html (+ sidecar _files) into docs/solutions/<slug>/."""
    for slug, _key in WORKSHOPS:
        sol = root / "workshops" / slug / "_solved"
        if not sol.is_dir():
            continue
        dst = docs / "solutions" / slug
        dst.mkdir(parents=True, exist_ok=True)
        for p in sol.glob("*.html"):
            shutil.copy2(p, dst / p.name)
        for d in sol.glob("*_files"):
            if d.is_dir():
                shutil.copytree(d, dst / d.name, dirs_exist_ok=True)
```

(d) Call it in `main()` — add after the `render_workshop_deck` loop (after line 188):

```python
    copy_solutions(root, root / DOCS)
```

- [ ] **Step 4: Create the solutions pages**

`site/basic-solutions.qmd`:
```markdown
---
title: "Coding solutions — Basic (R)"
---

Worked, executed solutions for every step of the Basic workshop (the teacher
*To fill / Solved* tabs). Pick a step.

{{< include _generated/basic-solutions.md >}}
```

`site/advanced-solutions.qmd`:
```markdown
---
title: "Coding solutions — Advanced (R)"
---

Worked, executed solutions for every step of the Advanced workshop (the teacher
*To fill / Solved* tabs). Pick a step.

{{< include _generated/advanced-solutions.md >}}
```

- [ ] **Step 5: Run to verify pass**

Run: `python -m pytest tests/skills/test_build_site.py -q -k solutions`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/site_content.py scripts/build_site.py site/basic-solutions.qmd \
        site/advanced-solutions.qmd tests/skills/test_site_content.py tests/skills/test_build_site.py
git commit -m "feat(site): Coding solutions page (one tab per step) from _solved/

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 2.3: Add the 4th "Coding solutions" tile button

**Files:**
- Modify: `site/basic.qmd:5-7`, `site/advanced.qmd` (same block), `site/downloads.qmd`

- [ ] **Step 1: Add the button to `site/basic.qmd`** — replace lines 5-7:

```markdown
[Open the deck ↗](slides/workshops/mlt-r-basic/00-basic-deck.html){.btn-deck}
[Download deck](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic-deck.html){.btn-dl}
[Download workshop ZIP](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip){.btn-dl}
[Coding solutions ↗](basic-solutions.html){.btn-deck}
```

- [ ] **Step 2: Add the button to `site/advanced.qmd`** — append after the existing three-button block (mirror of Step 1 with `advanced` / `mlt-r-advanced`):

```markdown
[Coding solutions ↗](advanced-solutions.html){.btn-deck}
```

- [ ] **Step 3: Add a Downloads link** — in `site/downloads.qmd`, append to the `## Latest assets` list (after line 14):

```markdown
- [Basic teacher bundle (ZIP, incl. solutions)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic-teacher.zip)
- [Advanced teacher bundle (ZIP, incl. solutions)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced-teacher.zip)
```

- [ ] **Step 4: Commit**

```bash
git add site/basic.qmd site/advanced.qmd site/downloads.qmd
git commit -m "feat(site): 4th 'Coding solutions' tile button + teacher bundle links

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3 — Orchestrator + release gates + `/mlt-build`

### Task 3.1: `build_all.py` command plan (failing test)

**Files:**
- Create: `tests/skills/test_build_all.py`
- Create: `scripts/build_all.py`

- [ ] **Step 1: Write the failing test**

`tests/skills/test_build_all.py`:
```python
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_all as ba  # noqa: E402


def _labels(cmds):
    return [label for label, _argv in cmds]


def test_plan_order_default():
    cmds = ba.plan_commands(["mlt-r-basic"], release=False, no_site=False, skip_masking=False)
    assert _labels(cmds) == [
        "rebuild", "check-masking", "render-deck", "zip", "site",
    ]


def test_plan_skip_masking_and_no_site():
    cmds = ba.plan_commands(["mlt-r-basic"], release=False, no_site=True, skip_masking=True)
    assert _labels(cmds) == ["rebuild", "render-deck", "zip"]


def test_plan_release_adds_release_stage_before_site():
    cmds = ba.plan_commands(["mlt-r-basic"], release=True, no_site=False, skip_masking=True)
    assert _labels(cmds) == ["rebuild", "render-deck", "zip", "release", "site"]


def test_zip_stage_targets_each_workshop():
    cmds = ba.plan_commands(["mlt-r-basic", "mlt-r-advanced"], release=False,
                            no_site=True, skip_masking=True)
    zips = [argv for label, argv in cmds if label == "zip"]
    assert any("mlt-r-basic" in " ".join(a) for a in zips)
    assert any("mlt-r-advanced" in " ".join(a) for a in zips)
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_all.py -q`
Expected: FAIL (no module `build_all`).

- [ ] **Step 3: Implement `scripts/build_all.py`**

```python
#!/usr/bin/env python3
"""One idempotent entrypoint that rebuilds every consumable MLT artifact.

Chains (per dependency order):
  rebuild.R -> check-masking.R -> render decks -> from-disk ZIP (+teacher)
  -> build_release.py (optional) -> build_site.py.

Each stage is also runnable on its own; this only adds ordering. plan_commands()
is pure (unit-tested); main() executes the plan via subprocess.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

RSCRIPT = os.environ.get("MLT_RSCRIPT", "Rscript")


def _workshops(root: Path) -> list[str]:
    wdir = root / "workshops"
    if not wdir.is_dir():
        return []
    return sorted(p.name for p in wdir.iterdir()
                  if p.is_dir() and (p / f"{p.name}.Rproj").exists())


def plan_commands(slugs, release, no_site, skip_masking):
    """Ordered [(label, argv)] for the given workshops + flags. Pure."""
    cmds: list[tuple[str, list[str]]] = []
    cmds.append(("rebuild", [RSCRIPT, "dev/mltbuild/rebuild.R", *slugs]))
    if not skip_masking:
        for slug in slugs:
            cmds.append(("check-masking",
                         [RSCRIPT, "dev/mltbuild/check-masking.R", slug]))
    for slug in slugs:
        cmds.append(("render-deck",
                     ["quarto", "render", f"slides/workshops/{slug}"]))
    for slug in slugs:
        cmds.append(("zip",
                     [sys.executable, "scripts/build_workshop_zip.py",
                      f"workshops/{slug}"]))
    if release:
        cmds.append(("release", [sys.executable, "scripts/build_release.py"]))
    if not no_site:
        cmds.append(("site", [sys.executable, "scripts/build_site.py"]))
    return cmds


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Build every MLT artifact in order")
    ap.add_argument("--workshop", action="append", dest="workshops",
                    help="slug to build (repeatable; default: all with a .Rproj)")
    ap.add_argument("--root", default=".")
    ap.add_argument("--release", action="store_true",
                    help="also assemble dev/release-assets/ (embed decks + ZIPs)")
    ap.add_argument("--no-site", action="store_true", help="skip the docs/ build")
    ap.add_argument("--skip-masking", action="store_true",
                    help="skip the numeric hoist-safety gate")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    slugs = args.workshops or _workshops(root)
    if not slugs:
        print("no workshops found under workshops/", file=sys.stderr)
        return 1
    for label, cmd in plan_commands(slugs, args.release, args.no_site, args.skip_masking):
        print(f"[build-all] {label}: {' '.join(cmd)}", file=sys.stderr)
        subprocess.run(cmd, cwd=str(root), check=True)
    print("[build-all] done", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run to verify pass**

Run: `python -m pytest tests/skills/test_build_all.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/build_all.py tests/skills/test_build_all.py
git commit -m "feat(build): scripts/build_all.py — one idempotent build-everything entrypoint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 3.2: Release assets — teacher zips + freshness assertion

**Files:**
- Modify: `tests/skills/test_build_release.py`
- Modify: `scripts/build_release.py`

- [ ] **Step 1: Update the contract test** — replace `tests/skills/test_build_release.py` body assertion (line 13) and add a freshness test:

```python
def test_asset_names_are_contractual():
    assert br.DECK_ASSETS["theory"] == "mlt-overview-theory-deck.html"
    assert br.DECK_ASSETS["basic"] == "mlt-r-basic-deck.html"
    assert br.DECK_ASSETS["advanced"] == "mlt-r-advanced-deck.html"
    assert br.ZIP_ASSETS == [
        "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
        "mlt-r-advanced.zip", "mlt-r-advanced-teacher.zip",
    ]


def test_zip_is_fresh_passes_when_zip_newer(tmp_path):
    (tmp_path / "_authoring").mkdir()
    old = tmp_path / "_authoring" / "workshop.yml"
    old.write_text("slug: x\n", encoding="utf-8")
    z = tmp_path / "x.zip"
    z.write_text("zip", encoding="utf-8")
    os = __import__("os")
    os.utime(old, (1_000, 1_000))
    os.utime(z, (2_000, 2_000))
    assert br.zip_is_fresh(z, tmp_path) is True


def test_zip_is_fresh_fails_when_authoring_newer(tmp_path):
    (tmp_path / "_authoring").mkdir()
    a = tmp_path / "_authoring" / "workshop.yml"
    a.write_text("slug: x\n", encoding="utf-8")
    z = tmp_path / "x.zip"
    z.write_text("zip", encoding="utf-8")
    os = __import__("os")
    os.utime(z, (1_000, 1_000))
    os.utime(a, (2_000, 2_000))
    assert br.zip_is_fresh(z, tmp_path) is False
```

- [ ] **Step 2: Run to verify failure**

Run: `python -m pytest tests/skills/test_build_release.py -q`
Expected: FAIL (`ZIP_ASSETS` differs; `zip_is_fresh` undefined).

- [ ] **Step 3: Implement** — in `scripts/build_release.py`:

(a) Replace `ZIP_ASSETS` (line 22):
```python
ZIP_ASSETS = [
    "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
    "mlt-r-advanced.zip", "mlt-r-advanced-teacher.zip",
]
```

(b) Add a freshness helper after `_rendered_html()` (after line 43):
```python
def zip_is_fresh(zip_path: Path, workshop_dir: Path) -> bool:
    """True if zip_path is newer than every file under workshop_dir/_authoring.

    Non-fragment workshops (no _authoring/) are always considered fresh.
    """
    authoring = Path(workshop_dir) / "_authoring"
    if not authoring.is_dir():
        return True
    if not Path(zip_path).exists():
        return False
    zmt = Path(zip_path).stat().st_mtime
    newest = max((p.stat().st_mtime for p in authoring.rglob("*") if p.is_file()),
                 default=0.0)
    return zmt >= newest
```

(c) Replace the ZIP-copy loop in `build()` (lines 55-61) with a freshness-asserting copy:
```python
    for z in ZIP_ASSETS:
        srcz = root / "dist" / z
        if not srcz.exists():
            print(f"WARNING: {srcz} missing — run /mlt-build first", file=sys.stderr)
            continue
        slug = z.replace("-teacher", "").replace(".zip", "")
        wdir = root / "workshops" / slug
        if not zip_is_fresh(srcz, wdir):
            raise SystemExit(
                f"ERROR: {srcz} is STALE vs {wdir}/_authoring — rebuild via /mlt-build"
            )
        shutil.copy2(srcz, out / z)
        made.append(out / z)
```

- [ ] **Step 4: Run to verify pass**

Run: `python -m pytest tests/skills/test_build_release.py -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/build_release.py tests/skills/test_build_release.py
git commit -m "feat(release): ship teacher bundles + assert ZIP freshness vs _authoring

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 3.3: `/mlt-build` command

**Files:**
- Create: `.claude/commands/mlt-build.md`

- [ ] **Step 1: Create the command**

```markdown
---
description: Build every consumable MLT artifact in dependency order (one idempotent entrypoint)
---

Regenerate the whole pipeline from one command: fragment-build each workshop tree, render the
decks, package the student ZIP + teacher bundle from disk, and rebuild the public site.

Arguments: $ARGUMENTS — optional flags forwarded to the orchestrator:
`--workshop <slug>` (repeatable; default = every workshop with a `.Rproj`), `--release` (also
assemble `dev/release-assets/`), `--no-site`, `--skip-masking`.

Steps:

1. Run (R must be on PATH as the 4.6 toolchain; set `MLT_RSCRIPT` to override, e.g.
   `MLT_RSCRIPT="/c/Program Files/R/R-4.6.0/bin/Rscript.exe"`):
   `python scripts/build_all.py $ARGUMENTS`
   It chains: `rebuild.R` → `check-masking.R` → `quarto render` decks → `build_workshop_zip.py`
   (student + teacher, from the generated on-disk tree) → `build_release.py` (with `--release`)
   → `build_site.py`.
2. Report the final `[build-all] done` line (or the failing stage).

Notes:

- Idempotent: re-running converges to the same state.
- `/mlt-dist` is a deprecated single-workshop alias of this command.
- The generated `steps/ full/ _solved/` trees are gitignored; this command materializes and ships
  them — never commit them.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/mlt-build.md
git commit -m "feat(build): /mlt-build command wrapping the unified entrypoint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Phase 4 — Hooks, portal, command, and docs realignment

### Task 4.1: Repoint `remind-workshop-dist.py` at `/mlt-build`

**Files:**
- Modify: `.claude/hooks/remind-workshop-dist.py:45-49`

- [ ] **Step 1: Update the message** — replace lines 45-49:

```python
        print(
            "[remind] workshop source changed -> rebuild & ship via /mlt-build "
            "(it fragment-builds the tree before zipping) before publishing a release.",
            file=sys.stderr,
        )
```

- [ ] **Step 2: Run the hook tests (no message assertion; must still pass)**

Run: `python -m pytest tests/skills/test_remind_workshop_dist.py -q`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add .claude/hooks/remind-workshop-dist.py
git commit -m "fix(hook): remind to use /mlt-build (fragment-aware), not /mlt-dist

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.2: Realign the author-dashboard slide artifacts

**Files:**
- Modify: `scripts/build_portal.py:36-38`

- [ ] **Step 1: Drop the stale per-chapter slide link** — replace lines 36-38:

```python
# Per-chapter external artifacts. The per-chapter deck scheme
# (slides/chapters/<slug>.html) was retired by the unified single-deck build
# (slides/slides.qmd); the dashboard no longer links a broken per-chapter deck.
EXTERNAL_ARTIFACTS: list[tuple[str, str, str]] = []
```

- [ ] **Step 2: Verify the portal still builds**

Run: `python scripts/build_portal.py`
Expected: exits 0; `portal.html` regenerated with no "Slides" gaps.

- [ ] **Step 3: Commit**

```bash
git add scripts/build_portal.py
git commit -m "fix(portal): drop retired per-chapter slide artifact from dashboard

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.3: Deprecate `/mlt-dist` to a thin wrapper

**Files:**
- Modify: `.claude/commands/mlt-dist.md`

- [ ] **Step 1: Replace the command body** with:

```markdown
---
description: (Deprecated) Build one workshop's deck + ZIP — use /mlt-build instead
---

**Deprecated.** This wraps the unified entrypoint for a single workshop. Prefer `/mlt-build`.

Arguments: $ARGUMENTS — a workshop slug (e.g. `mlt-r-basic`).

Steps:

1. Run: `python scripts/build_all.py --workshop $ARGUMENTS --no-site`
   It fragment-builds the workshop tree, renders its deck, and packages the student ZIP + teacher
   bundle from the generated on-disk tree (NOT `git ls-files`). With no slug it builds every
   workshop.
2. Remind the user to run `/mlt-build --release` (or the full `/mlt-build`) before publishing a
   per-cohort GitHub Release.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/mlt-dist.md
git commit -m "refactor(cmd): deprecate /mlt-dist to a /mlt-build wrapper

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.4: Student README — Model C open flow

**Files:**
- Modify: `workshops/mlt-r-basic/README.md:28-60`

- [ ] **Step 1: Replace the "How to start" + "How the steps/ folders work" sections** (lines 28-60) with:

```markdown
## How to start

You need R (>= 4.5) and RStudio. Fetch the workshop materials:

```r
usethis::use_course(
  "https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-basic.zip"
)
```

The download is a **bundle of step snapshots**, not a single project. Each `steps/NN-slug/`
opens as its own RStudio project (double-click its `.Rproj`).

- **`steps/00-setup/`** ships *without* renv on purpose: it is where we run `renv::init()` and
  build the project from scratch — that is the first lesson.
- **`steps/01-import/` … `steps/05-report/`** each ship a complete renv project: open the step's
  `.Rproj` (its `renv` auto-activates), then `renv::restore()` to install the exact pinned
  packages for that step.

## How the `steps/` folders work

Each `steps/NN-slug/` is a **complete, cumulative snapshot** of the project up to that point — not
a diff. The solution to step N is simply step N+1.

If you fall behind during the live coding, do not panic: open the **next** step's `.Rproj`,
`renv::restore()`, and continue from a clean, runnable starting point. `full/` holds the whole
solved project for reference.
```

- [ ] **Step 2: Commit**

```bash
git add workshops/mlt-r-basic/README.md
git commit -m "docs(basic): rewrite student start flow for per-step projects (Model C)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.5: Root README — unified pipeline + three audiences

**Files:**
- Modify: `README.md` (Public site / Repository map area)

- [ ] **Step 1: Read the current README build section**

Run: `python -c "print(open('README.md',encoding='utf-8').read())"` — locate the "Public site" / build instructions block.

- [ ] **Step 2: Replace that block** with a section documenting the unified pipeline (adapt the exact heading to what exists; insert this verbatim content):

```markdown
## Build & release — one pipeline, three audiences

The whole course rebuilds from a single idempotent entrypoint:

```sh
python scripts/build_all.py            # all workshops: rebuild -> decks -> ZIPs -> site
python scripts/build_all.py --release  # also assemble dev/release-assets/ (embed decks + ZIPs)
```

(Equivalently the `/mlt-build` command.) It chains, in dependency order:
`dev/mltbuild/rebuild.R` (fragment-build each workshop tree from `workshops/<slug>/_authoring/`)
→ `check-masking.R` → `quarto render` decks → `scripts/build_workshop_zip.py` (student ZIP +
teacher bundle, packaged from the generated on-disk tree) → `scripts/build_release.py` →
`scripts/build_site.py` (→ `docs/`).

- **Student** downloads `mlt-r-<lvl>.zip`: a bundle of per-step R projects (Model C). Source of
  truth is `_authoring/`; `steps/ full/ _solved/` are generated and gitignored.
- **Teacher** downloads `mlt-r-<lvl>-teacher.zip` (student tree + `_solved/` worked solutions),
  or reads them on the site (the tile's **Coding solutions** button).
- **Dev/author** edits `_authoring/` beats and re-runs `/mlt-build`; drift is zero.

After content changes, run `python scripts/build_site.py` (or `/mlt-build`) and commit `/docs`.
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document the unified build pipeline + three audiences

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.6: `dev/mltbuild/README.md` — close the gap

**Files:**
- Modify: `dev/mltbuild/README.md` ("Known gaps / next" section)

- [ ] **Step 1: Read the "Known gaps / next" section**

Run: `python -c "import re,io; t=open('dev/mltbuild/README.md',encoding='utf-8').read(); i=t.find('Known gaps'); print(t[i-40:i+1200])"`

- [ ] **Step 2: Replace the release-pipeline gap bullet** with a CLOSED note:

```markdown
- ~~Release/portal pipeline is NOT yet fragment-aware.~~ **CLOSED (2026-06-03).** The unified
  entrypoint `python scripts/build_all.py` (`/mlt-build`) fragment-builds each workshop, renders
  the decks, packages the student ZIP + teacher bundle **from the generated on-disk tree**, then
  runs `build_release.py` + `build_site.py`. The student ZIP ships per-step R projects (Model C);
  `materialize.R` scaffolds each step (`.Rproj` + `.Rprofile` + `renv/`; `00-setup` stays bare).
  The `remind-workshop-dist.py` hook now points at `/mlt-build`.
```

- [ ] **Step 3: Commit**

```bash
git add dev/mltbuild/README.md
git commit -m "docs(mltbuild): mark release-pipeline gap CLOSED; document per-step scaffolding

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 4.7: Vault tracking note

**Files:**
- Modify: the main tracking note under `../obsidian-vault/progetti/mlt-overview/` (the additional working dir)

- [ ] **Step 1: Locate the tracking note**

Run: `ls "../obsidian-vault/progetti/mlt-overview/"` (from repo root; adjust to the actual file).

- [ ] **Step 2: Append a "consistency session" entry** (Italian, design-note voice) summarizing: pipeline unica `/mlt-build`, ZIP Model C, bundle docente, pagina Coding solutions, gap CHIUSO; prossimi: W2 (redesign deck) e W3 (migrazione Advanced).

- [ ] **Step 3: Commit (vault repo, if it is a git repo; else save only)**

```bash
git -C ../obsidian-vault add progetti/mlt-overview && \
git -C ../obsidian-vault commit -m "mlt-overview: consistency session — unified build pipeline" || true
```

---

## Phase 5 — Hygiene + full verification

### Task 5.1: Track deck image dirs (reproducibility)

**Files:** `img/ecdc/`, `img/horst/`, `img/horststyle/`, `slides/workshops/_assets/`

- [ ] **Step 1: Stage and commit the untracked image dirs**

```bash
git add img/ecdc img/horst img/horststyle slides/workshops/_assets
git status --short img slides/workshops/_assets   # confirm only intended files
git commit -m "assets: track workshop-deck image dirs (reproducible renders)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 5.2: Commit current deck state (pre-W2)

**Files:** `slides/workshops/mlt-r-basic/00-basic-deck.qmd`, `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`, both `concept-graph.mmd`

- [ ] **Step 1: Review the diff, then commit the WIP deck state**

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd slides/workshops/mlt-r-basic/concept-graph.mmd \
        slides/workshops/mlt-r-advanced/00-advanced-deck.qmd slides/workshops/mlt-r-advanced/concept-graph.mmd
git commit -m "slides: commit current workshop deck state (pre-W2 redesign)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 5.3: Untrack the stale root `_solved.R`

**Files:** `workshops/mlt-r-basic/_solved.R`

- [ ] **Step 1: Remove from the index (keep on disk) and commit**

```bash
git rm --cached workshops/mlt-r-basic/_solved.R
echo "workshops/*/_solved.R" >> .gitignore   # only if not already covered
git add .gitignore
git commit -m "chore: untrack pre-migration root _solved.R (replaced by _solved/ tree)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 5.4: Full pipeline run + artifact assertions

**Files:** none (regenerates artifacts).

- [ ] **Step 1: Run the whole Python + R test suite**

```bash
python -m pytest tests/ -q
"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/run-tests.R
```
Expected: all green.

- [ ] **Step 2: Full build with release**

Run: `MLT_RSCRIPT="/c/Program Files/R/R-4.6.0/bin/Rscript.exe" python scripts/build_all.py --workshop mlt-r-basic --release`
Expected: `[build-all] done`. (Advanced may be built separately once migrated — W3.)

- [ ] **Step 3: Assert the student ZIP is Model C (no pre-migration leftovers)**

```bash
python - <<'PY'
import zipfile
z = zipfile.ZipFile("dev/release-assets/mlt-r-basic.zip")
n = z.namelist()
assert any(x.endswith("steps/00-setup/00-setup.R") for x in n), "missing .R step"
assert any(x.endswith("steps/01-import/renv.lock") for x in n), "missing per-step lock"
assert any(x.endswith("steps/01-import/01-import.Rproj") for x in n), "missing per-step .Rproj"
assert not any(x == "mlt-r-basic/renv.lock" for x in n), "leaked root renv.lock"
assert not any("_solved" in x for x in n), "leaked solutions into student zip"
assert not any(x.endswith(".qmd") and "/steps/" in x and "report" not in x for x in n), "stale .qmd step"
assert not any("_template" in x or "yourturn" in x for x in n), "stale legacy files"
print("STUDENT ZIP OK:", len(n), "entries")
PY
```
Expected: `STUDENT ZIP OK`.

- [ ] **Step 4: Assert the teacher bundle carries `_solved/`**

```bash
python -c "import zipfile;n=zipfile.ZipFile('dev/release-assets/mlt-r-basic-teacher.zip').namelist();assert any('_solved/00-setup.html' in x for x in n);print('TEACHER ZIP OK')"
```
Expected: `TEACHER ZIP OK`.

### Task 5.5: Visual verification (chrome-devtools)

**Files:** none.

- [ ] **Step 1: Serve docs/ and open the portal**

Run: `python -m http.server -d docs 8099` (background), then via chrome-devtools MCP navigate to
`http://localhost:8099/basic.html`.

- [ ] **Step 2: Verify the tile + solutions page**

- Confirm the **Coding solutions** button is present on `basic.html` and links to `basic-solutions.html`.
- Navigate to `http://localhost:8099/basic-solutions.html`; confirm the **panel-tabset** shows one
  tab per step and each tab's iframe renders the solved content (math rendered, no broken frame).
- Take a screenshot of each for the record. Fix any layout/contrast/overflow issues and re-run
  `python scripts/build_site.py`.

- [ ] **Step 3: Spot-check a rendered deck**

Navigate to `http://localhost:8099/slides/workshops/mlt-r-basic/00-basic-deck.html`; confirm it
renders (images resolve via `docs/img/`).

- [ ] **Step 4: Stop the server**

Run: stop the background `http.server`.

---

## Self-Review (completed by plan author)

- **Spec coverage:** §3 entrypoint → Task 3.1/3.3; §4.0 engine → Phase 0; §4.1 ZIP → Task 1.2;
  §4.2 teacher → Task 1.2/3.2; §5 portal → Phase 2; §6 freshness+masking → Task 3.2/3.1;
  §7 hooks/cmd → Tasks 4.1–4.3; §8 docs → Tasks 4.4–4.7; §9 hygiene → Tasks 5.1–5.3;
  §10 verification → Tasks 5.4–5.5.
- **Type/name consistency:** `is_fragment_workshop`, `student_payload`, `teacher_payload`,
  `build_zip(..., teacher=)`, `zip_is_fresh`, `solutions_tabset_md`, `copy_solutions`,
  `plan_commands` are used consistently across tasks and tests.
- **Open detail (flagged, not a blocker):** if any `_solved/<NN>.html` is non-self-contained,
  Task 2.2's `copy_solutions` also copies sibling `*_files/`; the iframe isolates styles. Verified
  visually in Task 5.5.
```
