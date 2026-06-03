# MLT workshop build — Advanced end-to-end (plan 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Advanced R workshop (`workshops/mlt-r-advanced/`) to the fragment-build method (`dev/mltbuild/`), so its student/teacher/full tree is generated from a committed `_authoring/` source, and wire it into the unified `/mlt-build` pipeline (ZIP Model C + teacher bundle + release + portal).

**Architecture:** Five steps. `00-recap` is **seeded from the Basic workshop's full pipeline** (self-seeding ripasso: it re-runs Basic end-to-end from `data-raw/heart_failure.csv` with `set.seed`, so the random forest exists in memory — no cross-workshop `.rds`). `01-interpret`, `02-deep-learning`, `03-ellmer` are **cumulative `append` beats** with hole exercises. `04-targets` is a **`transform-terminal` step built with `engine: targets`**: the same end-to-end pipeline expressed target-by-target in `_targets.R` (+ self-contained `R/pipeline-fns.R`), with `report.qmd` rendered **as a `tar_quarto` node**, never standalone — `tar_make()` runs once at build. The engine gains five small capabilities (seed-from, carry-forward, targets terminal, per-step parity config, R-version param); everything else reuses the Basic engine unchanged.

**Tech Stack:** Base-R engine (`dev/mltbuild/`, testthat), Quarto, renv pinned to R 4.6.0 + PPM, Python stdlib pipeline scripts (`scripts/*.py`, pytest). R 4.6.0 at `C:\Program Files\R\R-4.6.0`. SHAP via `kernelshap`+`shapviz`; deep learning via `torch`/`brulee`/`luz`; LLM via `ellmer`; pipeline via `targets`/`tarchetypes`.

**Reference spec:** `dev-docs/superpowers/specs/2026-06-02-mlt-workshop-fragment-build-design.md` (§4.2 transform Advanced, §4.3 extract self-contained, §6 carry-forward, §10 invariants, §11 F2).

**Plan 1 (done, merged):** `2026-06-02-mlt-workshop-build-core.md` — the engine.
**Plan 2 (done, merged):** `2026-06-02-mlt-workshop-basic-end-to-end.md` — Basic migration; the structural template for this plan.
**W1 (done, merged):** `2026-06-03-mlt-build-pipeline-consistency.md` — `/mlt-build` unified entrypoint; left explicit hooks for Advanced (re-add teacher zip, 4th portal button, parity/masking generalization).
**W2 (done, merged):** Advanced deck redesign — already on `main`; W3 must keep the five step slugs byte-identical (`00-recap … 04-targets`) so the deck's go-to-code slides stay valid.

---

## Decisions locked at plan review (2026-06-03)

1. **Branch off `main`** (`a768e59`, post-W2-merge). The in-flight working-tree edits to `steps/04-targets/{04-targets.qmd,_targets.R}` (which wire `report.qmd` as a `tar_quarto` node) are kept as reference for Task B5; unrelated stray edits (`portal.html`, `course/10-best-practices/narrative.html`, deleted `data/…PubMed….csv`, `mlt-r-basic/{.Rproj,renv.lock}`, untracked `_archive/legacy-xaringan/data/`) are stashed/reverted in Task 0.
2. **Self-seeding via the Basic full pipeline.** `00-recap` = Basic's `full.R` (assembled from Basic's `_authoring`, inlined verbatim) + torch pre-warm. No `final_fit.rds` anywhere; the model is in-memory in the cumulative append, and a *trained target* in `04`. (Spec §10.6.)
3. **`04-targets` is the end-to-end pipeline target-by-target** (load → split → recipe → fit → `final_fit` → explanation → report node), not the legacy reload-from-`.rds` version. `report.qmd` reads `tar_read()`, never recomputes (spec §10.5). The standalone `04-targets.qmd` demo is **deleted**.
4. **Ship no `.rds`; degrade gracefully offline.** The ellmer cache and the option-B GPU loss curve are **not** shipped as `.rds`: 03-ellmer prints a labeled fallback when no key is set, and the option-B loss curve becomes a committed `.png`. No change to the `_DENY_SUFFIXES` packer rule.
5. **Generalize the engine where the gate is load-bearing, minimal elsewhere.** New first-class capabilities: `seed_from`, `carry:`, `engine: targets`, per-step `check:`. `check-masking.R` is **reused almost as-is** — because 00-recap embeds Basic's pipeline, Advanced's `full.R` binds a real `final_fit` (`last_fit`), so the existing `tune::collect_metrics(e$final_fit)` extractor works; only the R-version path is parameterized.

## Operative decisions I made (confirm at review; cheap to change)

- **A. `00-recap` seed mechanism = build-time assembly from Basic's `_authoring`.** A `seed_from: mlt-r-basic` field in `00-recap/meta.yml` makes `read_workshop()` prepend `assemble_full(<basic append beats>)` to the beat, union Basic's package set into the step, and mark it seeded (so step 0 ships a full renv project, not bare). DRY (single source = Basic's `_authoring`), order-independent (no dependency on Basic's *generated* tree), self-contained at ship (the generated `00-recap.R` has Basic's pipeline inlined verbatim).
- **B. Build-runtime cost is accepted.** Because the cumulative append re-runs Basic's `workflow_set` tuning inside every step render (00 in 01/02/03/full + 2× in masking), an Advanced build is heavier than Basic's — same order of magnitude as Basic's own build (which already re-renders the tuning ~5×), plus a small live MLP and `kernelshap`. Mitigations live in the authoring (MLP ≤30 epochs, CNN/RNN shape-only, ellmer gated off, `kernelshap`/`vip` `nsim` modest). If a build is intolerably slow at review, the fallback is to seed `00-recap` from a single seeded `ranger` refit instead of the full tuning — a one-line change to `00-recap/beat.R` + `meta.packages`.
- **C. `04` trains the model as a target** (no `model_file`/`reload_model`). `pipeline-fns.R` gains `split_cohort()`, `make_recipe()`, `fit_rf()`; `_targets.R` gains the corresponding targets. The hole exercises sit on `tar_target` definitions.

## Conventions used by this plan

- **Engine work (`dev/mltbuild/`)**: pure base-R, strict TDD (Step 1 write failing test → Step 2 run, verify FAIL → Step 3 implement → Step 4 run, verify PASS → Step 5 commit). Tests in `dev/mltbuild/tests/testthat/`. Run the suite with `"$RS" dev/mltbuild/run-tests.R` — baseline **`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 100 ]`**; every engine task must keep FAIL 0 and grow PASS.
- **Authoring/pipeline work**: implement → run the exact command shown → confirm the `Expected:` line → commit.
- **Rscript on this machine**: `RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'`; every R `Run:` uses `"$RS"`. The Bash tool is available for POSIX commands; PowerShell for native Windows.
- **Commit messages**: `mltbuild: <change>` for engine; `mlt-r-advanced: <change>` for authoring; `pipeline: <change>` or `site: <change>` for the Python/portal layer. One logical change per commit. **NEVER `git push`** (the user pushes).
- **Language**: student-facing artifacts (beats, report, holes, README) in **English**; design notes / teacher `<!-- -->` notes / commit bodies may be Italian.
- **Visual verification is mandatory** (repo CLAUDE.md): no `_solved/*.html`, deck, or portal page is "done" until inspected with chrome-devtools.

### Hole marker format (engine grammar — `dev/mltbuild/R/holes.R`; NOT the spec §5 `#@` proposal)

```r
# >>>hole id=<id> kind=fill|parsons|prose [prompt=<text to end of line>]
#   solved:
<real code>
#   blank:
<code with ___ placeholders>
# <<<hole
```

`id=` is required. `prompt=` must be the **last** field (captured greedily to EOL). `kind=fill` (default) keeps the `blank:` lines; `kind=prose` emits a single `# TODO: <prompt>` (needs only `solved:`); `kind=parsons` emits `# Reorder the lines to: <prompt>` + the solved lines reversed (needs only `solved:`). `library()` calls are hoisted to the top by the assembler; `set.seed()` stays in place.

### Fragment marker format (`dev/mltbuild/R/fragments.R`)

```r
# >>>frag id=<id>
<canonical solved lines>
# <<<frag
```

Stripped from every student/teacher/full artifact; sliced by id and substituted into a transform-terminal template at a whole-line `{{frag:id}}` token. Define each id **once**.

### `_authoring/` tree layout (target for Advanced)

```
workshops/mlt-r-advanced/
  _authoring/
    workshop.yml                 # slug, r_version, ppm_snapshot, dataset, steps[]
    00-recap/      meta.yml  beat.R            # seed_from: mlt-r-basic
    01-interpret/  meta.yml  beat.R
    02-deep-learning/ meta.yml beat.R  R/nn-modules.R     # carry: [R/nn-modules.R]
    03-ellmer/     meta.yml  beat.R
    04-targets/    meta.yml  _targets.R  report.qmd  R/pipeline-fns.R   # engine: targets
  data-raw/        heart_failure.csv  hf_notes.csv        # committed (parent of _authoring)
  renv/            activate.R  settings.json              # committed; seeds per-step projects
  renv.lock                                               # committed (R 4.6 + PPM)
  README.md  CLAUDE.md  mlt-r-advanced.Rproj              # committed
  steps/  full/  _solved/                                 # GENERATED + gitignored
```

Only `_authoring/`, `data-raw/`, `renv/` + `renv.lock`, `README.md`, `CLAUDE.md`, `.Rproj` are committed. `steps/`, `full/`, `_solved/` are generated by `build.R` and gitignored.

---

## File Structure

**Engine (pure, TDD — `dev/mltbuild/R/` + entrypoints):**
- `R/config.R` — extend `read_meta()` (new fields `carry`, `check`, `engine`, `seed_from`) and `read_workshop()` (resolve `seed_from`, mark seeded). Add helper `sibling_full()`.
- `R/assemble.R` — add `packages_for_step(metas, n)` (cumulative START ∪ seeded-step own packages).
- `R/materialize.R` — `with_renv`/lock via `packages_for_step`; copy `carry:` files cumulatively; emit a `transform-terminal` `engine: targets` step as a multi-file copy (`_targets.R` + `report.qmd` frag-substituted, `R/` verbatim).
- `build.R` — parameterize the workshop library path from `wk$r_version`; build an `engine: targets` step via `targets::tar_make()` + copy the report node HTML.
- `check-masking.R` — parameterize the same library path from `read_workshop()`.
- `parity.R` — drive per-step `kw`/`imgs` from each step's `meta$check` (workshop-agnostic); migrate Basic's checks into Basic's `_authoring/*/meta.yml`.
- Tests: `tests/testthat/test-config.R`, `test-assemble.R`, `test-materialize.R`, plus new `test-seed.R`, `test-carry.R`, `test-targets-terminal.R`, `test-parity-config.R`. Fixture extensions under `tests/testthat/fixtures/`.

**Authoring + repo (`workshops/mlt-r-advanced/`):**
- New `_authoring/` tree (Tasks B0–B5). Re-pinned `renv.lock`. Updated `.gitignore`, `README.md`. Retired `R/seed-data.R` (model copy), legacy `steps/`, root `_solved.R`.

**Pipeline + portal (`scripts/`, `site/`, `tests/`):**
- `scripts/build_release.py` — re-add `mlt-r-advanced-teacher.zip` to `ZIP_ASSETS`.
- `tests/skills/test_build_release.py` — extend `test_asset_names_are_contractual` to 4 elements.
- `site/advanced.qmd` — 4th "Coding solutions" button + Model C run instructions.
- `site/downloads.qmd` — add the Advanced teacher bundle link; fix the "single project" wording.

---

## Task 0 — Branch, baseline, triage

**Files:** none created; git state only.

- [ ] **Step 1: Confirm the engine baseline is green**

Run: `RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'; "$RS" dev/mltbuild/run-tests.R`
Expected: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 100 ]`

- [ ] **Step 2: Triage the working tree, then branch**

The working tree carries one keep and several strays. Stash everything, branch, then restore only the keep.

Run:
```bash
git stash push -u -m "pre-plan3 worktree" -- \
  course/10-best-practices/narrative.html portal.html \
  workshops/mlt-r-basic/mlt-r-basic.Rproj workshops/mlt-r-basic/renv.lock \
  data/PubMed_Timeline_Results_by_Year.csv _archive/legacy-xaringan/data
