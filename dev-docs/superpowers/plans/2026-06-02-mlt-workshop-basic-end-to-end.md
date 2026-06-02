# MLT workshop build — Basic end-to-end (plan 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the plan-1 `dev/mltbuild/` engine to a full *Basic-workshop-end-to-end* build: per-step `renv.lock`, teacher tabbed HTML, the self-contained `05-report` transform-terminal, the hand-migrated `_authoring/` source, and an oracle-parity gate — then flip the repo to treat the generated tree as build output.

**Architecture:** Extend the pure R engine (`dev/mltbuild/R/`) with: a hardened `materialize_workshop()` (selective unlink), named-fragment markers (`# >>>frag`/`# <<<frag`) with extract/strip, `{{frag:id}}` token substitution for the report template, a teacher tabbed-`.qmd` generator, and transform-terminal support. A separate **build orchestration** script (impure: needs renv + quarto) materializes `workshops/mlt-r-basic/{steps,full,_solved}`, generates per-step locks via `renv::snapshot(packages=)`, and renders the teacher HTML + report HTML. The Basic `_authoring/` tree is hand-migrated from the current `steps/*.qmd`. A parity harness re-renders the generated solved and asserts the deterministic numbers match the already-built `*-solved.html` oracle.

**Tech Stack:** R 4.6.0 (`C:\Program Files\R\R-4.6.0`), `{testthat}` + `{yaml}` for the engine (base R only inside engine functions), `{renv}` 1.2.3 + Quarto CLI 1.9.37 for the orchestration, `{rvest}`/regex for parity number-extraction, chrome-devtools MCP for the visual spot-check.

**Reference spec:** `dev-docs/superpowers/specs/2026-06-02-mlt-workshop-fragment-build-design.md` (§4.2 transform-terminal, §5 holes, §6 step contract, §7 renv per-step, §8 teacher tabs, §10 invariants, §11 migration + oracle).

**Plan 1 (done):** `dev-docs/superpowers/plans/2026-06-02-mlt-workshop-build-core.md` — engine green at PASS 45. See its "What this plan deliberately defers to plan 2" section: this plan implements every deferred item.

**Decisions locked at plan review (2026-06-02):**

1. **Per-step `renv.lock`** → `renv::snapshot(lockfile=, packages=<cumulative 00..N-1>, prompt=FALSE)` run from inside `workshops/mlt-r-basic` (via `source("renv/activate.R")`) with `options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2026-06-01"))`. Verified: pulls the full recursive closure and records the PPM repo + R 4.6.0. Step 00 gets **no** lock.
2. **Report (05) DRY** → **named-fragment tokens**. Beats mark reusable canonical regions (`# >>>frag id=… / # <<<frag`); the report template references them with `{{frag:id}}`; the build inlines the *solved* text. Report-specific glue (`verbose = FALSE`, `model_label`, inline metric extraction, no `future`/`saveRDS`) is authored directly in the template. The shipped `report.qmd` has all code inline (no `#| include` at runtime).
3. **Beat extraction** → **hand-authored**, step by step (this plan provides the exact content). No `.qmd` parser (one-time, 6 steps, editorial judgment → YAGNI).
4. **Parity** → **structural, not numeric.** The workshop teaches a *method*; exact numbers are not the deliverable and legitimately vary (different student seeds; Python/torch in Advanced — which is *why* we lean on qmd/targets/renv). The gate asserts each generated step **renders without error** and produces the **expected kinds of output** (e.g. step 04 → a 4-model ranking + ROC + PR curves + a 3-metric `last_fit`; step 05 → cohort table + ranking + winner statement + curves). The old `*-solved.html` are kept **transiently** as a visual reference only — their numbers are not pinned. *(Revised at plan review 2026-06-02: numeric oracle dropped — "chi se ne frega dei numeri".)*

---

## Conventions used by this plan

- All R run with R 4.6 explicitly. In Git Bash: `RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'`; every "Run:" uses `"$RS"`.
- Engine functions in `dev/mltbuild/R/` stay **pure** (string/list in → string/list out, base R only). Tests in `dev/mltbuild/tests/testthat/`, run via `"$RS" dev/mltbuild/run-tests.R` (expects `PASS`).
- Orchestration (renv/quarto) lives in `dev/mltbuild/build.R` + helpers; it is **not** unit-tested — it is verified by running and by the parity gate.
- One logical change per commit (project rule). **Never `git push`** — local commits only; the user pushes.
- Work on a dedicated branch `plan2-basic-end-to-end` (created in Task 0).
- Language: student-facing artifacts (beat code, prose, titles) in **English**; design/teacher notes in **Italian** (project rule). Empty line before every markdown list.

### Hole marker format (unchanged from plan 1)

```
# >>>hole id=<id> kind=fill|parsons|prose [prompt=<text to end of line>]
#   solved:
<solved lines>
#   blank:
<blank lines (may contain ___)>
# <<<hole
```

`kind=fill` keeps blank lines in blank mode; `kind=prose` emits `# TODO: <prompt>`; `kind=parsons` emits the reversed solved lines under `# Reorder the lines to: <prompt>`. `prompt=` must be the LAST field on the header line (captured greedily).

### Fragment marker format (NEW — frozen here)

A fragment is a **named canonical region** inside a beat's *solved* code, reused verbatim by the report template. Markers are plain R comments that ride through `parse_beat()` untouched:

```
# >>>frag id=<id>
<canonical solved lines, at their natural indentation>
# <<<frag
```

- Fragment markers may appear in plain text or **inside a hole's `solved:` section** (e.g. the wrangle hole). They are **stripped** from every student/teacher/`full` artifact (Task 3) and **sliced out by id** for report substitution (Task 3 `collect_fragments()` → `render_report()`).
- A fragment is defined **once** (in the beat that introduces the code). Reused fragments in this workshop: `wrangle-tail` (beat 01), `split` + `recipe` (beat 03), `specs` (beat 04).
- The fragment lines carry their own indentation. `{{frag:wrangle-tail}}` lines are 2-space indented (they continue an `… |>` pipe); `{{frag:split|recipe|specs}}` lines start at column 0.

### `_authoring/` tree layout for `mlt-r-basic`

```
workshops/mlt-r-basic/
  _authoring/                       # FONTE DI VERITÀ (committed)
    workshop.yml
    00-setup/    meta.yml beat.R
    01-import/   meta.yml beat.R    # defines frag wrangle-tail
    02-eda/      meta.yml beat.R
    03-logistic/ meta.yml beat.R    # defines frags split, recipe
    04-zoo/      meta.yml beat.R    # defines frag specs
    05-report/   meta.yml report.qmd   # type: transform-terminal; uses {{frag:…}}
    _oracle/     parity-oracle.yml  # committed reference numbers (Task 8)
                 NN-slug-solved.html  # transient, gitignored (visual spot-check only)
  data-raw/heart_failure.csv        # committed seed (already present)
  steps/ full/ _solved/             # GENERATED, gitignored after Task 12
```

`data-raw/` for the build is resolved by `read_workshop()` (Task 2): it prefers `_authoring/data-raw/`, falling back to `<workshop>/data-raw/`. For `mlt-r-basic` the fallback (`workshops/mlt-r-basic/data-raw/`) is used.

### Design notes (read before authoring)

- **Seeding: transcribe faithfully (don't chase numbers).** Keep each step's `set.seed(123)` as the current `.qmd` has it — `03`/`04` seed before the split and `04` again before the folds; `05-report` seeds once at the top. This is faithful transcription, **not** a numeric constraint: parity is structural (Decision 4), so a number that differs from the old render is *not* a failure. (The assembled step-04 script now runs the full step-03 history before the zoo — fine; it just re-fits the trivial glm baseline first.)
- **No "given" recaps in beats.** Each `beat.R` contains ONLY its new code (new `library()` calls + the new beat). Cumulative recaps are regenerated by assembling prior beats' solved renders. This is the DRY win (the wrangle is authored once, in beat 01).
- **Numbers, not HTML structure, define parity.** The generated teacher HTML is a *new* artifact (To-fill / Solved tabs) that replaces the old per-step solved docs; its structure differs from the oracle. Parity asserts the deterministic *numbers* match (Task 11).

---

## File Structure

Engine (pure, TDD):

- Modify: `dev/mltbuild/R/materialize.R` — harden unlink; transform-terminal branch; data-raw dir.
- Modify: `dev/mltbuild/R/config.R` — `read_workshop()` resolves `data_raw_dir` + transform `template`.
- Modify: `dev/mltbuild/R/assemble.R` — strip frags in `assemble_step`/`assemble_full`; add `assemble_solved_through()`.
- Create: `dev/mltbuild/R/fragments.R` — `strip_frag_markers()`, `extract_fragment()`, `collect_fragments()`.
- Create: `dev/mltbuild/R/report.R` — `render_report()`.
- Create: `dev/mltbuild/R/teacher.R` — `build_teacher_qmd()`.
- Modify/Create tests: `test-materialize.R`, `test-config.R`, `test-assemble.R`, `test-fragments.R`, `test-report.R`, `test-teacher.R`.
- Modify fixture `tests/testthat/fixtures/wkfix/` — add a frag + a transform-terminal step.

Orchestration (impure, run-verified):

- Create: `dev/mltbuild/R/renvlock.R` — `write_step_lock()` (renv snapshot wrapper).
- Modify: `dev/mltbuild/build.R` — real wiring into `workshops/<slug>/{steps,full,_solved}` + locks + render.
- Create: `dev/mltbuild/parity.R` — extract numbers from a rendered HTML; compare to oracle yml.
- Create: `dev/mltbuild/extract-oracle.R` — one-off: oracle HTML → `parity-oracle.yml`.

Authoring + repo:

- Create: `workshops/mlt-r-basic/_authoring/**` (workshop.yml, 6 steps, fragments, report template).
- Create: `workshops/mlt-r-basic/_authoring/_oracle/parity-oracle.yml`.
- Modify: `.gitignore` (root) — ignore generated workshop output (Task 12).
- Modify: `workshops/mlt-r-basic/CLAUDE.md` + `README.md` — document `_authoring/` source-of-truth.
- Modify: `.claude/commands/mlt-workshop-build.md` — real build flow.

---

## Task 0: Branch + safety baseline

**Files:** none (git only).

- [ ] **Step 1: Confirm engine is green on main**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]`.

- [ ] **Step 2: Create the dedicated branch**

```bash
git checkout -b plan2-basic-end-to-end
git status
```
Expected: on `plan2-basic-end-to-end`. (Do NOT push.)

- [ ] **Step 3: Commit the plan itself**

```bash
git add dev-docs/superpowers/plans/2026-06-02-mlt-workshop-basic-end-to-end.md
git commit -m "Plan 2: Basic workshop end-to-end build (writing-plans)"
```

---

## Task 1: Harden `materialize_workshop()` unlink (data-loss hazard)

**Files:**
- Modify: `dev/mltbuild/R/materialize.R`
- Modify: `dev/mltbuild/tests/testthat/test-materialize.R`

Plan-1 flagged: `materialize_workshop()` runs `unlink(out_dir, recursive = TRUE)` — fine for a tempdir, fatal when `out_dir = workshops/mlt-r-basic/` (it would delete the committed `_authoring/` + `data-raw/`). Fix: only remove the **generated** subtrees, and refuse if `out_dir` looks like an authoring root but no subtree exists yet (defensive).

- [ ] **Step 1: Write the failing test (append to test-materialize.R)**

```r
test_that("materialize_workshop preserves _authoring/ and data-raw/ at the out_dir root", {
  out <- tempfile("wkout-")
  dir.create(file.path(out, "_authoring"), recursive = TRUE)
  writeLines("sentinel", file.path(out, "_authoring", "keep.txt"))
  dir.create(file.path(out, "data-raw"), recursive = TRUE)
  writeLines("a,b\n1,2", file.path(out, "data-raw", "toy.csv"))
  # a stale generated subtree that MUST be wiped + rebuilt:
  dir.create(file.path(out, "steps", "stale"), recursive = TRUE)
  writeLines("old", file.path(out, "steps", "stale", "old.R"))

  wk <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  materialize_workshop(wk, out)

  expect_true(file.exists(file.path(out, "_authoring", "keep.txt")))   # source untouched
  expect_true(file.exists(file.path(out, "data-raw", "toy.csv")))      # source untouched
  expect_false(dir.exists(file.path(out, "steps", "stale")))           # stale subtree gone
  expect_true(dir.exists(file.path(out, "steps", "00-setup")))         # rebuilt
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — the original `unlink(out_dir)` deletes `_authoring/` and `data-raw/`.

- [ ] **Step 3: Implement the selective unlink (edit materialize.R)**

Replace the single `unlink(out_dir, recursive = TRUE)` line with:

```r
  # HARDENED: never unlink out_dir itself — it may hold the committed _authoring/ +
  # data-raw/ source-of-truth. Remove ONLY the generated subtrees.
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (sub in c("steps", "full", "_solved")) {
    unlink(file.path(out_dir, sub), recursive = TRUE)
  }
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (all suites, including the existing materialize tests that use a fresh tempdir).

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/materialize.R dev/mltbuild/tests/testthat/test-materialize.R
git commit -m "mltbuild: harden materialize_workshop() to unlink only generated subtrees"
```

---

## Task 2: `read_workshop()` resolves data-raw dir + transform template

**Files:**
- Modify: `dev/mltbuild/R/config.R`
- Modify: `dev/mltbuild/tests/testthat/test-config.R`

`mlt-r-basic` keeps `data-raw/` at the workshop level (sibling of `_authoring/`), and step 05 is a transform-terminal whose source is `report.qmd`, not `beat.R`. Teach `read_workshop()` both.

- [ ] **Step 1: Write the failing test (append to test-config.R)**

```r
test_that("read_workshop resolves data_raw_dir, preferring authoring/data-raw", {
  wk <- read_workshop(fixroot)
  expect_equal(normalizePath(wk$data_raw_dir),
               normalizePath(file.path(fixroot, "data-raw")))
})

test_that("read_workshop loads a transform-terminal template instead of beat.R", {
  wk <- read_workshop(fixroot)
  rep_step <- Filter(function(s) s$meta$type == "transform-terminal", wk$steps)[[1]]
  expect_equal(rep_step$meta$type, "transform-terminal")
  expect_true(length(rep_step$beat) == 0L)               # no append beat
  expect_true(any(grepl("\\{\\{frag:", rep_step$template)))  # template carries tokens
})
```

> This test needs the fixture extended with a transform step — done in Task 6 Step 1. To keep Task 2 self-contained, add the `data_raw_dir` test now (passes after Step 3) and mark the transform test `skip("fixture extended in Task 6")` until Task 6 removes the skip. Replace the second `test_that` body's first line with `skip("transform fixture added in Task 6")` for this task.

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — `wk$data_raw_dir` is NULL.

- [ ] **Step 3: Implement (edit config.R)**

Replace `read_workshop()` with:

```r
read_workshop <- function(authoring_dir) {
  wk <- yaml::read_yaml(file.path(authoring_dir, "workshop.yml"))
  steps <- lapply(wk$steps, function(slug) {
    step_dir  <- file.path(authoring_dir, slug)
    meta      <- read_meta(step_dir)
    beat_file <- file.path(step_dir, "beat.R")
    is_xform  <- identical(meta$type, "transform-terminal")
    tmpl_file <- if (is_xform) file.path(step_dir, meta$template %||% "report.qmd") else NA_character_
    list(
      slug     = slug,
      meta     = meta,
      beat     = if (!is_xform && file.exists(beat_file)) parse_beat(readLines(beat_file)) else list(),
      template = if (is_xform && file.exists(tmpl_file)) readLines(tmpl_file) else character(0)
    )
  })
  # data-raw lives under _authoring/data-raw, else at the workshop root (parent of _authoring).
  cand <- c(file.path(authoring_dir, "data-raw"),
            file.path(dirname(authoring_dir), "data-raw"))
  data_raw_dir <- cand[dir.exists(cand)][1]
  list(
    slug = wk$slug, r_version = wk$r_version, ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset, authoring_dir = authoring_dir,
    data_raw_dir = if (length(data_raw_dir) && !is.na(data_raw_dir)) data_raw_dir else NA_character_,
    steps = steps
  )
}
```

Also update `read_meta()` to carry the optional `template` field:

```r
read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages <- as.character(m$packages %||% character(0))
  m$type     <- m$type %||% "append"
  m$template <- m$template %||% NULL
  m
}
```

- [ ] **Step 4: Point `.copy_data_raw()` at the resolved dir (edit materialize.R)**

Change the materialize loop + full block to copy from `wk$data_raw_dir` instead of `wk$authoring_dir`. Replace both `.copy_data_raw(wk$authoring_dir, …)` calls with `.copy_data_raw(wk$data_raw_dir, …)`, and make `.copy_data_raw()` tolerate `NA`:

```r
.copy_data_raw <- function(data_raw_dir, dest_dir) {
  if (is.na(data_raw_dir) || !dir.exists(data_raw_dir)) return(invisible())
  dir.create(file.path(dest_dir, "data-raw"), recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(data_raw_dir, full.names = TRUE),
            file.path(dest_dir, "data-raw"), recursive = TRUE)
}
```

- [ ] **Step 5: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (data_raw_dir test green; transform test skipped).

- [ ] **Step 6: Commit**

```bash
git add dev/mltbuild/R/config.R dev/mltbuild/R/materialize.R dev/mltbuild/tests/testthat/test-config.R
git commit -m "mltbuild: read_workshop() resolves data_raw_dir + transform template"
```

---

## Task 3: Fragment markers — strip, extract, collect; assemble strips; solved-through

**Files:**
- Create: `dev/mltbuild/R/fragments.R`
- Modify: `dev/mltbuild/R/assemble.R`
- Create: `dev/mltbuild/tests/testthat/test-fragments.R`
- Modify: `dev/mltbuild/tests/testthat/test-assemble.R`

- [ ] **Step 1: Write the failing tests — fragments (create test-fragments.R)**

```r
test_that("strip_frag_markers removes only marker lines, keeps enclosed code", {
  x <- c("a <- 1", "# >>>frag id=foo", "b <- 2", "# <<<frag", "c <- 3")
  expect_equal(strip_frag_markers(x), c("a <- 1", "b <- 2", "c <- 3"))
})

test_that("extract_fragment slices the named region (markers excluded)", {
  x <- c("head |>", "  # >>>frag id=tail", "  step_a() |>", "  step_b()", "  # <<<frag", "done")
  expect_equal(extract_fragment(x, "tail"), c("  step_a() |>", "  step_b()"))
})

test_that("extract_fragment errors on a missing id", {
  expect_error(extract_fragment(c("x <- 1"), "nope"), "fragment")
})

test_that("collect_fragments gathers frags across all beats (solved render)", {
  b1 <- parse_beat(c("# >>>hole id=h kind=fill prompt=p", "#   solved:",
                     "v <- 0 |>", "  # >>>frag id=tail", "  f()", "  # <<<frag",
                     "#   blank:", "v <- ___", "# <<<hole"))
  wk <- list(steps = list(list(beat = b1)))
  fr <- collect_fragments(wk)
  expect_equal(fr$tail, "  f()")
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — `strip_frag_markers` not found.

- [ ] **Step 3: Implement fragments.R**

```r
# Named-fragment markers: build-time-only annotations inside beat solved code.
#   # >>>frag id=<id>
#   <canonical solved lines>
#   # <<<frag
# Stripped from every student/teacher/full artifact; sliced by id for the report.

.FRAG_OPEN  <- "^#\\s*>>>frag\\s+id=([^ ]+)\\s*$"
.FRAG_CLOSE <- "^#\\s*<<<frag\\s*$"

strip_frag_markers <- function(lines) {
  lines[!grepl("^#\\s*(>>>frag|<<<frag)\\b", lines)]
}

extract_fragment <- function(lines, id) {
  open <- which(grepl(.FRAG_OPEN, lines) & sub(.FRAG_OPEN, "\\1", lines) == id)
  if (!length(open)) stop("fragment id not found: ", id)
  start <- open[[1]]
  close <- which(grepl(.FRAG_CLOSE, lines) & seq_along(lines) > start)
  if (!length(close)) stop("unclosed fragment: ", id)
  lines[(start + 1L):(close[[1]] - 1L)]
}

collect_fragments <- function(wk) {
  frags <- list()
  for (st in wk$steps) {
    if (!length(st$beat)) next
    solved <- render_beat(st$beat, "solved")   # keeps frag markers
    open   <- grep(.FRAG_OPEN, solved, value = TRUE)
    for (line in open) {
      id <- sub(.FRAG_OPEN, "\\1", line)
      frags[[id]] <- extract_fragment(solved, id)
    }
  }
  frags
}
```

- [ ] **Step 4: Write the failing tests — assemble strips frags + solved-through (append to test-assemble.R)**

```r
test_that("assemble_step strips frag markers from prior solved beats", {
  fb <- list(
    parse_beat(c("# B0 ----", "x <- 0 |>", "  # >>>frag id=f", "  g()", "  # <<<frag")),
    parse_beat(c("# B1 ----", "# >>>hole id=h kind=fill prompt=p",
                 "#   solved:", "y <- 1", "#   blank:", "y <- ___", "# <<<hole"))
  )
  out <- assemble_step(fb, 1L)
  expect_false(any(grepl(">>>frag|<<<frag", out)))
  expect_true(all(c("x <- 0 |>", "  g()", "y <- ___") %in% out))
})

test_that("assemble_solved_through joins beats 0..n all solved, frags stripped", {
  out <- assemble_solved_through(beats, 1L)   # `beats` from earlier in this file
  expect_true(all(c("x <- 0", "y <- 1") %in% out))
  expect_false("z <- 2" %in% out)
  expect_false(any(grepl(">>>frag|<<<frag", out)))
})
```

- [ ] **Step 5: Implement (edit assemble.R) — strip frags + add solved-through**

```r
assemble_step <- function(beats, n) {
  stopifnot(n >= 0, n < length(beats))
  prior   <- if (n >= 1L) lapply(beats[seq_len(n)], render_beat, mode = "solved") else list()
  current <- list(render_beat(beats[[n + 1L]], mode = "blank"))
  strip_frag_markers(.join_beats(c(prior, current)))
}

assemble_full <- function(beats) {
  strip_frag_markers(.join_beats(lapply(beats, render_beat, mode = "solved")))
}

assemble_solved_through <- function(beats, n) {
  # All of beats 0..n rendered SOLVED (teacher "Solved" tab). 0-based n.
  stopifnot(n >= 0, n < length(beats))
  strip_frag_markers(.join_beats(lapply(beats[seq_len(n + 1L)], render_beat, mode = "solved")))
}
```

- [ ] **Step 6: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (fragments + assemble suites green).

- [ ] **Step 7: Commit**

```bash
git add dev/mltbuild/R/fragments.R dev/mltbuild/R/assemble.R dev/mltbuild/tests/testthat/test-fragments.R dev/mltbuild/tests/testthat/test-assemble.R
git commit -m "mltbuild: fragment markers (strip/extract/collect) + assemble strips frags + solved-through"
```

---

## Task 4: `render_report()` — `{{frag:id}}` token substitution

**Files:**
- Create: `dev/mltbuild/R/report.R`
- Create: `dev/mltbuild/tests/testthat/test-report.R`

- [ ] **Step 1: Write the failing test (create test-report.R)**

```r
test_that("render_report substitutes a frag token, preserving fragment indentation", {
  template <- c("hf <- import(x) |>", "{{frag:wrangle-tail}}", "", "summary(hf)")
  frags <- list(`wrangle-tail` = c("  clean_names() |>", "  select(-time)"))
  out <- render_report(template, frags)
  expect_equal(out, c("hf <- import(x) |>", "  clean_names() |>", "  select(-time)",
                      "", "summary(hf)"))
})

test_that("render_report errors on an unknown token", {
  expect_error(render_report("{{frag:nope}}", list()), "nope")
})

test_that("render_report leaves non-token lines untouched", {
  expect_equal(render_report(c("a", "b"), list()), c("a", "b"))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — `render_report` not found.

- [ ] **Step 3: Implement report.R**

```r
# Substitute {{frag:id}} tokens in a transform-terminal template with the named
# fragment's solved lines (verbatim, preserving the fragment's own indentation).

.FRAG_TOKEN <- "^\\s*\\{\\{frag:([^}]+)\\}\\}\\s*$"

render_report <- function(template_lines, fragments) {
  out <- character(0)
  for (line in template_lines) {
    if (grepl(.FRAG_TOKEN, line)) {
      id <- sub(.FRAG_TOKEN, "\\1", line)
      if (is.null(fragments[[id]])) stop("unknown fragment token in report: ", id)
      out <- c(out, fragments[[id]])
    } else {
      out <- c(out, line)
    }
  }
  out
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/report.R dev/mltbuild/tests/testthat/test-report.R
git commit -m "mltbuild: render_report() substitutes {{frag:id}} tokens"
```

---

## Task 5: `build_teacher_qmd()` — tabbed To-fill / Solved wrapper

**Files:**
- Create: `dev/mltbuild/R/teacher.R`
- Create: `dev/mltbuild/tests/testthat/test-teacher.R`

- [ ] **Step 1: Write the failing test (create test-teacher.R)**

```r
test_that("build_teacher_qmd wraps blank (verbatim) and solved (executed) tabs", {
  out <- build_teacher_qmd("Step 01 — Import", c("y <- ___"), c("y <- 1"))
  expect_true(any(grepl("^title:", out)))
  expect_true(any(grepl("embed-resources: true", out)))
  expect_true(any(grepl("^::: \\{\\.panel-tabset\\}$", out)))
  expect_true(any(grepl("^## To fill$", out)))
  expect_true(any(grepl("^## Solved$", out)))
  # blank is a NON-executed ```r block; solved is an executed ```{r} chunk:
  expect_true(any(out == "```r"))
  expect_true(any(out == "```{r}"))
  expect_true(any(out == "y <- ___"))
  expect_true(any(out == "y <- 1"))
  expect_true(any(out == ":::"))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — `build_teacher_qmd` not found.

- [ ] **Step 3: Implement teacher.R**

```r
# Build the per-step teacher HTML source: a panel-tabset .qmd with a verbatim
# "To fill" tab (the student script) and an executed "Solved" tab (cumulative solved).

build_teacher_qmd <- function(title, blank_lines, solved_lines) {
  c(
    "---",
    paste0("title: \"", title, " (teacher)\""),
    "format:",
    "  html:",
    "    embed-resources: true",
    "    toc: true",
    "execute:",
    "  warning: false",
    "  message: false",
    "---",
    "",
    "::: {.panel-tabset}",
    "",
    "## To fill",
    "",
    "```r",
    blank_lines,
    "```",
    "",
    "## Solved",
    "",
    "```{r}",
    "#| code-fold: false",
    solved_lines,
    "```",
    "",
    ":::"
  )
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/teacher.R dev/mltbuild/tests/testthat/test-teacher.R
git commit -m "mltbuild: build_teacher_qmd() tabbed To-fill/Solved wrapper"
```

---

## Task 6: Transform-terminal support in `materialize_workshop()` (+ extend fixture)

**Files:**
- Modify: `dev/mltbuild/R/materialize.R`
- Modify: `dev/mltbuild/tests/testthat/test-materialize.R`
- Modify: `dev/mltbuild/tests/testthat/test-config.R` (un-skip the Task-2 transform test)
- Create fixture: `tests/testthat/fixtures/wkfix/01-import/beat.R` gains a frag; add `tests/testthat/fixtures/wkfix/03-report/{meta.yml,report.qmd}`; extend `workshop.yml`.

- [ ] **Step 1: Extend the fixture**

Append a frag to `fixtures/wkfix/01-import/beat.R` so collect_fragments has something to find:

```r
# Wrangle ----
# >>>hole id=clean kind=fill prompt=clean the names
#   solved:
toy <- janitor::clean_names(toy)
#   blank:
toy <- janitor::___(toy)
# <<<hole
# >>>frag id=clean-call
toy <- janitor::clean_names(toy)
# <<<frag
```

Add `fixtures/wkfix/03-report/meta.yml`:

```yaml
type: transform-terminal
slug: 03-report
title: "Report"
template: report.qmd
packages: []
```

Add `fixtures/wkfix/03-report/report.qmd`:

````qmd
---
title: "Toy report"
format: html
---

```{r}
{{frag:clean-call}}
summary(toy)
```
````

Extend `fixtures/wkfix/workshop.yml` steps:

```yaml
steps: [00-setup, 01-import, 02-eda, 03-report]
```

- [ ] **Step 2: Write the failing materialize test (append to test-materialize.R)**

```r
test_that("materialize writes a substituted report.qmd for transform-terminal steps (no .R)", {
  out <- tempfile("wkout-")
  wk  <- read_workshop(testthat::test_path("fixtures", "wkfix"))
  materialize_workshop(wk, out)

  rep_dir <- file.path(out, "steps", "03-report")
  expect_true(file.exists(file.path(rep_dir, "report.qmd")))
  expect_false(file.exists(file.path(rep_dir, "03-report.R")))   # transform: no student .R
  rq <- readLines(file.path(rep_dir, "report.qmd"))
  expect_true(any(grepl("clean_names\\(toy\\)", rq)))            # token substituted
  expect_false(any(grepl("\\{\\{frag:", rq)))                    # no leftover tokens
  # append steps still produce their .R:
  expect_true(file.exists(file.path(out, "steps", "02-eda", "02-eda.R")))
})
```

- [ ] **Step 3: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL — report.qmd not written; and the Task-2 transform test (still skipped) should be un-skipped now.

In `test-config.R`, remove the `skip("transform fixture added in Task 6")` line so that test runs.

- [ ] **Step 4: Implement transform branch (edit materialize.R)**

Replace the materialize loop body so it branches on step type, and collect fragments once up front:

```r
materialize_workshop <- function(wk, out_dir) {
  beats <- lapply(wk$steps, `[[`, "beat")
  metas <- lapply(wk$steps, `[[`, "meta")
  frags <- collect_fragments(wk)

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (sub in c("steps", "full", "_solved")) unlink(file.path(out_dir, sub), recursive = TRUE)

  append_beats <- beats[vapply(metas, function(m) identical(m$type, "append"), logical(1))]

  for (n in seq_along(wk$steps) - 1L) {           # 0-based
    step  <- wk$steps[[n + 1L]]
    slug  <- step$slug
    sdir  <- file.path(out_dir, "steps", slug)
    if (identical(step$meta$type, "transform-terminal")) {
      .write_lines(render_report(step$template, frags), file.path(sdir, "report.qmd"))
    } else {
      ai <- sum(vapply(metas[seq_len(n + 1L)], function(m) identical(m$type, "append"), logical(1))) - 1L
      .write_lines(assemble_step(append_beats, ai), file.path(sdir, paste0(slug, ".R")))
    }
    .write_lines(packages_through(metas, n), file.path(sdir, "packages.txt"))
    .write_lines(character(0), file.path(sdir, ".here"))
    .copy_data_raw(wk$data_raw_dir, sdir)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(append_beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$data_raw_dir, full_dir)
  invisible(out_dir)
}
```

> Note `ai` (the append-index): transform steps are skipped in the append sequence, so an append step's index among append beats is its count of append steps so far minus one. With 05 the only transform step (at the end), `ai == n` for all append steps in `mlt-r-basic`; the formula stays correct if a transform step is ever inserted earlier.

- [ ] **Step 5: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (materialize + config transform tests green).

- [ ] **Step 6: Commit**

```bash
git add dev/mltbuild/R/materialize.R dev/mltbuild/tests/testthat
git commit -m "mltbuild: materialize transform-terminal steps (render report.qmd, skip .R)"
```

---

## Task 7: Author `workshops/mlt-r-basic/_authoring/` (hand-migrated beats + fragments + report)

**Files (create):**
- `workshops/mlt-r-basic/_authoring/workshop.yml`
- `.../00-setup/{meta.yml,beat.R}` … `.../04-zoo/{meta.yml,beat.R}`
- `.../05-report/{meta.yml,report.qmd}`

This is the migration. Content transcribed from the current `steps/*.qmd` + `R/yourturn-*.R`, with the new beat/hole/fragment grammar and the per-oracle seeding (see Design notes). The "given" recaps are dropped (regenerated by assembly).

- [ ] **Step 1: workshop.yml**

`workshops/mlt-r-basic/_authoring/workshop.yml`:

```yaml
slug: mlt-r-basic
r_version: "4.6.0"
ppm_snapshot: "2026-06-01"
dataset: data-raw/heart_failure.csv
steps: [00-setup, 01-import, 02-eda, 03-logistic, 04-zoo, 05-report]
```

- [ ] **Step 2: 00-setup**

`.../00-setup/meta.yml`:

```yaml
type: append
slug: 00-setup
title: "Step 00 — Setup"
packages: [here, rio]
```

`.../00-setup/beat.R` (the first formative — the import is the hole):

```r
# Setup ----
library(here)
library(rio)

# >>>hole id=load kind=fill prompt=load the clinical CSV with rio + here
#   solved:
hf_raw <- import(here("data-raw", "heart_failure.csv"), setclass = "tibble")
#   blank:
hf_raw <- import(here("data-raw", "___"), setclass = "tibble")
# <<<hole
dim(hf_raw)
```

- [ ] **Step 3: 01-import (defines `wrangle-tail`)**

`.../01-import/meta.yml`:

```yaml
type: append
slug: 01-import
title: "Step 01 — Import & wrangle"
packages: [tidyverse, janitor]
```

`.../01-import/beat.R`:

```r
library(tidyverse)
library(janitor)

# Wrangle ----
# >>>hole id=wrangle kind=fill prompt=clean names; drop the leaky time column; build the event-first outcome factor; factor the 0/1 flags
#   solved:
hf <- hf_raw |>
  # >>>frag id=wrangle-tail
  clean_names() |>
  select(-time) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "died", "survived"),
      levels = c("died", "survived"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor))
  # <<<frag
#   blank:
hf <- hf_raw |>
  clean_names() |>
  select(-___) |>
  mutate(
    outcome = factor(
      if_else(death_event == 1, "___", "___"),
      levels = c("___", "___"),
    ),
  ) |>
  select(-death_event) |>
  mutate(across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), ___))
# <<<hole

glimpse(hf)

# Quick checks: 12 columns, a 2-level factor (event first), ~32% events.
ncol(hf)
levels(hf$outcome)
count(hf, outcome)
```

- [ ] **Step 4: 02-eda**

`.../02-eda/meta.yml`:

```yaml
type: append
slug: 02-eda
title: "Step 02 — Clinical EDA"
packages: [gtsummary]
```

`.../02-eda/beat.R`:

```r
library(gtsummary)

# Stratified summary table ----
hf |>
  tbl_summary(
    by = outcome,
    include = c(
      age, sex, ejection_fraction, serum_creatinine, serum_sodium,
      creatinine_phosphokinase, platelets, anaemia, diabetes,
      high_blood_pressure, smoking,
    ),
  )

# Ejection fraction by outcome ----
ef_plot <- hf |>
  ggplot(aes(x = outcome, y = ejection_fraction, fill = outcome)) +
  geom_boxplot() +
  theme_minimal()

ef_plot
```

> Note: the original `02-eda.qmd` `ggsave()`s to `output/`. The generated step folders have no `output/` by default and the saved PNG is not part of any number; dropping `ggsave()` keeps the beat self-contained. (If the teacher render needs the file on disk, the orchestration creates `output/` — see Task 10 Step 4.)

- [ ] **Step 5: 03-logistic (defines `split`, `recipe`; score is the hole)**

`.../03-logistic/meta.yml`:

```yaml
type: append
slug: 03-logistic
title: "Step 03 — Logistic spine"
packages: [tidymodels]
```

`.../03-logistic/beat.R`:

```r
library(tidymodels)
set.seed(123)

# Split ----
# >>>frag id=split
data_split <- initial_split(hf, prop = 0.75, strata = outcome)
train <- training(data_split)
test  <- testing(data_split)
# <<<frag

# Recipe (no imputation: heart_failure has no missing values) ----
# >>>frag id=recipe
base_rec <- recipe(outcome ~ ., data = train) |>
  step_dummy(all_nominal_predictors()) |>
  step_zv(all_predictors()) |>
  step_normalize(all_numeric_predictors())
# <<<frag

# Spec ----
log_spec <- logistic_reg() |> set_engine("glm")

# Workflow ----
log_wf <- workflow() |>
  add_recipe(base_rec) |>
  add_model(log_spec)

# Fit ----
log_fit <- fit(log_wf, data = train)
log_fit

# Predict & score (both metrics) ----
hf_metrics <- metric_set(roc_auc, pr_auc)

# >>>hole id=score kind=fill prompt=augment the test set, then score both metrics on .pred_died
#   solved:
log_fit |>
  augment(new_data = test) |>
  hf_metrics(truth = outcome, .pred_died)
#   blank:
log_fit |>
  augment(new_data = ___) |>
  hf_metrics(truth = outcome, ___)
# <<<hole
```

- [ ] **Step 6: 04-zoo (defines `specs`; finalize is the hole; keeps the future toggle + double seed)**

`.../04-zoo/meta.yml`:

```yaml
type: append
slug: 04-zoo
title: "Step 04 — The zoo, tuned"
packages: [workflowsets, future, glmnet, kknn, kernlab, ranger]
```

`.../04-zoo/beat.R`:

```r
library(workflowsets)
library(future)

# Optional speed-up: parallelize tuning across cores, leaving one for the OS.
# Comment this line out and everything still runs — just sequentially.
plan(multisession, workers = max(1, parallel::detectCores() - 1))
set.seed(123)

# Model specs (hyper-parameters left to tune) ----
# >>>frag id=specs
penlog_spec <- logistic_reg(penalty = tune(), mixture = tune()) |> set_engine("glmnet")
knn_spec    <- nearest_neighbor(neighbors = tune()) |> set_engine("kknn")   |> set_mode("classification")
svm_spec    <- svm_rbf(cost = tune(), rbf_sigma = tune()) |> set_engine("kernlab") |> set_mode("classification")
rf_spec     <- rand_forest(mtry = tune(), min_n = tune()) |> set_engine("ranger")  |> set_mode("classification")
# <<<frag

# Resamples ----
folds <- vfold_cv(train, v = 5, strata = outcome)

# Two metrics, watched together ----
hf_metrics <- metric_set(roc_auc, pr_auc)

# Workflow set ----
wf_set <- workflow_set(
  preproc = list(rec = base_rec),
  models  = list(penlog = penlog_spec, knn = knn_spec, svm = svm_spec, rf = rf_spec),
)

# Tune every workflow ----
wf_res <- wf_set |>
  workflow_map(
    "tune_grid",
    resamples = folds,
    grid      = 8,
    metrics   = hf_metrics,
    verbose   = TRUE,
    seed      = 123,
  )

# Compare the candidates ----
rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE)
autoplot(wf_res)

# Finalize & validate ----
# >>>hole id=finalize kind=fill prompt=rank, pull the winner id + best params, finalize, then last_fit on the original split
#   solved:
best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(wflow_id)
best_res    <- extract_workflow_set_result(wf_res, best_id)
best_params <- select_best(best_res, metric = "roc_auc")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(best_params)

final_fit <- last_fit(final_wf, split = data_split, metrics = metric_set(roc_auc, pr_auc, accuracy))
collect_metrics(final_fit)
#   blank:
best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(___)
best_res    <- extract_workflow_set_result(wf_res, ___)
best_params <- select_best(best_res, metric = "___")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(___)

final_fit <- last_fit(final_wf, split = ___, metrics = metric_set(roc_auc, pr_auc, accuracy))
collect_metrics(final_fit)
# <<<hole

# Test-set ROC & PR curves ----
preds <- collect_predictions(final_fit)
preds |> roc_curve(outcome, .pred_died) |> autoplot()
preds |> pr_curve(outcome, .pred_died) |> autoplot()
```

> Dropped from the beat vs the old `04-zoo.qmd`: the `saveRDS(final_fit, …)` / `saveRDS(wf_rank, …)` lines. The report no longer reloads a hand-made cache (it re-runs the analysis), so the persisted `.rds` files are obsolete (spec §4.2, and the 2026-06-01 design change baked into `05-report`).

- [ ] **Step 7: 05-report (transform-terminal; single seed; 4 frag tokens)**

`.../05-report/meta.yml`:

```yaml
type: transform-terminal
slug: 05-report
title: "Step 05 — Reproducible report"
template: report.qmd
packages: []
```

`.../05-report/report.qmd` (transcribed from the `05-report` oracle, shared blocks → tokens; **single** `set.seed(123)`):

````qmd
---
title: "Practical AI for Medical Data — a reproducible model report"
subtitle: "Predicting in-hospital death after a heart-failure episode"
date: today
format:
  html:
    embed-resources: true
    toc: true
    code-fold: true
execute:
  warning: false
  message: false
---

## What this report does

This is the reproducible deliverable of the workshop. It **runs the entire analysis as it
renders** — split → preprocess → tune four model families on cross-validation → finalize the
winner → validate once on the held-out test set — and then reports the result. Nothing is
typed in by hand and nothing is reloaded from a private cache: **every number and figure below
was produced by the same render that prints it.** Re-render on any machine with the pinned
environment and you reproduce the *analysis*, not just the document.

```{r setup}
library(here)
library(rio)
library(tidyverse)
library(janitor)
library(tidymodels)
library(gtsummary)

set.seed(123)
```

## The cohort

```{r cohort}
# Load & wrangle exactly as in Steps 00-01 ----
hf <- import(here("data-raw", "heart_failure.csv"), setclass = "tibble") |>
{{frag:wrangle-tail}}
```

The analysis cohort is the heart-failure clinical records (Chicco & Jurman 2020):
`r nrow(hf)` patients, of whom
`r scales::percent(mean(hf$outcome == "died"), accuracy = 0.1)` died during follow-up. The
table below summarises the eleven candidate predictors, stratified by outcome.

```{r baseline}
hf |>
  tbl_summary(
    by = outcome,
    include = c(
      age, sex, ejection_fraction, serum_creatinine, serum_sodium,
      creatinine_phosphokinase, platelets, anaemia, diabetes,
      high_blood_pressure, smoking,
    ),
  )
```

## Split and preprocess

We hold out a stratified 25% test set that **no tuning ever sees**, and build the same recipe
used throughout the workshop (dummy-code, drop zero-variance, normalize — no imputation, the
data has no missing values).

```{r split-recipe}
# Split: a held-out test set the tuning never touches ----
{{frag:split}}

# Recipe ----
{{frag:recipe}}
```

## Tune four model families on cross-validation

Each spec leaves its hyperparameters as `tune()`. We bundle the one recipe with the four
specs into a `workflow_set`, then tune every workflow over a shared 5-fold cross-validation,
scoring **both** AUC-ROC and AUC-PR.

```{r tune}
# Model specs (hyperparameters left to tune) ----
{{frag:specs}}

# One shared resampling scheme and metric set ----
folds      <- vfold_cv(train, v = 5, strata = outcome)
hf_metrics <- metric_set(roc_auc, pr_auc)

# Bundle {one recipe} x {four specs}, then tune every workflow ----
wf_set <- workflow_set(
  preproc = list(rec = base_rec),
  models  = list(penlog = penlog_spec, knn = knn_spec, svm = svm_spec, rf = rf_spec),
)

wf_res <- wf_set |>
  workflow_map(
    "tune_grid",
    resamples = folds,
    grid      = 8,
    metrics   = hf_metrics,
    seed      = 123,
    verbose   = FALSE,
  )
```

The ranking by cross-validated AUC-ROC (the honest comparison — it never touches the test
set):

```{r ranking}
wf_rank <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE)

model_label <- c(
  rec_penlog = "Penalized logistic (glmnet)",
  rec_knn    = "k-nearest neighbours",
  rec_svm    = "RBF support vector machine",
  rec_rf     = "Random forest"
)

wf_rank |>
  dplyr::filter(.metric == "roc_auc") |>
  transmute(
    Model        = model_label[wflow_id],
    `CV AUC-ROC` = round(mean, 3),
    `Std. error` = round(std_err, 3),
    Rank         = rank,
  )
```

## Finalize the winner and validate once

We take the top-ranked workflow, lock in its best hyperparameters, refit on the full training
set, and score it **once** on the untouched test set.

```{r finalize}
best_id     <- wf_rank |>
  dplyr::filter(.metric == "roc_auc") |>
  dplyr::slice_min(rank, n = 1) |> dplyr::pull(wflow_id)
best_res    <- extract_workflow_set_result(wf_res, best_id)
best_params <- select_best(best_res, metric = "roc_auc")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(best_params)

final_fit <- last_fit(
  final_wf,
  split   = data_split,
  metrics = metric_set(roc_auc, pr_auc, accuracy),
)

cv_auc       <- wf_rank |>
  dplyr::filter(.metric == "roc_auc") |>
  dplyr::slice_min(rank, n = 1) |> dplyr::pull(mean)
test_metrics <- collect_metrics(final_fit)
get_metric   <- function(m) {
  test_metrics |> dplyr::filter(.metric == m) |> dplyr::pull(.estimate)
}
test_roc <- get_metric("roc_auc")
test_pr  <- get_metric("pr_auc")
test_acc <- get_metric("accuracy")
```

The winner is **`r model_label[best_id]`**. Its cross-validated AUC-ROC was
**`r round(cv_auc, 3)`**; refit on the training split and scored once on the held-out test
set, it reached a test AUC-ROC of **`r round(test_roc, 3)`**, an AUC-PR of
**`r round(test_pr, 3)`**, and an accuracy of **`r round(test_acc, 3)`**. The gap between the
cross-validated and the single-split test numbers is the honest noise of a small cohort
(~`r nrow(test)` test patients) — which is exactly why we pre-commit to one held-out
evaluation and read it *alongside* the cross-validation, never a single number on its own.

## Test-set ROC and PR curves

```{r curves}
preds <- collect_predictions(final_fit)

preds |> roc_curve(outcome, .pred_died) |> autoplot()
preds |> pr_curve(outcome, .pred_died) |> autoplot()
```

## Reproducibility

Every result above is reproducible by construction:

- **One render, one analysis.** This report *executes* the split → tune → finalize →
  `last_fit` pipeline as it renders, so the printed numbers and the code that produced them
  are guaranteed to be the same object — they cannot drift apart, because there is no
  hand-made cache to fall out of date.
- **Fixed randomness.** `set.seed(123)` makes the split, the folds, and the tuning grid
  deterministic, so the same machine re-renders to the same numbers.
- **Pinned environment.** Package versions are locked with `renv`; `renv::snapshot()` records
  them in `renv.lock`, and `renv::restore()` rebuilds the exact library on another machine.
- **Stable paths.** All file access goes through `here::here()`, anchored to this step's
  `.here` sentinel, so the report renders identically regardless of the working directory.
- **One outcome convention.** The event is `died` (the *first* factor level), so every metric
  scores `.pred_died` as the positive class by default — consistently, end to end.

That is the whole point: a clinical model someone else can re-run — and reproduce the
*analysis*, number for number, not just the document. When an analysis grows too heavy to
re-run on every render, the next step is not a hand-made `.rds` cache but a **pipeline**
(`targets`, the Advanced capstone): it caches *with* inspectable, hash-checked intermediate
targets — each one re-derivable and auditable — and compiles this very report itself.
````

- [ ] **Step 8: Verify the authoring tree assembles (temp materialize)**

Run:
```bash
"$RS" -e '
for (f in list.files("dev/mltbuild/R", "[.]R$", full.names=TRUE)) source(f)
wk <- read_workshop("workshops/mlt-r-basic/_authoring")
out <- tempfile("mltchk-"); materialize_workshop(wk, out)
cat("steps:", paste(basename(list.dirs(file.path(out,"steps"), recursive=FALSE)), collapse=", "), "\n")
s4 <- readLines(file.path(out,"steps","04-zoo","04-zoo.R"))
cat("04 has no ___ outside the finalize blank? blanks:", sum(grepl("___", s4)), "\n")
cat("04 frag markers leaked:", sum(grepl(">>>frag|<<<frag", s4)), "\n")
rq <- readLines(file.path(out,"steps","05-report","report.qmd"))
cat("report tokens left:", sum(grepl("\\{\\{frag:", rq)), " wrangle inlined:", any(grepl("clean_names", rq)), "\n")
cat("full.R blanks:", sum(grepl("___", readLines(file.path(out,"full","full.R")))), "\n")
'
```
Expected: 6 step dirs; `04 frag markers leaked: 0`; `report tokens left: 0` and `wrangle inlined: TRUE`; `full.R blanks: 0`. (Step 04 will show some `___` — only the finalize blank — that is expected; the key checks are no frag leakage and no leftover tokens.)

- [ ] **Step 9: Commit**

```bash
git add workshops/mlt-r-basic/_authoring
git commit -m "mlt-r-basic: hand-migrate steps into _authoring/ fragment source"
```

---

## Task 8: Preserve the old solved HTML as a transient visual reference

**Files:**
- Create (transient, gitignored): `workshops/mlt-r-basic/_authoring/_oracle/*-solved.html`
- Modify: `.gitignore` (root)

The 6 old `*-solved.html` currently live UNDER `steps/` — the first real build (Task 10) wipes `steps/`. Copy them to safety FIRST so they survive as a **visual reference** for the spot-checks (Tasks 10/11). We do **not** extract or pin any numbers (Decision 4): they are a "does the new output look like a workshop output?" reference, nothing more, and can be deleted after migration.

- [ ] **Step 1: Copy the old solved HTML out of the build path**

Run:
```bash
mkdir -p workshops/mlt-r-basic/_authoring/_oracle
cp workshops/mlt-r-basic/steps/00-setup/00-setup-solved.html      workshops/mlt-r-basic/_authoring/_oracle/
cp workshops/mlt-r-basic/steps/01-import/01-import-solved.html    workshops/mlt-r-basic/_authoring/_oracle/
cp workshops/mlt-r-basic/steps/02-eda/02-eda-solved.html          workshops/mlt-r-basic/_authoring/_oracle/
cp workshops/mlt-r-basic/steps/03-logistic/03-logistic-solved.html workshops/mlt-r-basic/_authoring/_oracle/
cp workshops/mlt-r-basic/steps/04-zoo/04-zoo-solved.html          workshops/mlt-r-basic/_authoring/_oracle/
cp workshops/mlt-r-basic/steps/05-report/05-report-solved.html    workshops/mlt-r-basic/_authoring/_oracle/
ls -la workshops/mlt-r-basic/_authoring/_oracle/
```
Expected: 6 HTML files copied.

- [ ] **Step 2: Keep the reference copies out of git**

They are ~7 MB and transient. Append to root `.gitignore`:
```
# Transient visual reference (old solved HTML; not committed — see plan 2 Task 8)
workshops/*/_authoring/_oracle/
```

```bash
git add .gitignore
git commit -m "mlt-r-basic: keep old solved HTML as transient visual reference (gitignored)"
```

> No numeric oracle, no `extract-oracle.R`, no `parity-oracle.yml`, no `rvest` dependency — parity is structural (Decision 4). These reference copies may be deleted once the migration is verified.

---

## Task 9: Per-step `renv.lock` generator

**Files:**
- Create: `dev/mltbuild/R/renvlock.R`

`write_step_lock()` wraps the verified incantation. It is impure (runs renv) so it is verified by running, not unit tests; the cumulative package logic it consumes (`packages_through`) is already tested.

- [ ] **Step 1: Implement renvlock.R**

```r
# Generate one per-step renv.lock = cumulative packages 00..N-1, pinned to PPM.
# Must be called from a process whose getwd() is the workshop project root (so
# renv/activate.R has been sourced and the project library is active).

write_step_lock <- function(lockfile_abs, packages, ppm_url) {
  if (!length(packages)) return(invisible(NULL))   # step 00: no lock
  options(repos = c(CRAN = ppm_url))
  dir.create(dirname(lockfile_abs), recursive = TRUE, showWarnings = FALSE)
  renv::snapshot(lockfile = lockfile_abs, packages = packages, prompt = FALSE)
  invisible(lockfile_abs)
}
```

- [ ] **Step 2: Smoke-test on a single step's package set**

Run:
```bash
"$RS" -e '
setwd("workshops/mlt-r-basic"); source("renv/activate.R")
src <- file.path("..","..","dev","mltbuild","R")
for (f in list.files(src, "[.]R$", full.names=TRUE)) source(f)
tl <- tempfile(fileext=".lock")
write_step_lock(tl, c("here","rio","tidyverse","janitor"), "https://packagemanager.posit.co/cran/2026-06-01")
lf <- renv::lockfile_read(tl)
cat("npkgs:", length(lf$Packages), " repo:", lf$R$Repositories$CRAN, "\n")
cat("has janitor:", "janitor" %in% names(lf$Packages), " has dplyr(dep):", "dplyr" %in% names(lf$Packages), "\n")
'
```
Expected: `npkgs` in the dozens, `repo: https://packagemanager.posit.co/cran/2026-06-01`, `has janitor: TRUE`, `has dplyr(dep): TRUE` (recursive closure pulled in).

- [ ] **Step 3: Commit**

```bash
git add dev/mltbuild/R/renvlock.R
git commit -m "mltbuild: write_step_lock() per-step renv.lock via renv::snapshot(packages=)"
```

---

## Task 10: Real build orchestration — materialize + locks + render into `workshops/mlt-r-basic`

**Files:**
- Modify: `dev/mltbuild/build.R`

Replace the plan-1 stub (which wrote to a tempdir) with the real wiring. The build: materialize into `workshops/mlt-r-basic/`; write per-step locks; render the teacher HTML for each append step and the report HTML for the transform step, into `_solved/`.

- [ ] **Step 1: Implement the orchestration build.R**

`dev/mltbuild/build.R`:

```r
# Build a workshop end-to-end from its _authoring/ source.
# Usage (from repo root, R 4.6):
#   Rscript dev/mltbuild/build.R workshops/mlt-r-basic
# Produces, under <workshop>/: steps/<NN>/{<NN>.R | report.qmd, packages.txt, renv.lock, .here, data-raw/},
# full/, and _solved/<NN>.html (teacher tabs for append; rendered report for transform).
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
workshop  <- normalizePath(args[[1]], winslash = "/")
authoring <- file.path(workshop, "_authoring")
root      <- normalizePath(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))), winslash = "/")
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)

# Make quarto's child R see the workshop library (packages are NOT in the global lib).
wlib <- file.path(workshop, "renv", "library", "windows", "R-4.6", "x86_64-w64-mingw32")
Sys.setenv(R_LIBS = normalizePath(wlib, winslash = "/"))
.libPaths(c(normalizePath(wlib, winslash = "/"), .libPaths()))

wk  <- read_workshop(authoring)
ppm <- paste0("https://packagemanager.posit.co/cran/", wk$ppm_snapshot)

# 1. Steps + full (.R / report.qmd, packages.txt, .here, data-raw)
materialize_workshop(wk, workshop)

# 2. Per-step renv.lock (from inside the project so renv is active)
old <- getwd(); on.exit(setwd(old), add = TRUE)
setwd(workshop); source(file.path("renv", "activate.R"))
metas <- lapply(wk$steps, `[[`, "meta")
for (n in seq_along(wk$steps) - 1L) {
  slug <- wk$steps[[n + 1L]]$slug
  pk   <- packages_through(metas, n)
  write_step_lock(file.path(workshop, "steps", slug, "renv.lock"), pk, ppm)
}
# full/ lock = all packages
all_pkgs <- unique(unlist(lapply(metas, function(m) m$packages)))
write_step_lock(file.path(workshop, "full", "renv.lock"), all_pkgs, ppm)
setwd(old)

# 3. Render _solved/ HTML
solved_dir <- file.path(workshop, "_solved"); dir.create(solved_dir, showWarnings = FALSE)
beats <- lapply(wk$steps, `[[`, "beat")
append_beats <- beats[vapply(metas, function(m) identical(m$type, "append"), logical(1))]

render_one <- function(qmd_abs, html_out) {
  quarto::quarto_render(input = qmd_abs, quiet = TRUE)
  produced <- sub("[.]qmd$", ".html", qmd_abs)
  file.copy(produced, html_out, overwrite = TRUE); unlink(produced)
}

ai <- -1L
for (n in seq_along(wk$steps) - 1L) {
  step <- wk$steps[[n + 1L]]; slug <- step$slug
  sdir <- file.path(workshop, "steps", slug)
  dir.create(file.path(sdir, "output"), showWarnings = FALSE)   # for any ggsave in solved
  if (identical(step$meta$type, "transform-terminal")) {
    render_one(file.path(sdir, "report.qmd"), file.path(solved_dir, paste0(slug, ".html")))
  } else {
    ai <- ai + 1L
    blank  <- assemble_step(append_beats, ai)
    solved <- assemble_solved_through(append_beats, ai)
    tq <- file.path(sdir, paste0("_teacher-", slug, ".qmd"))
    writeLines(build_teacher_qmd(step$meta$title, blank, solved), tq)
    render_one(tq, file.path(solved_dir, paste0(slug, ".html")))
  }
  cat("rendered", slug, "\n")
}
cat("BUILD OK:", wk$slug, "->", workshop, "\n")
```

> Rendering uses the build machine's full workshop library (set via `R_LIBS`), NOT a per-step `renv::restore()` — the per-step locks are for *students*. Each teacher `.qmd` is rendered with its step folder as the input dir, so `here()`/`.here`/`data-raw/` resolve locally. The temporary `_teacher-<slug>.qmd` is left in the step folder (harmless, gitignored with the rest of `steps/`); the produced `.html` is moved into `_solved/`.

- [ ] **Step 2: Run the full build**

Run: `"$RS" dev/mltbuild/build.R workshops/mlt-r-basic`
Expected: `rendered 00-setup` … `rendered 05-report`, then `BUILD OK: mlt-r-basic -> …`. This executes the zoo tuning twice (step 04 solved tab + report) — expect ~tens of seconds.

- [ ] **Step 3: Verify the generated tree**

Run:
```bash
ls workshops/mlt-r-basic/_solved/
ls workshops/mlt-r-basic/steps/04-zoo/
"$RS" -e 'lf <- jsonlite::fromJSON("workshops/mlt-r-basic/steps/04-zoo/renv.lock"); cat("step04 lock has ranger:", "ranger" %in% names(lf$Packages$Packages %||% lf$Packages), "\n")' 2>/dev/null || echo "(inspect lock manually)"
test -f workshops/mlt-r-basic/steps/00-setup/renv.lock && echo "FAIL: step 00 must NOT have a lock" || echo "OK: step 00 has no lock"
```
Expected: `_solved/` has 6 HTML; `steps/04-zoo/` has `04-zoo.R`, `renv.lock`, `packages.txt`, `.here`, `data-raw/`; step 00 has NO `renv.lock`.

- [ ] **Step 4: Visual smoke check (chrome-devtools)**

Open `workshops/mlt-r-basic/_solved/04-zoo.html` and `05-report.html` in chrome-devtools; confirm the To-fill/Solved tabs render (for 04), the report renders end-to-end (for 05), the ranking table + ROC/PR curves are present, and there are no error tracebacks. (Visual-verification rule — the artifact is not "done" until inspected.)

- [ ] **Step 5: Commit (the build script only — generated tree is committed-then-ignored in Task 12)**

```bash
git add dev/mltbuild/build.R
git commit -m "mltbuild: real build orchestration (materialize + per-step locks + render _solved)"
```

---

## Task 11: Structural parity gate

**Files:**
- Create: `dev/mltbuild/parity.R`

Structural, not numeric (Decision 4): each generated `_solved/<step>.html` must render the expected **kinds** of output. The build already fails loudly on a render error (knitr halts on error by default), so this gate adds per-step *presence* assertions: required keywords (proof the right method ran) + a minimum plot count. Numbers are not pinned. Base R only — no `rvest`, no oracle yml.

> Note: the To-fill tab legitimately contains `___` (the blank student code shown verbatim), so this gate must **not** assert "no `___` anywhere". A `___` that broke execution would already have failed the render.

- [ ] **Step 1: Implement the structural checker**

`dev/mltbuild/parity.R`:

```r
# Structural parity: each generated _solved/<step>.html renders the expected KINDS
# of output. Numbers are NOT pinned (the workshop teaches a method; seeds / renv /
# targets / torch legitimately vary). Run: Rscript dev/mltbuild/parity.R workshops/mlt-r-basic
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
workshop <- args[[1]]

# Per-step expectations: kw = substrings that MUST appear (in code echo or output);
# imgs = minimum number of embedded plots (<img ...>).
checks <- list(
  "00-setup"    = list(kw = c("panel-tabset", "To fill", "Solved", "dim"),        imgs = 0L),
  "01-import"   = list(kw = c("outcome", "died", "survived", "glimpse"),          imgs = 0L),
  "02-eda"      = list(kw = c("ejection_fraction", "tbl_summary"),                imgs = 1L),
  "03-logistic" = list(kw = c("roc_auc", "pr_auc", "augment"),                    imgs = 0L),
  "04-zoo"      = list(kw = c("penlog", "knn", "svm", "rf", "accuracy", "last_fit"), imgs = 2L),
  "05-report"   = list(kw = c("Random forest", "roc_auc", "Reproducibility"),     imgs = 2L)
)

fails <- character(0)
for (slug in names(checks)) {
  f <- file.path(workshop, "_solved", paste0(slug, ".html"))
  if (!file.exists(f)) { fails <- c(fails, paste0(slug, " - HTML not produced")); next }
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  for (k in checks[[slug]]$kw) {
    if (!grepl(k, html, fixed = TRUE)) fails <- c(fails, paste0(slug, " - missing: ", k))
  }
  nimg <- length(gregexpr("<img", html, fixed = TRUE)[[1]])
  if (gregexpr("<img", html, fixed = TRUE)[[1]][1] == -1L) nimg <- 0L
  if (nimg < checks[[slug]]$imgs) {
    fails <- c(fails, paste0(slug, " - expected >=", checks[[slug]]$imgs, " plots, found ", nimg))
  }
}
if (length(fails)) {
  cat("STRUCTURAL PARITY FAIL\n", paste(fails, collapse = "\n"), "\n"); quit(status = 1L)
}
cat("STRUCTURAL PARITY OK - every step renders the expected outputs.\n")
```

- [ ] **Step 2: Run the gate**

Run: `"$RS" dev/mltbuild/parity.R workshops/mlt-r-basic`
Expected: `STRUCTURAL PARITY OK - …`.

If it FAILS: use superpowers:systematic-debugging. Likely causes: (a) a fragment captured the wrong lines (inspect `steps/05-report/report.qmd` for leftover `{{frag:}}` or a malformed pipe); (b) a beat didn't `library()` something so an output is missing; (c) a plot keyword/`<img` is genuinely absent (the render swallowed a chunk). Fix the root cause; adjust a `checks` keyword only if it was simply wrong about the expected output, never to paper over a real gap.

- [ ] **Step 3: Visual spot-check (chrome-devtools)**

Open the regenerated `_solved/04-zoo.html` and `_solved/05-report.html` beside the transient old `_authoring/_oracle/*-solved.html`; confirm the new outputs are the *same kind* (ranking table with 4 models, winner statement, ROC/PR curves render). Numbers differing is expected and fine.

- [ ] **Step 4: Commit**

```bash
git add dev/mltbuild/parity.R
git commit -m "mltbuild: structural parity gate (renders + expected output kinds)"
```

---

## Task 12: Flip the repo — ignore generated tree, drop legacy sources

**Files:**
- Modify: `.gitignore` (root)
- Modify: `workshops/mlt-r-basic/.gitignore`
- Modify: `workshops/mlt-r-basic/CLAUDE.md`, `workshops/mlt-r-basic/README.md`
- Remove from index: legacy `workshops/mlt-r-basic/steps/**` hand-authored files

Only after Task 11 is green. The generated `steps/`, `full/`, `_solved/` become build output; `_authoring/` + `data-raw/` are the committed source.

- [ ] **Step 1: Ignore the generated subtrees (root .gitignore)**

Append to root `.gitignore`:
```
# Generated workshop trees (build on-demand from _authoring/ via dev/mltbuild/build.R)
workshops/*/steps/
workshops/*/full/
workshops/*/_solved/
```

- [ ] **Step 2: Replace the legacy per-workshop .gitignore**

`workshops/mlt-r-basic/.gitignore` (the old rules targeted hand-authored `steps/` artifacts — now the whole generated tree is ignored at root). Reduce it to renv + R cruft only:
```
.Rproj.user
.Rhistory
.RData
.Ruserdata
renv/library/
renv/local/
renv/cellar/
renv/staging/
.quarto/
.Renviron
```

- [ ] **Step 3: Drop the legacy generated tree from the index**

```bash
git rm -r --cached workshops/mlt-r-basic/steps workshops/mlt-r-basic/full 2>/dev/null; true
git status --short | head -40
```
Expected: the old `steps/**` (`.qmd`, `yourturn-*.R`, `*-solved.html`, `.keep`, `output/*`) leave the index; the working-tree generated files remain but are now ignored. Confirm `_authoring/`, `data-raw/`, `renv.lock`, `R/`, `requirements.R` are STILL tracked.

> `_solved.R`, `requirements.R`, `_manifest.yml`, `R/`, `data-raw/`, `renv.lock` at the workshop root stay tracked — they are not under the generated subtrees. The legacy root-level `R/_dependencies.R` hack (for `set_engine` strings) is now redundant (beat 04 enumerates the engines in its meta → the per-step lock includes them); leave the file for the live workshop's own `renv.lock` but note it in the README.

- [ ] **Step 4: Update workshop docs**

In `workshops/mlt-r-basic/CLAUDE.md`, append under the conventions:
```markdown
- SOURCE OF TRUTH is `_authoring/` (fragment beats + report template). `steps/`, `full/`,
  `_solved/` are GENERATED by `dev/mltbuild/build.R` and gitignored — never edit them by hand.
  Rebuild: `Rscript dev/mltbuild/build.R workshops/mlt-r-basic`. Parity gate:
  `Rscript dev/mltbuild/parity.R workshops/mlt-r-basic`.
```

In `workshops/mlt-r-basic/README.md`, add a short "Building from source" section pointing at the same two commands and noting that students receive the generated `steps/` tree (one `renv.lock` per step; step 00 runs `renv::init()`).

- [ ] **Step 5: Commit**

```bash
git add .gitignore workshops/mlt-r-basic/.gitignore workshops/mlt-r-basic/CLAUDE.md workshops/mlt-r-basic/README.md
git add -u workshops/mlt-r-basic/steps workshops/mlt-r-basic/full
git commit -m "mlt-r-basic: treat steps/full/_solved as generated; _authoring/ is source of truth"
```

---

## Task 13: Finalize the command + engine entry; full green

**Files:**
- Modify: `.claude/commands/mlt-workshop-build.md`
- Modify: `dev/mltbuild/build.R` (only if Step 1 surfaces a doc/flag gap)

- [ ] **Step 1: Update the command to the real flow**

`.claude/commands/mlt-workshop-build.md`:
```markdown
---
description: Build a workshop's generated tree (steps/ + full/ + _solved/) from its _authoring/ fragments
---

Build the generated student + teacher tree for one R workshop from its fragment source, then
gate it against the parity oracle.

Arguments: $ARGUMENTS (workshop slug, e.g. `mlt-r-basic`).

Steps:

1. `WS=workshops/$ARGUMENTS`. Confirm `$WS/_authoring/workshop.yml` exists.
2. Build (R 4.6): `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/build.R "$WS"`
   → writes `$WS/{steps,full,_solved}` + per-step `renv.lock` (step 00 has none).
3. Structural parity: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/parity.R "$WS"`
   → must print `STRUCTURAL PARITY OK` (renders + expected output kinds; numbers are not pinned).
4. Report the generated `steps/`, `full/`, `_solved/`.

Notes:
- `steps/`, `full/`, `_solved/` are gitignored (build on-demand); only `_authoring/` + `data-raw/`
  + the workshop `renv.lock` are committed.
- Engine unit tests: `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/run-tests.R`.
- Advanced (`mlt-r-advanced`, targets/transform) lands in a later plan.
```

- [ ] **Step 2: Full engine suite green**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: `[ FAIL 0 | … | PASS … ]` (≥ 45 + the new fragment/report/teacher/materialize/config tests).

- [ ] **Step 3: Clean rebuild + parity from scratch (idempotence)**

Run:
```bash
"$RS" dev/mltbuild/build.R workshops/mlt-r-basic && "$RS" dev/mltbuild/parity.R workshops/mlt-r-basic
```
Expected: `BUILD OK` then `PARITY OK`. Re-running must reproduce identically (idempotent — the hardened unlink wipes only generated subtrees).

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/mlt-workshop-build.md
git commit -m "mltbuild: /mlt-workshop-build runs build + parity gate (real flow)"
```

- [ ] **Step 5: Finishing the branch**

Use superpowers:finishing-a-development-branch to decide merge/PR/cleanup. Do NOT push — present options; the user merges/pushes.

---

## Self-Review

**1. Spec coverage:**

- §4.2 transform-terminal (Basic 05) → Tasks 4, 6, 7 (report.qmd template + tokens + render). Single-seed replication noted.
- §5 holes → all kinds already in engine (plan 1); migration uses `fill`/`prose` as authored.
- §6 step contract (`.here`, `data-raw`, no `.qmd` in append steps, step-00 first formative) → Tasks 6, 7, 10.
- §7 renv per-step (lock = 00..N-1, step 00 none, PPM binaries) → Tasks 9, 10.
- §8 teacher tabbed HTML (To-fill/Solved; transform = rendered report) → Tasks 5, 10.
- §10 invariants: (1) every step renders → Task 10 + structural gate; (2) `.here` present → materialize writes it; (8) lock coherent → Task 9/10; (9) no `___` in executed chunks → solved tab uses solved render (To-fill `___` is non-executed verbatim); (10) parity → Task 11 (structural — numbers not pinned per Decision 4). (Invariants 3–7 are Advanced-specific → next plan.)
- §11 migration → Tasks 7, 8, 11. (Numeric oracle from §11 deliberately downgraded to a transient visual reference at plan review — see Decision 4.)
- Plan-1 deferred list: renv.lock ✓(9/10), teacher HTML ✓(5/10), transform-terminal ✓(4/6/7), Basic migration ✓(7), parity ✓(8/11), **unlink hazard ✓(1)**. (Advanced self-seeding + adversarial verifier subagent → next plan.)

**2. Placeholder scan:** none. Every engine step has runnable code + a test; every orchestration step has an exact command + expected output. The full beat/report content is transcribed inline (Task 7). The `> Note:`/`>` blocks flag intentional scope boundaries or rationale, not missing content.

**3. Type consistency:** `read_workshop()$steps[[k]]` now carries `meta`, `beat` (parsed, append), `template` (lines, transform); `wk$data_raw_dir` consumed by `.copy_data_raw()`. `strip_frag_markers`/`extract_fragment`/`collect_fragments` (fragments.R) feed `render_report()` (report.R) and `assemble_*` (assemble.R). `assemble_solved_through()` + `assemble_step()` feed `build_teacher_qmd()` (teacher.R) in build.R. `packages_through()` feeds `write_step_lock()` (renvlock.R). `materialize_workshop()` branches on `meta$type`. Names are consistent across tasks.

**4. Parity scope (revised at review):** parity is **structural**, not numeric — the workshop teaches a method and exact numbers legitimately vary (seeds, Python/torch in Advanced). Task 8 keeps the old solved HTML only as a transient visual reference; Task 11 asserts each step renders + produces the expected output kinds. No regex-on-numbers oracle, so no false-fail-on-number risk.