git stash push -m "keep: 04-targets in-flight (reference for B5)" -- \
  workshops/mlt-r-advanced/steps/04-targets/04-targets.qmd \
  workshops/mlt-r-advanced/steps/04-targets/_targets.R
git checkout -b plan3-advanced-end-to-end
git stash pop   # restores the 04-targets reference edits onto the new branch
```
Expected: on branch `plan3-advanced-end-to-end`; `git status` shows only the two `steps/04-targets/*` files modified; the stray edits remain stashed (recoverable, not on the branch). (The first stash is intentionally left on the stack — it is not W3 work.)

- [ ] **Step 3: Commit the plan file**

Run:
```bash
git add dev-docs/superpowers/plans/2026-06-03-mlt-workshop-advanced-end-to-end.md
git commit -m "mlt-r-advanced: add plan 3 (Advanced end-to-end fragment-build)"
```
Expected: one commit on `plan3-advanced-end-to-end`.

---

# Fase A — Engine extensions (`dev/mltbuild/`, strict TDD)

Each task: write the failing test → run, verify FAIL → implement → run, verify PASS → run the **full** suite (`run-tests.R`, must stay FAIL 0) → commit.

## Task A1 — `seed_from`: seed a step from a sibling workshop's full pipeline (+ non-bare seeded step)

**What:** A step whose `meta.yml` has `seed_from: <slug>` gets the sibling workshop's assembled `full.R` prepended to its beat, the sibling's packages unioned in, and — crucially — a **full renv project + lock even at index 0** (overriding the "step 0 is bare" rule, which stays correct for Basic).

**Files:**
- Modify: `dev/mltbuild/R/config.R` (`read_meta`, `read_workshop`, new `sibling_full`)
- Modify: `dev/mltbuild/R/assemble.R` (new `packages_for_step`)
- Modify: `dev/mltbuild/R/materialize.R` (`with_renv` + lock via `packages_for_step`)
- Modify: `dev/mltbuild/build.R` (per-step lock via `packages_for_step`)
- Test: `dev/mltbuild/tests/testthat/test-seed.R` (new); fixtures under `tests/testthat/fixtures/`

- [ ] **Step 1: Write the failing test**

Create `dev/mltbuild/tests/testthat/test-seed.R`. It builds a tiny two-workshop fixture in `tempfile()` dirs (a "base" with two append beats, and a "downstream" whose step 00 has `seed_from: wkbase`), then asserts the seeded step inlines the base's full and is a full renv project.

```r
# A minimal sibling-workshop pair built in temp dirs.
.make_seed_fixture <- function() {
  rootp <- tempfile("seedfix-"); dir.create(rootp)
  ws <- file.path(rootp, "workshops"); dir.create(ws)

  # renv source (activate.R) the per-step scaffolder copies
  renv_src <- file.path(ws, "_renv"); dir.create(renv_src)
  writeLines("# fake activate", file.path(renv_src, "activate.R"))

  mk_step <- function(auth, slug, meta, beat = NULL) {
    d <- file.path(auth, slug); dir.create(d, recursive = TRUE)
    writeLines(meta, file.path(d, "meta.yml"))
    if (!is.null(beat)) writeLines(beat, file.path(d, "beat.R"))
  }

  # base workshop: 00 introduces pkgA; 01 introduces pkgB
  bauth <- file.path(ws, "wkbase", "_authoring"); dir.create(bauth, recursive = TRUE)
  dir.create(file.path(ws, "wkbase", "renv"))
  file.copy(file.path(renv_src, "activate.R"), file.path(ws, "wkbase", "renv", "activate.R"))
  dir.create(file.path(ws, "wkbase", "data-raw"))
  writeLines("x", file.path(ws, "wkbase", "data-raw", "d.csv"))
  writeLines(c("slug: wkbase", "r_version: \"4.6.0\"", "ppm_snapshot: \"2026-06-01\"",
               "dataset: data-raw/d.csv", "steps: [00-a, 01-b]"),
             file.path(bauth, "workshop.yml"))
  mk_step(bauth, "00-a", c("slug: 00-a", "title: A", "packages: [pkgA]"),
          c("library(pkgA)", "a_value <- 1"))
  mk_step(bauth, "01-b", c("slug: 01-b", "title: B", "packages: [pkgB]"),
          c("library(pkgB)", "b_value <- 2"))

  # downstream workshop: step 00 seeds from wkbase; step 01 is a normal append
  dauth <- file.path(ws, "wkdown", "_authoring"); dir.create(dauth, recursive = TRUE)
  dir.create(file.path(ws, "wkdown", "renv"))
  file.copy(file.path(renv_src, "activate.R"), file.path(ws, "wkdown", "renv", "activate.R"))
  dir.create(file.path(ws, "wkdown", "data-raw"))
  writeLines("x", file.path(ws, "wkdown", "data-raw", "d.csv"))
  writeLines(c("slug: wkdown", "r_version: \"4.6.0\"", "ppm_snapshot: \"2026-06-01\"",
               "dataset: data-raw/d.csv", "steps: [00-recap, 01-next]"),
             file.path(dauth, "workshop.yml"))
  mk_step(dauth, "00-recap", c("slug: 00-recap", "title: Recap", "seed_from: wkbase",
                               "packages: [pkgWarm]"),
          c("library(pkgWarm)", "warm <- TRUE"))
  mk_step(dauth, "01-next", c("slug: 01-next", "title: Next", "packages: [pkgC]"),
          c("library(pkgC)", "c_value <- 3"))
  list(down_auth = dauth)
}

test_that("seed_from inlines the sibling's full into the seeded step", {
  fx <- .make_seed_fixture()
  out <- tempfile("seedout-")
  wk  <- read_workshop(fx$down_auth)
  materialize_workshop(wk, dirname(dirname(fx$down_auth)))   # workshops/wkdown
  s0 <- readLines(file.path(dirname(dirname(fx$down_auth)), "..", "wkdown") |> normalizePath() |>
                  file.path("steps", "00-recap", "00-recap.R"))
  expect_true(any(grepl("a_value <- 1", s0)))   # base beat 00 solved, inlined
  expect_true(any(grepl("b_value <- 2", s0)))   # base beat 01 solved, inlined
  expect_true(any(grepl("warm <- TRUE", s0)))   # the recap's own beat, appended after the seed
})

test_that("a seeded step 0 is a FULL renv project (not bare) and carries the unioned packages", {
  fx  <- .make_seed_fixture()
  wk  <- read_workshop(fx$down_auth)
  metas <- lapply(wk$steps, `[[`, "meta")
  # 00-recap's lock packages = base's {pkgA,pkgB} unioned with its own {pkgWarm}
  expect_setequal(packages_for_step(metas, 0L), c("pkgA", "pkgB", "pkgWarm"))
  wsdir <- normalizePath(file.path(dirname(dirname(fx$down_auth))), winslash = "/")
  materialize_workshop(wk, wsdir)
  s0 <- file.path(wsdir, "steps", "00-recap")
  expect_true(file.exists(file.path(s0, ".Rprofile")))           # NOT bare
  expect_true(file.exists(file.path(s0, "renv", "activate.R")))
})
```

- [ ] **Step 2: Run, verify FAIL**

Run: `"$RS" -e "testthat::test_dir('dev/mltbuild/tests/testthat', filter='seed')"`
Expected: FAIL — `packages_for_step` not found / `seed_from` ignored (step 00 bare, base code absent).

- [ ] **Step 3: Implement**

In `dev/mltbuild/R/config.R`, extend `read_meta` to surface the new optional fields:

```r
read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages  <- as.character(m$packages %||% character(0))
  m$type      <- m$type %||% "append"
  m$template  <- m$template %||% NULL
  m$carry     <- as.character(m$carry %||% character(0))   # files to carry forward
  m$check     <- m$check %||% NULL                          # parity expectations
  m$engine    <- m$engine %||% NULL                         # "targets" for the capstone
  m$seed_from <- m$seed_from %||% NULL                      # sibling workshop slug
  m
}
```

Add `sibling_full()` to `config.R` and resolve `seed_from` inside `read_workshop()` (prepend the sibling full to the beat's raw lines BEFORE `parse_beat`, and union the sibling's packages into this step's `meta$packages`, marking it seeded):

```r
# Assemble a sibling workshop's full.R (append beats, solved) from its _authoring.
sibling_full <- function(authoring_dir, slug) {
  sib <- file.path(dirname(dirname(authoring_dir)), slug, "_authoring")
  if (!dir.exists(sib)) stop("seed_from: sibling workshop not found: ", sib)
  swk    <- read_workshop(sib)
  smetas <- lapply(swk$steps, `[[`, "meta")
  sbeats <- lapply(swk$steps, `[[`, "beat")
  ab     <- sbeats[vapply(smetas, function(m) identical(m$type, "append"), logical(1))]
  list(
    lines    = assemble_full(ab),
    packages = unique(unlist(lapply(smetas, function(m) m$packages %||% character(0))))
  )
}
```

In `read_workshop`, replace the per-step `beat = ...` construction so a `seed_from` step prepends the sibling full and absorbs its packages:

```r
read_workshop <- function(authoring_dir) {
  wk <- yaml::read_yaml(file.path(authoring_dir, "workshop.yml"))
  steps <- lapply(wk$steps, function(slug) {
    step_dir  <- file.path(authoring_dir, slug)
    meta      <- read_meta(step_dir)
    beat_file <- file.path(step_dir, "beat.R")
    is_xform  <- identical(meta$type, "transform-terminal")
    tmpl_file <- if (is_xform) file.path(step_dir, meta$template %||% "report.qmd") else NA_character_

    raw_beat <- if (!is_xform && file.exists(beat_file)) readLines(beat_file) else character(0)
    meta$seeded <- FALSE
    if (!is.null(meta$seed_from)) {
      sf <- sibling_full(authoring_dir, meta$seed_from)
      raw_beat <- c(sf$lines, "", raw_beat)                  # seed first, recap's own beat after
      meta$packages <- unique(c(sf$packages, meta$packages)) # the seeded step needs all of them
      meta$seeded <- TRUE
    }

    list(
      slug     = slug,
      meta     = meta,
      beat     = if (!is_xform) parse_beat(raw_beat) else list(),
      template = if (is_xform) {
        if (!file.exists(tmpl_file))
          stop("transform-terminal step '", slug, "': template not found: ", tmpl_file)
        readLines(tmpl_file)
      } else character(0)
    )
  })
  cand <- c(file.path(authoring_dir, "data-raw"), file.path(dirname(authoring_dir), "data-raw"))
  data_raw_dir <- cand[dir.exists(cand)][1]
  renv_cand <- c(file.path(authoring_dir, "renv"), file.path(dirname(authoring_dir), "renv"))
  renv_dir <- renv_cand[dir.exists(renv_cand)][1]
  list(
    slug = wk$slug, r_version = wk$r_version, ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset, authoring_dir = authoring_dir,
    data_raw_dir = data_raw_dir, renv_dir = renv_dir, steps = steps
  )
}
```

Add `packages_for_step()` to `dev/mltbuild/R/assemble.R` (the lock packages for step n; a seeded step 0 contributes its own unioned packages so it is non-bare):

```r
packages_for_step <- function(metas, n) {
  # Lock for step n = cumulative START (beats 0..n-1). EXCEPTION: a seeded step
  # ships pre-populated given-code, so it needs ITS OWN packages already present.
  base <- packages_through(metas, n)
  if (isTRUE(metas[[n + 1L]]$seeded)) base <- unique(c(base, metas[[n + 1L]]$packages))
  base
}
```

In `dev/mltbuild/R/materialize.R`, replace the two `pk <- packages_through(metas, n)` / `with_renv = length(pk) > 0L` lines so the seeded step 0 is non-bare:

```r
    pk <- packages_for_step(metas, n)
    .write_lines(packages_through(metas, n), file.path(sdir, "packages.txt"))  # packages.txt stays START-state
    .write_lines(character(0), file.path(sdir, ".here"))
    .copy_data_raw(wk$data_raw_dir, sdir)
    write_step_project(sdir, wk$renv_dir, with_renv = length(pk) > 0L)
```

In `dev/mltbuild/build.R`, change the per-step lock loop to use `packages_for_step`:

```r
for (n in seq_along(wk$steps) - 1L) {
  slug <- wk$steps[[n + 1L]]$slug
  pk   <- packages_for_step(metas, n)
  write_step_lock(file.path(workshop, "steps", slug, "renv.lock"), pk, ppm)
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `"$RS" -e "testthat::test_dir('dev/mltbuild/tests/testthat', filter='seed')"`
Expected: PASS (both tests).

- [ ] **Step 5: Run the full suite + commit**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: `[ FAIL 0 | ... | PASS >100 ]` (Basic's existing tests unaffected — `packages_for_step` reduces to `packages_through` when not seeded).

```bash
git add dev/mltbuild/R/config.R dev/mltbuild/R/assemble.R dev/mltbuild/R/materialize.R dev/mltbuild/build.R dev/mltbuild/tests/testthat/test-seed.R
git commit -m "mltbuild: seed_from inlines a sibling workshop's full into a seeded step 0 (non-bare)"
```

## Task A2 — `carry:`: carry forward side-files into downstream steps

**What:** A step declaring `carry: [R/nn-modules.R]` ships that file into its own generated folder **and every downstream step + `full/`**, at the same relative path. The file is copied, not sourced/scanned (spec §6, §10.7).

**Files:**
- Modify: `dev/mltbuild/R/materialize.R`
- Test: `dev/mltbuild/tests/testthat/test-carry.R` (new); extend `tests/testthat/fixtures/wkfix` with a carry file.

- [ ] **Step 1: Write the failing test**

Add a carry file to the existing fixture and a `carry:` field to one of its step metas, then assert propagation. First extend the fixture:

```bash
mkdir -p dev/mltbuild/tests/testthat/fixtures/wkfix/01-import/R
printf 'helper <- function() 42L\n' > dev/mltbuild/tests/testthat/fixtures/wkfix/01-import/R/helper.R
```

Append to `dev/mltbuild/tests/testthat/fixtures/wkfix/01-import/meta.yml` the line `carry: [R/helper.R]` (read the file first; keep its existing keys).

Create `dev/mltbuild/tests/testthat/test-carry.R`:

```r
fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("carry: copies the file into its own step and every downstream step + full", {
  out <- tempfile("carryout-")
  wk  <- read_workshop(fixroot)
  materialize_workshop(wk, out)
  # declared at 01-import -> present from 01 onward + full, absent at 00-setup
  expect_false(file.exists(file.path(out, "steps", "00-setup", "R", "helper.R")))
  expect_true(file.exists(file.path(out, "steps", "01-import", "R", "helper.R")))
  expect_true(file.exists(file.path(out, "steps", "02-eda",   "R", "helper.R")))
  expect_true(file.exists(file.path(out, "full", "R", "helper.R")))
  expect_equal(readLines(file.path(out, "full", "R", "helper.R")), "helper <- function() 42L")
})
```

- [ ] **Step 2: Run, verify FAIL** — Run: `"$RS" -e "testthat::test_dir('dev/mltbuild/tests/testthat', filter='carry')"` → FAIL (`R/helper.R` not copied).

- [ ] **Step 3: Implement** — in `materialize.R`, add a carry helper and call it per step + full:

```r
.copy_carry <- function(authoring_dir, metas, upto_n, dest_dir) {
  # Copy every file declared in `carry:` by steps 0..upto_n into dest_dir, same rel path.
  files <- unique(unlist(lapply(metas[seq_len(upto_n + 1L)], function(m) m$carry %||% character(0))))
  step_slugs <- vapply(metas, function(m) m$slug, character(1))
  for (rel in files) {
    # find the step that declares it (first owner) and copy from there
    owner <- which(vapply(metas[seq_len(upto_n + 1L)],
                          function(m) rel %in% (m$carry %||% character(0)), logical(1)))[1]
    src <- file.path(authoring_dir, metas[[owner]]$slug, rel)
    if (!file.exists(src)) stop("carry: file not found: ", src)
    dst <- file.path(dest_dir, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    file.copy(src, dst, overwrite = TRUE)
  }
}
```

Note `read_meta` does not currently store `slug` on the meta when it is absent; the fixture metas already carry `slug`. To be safe, the owner lookup uses `metas[[owner]]$slug` which is present in all real metas. In the per-step loop (after `.copy_data_raw`), add `.copy_carry(wk$authoring_dir, metas, n, sdir)`. After the `full/` block, add `.copy_carry(wk$authoring_dir, metas, length(metas) - 1L, full_dir)`.

- [ ] **Step 4: Run, verify PASS** — Run the `carry` filter → PASS.

- [ ] **Step 5: Full suite + commit**

Run: `"$RS" dev/mltbuild/run-tests.R` → FAIL 0.
```bash
git add dev/mltbuild/R/materialize.R dev/mltbuild/tests/testthat/test-carry.R dev/mltbuild/tests/testthat/fixtures/wkfix/01-import/
git commit -m "mltbuild: carry: ships declared side-files into downstream steps + full"
```

## Task A3 — `engine: targets`: a multi-file transform-terminal built with `tar_make()`

**What:** A `transform-terminal` step with `engine: targets` emits **all** its authored files (`_targets.R`, `report.qmd`, `R/*.R`), rendering **hole markers** in each (`_targets.R` carries the `tar_target` exercises). The **student** step gets holes BLANK; the **build** renders holes SOLVED into a temp dir and runs `targets::tar_make()` once there, then copies the pipeline's `report.html` node output to `_solved/<slug>.html` — never a standalone `quarto_render` of `report.qmd` (spec §10.5). No `{{frag:id}}` tokens are used here: the `§4.3` extract in `R/pipeline-fns.R` is authored self-contained.

**Files:**
- Modify: `dev/mltbuild/R/materialize.R` (emit multi-file for `engine: targets`)
- Modify: `dev/mltbuild/build.R` (build via `tar_make`)
- Test: `dev/mltbuild/tests/testthat/test-targets-terminal.R` (new, materialize-only — no real tar_make in unit tests); a fixture `engine: targets` step.

- [ ] **Step 1: Write the failing test** (materialize emits all files, substitutes tokens in `_targets.R`/`report.qmd`, copies `R/` verbatim)

Create a fixture targets step `tests/testthat/fixtures/wktar/` (a self-contained mini-workshop: one append beat defining a `{{frag:wrangle}}` fragment + one `engine: targets` terminal). Then:

```r
tarroot <- testthat::test_path("fixtures", "wktar", "_authoring")

test_that("engine:targets materializes _targets.R + report.qmd + R/, with holes BLANK for the student", {
  out <- tempfile("tarout-")
  wk  <- read_workshop(tarroot)
  materialize_workshop(wk, out)
  sd <- file.path(out, "steps", "01-pipe")
  expect_true(file.exists(file.path(sd, "_targets.R")))
  expect_true(file.exists(file.path(sd, "report.qmd")))
  expect_true(file.exists(file.path(sd, "R", "pipeline-fns.R")))
  tt <- readLines(file.path(sd, "_targets.R"))
  expect_true(any(grepl("___", tt)))                 # the tar_target hole is BLANK for the student
  expect_false(any(grepl(">>>hole", tt)))            # hole markers stripped, not shipped
  # the student .R is NOT produced for a transform step
  expect_false(file.exists(file.path(sd, "01-pipe.R")))
})

test_that("engine:targets can render the SOLVED tree for the build (no blanks, no markers)", {
  wk  <- read_workshop(tarroot)
  td  <- tempfile("tarsolved-"); dir.create(td)
  .emit_targets_step(file.path(wk$authoring_dir, "01-pipe"), td, mode = "solved")
  tt  <- readLines(file.path(td, "_targets.R"))
  expect_false(any(grepl("___", tt)))                # solved: blanks filled
  expect_false(any(grepl(">>>hole", tt)))
  expect_true(file.exists(file.path(td, "R", "pipeline-fns.R")))
})
```

(The plan's executing agent authors `fixtures/wktar/`: `_authoring/workshop.yml` with `steps: [01-pipe]` (single step — no append beats needed since the extract is self-contained); `01-pipe/meta.yml` with `type: transform-terminal`, `engine: targets`, `packages: [targets]`; `01-pipe/_targets.R` containing one `# >>>hole id=t kind=fill … ___ … # <<<hole`; `01-pipe/report.qmd` (any minimal qmd); `01-pipe/R/pipeline-fns.R` (any function). Note `_emit_targets_step` is the internal helper added in Step 3 — `testthat` sees it because the suite sources the engine `R/`.)

- [ ] **Step 2: Run, verify FAIL** — Run the `targets-terminal` filter → FAIL (only `report.qmd` emitted today; `_targets.R`/`R/` missing).

- [ ] **Step 3: Implement** — add a hole-aware emitter to `materialize.R` and branch the transform arm on `engine`:

```r
.render_authored_file <- function(src, mode) {
  # Parse hole markers in an authored .R/.qmd, render to `mode` (blank|solved), strip frag markers.
  strip_frag_markers(render_beat(parse_beat(readLines(src)), mode = mode))
}

.emit_targets_step <- function(auth_step, dest, mode) {
  # Emit every authored file (except meta.yml): .R/.qmd hole-rendered to `mode`, others copied verbatim.
  base <- normalizePath(auth_step, winslash = "/")
  for (src in list.files(auth_step, recursive = TRUE, full.names = TRUE)) {
    if (basename(src) == "meta.yml") next
    rel <- sub(paste0("^", base, "/?"), "", normalizePath(src, winslash = "/"))
    dst <- file.path(dest, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    if (grepl("[.](R|qmd)$", src)) .write_lines(.render_authored_file(src, mode), dst)
    else                          file.copy(src, dst, overwrite = TRUE)
  }
}
```

Then in the per-step loop, branch the transform arm on `engine` (student gets BLANK):

```r
    if (identical(step$meta$type, "transform-terminal")) {
      if (identical(step$meta$engine, "targets")) {
        .emit_targets_step(file.path(wk$authoring_dir, slug), sdir, mode = "blank")
      } else {
        .write_lines(render_report(step$template, frags), file.path(sdir, "report.qmd"))
      }
    } else if (identical(step$meta$type, "append")) {
```

In `build.R`, branch the render loop on `engine: targets` — render the SOLVED tree into a temp dir, copy `data-raw/`, run `tar_make()`, lift the report node HTML:

```r
  if (identical(step$meta$type, "transform-terminal")) {
    if (identical(step$meta$engine, "targets")) {
      tdir <- tempfile("tar-solved-"); dir.create(tdir)
      .emit_targets_step(file.path(authoring, slug), tdir, mode = "solved")
      .copy_data_raw(wk$data_raw_dir, tdir)                 # the format="file" cohort target needs data-raw/
      old2 <- getwd(); setwd(tdir)
      targets::tar_make(callr_function = NULL)              # in-process so .libPaths/R_LIBS propagate
      setwd(old2)
      produced <- file.path(tdir, "report.html")
      if (!file.exists(produced)) stop("targets pipeline produced no report.html: ", produced)
      file.copy(produced, file.path(solved_dir, paste0(slug, ".html")), overwrite = TRUE)
      unlink(tdir, recursive = TRUE)
    } else {
      render_one(file.path(sdir, "report.qmd"), file.path(solved_dir, paste0(slug, ".html")))
    }
  } else {
```

`callr_function = NULL` runs targets in the current process so the workshop library path set at the top of `build.R` is visible to the pipeline workers and to the `tar_quarto` render. `tar_quarto(report, path = "report.qmd")` writes `report.html` next to `report.qmd` in the working dir (the temp tree). The student `steps/04-targets/` ships only the BLANK `_targets.R` + `report.qmd` + `R/pipeline-fns.R` (no store, no HTML).

- [ ] **Step 4: Run, verify PASS** — Run the `targets-terminal` filter → PASS (materialize-level; the `tar_make` path is exercised end-to-end in Task D1, not in unit tests).

- [ ] **Step 5: Full suite + commit**

Run: `"$RS" dev/mltbuild/run-tests.R` → FAIL 0.
```bash
git add dev/mltbuild/R/materialize.R dev/mltbuild/build.R dev/mltbuild/tests/testthat/test-targets-terminal.R dev/mltbuild/tests/testthat/fixtures/wktar/
git commit -m "mltbuild: engine: targets emits a multi-file pipeline step built via tar_make()"
```

## Task A4 — per-step parity from `meta$check` (workshop-agnostic `parity.R`)

**What:** `parity.R` reads each step's `meta$check: {kw: [...], imgs: N}` from `_authoring/` instead of a hardcoded Basic table, so it works for any workshop. Basic's existing expectations move into Basic's `_authoring/*/meta.yml` with **no behavior change**.

**Files:**
- Modify: `dev/mltbuild/parity.R`
- Modify: each `workshops/mlt-r-basic/_authoring/*/meta.yml` (add `check:` mirroring the current hardcoded list)
- Test: `dev/mltbuild/tests/testthat/test-parity-config.R` (new) — unit-test a pure helper `parity_checks(wk)` extracted from `parity.R`.

- [ ] **Step 1: Write the failing test**

Extract the check-collection into a pure, testable helper. Create `test-parity-config.R`:

```r
test_that("parity_checks reads kw/imgs from each step's meta$check", {
  wk <- read_workshop(testthat::test_path("fixtures", "wkfix", "_authoring"))
  # the fixture's 02-eda meta declares check: {kw: [janitor], imgs: 0}  (added by this task)
  ck <- parity_checks(wk)
  expect_true("02-eda" %in% names(ck))
  expect_equal(ck[["02-eda"]]$imgs, 0L)
  expect_true("janitor" %in% ck[["02-eda"]]$kw)
})
```

(Executing agent: the `wkfix` fixture's `_authoring/` is at `tests/testthat/fixtures/wkfix` — confirm whether `read_workshop` is called with that path or its `_authoring` child, and add a `check:` block to the fixture's `02-eda/meta.yml`.)

- [ ] **Step 2: Run, verify FAIL** — `parity_checks` undefined → FAIL.

- [ ] **Step 3: Implement** — add `parity_checks()` to a sourced engine file (e.g. new `dev/mltbuild/R/parity-config.R`) and rewrite `parity.R` to source the engine and drive off it:

```r
# dev/mltbuild/R/parity-config.R
parity_checks <- function(wk) {
  out <- list()
  for (st in wk$steps) {
    ck <- st$meta$check
    if (is.null(ck)) next
    out[[st$slug]] <- list(kw = as.character(ck$kw %||% character(0)),
                           imgs = as.integer(ck$imgs %||% 0L))
  }
  out
}
```

Rewrite `parity.R` to load the engine `R/` and use `parity_checks(read_workshop(...))` instead of the hardcoded `checks` list (the `_solved/*.html` reading loop is unchanged):

```r
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 1L)
workshop <- args[[1]]
root <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
wk <- read_workshop(file.path(workshop, "_authoring"))
checks <- parity_checks(wk)
# ... existing fails-collection loop over names(checks), reading <workshop>/_solved/<slug>.html ...
```

Then add a `check:` block to each `workshops/mlt-r-basic/_authoring/*/meta.yml` mirroring the current hardcode (00-setup: `{kw: [panel-tabset, To fill, Solved, dim], imgs: 0}`, 01-import, 02-eda, 03-logistic, 04-zoo, 05-report — copy the exact `kw`/`imgs` from the current `parity.R`).

- [ ] **Step 4: Run, verify PASS** — `parity` filter → PASS.

- [ ] **Step 5: Regression-gate Basic + commit**

Basic must still pass its structural gate end-to-end (this proves the migration of its checks is behavior-preserving):
Run: `"$RS" dev/mltbuild/build.R workshops/mlt-r-basic && "$RS" dev/mltbuild/parity.R workshops/mlt-r-basic`
Expected: `BUILD OK: mlt-r-basic …` then `STRUCTURAL PARITY OK …`.
Run: `"$RS" dev/mltbuild/run-tests.R` → FAIL 0.
```bash
git add dev/mltbuild/parity.R dev/mltbuild/R/parity-config.R dev/mltbuild/tests/testthat/test-parity-config.R workshops/mlt-r-basic/_authoring
git commit -m "mltbuild: drive parity.R from per-step meta\$check (workshop-agnostic); migrate Basic checks"
```

## Task A5 — parameterize the workshop library path from `r_version`

**What:** `build.R` and `check-masking.R` hardcode `renv/library/windows/R-4.6/...`. Derive `R-<major.minor>` from `wk$r_version` so a re-pin only touches `workshop.yml`. Behavior is identical for Basic (4.6.0 → `R-4.6`).

**Files:**
- Modify: `dev/mltbuild/R/utils.R` (helper `wlib_path`)
- Modify: `dev/mltbuild/build.R`, `dev/mltbuild/check-masking.R`
- Test: `dev/mltbuild/tests/testthat/test-config.R` (append a `wlib_path` case)

- [ ] **Step 1: Write the failing test** — append to `test-config.R`:

```r
test_that("wlib_path derives the R-major.minor library segment from r_version", {
  p <- wlib_path("/tmp/ws", "4.6.0")
  expect_match(p, "renv/library/windows/R-4\\.6/x86_64-w64-mingw32$")
  expect_match(wlib_path("/tmp/ws", "4.5.2"), "R-4\\.5/")
})
```

- [ ] **Step 2: Run, verify FAIL** — `wlib_path` undefined.

- [ ] **Step 3: Implement** — add to `utils.R`:

```r
wlib_path <- function(workshop, r_version) {
  rv <- paste(strsplit(r_version, ".", fixed = TRUE)[[1]][1:2], collapse = ".")  # "4.6.0" -> "4.6"
  file.path(workshop, "renv", "library", "windows", paste0("R-", rv), "x86_64-w64-mingw32")
}
```

In `build.R` replace `wlib <- file.path(workshop, "renv", "library", "windows", "R-4.6", "x86_64-w64-mingw32")` with `wlib <- wlib_path(workshop, wk$r_version)` — **but** `wk` is read just below; move the `wk <- read_workshop(authoring)` line above the `wlib` assignment, then set the lib path. In `check-masking.R`, similarly read `wk <- read_workshop(file.path(workshop, "_authoring"))` first, then `wlib <- normalizePath(wlib_path(workshop, wk$r_version), winslash = "/", mustWork = FALSE)`.

- [ ] **Step 4: Run, verify PASS** — `config` filter → PASS.

- [ ] **Step 5: Regression + commit**

Run: `"$RS" dev/mltbuild/build.R workshops/mlt-r-basic` → `BUILD OK` (proves the 4.6 path still resolves).
Run: `"$RS" dev/mltbuild/run-tests.R` → FAIL 0.
```bash
git add dev/mltbuild/R/utils.R dev/mltbuild/build.R dev/mltbuild/check-masking.R dev/mltbuild/tests/testthat/test-config.R
git commit -m "mltbuild: derive the workshop library path from r_version (build.R + check-masking.R)"
```

---

# Fase B — Authoring migration (`workshops/mlt-r-advanced/_authoring/`)

Each task: create the source files → (where a quick smoke is possible) verify → commit. The full build/parity/visual gate is Fase D; do not block individual authoring commits on a full render. **Reuse the cumulative environment**: in the append model, step N's solved script is `beats 0..N-1 solved + beat N blank`, so every later beat may use objects the recap/earlier beats created (`hf`, `train`, `test`, `data_split`, `base_rec`, `log_fit`, `final_fit` from the seeded recap; `bg`, `pred_fun` from 01).

## Task B0 — Scaffold `_authoring/`, `workshop.yml`, re-pin renv to R 4.6 + PPM

**Files:**
- Create: `workshops/mlt-r-advanced/_authoring/workshop.yml`
- Modify: `workshops/mlt-r-advanced/requirements.R` (PPM repo)
- Confirm committed: `workshops/mlt-r-advanced/data-raw/{heart_failure.csv,hf_notes.csv}`

- [ ] **Step 1: Create the authoring dir + `workshop.yml`**

```bash
mkdir -p workshops/mlt-r-advanced/_authoring/00-recap \
         workshops/mlt-r-advanced/_authoring/01-interpret \
         workshops/mlt-r-advanced/_authoring/02-deep-learning/R \
         workshops/mlt-r-advanced/_authoring/03-ellmer \
         workshops/mlt-r-advanced/_authoring/04-targets/R
```

`workshops/mlt-r-advanced/_authoring/workshop.yml`:
```yaml
slug: mlt-r-advanced
r_version: "4.6.0"
ppm_snapshot: "2026-06-01"
dataset: data-raw/heart_failure.csv
steps: [00-recap, 01-interpret, 02-deep-learning, 03-ellmer, 04-targets]
```

- [ ] **Step 2: Ensure `data-raw/` is committed at the workshop root, retire the cross-workshop seed**

`heart_failure.csv` + `hf_notes.csv` are deterministic and must be committed (the build copies `data-raw/` into every step). `seed-data.R`'s job (copy Basic's `final_fit.rds` + regenerate notes) is obsolete: the model is now self-seeded by the recap, and the notes are committed.

Run:
```bash
git add -f workshops/mlt-r-advanced/data-raw/heart_failure.csv workshops/mlt-r-advanced/data-raw/hf_notes.csv
git rm workshops/mlt-r-advanced/R/seed-data.R
```
Expected: both CSVs staged; `seed-data.R` removed. (If `R/seed-data.R` is the only file in `R/`, the dir is now empty — fine.)

- [ ] **Step 3: Re-pin renv to R 4.6 + PPM** (environment op — needs network; slow)

Edit `workshops/mlt-r-advanced/requirements.R` line 4 to the PPM snapshot:
```r
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2026-06-01"))
```

Then build the R-4.6 library + lock from the workshop root:
```bash
RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'
( cd workshops/mlt-r-advanced && "$RS" -e 'source("renv/activate.R"); source("requirements.R")' )
```
Expected: installs the package set under `renv/library/windows/R-4.6/…`, writes `renv.lock` recording `"R": {"Version": "4.6.0"}` and `Repositories` pointing at the PPM snapshot. Verify: `grep -m1 'Version' workshops/mlt-r-advanced/renv.lock` shows `4.6` near the top.

- [ ] **Step 4: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/workshop.yml workshops/mlt-r-advanced/requirements.R workshops/mlt-r-advanced/renv.lock workshops/mlt-r-advanced/data-raw
git commit -m "mlt-r-advanced: scaffold _authoring/workshop.yml + re-pin renv to R 4.6/PPM; retire seed-data model copy"
```

## Task B1 — `00-recap` (seed from Basic's full pipeline + torch pre-warm)

**Files:**
- Create: `workshops/mlt-r-advanced/_authoring/00-recap/meta.yml`, `.../00-recap/beat.R`

- [ ] **Step 1: `00-recap/meta.yml`**

```yaml
slug: 00-recap
title: "Step 00 — Recap & setup"
seed_from: mlt-r-basic
packages: [torch]
check:
  kw: [final_fit, last_fit, roc_auc, torch_tensor]
  imgs: 2
```

(`seed_from` makes `read_workshop()` prepend Basic's assembled `full.R` and union Basic's packages; `packages: [torch]` is the only thing 00-recap adds. The lock for 00-recap = Basic's set ∪ torch.)

- [ ] **Step 2: `00-recap/beat.R`** — only the recap's *own* code; the Basic pipeline is prepended by the engine.

```r
# Sanity-check the reloaded Basic model — one-row probability prediction (no retraining) ----
fitted_wf <- extract_workflow(final_fit)
predict(fitted_wf, hf[1, ], type = "prob")

# Pre-warm torch so deep learning is instant later ----
library(torch)
torch_tensor(1)             # forces the LibTorch backend to load now, not mid-demo
torch::cuda_is_available()  # FALSE on this CPU build box; TRUE on the classroom GPU machine
```

(`final_fit`, `hf` come from the inlined Basic pipeline. `extract_workflow`/`predict` resolve via tidymodels, attached by the Basic seed. `00-recap` is a DEMO — no holes — so the teacher tabs render To-fill == Solved.)

- [ ] **Step 3: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/00-recap
git commit -m "mlt-r-advanced: 00-recap beat — self-seeding recap from the Basic full pipeline + torch warm-up"
```

## Task B2 — `01-interpret` (append; permutation VIMP + agnostic SHAP; fill hole)

**Files:** Create `…/01-interpret/meta.yml`, `…/01-interpret/beat.R`.

- [ ] **Step 1: `01-interpret/meta.yml`**

```yaml
slug: 01-interpret
title: "Step 01 — Open the black box"
packages: [vip, kernelshap, shapviz]
check:
  kw: [permute, kernelshap, permshap, sv_waterfall]
  imgs: 2
```

- [ ] **Step 2: `01-interpret/beat.R`** — reuses `train`, `base_rec`, `log_fit`, `final_fit` from the recap.

```r
library(vip)
library(kernelshap)
library(shapviz)

# The validated Basic random forest, already fitted in the recap, as a workflow ----
rf_wf <- extract_workflow(final_fit)

# Permutation VIMP — what the forest relies on ----
# NOTE: vip unwraps the workflow and hands the bare engine (ranger) to pred_wrapper, so we
# ignore `object` and route the prediction through the captured workflow `rf_wf` instead.
vimp_pred <- function(object, newdata) predict(rf_wf, newdata, type = "prob")$.pred_died
set.seed(1)
vip(
  rf_wf,
  method       = "permute",
  train        = train,
  target       = "outcome",
  metric       = "roc_auc",
  pred_wrapper = vimp_pred,
  nsim         = 10,
  event_level  = "first",
)

# SHAP on the logistic anchor (log_fit, fitted in the recap) — the sanity check ----
# kernelshap's pred_fun signature is function(object, X, ...).
pred_fun <- function(object, X) predict(object, X, type = "prob")$.pred_died
bg <- train |> select(-outcome)
set.seed(2)
ks_log <- permshap(log_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_log) |> sv_waterfall()

# The SHAP signs must echo the logistic coefficients ----
tidy(log_fit) |> dplyr::arrange(dplyr::desc(abs(estimate)))

# Your turn — same call, swap the model ----
# >>>hole id=shap-rf kind=fill prompt=point the SAME explainer at the random forest — only the model object changes
#   solved:
set.seed(3)
ks_rf <- kernelshap(rf_wf, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_rf) |> sv_waterfall()
#   blank:
set.seed(3)
ks_rf <- kernelshap(___, X = bg[1, ], bg_X = ___, pred_fun = ___)
shapviz(ks_rf) |> sv_waterfall()
# <<<hole
```

- [ ] **Step 3: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/01-interpret
git commit -m "mlt-r-advanced: 01-interpret beat — VIMP + agnostic SHAP (reuses recap model), fill hole"
```

## Task B3 — `02-deep-learning` (append; live MLP + carried torch modules; parsons hole; option-B as inline data)

**Files:** Create `…/02-deep-learning/meta.yml`, `.../beat.R`, `.../R/nn-modules.R`.

- [ ] **Step 1: `02-deep-learning/meta.yml`**

```yaml
slug: 02-deep-learning
title: "Step 02 — Deep learning, honestly"
packages: [brulee, luz]
carry: [R/nn-modules.R]
check:
  kw: [brulee, kernelshap, fused_net, torch_cat]
  imgs: 2
```

- [ ] **Step 2: `02-deep-learning/R/nn-modules.R`** — copy the current module file verbatim (it is correct and carried, not sourced into the pipeline deps):

Copy `workshops/mlt-r-advanced/steps/02-deep-learning/R/nn-modules.R` (read it; it defines `cnn_branch`, `rnn_branch`, `fused_net`) into `_authoring/02-deep-learning/R/nn-modules.R` unchanged.

- [ ] **Step 3: `02-deep-learning/beat.R`** — reuses `train`, `test`, `base_rec`, `bg`, `pred_fun` from earlier beats. The option-B loss curve is an **inline, labeled, illustrative** tibble (no `.rds`); the GPU demo is `if (FALSE)` with **namespace-qualified** calls so no `library()` is hoisted and run.

```r
library(brulee)

# A live MLP — knobs first, then train SMALL ----
set.seed(123)
mlp_spec <- mlp(hidden_units = 16, epochs = 30, penalty = 0.01, learn_rate = 0.05) |>
  set_engine("brulee") |>
  set_mode("classification")
mlp_fit <- fit(workflow() |> add_recipe(base_rec) |> add_model(mlp_spec), train)
augment(mlp_fit, test) |> roc_auc(truth = outcome, .pred_died)

# The same explainer, a new model (only the model object changed — now a neural net) ----
set.seed(3)
ks_mlp <- kernelshap(mlp_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_mlp) |> sv_waterfall()

# Written, not trained — the shape-check ----
source(here("R", "nn-modules.R"))
net   <- fused_net(n_tab = 11, sig_ch = 8, seq_in = 4, hidden = 16)
x_tab <- torch_randn(5, 11)
x_sig <- torch_randn(5, 1, 50)
x_seq <- torch_randn(5, 12, 4)
out   <- net(x_tab, x_sig, x_seq)
out$shape   # expect [5, 2] — five patients, two logits — WITHOUT training

# The one labeled exception — option B (pre-computed on GPU; illustrative, NOT live) ----
optionB_loss <- tibble::tibble(
  epoch = 1:40,
  loss  = round(0.12 + 0.57 * exp(-(0:39) / 8), 3),   # labeled illustrative curve (committed inline, no .rds)
)
optionB_loss |>
  ggplot2::ggplot(ggplot2::aes(epoch, loss)) +
  ggplot2::geom_line() +
  ggplot2::theme_minimal() +
  ggplot2::labs(title = "Fused-net training loss — pre-computed on GPU (labeled, not live)")

# GPU vs CPU — authored write-only (never runs here; qualified calls, no library() to hoist) ----
if (FALSE) {
  fitted <- fused_net |>
    luz::setup(loss = torch::nn_cross_entropy_loss(), optimizer = torch::optim_adam) |>
    luz::set_hparams(n_tab = 11, sig_ch = 8, seq_in = 4, hidden = 16) |>
    fit(train_dl, epochs = 40, accelerator = luz::accelerator(cpu = FALSE))
}

# Your turn — reorder the fused forward (Parsons) ----
# >>>hole id=fused-forward kind=parsons prompt=run the three branches, concat along dim=2, then the head
#   solved:
fused_forward <- function(self, x_tab, x_sig, x_seq) {
  t <- self$tab(x_tab)
  c <- self$cnn(x_sig)
  r <- self$rnn(x_seq)
  self$head(torch_cat(list(t, c, r), dim = 2))
}
# <<<hole
```

(If you prefer the real recorded loss values over the illustrative decay, read `workshops/mlt-r-advanced/steps/02-deep-learning/assets/optionB-loss.rds` and transcribe its `epoch`/`loss` vectors into the tibble — but keep it inline, no shipped `.rds`.)

- [ ] **Step 4: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/02-deep-learning
git commit -m "mlt-r-advanced: 02-deep-learning beat — live MLP + carried torch modules; parsons hole; option-B inline"
```

## Task B4 — `03-ellmer` (append; typed ETL; live gated-off; labeled inline fallback; fill hole)

**Files:** Create `…/03-ellmer/meta.yml`, `.../beat.R`.

- [ ] **Step 1: `03-ellmer/meta.yml`**

```yaml
slug: 03-ellmer
title: "Step 03 — An LLM as a typed, reproducible ETL"
packages: [ellmer]
check:
  kw: [type_object, type_enum, chat_structured, ischemic]
  imgs: 0
```

- [ ] **Step 2: `03-ellmer/beat.R`** — the live call is gated on `OPENAI_API_KEY`; with no key (the build case) it prints a **labeled inline** record (no `.rds` cache). The batch is `if (FALSE)` (written-not-run).

```r
library(ellmer)

notes <- rio::import(here("data-raw", "hf_notes.csv"), setclass = "tibble")

# A typed schema is the contract that turns an LLM into an ETL (not a chat) ----
# (ellmer 0.4.1: type_enum(values, description) — values first, description second.)
note_type <- type_object(
  age               = type_integer("patient age in years"),
  ejection_fraction = type_number("ejection fraction as a percentage; NA if not stated"),
  on_betablocker    = type_boolean("TRUE if a beta-blocker is given or continued"),
  primary_dx        = type_enum(
    c("ischemic", "hypertensive", "valvular", "other"),
    "primary cardiac diagnosis",
  ),
)

# Key from the workshop-root .Renviron (gitignored), env only — .here anchors here() to THIS step ----
renviron_path <- here("..", "..", ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

# ONE live extraction; labeled INLINE fallback when no key (honesty doctrine, no shipped cache) ----
if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  chat <- chat_openai(model = "gpt-5.4-nano", echo = "none")
  chat$chat_structured(notes$text[[1]], type = note_type)
} else {
  cat("[No API key set — showing a LABELED example of an earlier live extraction.]\n")
  list(age = 78L, ejection_fraction = 30, on_betablocker = TRUE, primary_dx = "ischemic")
}

# The batch — WRITTEN, NOT RUN (it would call the API once per note) ----
# Low temperature => deterministic ETL; map iterates note-by-note into a typed tibble.
if (FALSE) {
  extract_one <- function(txt) {
    chat_openai(model = "gpt-5.4-nano", params = params(temperature = 0))$chat_structured(txt, type = note_type)
  }
  notes |>
    dplyr::mutate(parsed = purrr::map(text, extract_one)) |>
    tidyr::unnest_wider(parsed)
}

# Your turn — extend the schema ----
# >>>hole id=schema-field kind=fill prompt=add a serum_creatinine field (a number in mg/dL, NA if not stated)
#   solved:
serum_creatinine <- type_number("serum creatinine in mg/dL; NA if not stated")
serum_creatinine
#   blank:
serum_creatinine <- type_number(___)
serum_creatinine
# <<<hole
```

- [ ] **Step 3: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/03-ellmer
git commit -m "mlt-r-advanced: 03-ellmer beat — typed ETL, gated live call + labeled inline fallback, fill hole"
```

## Task B5 — `04-targets` (engine: targets; end-to-end DAG that trains the model; report node; delete demo)

**Files:** Create `…/04-targets/meta.yml`, `.../_targets.R`, `.../R/pipeline-fns.R`, `.../report.qmd`.

- [ ] **Step 1: `04-targets/meta.yml`**

```yaml
type: transform-terminal
engine: targets
slug: 04-targets
title: "Step 04 — Reproducibility capstone"
packages: [targets, tarchetypes, ranger]
check:
  kw: [Permutation VIMP, Importance, ejection_fraction]
  imgs: 1
```

- [ ] **Step 2: `04-targets/R/pipeline-fns.R`** — self-contained (§4.3): `pkg::fun()` everywhere; `requireNamespace()` for the S3 generics (`predict.workflow`, `extract_*`). The model is **trained**, not reloaded.

```r
# Pipeline functions for the targets capstone. Paths come from format="file" targets,
# resolved by targets relative to its project root (this step folder) — do NOT use here().
# Self-contained per spec §4.3: pkg::fun() throughout; S3 generics need their namespace loaded.
requireNamespace("workflows", quietly = TRUE)   # supplies predict.workflow / the workflow S3 methods
requireNamespace("parsnip",   quietly = TRUE)
requireNamespace("recipes",   quietly = TRUE)
requireNamespace("rsample",   quietly = TRUE)

# Rebuild the modelling cohort exactly as in the Basic workshop (clean_names first) ----
load_cohort <- function(cohort_file) {
  rio::import(cohort_file, setclass = "tibble") |>
    janitor::clean_names() |>
    dplyr::select(-time) |>
    dplyr::mutate(
      outcome = factor(
        dplyr::if_else(death_event == 1, "died", "survived"),
        levels = c("died", "survived"),
      ),
    ) |>
    dplyr::select(-death_event) |>
    dplyr::mutate(
      dplyr::across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor),
    )
}

# A held-out split (the same convention as Basic) ----
split_cohort <- function(cohort) {
  set.seed(123)
  rsample::initial_split(cohort, prop = 0.75, strata = outcome)
}

# The preprocessing recipe (no imputation; dummy + zv + normalize) ----
make_recipe <- function(split) {
  recipes::recipe(outcome ~ ., data = rsample::training(split)) |>
    recipes::step_dummy(recipes::all_nominal_predictors()) |>
    recipes::step_zv(recipes::all_predictors()) |>
    recipes::step_normalize(recipes::all_numeric_predictors())
}

# Train the random forest workflow on the training split ----
fit_rf <- function(split, recipe) {
  spec <- parsnip::rand_forest() |>
    parsnip::set_engine("ranger") |>
    parsnip::set_mode("classification")
  wf <- workflows::workflow() |>
    workflows::add_recipe(recipe) |>
    workflows::add_model(spec)
  parsnip::fit(wf, data = rsample::training(split))
}

# The bridge: explain the trained forest with permutation VIMP (a serializable tibble) ----
# vip unwraps the workflow and hands the bare engine to pred_wrapper, so the closure routes
# the prediction through the captured `model` workflow. vip::vi() (not vip()) keeps the target
# value a plain tibble so tar_read()/downstream targets stay reliable.
explain_model <- function(model, cohort) {
  pred_wrapper <- function(object, newdata) predict(model, newdata, type = "prob")$.pred_died
  set.seed(1)
  vip::vi(
    model,
    method       = "permute",
    train        = cohort,
    target       = "outcome",
    metric       = "roc_auc",
    pred_wrapper = pred_wrapper,
    nsim         = 10,
    event_level  = "first",
  )
}
```

- [ ] **Step 3: `04-targets/_targets.R`** — the end-to-end DAG; the hole sits on the split target; the report is a `tar_quarto` node.

```r
library(targets)
library(tarchetypes)

# Packages every target needs (loaded in the targets worker process) ----
tar_option_set(
  packages = c("tidymodels", "ranger", "vip", "rio", "janitor", "dplyr"),
)

source("R/pipeline-fns.R")  # load_cohort(), split_cohort(), make_recipe(), fit_rf(), explain_model()

# The DAG: input file -> cohort -> split -> recipe -> trained model -> explanation -> report.
# Each analysis is an EXPLICIT, INSPECTABLE intermediate target (tar_read() one at a time);
# the pipeline COMPILES THE REPORT itself from those targets, so document and inputs can never disagree.
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(cohort,      load_cohort(cohort_file)),
  # >>>hole id=tar-split kind=fill prompt=make the train/test split a target with split_cohort()
  #   solved:
  tar_target(split,       split_cohort(cohort)),
  #   blank:
  tar_target(split,       ___(cohort)),
  # <<<hole
  tar_target(recipe,      make_recipe(split)),
  tar_target(model,       fit_rf(split, recipe)),
  tar_target(explanation, explain_model(model, cohort)),
  tar_quarto(report, path = "report.qmd")
)
```

- [ ] **Step 4: `04-targets/report.qmd`** — the report **node**: reads `tar_read(explanation)`, never recomputes. Copy the current `workshops/mlt-r-advanced/steps/04-targets/report.qmd` content (it already does exactly this), keeping the title, the `tar_read(explanation)` chunk, and the VIMP `geom_col` plot.

- [ ] **Step 5: Smoke-test the pipeline in isolation** (proves §10.4/§10.5 before the full build)

Render the solved tree to a temp dir and run it once:
```bash
RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'
"$RS" -e '
  for (f in list.files("dev/mltbuild/R", pattern="[.]R$", full.names=TRUE)) source(f)
  wlib <- wlib_path("workshops/mlt-r-advanced", "4.6.0"); .libPaths(c(normalizePath(wlib), .libPaths()))
  td <- tempfile("smoke-"); dir.create(td)
  .emit_targets_step("workshops/mlt-r-advanced/_authoring/04-targets", td, "solved")
  file.copy("workshops/mlt-r-advanced/data-raw", td, recursive=TRUE)
  setwd(td); targets::tar_make(callr_function=NULL)
  stopifnot(file.exists("report.html")); cat("SMOKE OK\n")
'
```
Expected: targets builds `cohort → split → recipe → model → explanation → report`, prints `SMOKE OK`. (This is the only place the pipeline runs outside the full build; it confirms `pipeline-fns.R` source()s in isolation and the report node renders.)

- [ ] **Step 6: Commit**

```bash
git add workshops/mlt-r-advanced/_authoring/04-targets
git commit -m "mlt-r-advanced: 04-targets — end-to-end targets DAG (trains model), report as tar_quarto node"
```

---

# Fase C — Repo flip + unified-pipeline wiring

## Task C1 — Gitignore the generated tree; untrack legacy sources

**Files:** Modify root `.gitignore` (confirm coverage); `git rm --cached` the legacy generated tree + drivers + model blob.

- [ ] **Step 1: Confirm `.gitignore` covers the generated tree + `_solved.R`**

Run: `grep -nE "workshops/\*/(steps|full|_solved)/?|_solved.R" .gitignore`
Expected: lines for `workshops/*/steps/`, `workshops/*/full/`, `workshops/*/_solved/`, and `workshops/*/_solved.R` (added when Basic migrated). If any is missing, add it.

- [ ] **Step 2: Untrack the legacy hand-authored tree + the cross-workshop model blob**

The build will wipe + regenerate `steps/`/`full/`/`_solved/`; these must stop being tracked. The committed `model/final_fit.rds` is obsolete (self-seeded now).

```bash
git rm -r --cached workshops/mlt-r-advanced/steps
git rm workshops/mlt-r-advanced/_solved.R
git rm workshops/mlt-r-advanced/model/final_fit.rds
```
Expected: those paths staged for deletion from the index. (Working copies of `steps/` remain until the Fase D build unlinks + regenerates them; that is fine — the regenerated tree is gitignored.)

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "mlt-r-advanced: gitignore the generated tree; untrack legacy steps/, _solved.R, model/final_fit.rds"
```

## Task C2 — Re-add the Advanced teacher ZIP to the release contract (test-first)

**Files:** Modify `tests/skills/test_build_release.py`, `scripts/build_release.py`.

- [ ] **Step 1: Update the contract test to the 4-element list (RED)**

In `tests/skills/test_build_release.py`, change `test_asset_names_are_contractual`:

```python
    assert br.ZIP_ASSETS == [
        "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
        "mlt-r-advanced.zip", "mlt-r-advanced-teacher.zip",
    ]
```

- [ ] **Step 2: Run, verify FAIL**

Run: `python -m pytest tests/skills/test_build_release.py::test_asset_names_are_contractual -q`
Expected: FAIL (current `ZIP_ASSETS` has 3 elements).

- [ ] **Step 3: Implement** — in `scripts/build_release.py`, replace the `ZIP_ASSETS` block (drop the deferral comment):

```python
ZIP_ASSETS = [
    "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
    "mlt-r-advanced.zip", "mlt-r-advanced-teacher.zip",
]
```

- [ ] **Step 4: Run, verify PASS**

Run: `python -m pytest tests/skills/test_build_release.py -q`
Expected: all pass (the slug-strip in `build()` already maps `mlt-r-advanced-teacher.zip` → `workshops/mlt-r-advanced`).

- [ ] **Step 5: Commit**

```bash
git add scripts/build_release.py tests/skills/test_build_release.py
git commit -m "pipeline: re-add mlt-r-advanced-teacher.zip to ZIP_ASSETS (Advanced is fragment-built)"
```

## Task C3 — Portal: 4th button, Model C run flow, teacher download link

**Files:** Modify `site/advanced.qmd`, `site/downloads.qmd`.

- [ ] **Step 1: `site/advanced.qmd` — add the Coding-solutions button**

After the `Download workshop ZIP` button line, add:
```markdown
[Coding solutions ↗](advanced-solutions.html){.btn-deck}
```
(`site/advanced-solutions.qmd` already exists; its tabset auto-fills once `_solved/*.html` is generated by Fase D + a site build.)

- [ ] **Step 2: `site/advanced.qmd` — convert "How to get & run it" to Model C**

Replace the container-project body (the `Open `mlt-r-advanced.Rproj`, then `renv::restore()`…` paragraph) with the per-step-bundle flow, preserving the ellmer/`.Renviron` note:

```markdown
The download is a **bundle of per-step projects**, not a single project. Open the step you are
on — start with `steps/00-recap/00-recap.Rproj`; opening a step's `.Rproj` auto-activates its
`renv`, then `renv::restore()` installs the pinned packages. Each step is a complete cumulative
snapshot (the solution to step N is step N+1).

The LLM step (`ellmer`) needs an OpenAI API key (optional — it falls back to a labeled cached
extraction): copy `.Renviron.example` → `.Renviron` and set your key. The key is read from env
only and is never committed.
```

- [ ] **Step 3: `site/downloads.qmd` — add the Advanced teacher bundle + fix the wording**

After the `Advanced workshop project (ZIP)` line add:
```markdown
- [Advanced teacher bundle (ZIP, incl. solutions)](https://github.com/CorradoLanera/mlt-overview/releases/latest/download/mlt-r-advanced-teacher.zip)
```
And in "Running a workshop", change the trailing clause `(Basic ships a bundle of per-step projects; Advanced ships a single project).` to `(both ship a bundle of per-step projects).`

- [ ] **Step 4: Commit**

```bash
git add site/advanced.qmd site/downloads.qmd
git commit -m "site: Advanced as fragment-built — Coding-solutions button, Model C run flow, teacher bundle link"
```

---

# Fase D — Build, verify, gate

## Task D1 — Build the Advanced workshop; visual-verify the teacher HTML

**Files:** generated `workshops/mlt-r-advanced/{steps,full,_solved}/` (gitignored).

- [ ] **Step 1: Build**

Run: `RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'; "$RS" dev/mltbuild/build.R workshops/mlt-r-advanced`
Expected: `rendered 00-recap … 04-targets` then `BUILD OK: mlt-r-advanced -> …`. (This is the heavy step: each append `_solved` re-runs the inlined Basic tuning + torch MLP + kernelshap; the `04-targets` build runs `tar_make()` once. Budget several minutes.)

- [ ] **Step 2: Sanity-check the emitted tree**

Run:
```bash
ls workshops/mlt-r-advanced/_solved/         # 00-recap.html … 04-targets.html (5)
test -f workshops/mlt-r-advanced/steps/00-recap/.Rprofile && echo "00-recap is a full renv project (seeded, non-bare)"
test ! -e workshops/mlt-r-advanced/steps/04-targets/04-targets.R && echo "04-targets ships no student .R (transform)"
grep -L '___' workshops/mlt-r-advanced/full/full.R >/dev/null && echo "full.R has no blanks"
```
Expected: 5 solved HTMLs; 00-recap has `.Rprofile`+`renv/`; 04-targets has `_targets.R`/`report.qmd`/`R/pipeline-fns.R` (blank hole) and no `.R`; `full.R` has no `___`.

- [ ] **Step 3: Visual verification (mandatory — chrome-devtools)**

Open each `_solved/*.html` in chrome-devtools and confirm the expected KINDS of output render (no `___` in executed chunks, no error blocks, plots present): 00-recap (Basic curves + torch tensor), 01-interpret (VIMP plot + two SHAP waterfalls), 02-deep-learning (MLP roc_auc, SHAP waterfall, `[5,2]` shape, labeled loss curve), 03-ellmer (typed record + labeled fallback line), 04-targets (the report-node VIMP plot). Fix any rendering defect at the beat level and rebuild the affected step before proceeding.

- [ ] **Step 4: Commit** (only the renv.lock if it changed; the tree is gitignored)

```bash
git add -A workshops/mlt-r-advanced/renv.lock 2>/dev/null || true
git diff --cached --quiet || git commit -m "mlt-r-advanced: per-step renv.lock refresh from build"
```

## Task D2 — Structural parity + masking gate

- [ ] **Step 1: Parity**

Run: `"$RS" dev/mltbuild/parity.R workshops/mlt-r-advanced`
Expected: `STRUCTURAL PARITY OK …`. (Drives off the per-step `meta$check` added in Fase B via Task A4.) If a `kw`/`imgs` expectation is wrong, fix the `meta.yml check:` to match what genuinely renders (not the other way around).

- [ ] **Step 2: Masking certification**

Run: `"$RS" dev/mltbuild/check-masking.R workshops/mlt-r-advanced`
Expected: `MASKING CHECK OK …`. The Advanced `full.R` binds a real `final_fit` (from the inlined Basic pipeline), so the existing extractor applies. **If it FAILS**, a heavy package (torch/brulee/kernelshap/ellmer) masks a tidymodels generic used by the inlined tuning once hoisted to the top: qualify the offending call as `pkg::fun()` in the relevant beat (spec §4.3), rebuild, re-run. This is expected hardening, not a blocker.

- [ ] **Step 3: Full engine suite still green**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: `[ FAIL 0 | … | PASS >100 ]`.

## Task D3 — Adversarial §10 invariant verifier (sub-agent gate)

Dispatch a fresh sub-agent (read-only) to adversarially check the spec §10 invariants against the built Advanced tree and `_authoring/`. It must try to *falsify* each, and report PASS/FAIL with evidence (file:line). The checklist:

- [ ] **§10.1** every `_solved/*.html` rendered without an error block; each student `steps/*/*.R` parses (`parse()` clean).
- [ ] **§10.2** a `.here` sentinel exists in every `steps/*/` and `full/`.
- [ ] **§10.3** behavioral parity: `load_cohort(data-raw/heart_failure.csv)` in `pipeline-fns.R` yields the *same tibble* (cols, levels, nrow, event-first `outcome`) as the inline wrangle in the recap/01 beat.
- [ ] **§10.4** `R/pipeline-fns.R` `source()`s in a clean session with only `.libPaths()` set (no attached tidyverse) without error (pkg:: + requireNamespace discipline).
- [ ] **§10.5** `tar_make()` ran once and produced the report node HTML; there is **no** standalone `04-targets.qmd` anywhere under `_authoring/` or `steps/`; `report.qmd` contains `tar_read(` and no analysis recomputation.
- [ ] **§10.6** self-seeding: no `model/final_fit.rds` is read or shipped; `00-recap` produces the model by running the inlined Basic pipeline with `set.seed`; no `readRDS(.../mlt-r-basic/...)` cross-workshop path exists.
- [ ] **§10.7** carry-forward: `R/nn-modules.R` is present in `steps/02…/`, `03…/`, `04…/` and `full/`, is `source()`d only by the 02 beat, and does **not** appear in `04-targets/_targets.R`'s `tar_option_set(packages=)` or pipeline deps.
- [ ] **§10.8** each `steps/NN/renv.lock` packages ⊇ the cumulative packages of beats `0..N-1` (∪ the seeded set at 00).
- [ ] **§10.9** no `___` survives in any executed chunk of any `_solved/*.html`; every hole id renders distinct blank vs solved.

Record the verdict in the task; fix any FAIL at the source (beat/meta) and rebuild before closing.

## Task D4 — Unified `/mlt-build` end-to-end (no stale deliverables)

- [ ] **Step 1: Run the full pipeline for Advanced**

Run: `MLT_RSCRIPT='/c/Program Files/R/R-4.6.0/bin/Rscript.exe' python scripts/build_all.py --workshop mlt-r-advanced --release`
Expected: stages `rebuild → check-masking → render-deck → zip → release → site` all exit 0; `[build-all] done`. (`build_workshop_zip.py` auto-detects `_authoring/` and emits both `dist/mlt-r-advanced.zip` and `dist/mlt-r-advanced-teacher.zip`; `build_release.py` copies all four ZIPs without the STALE error.)

- [ ] **Step 2: Verify the ZIP is Model C (per-step projects, no `.rds`)**

Run:
```bash
python -c "import zipfile; z=zipfile.ZipFile('dist/mlt-r-advanced.zip'); n=z.namelist(); \
print('teacher_solved_in_student:', any('_solved/' in x for x in n)); \
print('rds_shipped:', any(x.endswith('.rds') for x in n)); \
print('per_step_rproj:', sum(x.endswith('.Rproj') for x in n)); \
print('has_recap_proj:', any(x.endswith('steps/00-recap/00-recap.Rproj') for x in n))"
```
Expected: `teacher_solved_in_student: False`, `rds_shipped: False`, `per_step_rproj: >=6` (5 steps + full), `has_recap_proj: True`.

- [ ] **Step 3: Full build (both workshops) — confirm Basic is unregressed and the default `/mlt-build` is green**

Run: `MLT_RSCRIPT='/c/Program Files/R/R-4.6.0/bin/Rscript.exe' python scripts/build_all.py`
Expected: builds both workshops, both parity + masking gates green, decks rendered, ZIPs + teacher bundles emitted, portal rebuilt. `[build-all] done`.

- [ ] **Step 4: Visual-verify the portal (mandatory — chrome-devtools)**

Render/open the portal and confirm: the Advanced page shows **four** buttons incl. "Coding solutions"; `advanced-solutions.html` renders the 5-step tabset of `_solved` iframes (not the placeholder); the "How to get & run it" reads as the Model C per-step flow; Downloads lists the Advanced teacher bundle.

- [ ] **Step 5: Commit any portal source/regeneration that is tracked**

```bash
git add docs site 2>/dev/null || true
git diff --cached --quiet || git commit -m "site: rebuild portal — Advanced fragment-built (coding solutions + Model C)"
```

(Decks, `dist/` ZIPs, and `dev/release-assets/` are gitignored build artifacts — do not commit them. **Do not `git push`**; the user pushes.)

---

## Self-Review

**1. Spec coverage** (each spec § → task):
- §4.2 transform Advanced (04-targets, `_targets.R` + `report.qmd` node, `tar_make()` once, no demo qmd) → A3 + B5 + D1/D3.
- §4.3 extract self-contained (`pkg::fun()` + `requireNamespace`) → B5 `pipeline-fns.R` + D3 §10.4.
- §6 carry-forward (transported, not sourced into deps) → A2 + B3 + D3 §10.7.
- §10 invariants → D3 (all 1–9) + D1/D2 gates; §10.10 oracle is Basic-only (N/A for Advanced per §11).
- §11 F2 (beats 00–03 + self-seeding + transform 04) → B0–B5; self-seeding §10.6 → A1 + B1.
- W1 carry-overs (teacher ZIP, parity/masking generalization, 4th portal button, Model C run flow) → A4/A5 + C2/C3.

**2. Placeholder scan:** none. Engine tasks carry full test + impl code; authoring tasks carry full `meta.yml` + `beat.R`/`_targets.R`/`pipeline-fns.R`; pipeline/portal tasks carry exact before/after snippets. The only "read the source and transcribe" pointers (copy `nn-modules.R`; copy `report.qmd`; optionally transcribe real option-B values) reference on-disk files the executing agent reads.

**3. Type/identifier consistency:** new `meta.yml` keys (`carry`, `check`, `engine`, `seed_from`) are introduced in A1 (`read_meta`) and consumed consistently (A2 `carry`, A3 `engine`, A4 `check`, A1 `seed_from`); helper names (`sibling_full`, `packages_for_step`, `.emit_targets_step`, `.render_authored_file`, `wlib_path`, `parity_checks`) are defined once and referenced by those exact names; step slugs `00-recap … 04-targets` match `workshop.yml`, the deck's go-to-code paths, and `_manifest.yml`.

**4. Parity scope:** structural only (`kw`/`imgs` from `meta$check`), per Decision 4 lineage — numbers not pinned (torch/kernelshap/tuning legitimately vary); behavioral invariants are enforced by the D3 adversarial verifier and the masking gate, not by numeric oracles.

**5. Reversibility / safety:** branch off `main`; engine changes are additive and keep Basic green (regression-gated in A4/A5/D4); no `git push`; the only destructive git ops (`git rm --cached`) untrack already-superseded generated files.
