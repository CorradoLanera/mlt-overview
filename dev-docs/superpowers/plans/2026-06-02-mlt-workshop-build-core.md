# MLT workshop build — core engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure R engine that turns per-step *beat fragments* into the cumulative student `.R` scripts, the `full` project, and the per-step cumulative package list — with `testthat` coverage, no Quarto/render needed.

**Architecture:** A small R toolkit under `dev/mltbuild/` (plain `R/` functions + `tests/testthat/`). Pure text transforms: parse hole markers → render `solved`/`blank` → assemble cumulative scripts → compute cumulative package set → materialize step folders + `full`. Config (`workshop.yml`, `meta.yml`) read with `{yaml}`. This plan stops *before* `renv.lock` generation, tabbed-HTML rendering, the Basic migration, and parity (those need the full R/Quarto env → plan 2).

**Tech Stack:** R 4.6.0 (already installed at `C:\Program Files\R\R-4.6.0`), `{testthat}` + `{yaml}` (install from the pinned PPM snapshot), base R only inside the engine (no tidyverse dependency in the tool itself).

**Reference spec:** `dev-docs/superpowers/specs/2026-06-02-mlt-workshop-fragment-build-design.md` (§3 layout, §4 fragment types, §5 holes, §7 renv semantics: step-N lock = packages 00..N-1).

**Decision (overridable at review):** build tool in **R** (not Python) — it manipulates R code, will later drive `renv`/`quarto`, and is maintained by an R-first author. Existing `scripts/build_release.py` stays as-is for the ZIP/release flow.

---

## Conventions used by this plan

- All R commands run with R 4.6 explicitly:
  `RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'` (Git Bash) — every "Run:" line uses `"$RS"`.
- Engine functions are **pure** (string in → string out; lists in → lists out) and live in `dev/mltbuild/R/`.
- Tests live in `dev/mltbuild/tests/testthat/` and run via `testthat::test_dir()`.
- One logical change per commit (project rule). Never push.

### Hole marker format (frozen here; resolves spec §13 open item)

A `beat.R` is plain R with zero or more hole blocks. A block:

```r
# >>>hole id=<id> kind=fill|parsons|prose [prompt=<text up to end of line>]
#   solved:
<solved lines...>
#   blank:
<blank lines... (may contain ___)>
# <<<hole
```

- `kind=fill` (default): both `solved:` and `blank:` sections present. Solved render keeps the
  solved lines; blank render keeps the blank lines.
- `kind=parsons`: only a `solved:` section. Blank render = the solved lines **reordered
  deterministically** (reverse order) under a `# Reorder the lines to: <prompt>` comment.
- `kind=prose`: only a `solved:` section. Blank render = a single `# TODO: <prompt>` line.

Lines outside any hole block are literal text, emitted identically in both renders.

---

## File Structure

- Create: `dev/mltbuild/R/holes.R` — `parse_beat()`, `render_beat()` (parse + render holes)
- Create: `dev/mltbuild/R/assemble.R` — `assemble_step()`, `assemble_full()`, `packages_through()`
- Create: `dev/mltbuild/R/config.R` — `read_meta()`, `read_workshop()` (YAML)
- Create: `dev/mltbuild/R/materialize.R` — `materialize_workshop()`
- Create: `dev/mltbuild/tests/testthat/test-holes.R`
- Create: `dev/mltbuild/tests/testthat/test-assemble.R`
- Create: `dev/mltbuild/tests/testthat/test-config.R`
- Create: `dev/mltbuild/tests/testthat/test-materialize.R`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/` — a tiny 3-step fixture workshop
- Create: `.claude/commands/mlt-workshop-build.md` — the build command (calls the engine)
- Modify: `.gitignore` — ignore generated workshop output

---

## Task 1: Toolkit skeleton + test harness + fixture

**Files:**
- Create: `dev/mltbuild/R/.gitkeep`
- Create: `dev/mltbuild/run-tests.R`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/workshop.yml`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/00-setup/{beat.R,meta.yml}`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/01-import/{beat.R,meta.yml}`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/02-eda/{beat.R,meta.yml}`
- Create: `dev/mltbuild/tests/testthat/fixtures/wkfix/data-raw/toy.csv`
- Create: `dev/mltbuild/tests/testthat/test-smoke.R`

- [ ] **Step 1: Install the two tool dependencies (one-off)**

Run:
```bash
RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'
"$RS" -e 'options(repos=c(CRAN="https://packagemanager.posit.co/cran/2026-06-01"), pkgType="binary"); install.packages(setdiff(c("testthat","yaml"), rownames(installed.packages())))'
```
Expected: `testthat` and `yaml` available (no error on a follow-up `requireNamespace`).

- [ ] **Step 2: Create the test runner**

`dev/mltbuild/run-tests.R`:
```r
# Source the engine and run the testthat suite. Usage: Rscript dev/mltbuild/run-tests.R
here_dir <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(here_dir, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
testthat::test_dir(file.path(here_dir, "tests", "testthat"), stop_on_failure = TRUE)
```

- [ ] **Step 3: Create the fixture workshop**

`dev/mltbuild/tests/testthat/fixtures/wkfix/workshop.yml`:
```yaml
slug: wkfix
r_version: "4.6.0"
ppm_snapshot: "2026-06-01"
dataset: data-raw/toy.csv
steps: [00-setup, 01-import, 02-eda]
```

`dev/mltbuild/tests/testthat/fixtures/wkfix/data-raw/toy.csv`:
```
a,b
1,2
```

`fixtures/wkfix/00-setup/meta.yml`:
```yaml
type: append
slug: 00-setup
title: "Setup"
packages: []
```

`fixtures/wkfix/00-setup/beat.R`:
```r
# Setup ----
# >>>hole id=load kind=fill prompt=load the toy data
#   solved:
toy <- read.csv(here::here("data-raw", "toy.csv"))
#   blank:
toy <- read.csv(here::here("data-raw", "___"))
# <<<hole
```

`fixtures/wkfix/01-import/meta.yml`:
```yaml
type: append
slug: 01-import
title: "Import"
packages: [janitor]
```

`fixtures/wkfix/01-import/beat.R`:
```r
# Wrangle ----
# >>>hole id=clean kind=fill prompt=clean the names
#   solved:
toy <- janitor::clean_names(toy)
#   blank:
toy <- janitor::___(toy)
# <<<hole
```

`fixtures/wkfix/02-eda/meta.yml`:
```yaml
type: append
slug: 02-eda
title: "EDA"
packages: [janitor]
```

`fixtures/wkfix/02-eda/beat.R`:
```r
# EDA ----
# >>>hole id=summ kind=prose prompt=summarise the toy table
#   solved:
summary(toy)
# <<<hole
```

- [ ] **Step 4: Create a smoke test that proves the harness runs**

`dev/mltbuild/tests/testthat/test-smoke.R`:
```r
test_that("harness runs", {
  expect_true(TRUE)
})
```

- [ ] **Step 5: Run the suite**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (1 test). (The smoke test confirms testthat + the runner work.)

- [ ] **Step 6: Commit**

```bash
git add dev/mltbuild
git commit -m "Scaffold mltbuild toolkit: test runner + fixture workshop"
```

---

## Task 2: `parse_beat()` — parse hole markers into segments

**Files:**
- Create: `dev/mltbuild/R/holes.R`
- Create: `dev/mltbuild/tests/testthat/test-holes.R`

- [ ] **Step 1: Write the failing test**

`dev/mltbuild/tests/testthat/test-holes.R`:
```r
test_that("parse_beat splits literal text and a fill hole", {
  beat <- c(
    "# Setup ----",
    "# >>>hole id=load kind=fill prompt=load the toy data",
    "#   solved:",
    "x <- 1",
    "#   blank:",
    "x <- ___",
    "# <<<hole"
  )
  segs <- parse_beat(beat)
  expect_equal(length(segs), 2L)
  expect_equal(segs[[1]]$type, "text")
  expect_equal(segs[[1]]$lines, "# Setup ----")
  expect_equal(segs[[2]]$type, "hole")
  expect_equal(segs[[2]]$id, "load")
  expect_equal(segs[[2]]$kind, "fill")
  expect_equal(segs[[2]]$prompt, "load the toy data")
  expect_equal(segs[[2]]$solved, "x <- 1")
  expect_equal(segs[[2]]$blank, "x <- ___")
})

test_that("parse_beat handles prose holes (solved only)", {
  beat <- c(
    "# >>>hole id=summ kind=prose prompt=summarise it",
    "#   solved:",
    "summary(toy)",
    "# <<<hole"
  )
  segs <- parse_beat(beat)
  expect_equal(segs[[1]]$kind, "prose")
  expect_equal(segs[[1]]$solved, "summary(toy)")
  expect_equal(segs[[1]]$blank, character(0))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"parse_beat\"".

- [ ] **Step 3: Write the implementation**

`dev/mltbuild/R/holes.R`:
```r
# Parse / render beat fragments with hole markers. Base R only.

.parse_hole_header <- function(line) {
  rest <- sub("^#\\s*>>>hole\\s+", "", line)
  id     <- sub("^.*\\bid=([^ ]+).*$", "\\1", rest)
  kind   <- if (grepl("\\bkind=", rest)) sub("^.*\\bkind=([^ ]+).*$", "\\1", rest) else "fill"
  prompt <- if (grepl("\\bprompt=", rest)) sub("^.*\\bprompt=(.*)$", "\\1", rest) else ""
  list(id = id, kind = kind, prompt = prompt)
}

parse_beat <- function(lines) {
  segs <- list()
  text_buf <- character(0)
  flush_text <- function() {
    if (length(text_buf)) {
      segs[[length(segs) + 1L]] <<- list(type = "text", lines = text_buf)
      text_buf <<- character(0)
    }
  }
  i <- 1L
  n <- length(lines)
  while (i <= n) {
    line <- lines[[i]]
    if (grepl("^#\\s*>>>hole\\b", line)) {
      flush_text()
      hdr <- .parse_hole_header(line)
      solved <- character(0); blank <- character(0); section <- NA_character_
      i <- i + 1L
      while (i <= n && !grepl("^#\\s*<<<hole\\s*$", lines[[i]])) {
        l <- lines[[i]]
        if (grepl("^#\\s*solved:\\s*$", l)) { section <- "solved" }
        else if (grepl("^#\\s*blank:\\s*$", l)) { section <- "blank" }
        else if (identical(section, "solved")) { solved <- c(solved, l) }
        else if (identical(section, "blank"))  { blank  <- c(blank,  l) }
        i <- i + 1L
      }
      segs[[length(segs) + 1L]] <- list(
        type = "hole", id = hdr$id, kind = hdr$kind, prompt = hdr$prompt,
        solved = solved, blank = blank
      )
      i <- i + 1L  # skip the closing marker
    } else {
      text_buf <- c(text_buf, line)
      i <- i + 1L
    }
  }
  flush_text()
  segs
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (smoke + 2 holes tests).

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/holes.R dev/mltbuild/tests/testthat/test-holes.R
git commit -m "mltbuild: parse_beat() splits text and hole segments"
```

---

## Task 3: `render_beat()` — render segments to solved / blank

**Files:**
- Modify: `dev/mltbuild/R/holes.R`
- Modify: `dev/mltbuild/tests/testthat/test-holes.R`

- [ ] **Step 1: Write the failing tests (append to test-holes.R)**

```r
test_that("render_beat solved keeps solved lines", {
  beat <- c("# A ----",
            "# >>>hole id=h kind=fill prompt=p", "#   solved:", "x <- 1",
            "#   blank:", "x <- ___", "# <<<hole")
  out <- render_beat(parse_beat(beat), "solved")
  expect_equal(out, c("# A ----", "x <- 1"))
})

test_that("render_beat blank keeps blank lines", {
  beat <- c("# >>>hole id=h kind=fill prompt=p", "#   solved:", "x <- 1",
            "#   blank:", "x <- ___", "# <<<hole")
  expect_equal(render_beat(parse_beat(beat), "blank"), "x <- ___")
})

test_that("render_beat blank for prose emits a TODO", {
  beat <- c("# >>>hole id=h kind=prose prompt=do the thing", "#   solved:",
            "summary(x)", "# <<<hole")
  expect_equal(render_beat(parse_beat(beat), "blank"), "# TODO: do the thing")
  expect_equal(render_beat(parse_beat(beat), "solved"), "summary(x)")
})

test_that("render_beat blank for parsons reverses solved lines under a prompt", {
  beat <- c("# >>>hole id=h kind=parsons prompt=order these", "#   solved:",
            "step_one()", "step_two()", "# <<<hole")
  expect_equal(
    render_beat(parse_beat(beat), "blank"),
    c("# Reorder the lines to: order these", "step_two()", "step_one()")
  )
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"render_beat\"".

- [ ] **Step 3: Implement `render_beat()` (append to holes.R)**

```r
.render_hole <- function(seg, mode) {
  if (identical(mode, "solved")) return(seg$solved)
  # mode == "blank"
  switch(seg$kind,
    fill    = seg$blank,
    prose   = paste0("# TODO: ", seg$prompt),
    parsons = c(paste0("# Reorder the lines to: ", seg$prompt), rev(seg$solved)),
    stop("unknown hole kind: ", seg$kind)
  )
}

render_beat <- function(segments, mode = c("solved", "blank")) {
  mode <- match.arg(mode)
  out <- character(0)
  for (seg in segments) {
    out <- c(out, if (seg$type == "text") seg$lines else .render_hole(seg, mode))
  }
  out
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (all holes tests).

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/holes.R dev/mltbuild/tests/testthat/test-holes.R
git commit -m "mltbuild: render_beat() emits solved/blank incl prose+parsons"
```

---

## Task 4: `assemble_step()` / `assemble_full()` — cumulative scripts

**Files:**
- Create: `dev/mltbuild/R/assemble.R`
- Create: `dev/mltbuild/tests/testthat/test-assemble.R`

- [ ] **Step 1: Write the failing test**

`dev/mltbuild/tests/testthat/test-assemble.R`:
```r
mk <- function(txt) parse_beat(strsplit(txt, "\n", fixed = TRUE)[[1]])

beats <- list(
  mk("# B0 ----\n# >>>hole id=a kind=fill prompt=p\n#   solved:\nx <- 0\n#   blank:\nx <- ___\n# <<<hole"),
  mk("# B1 ----\n# >>>hole id=b kind=fill prompt=p\n#   solved:\ny <- 1\n#   blank:\ny <- ___\n# <<<hole"),
  mk("# B2 ----\n# >>>hole id=c kind=fill prompt=p\n#   solved:\nz <- 2\n#   blank:\nz <- ___\n# <<<hole")
)

test_that("assemble_step n shows prior beats solved and beat n blank", {
  out <- assemble_step(beats, 2L)  # step index 2 (third beat)
  expect_true(all(c("x <- 0", "y <- 1") %in% out))   # 0..n-1 solved
  expect_true("z <- ___" %in% out)                    # beat n blank
  expect_false("z <- 2" %in% out)
})

test_that("assemble_step 0 has only the first beat blank", {
  out <- assemble_step(beats, 0L)
  expect_true("x <- ___" %in% out)
  expect_false(any(c("y <- 1", "y <- ___") %in% out))
})

test_that("assemble_full shows every beat solved", {
  out <- assemble_full(beats)
  expect_true(all(c("x <- 0", "y <- 1", "z <- 2") %in% out))
  expect_false(any(grepl("___", out)))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"assemble_step\"".

- [ ] **Step 3: Implement**

`dev/mltbuild/R/assemble.R`:
```r
# Cumulative assembly of beats into step / full scripts.

.join_beats <- function(rendered_list) {
  # rendered_list: list of character vectors; join with one blank line between beats.
  out <- character(0)
  for (k in seq_along(rendered_list)) {
    if (k > 1L) out <- c(out, "")
    out <- c(out, rendered_list[[k]])
  }
  out
}

assemble_step <- function(beats, n) {
  # beats: list of parsed beats (0-indexed conceptually); n: 0-based step index.
  stopifnot(n >= 0, n < length(beats))
  prior <- if (n >= 1L) lapply(beats[seq_len(n)], render_beat, mode = "solved") else list()
  current <- list(render_beat(beats[[n + 1L]], mode = "blank"))
  .join_beats(c(prior, current))
}

assemble_full <- function(beats) {
  .join_beats(lapply(beats, render_beat, mode = "solved"))
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/assemble.R dev/mltbuild/tests/testthat/test-assemble.R
git commit -m "mltbuild: assemble_step()/assemble_full() cumulative scripts"
```

---

## Task 5: `packages_through()` — cumulative package set (00..N-1)

**Files:**
- Modify: `dev/mltbuild/R/assemble.R`
- Modify: `dev/mltbuild/tests/testthat/test-assemble.R`

- [ ] **Step 1: Write the failing test (append to test-assemble.R)**

```r
metas <- list(
  list(packages = character(0)),   # step 0
  list(packages = c("janitor")),   # step 1
  list(packages = c("janitor", "gtsummary"))  # step 2
)

test_that("packages_through gives the START state of step n = packages of beats 0..n-1", {
  expect_equal(packages_through(metas, 0L), character(0))            # step 0: nothing yet
  expect_equal(packages_through(metas, 1L), character(0))            # step 1: beat 0 introduced none
  expect_setequal(packages_through(metas, 2L), c("janitor"))        # step 2: beats 0..1
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"packages_through\"".

- [ ] **Step 3: Implement (append to assemble.R)**

```r
packages_through <- function(metas, n) {
  # Lock for step n = union of packages introduced by beats 0..n-1 (the START state).
  stopifnot(n >= 0, n <= length(metas))
  if (n == 0L) return(character(0))
  pk <- unlist(lapply(metas[seq_len(n)], function(m) m$packages %||% character(0)))
  unique(pk %||% character(0))
}

`%||%` <- function(x, y) if (is.null(x)) y else x
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/assemble.R dev/mltbuild/tests/testthat/test-assemble.R
git commit -m "mltbuild: packages_through() cumulative 00..N-1 package set"
```

---

## Task 6: `read_workshop()` / `read_meta()` — load the authoring tree

**Files:**
- Create: `dev/mltbuild/R/config.R`
- Create: `dev/mltbuild/tests/testthat/test-config.R`

- [ ] **Step 1: Write the failing test**

`dev/mltbuild/tests/testthat/test-config.R`:
```r
fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("read_workshop loads ordered steps with parsed beats and metas", {
  wk <- read_workshop(fixroot)
  expect_equal(wk$slug, "wkfix")
  expect_equal(length(wk$steps), 3L)
  expect_equal(vapply(wk$steps, function(s) s$slug, ""), c("00-setup", "01-import", "02-eda"))
  expect_equal(wk$steps[[2]]$meta$packages, "janitor")
  # beat parsed into segments:
  expect_true(any(vapply(wk$steps[[1]]$beat, function(s) s$type == "hole", logical(1))))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"read_workshop\"".

- [ ] **Step 3: Implement**

`dev/mltbuild/R/config.R`:
```r
# Load the authoring tree (workshop.yml + per-step meta.yml + beat.R).

read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages <- as.character(m$packages %||% character(0))
  m$type <- m$type %||% "append"
  m
}

read_workshop <- function(authoring_dir) {
  wk <- yaml::read_yaml(file.path(authoring_dir, "workshop.yml"))
  steps <- lapply(wk$steps, function(slug) {
    step_dir <- file.path(authoring_dir, slug)
    beat_file <- file.path(step_dir, "beat.R")
    list(
      slug = slug,
      meta = read_meta(step_dir),
      beat = if (file.exists(beat_file)) parse_beat(readLines(beat_file)) else list()
    )
  })
  list(
    slug = wk$slug,
    r_version = wk$r_version,
    ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset,
    authoring_dir = authoring_dir,
    steps = steps
  )
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/config.R dev/mltbuild/tests/testthat/test-config.R
git commit -m "mltbuild: read_workshop()/read_meta() load the authoring tree"
```

---

## Task 7: `materialize_workshop()` — write step folders + full

**Files:**
- Create: `dev/mltbuild/R/materialize.R`
- Create: `dev/mltbuild/tests/testthat/test-materialize.R`

Materialize each `steps/NN-slug/` with: `NN-slug.R` (cumulative student script), `data-raw/`
(copied), `.here` (sentinel), and a `packages.txt` (the cumulative 00..N-1 list — the *input* to
renv.lock generation in plan 2; the lock file itself is deferred). Also write `full/full.R`.

- [ ] **Step 1: Write the failing test**

`dev/mltbuild/tests/testthat/test-materialize.R`:
```r
fixroot <- testthat::test_path("fixtures", "wkfix")

test_that("materialize_workshop writes step scripts, data-raw, .here, packages.txt, full", {
  out <- file.path(tempfile("wkout-"))
  wk <- read_workshop(fixroot)
  materialize_workshop(wk, out)

  # step 00 — first formative blank, no prior, packages.txt empty
  s0 <- readLines(file.path(out, "steps", "00-setup", "00-setup.R"))
  expect_true(any(grepl('read.csv\\(here::here\\("data-raw", "___"\\)\\)', s0)))
  expect_false(any(grepl('"toy.csv"', s0)))
  expect_true(file.exists(file.path(out, "steps", "00-setup", ".here")))
  expect_true(file.exists(file.path(out, "steps", "00-setup", "data-raw", "toy.csv")))
  expect_equal(readLines(file.path(out, "steps", "00-setup", "packages.txt")), character(0))

  # step 02 — prior beats solved, this beat blank (prose TODO), packages from 00..01
  s2 <- readLines(file.path(out, "steps", "02-eda", "02-eda.R"))
  expect_true(any(grepl('clean_names\\(toy\\)', s2)))    # beat 01 solved (prior)
  expect_true(any(grepl("# TODO: summarise the toy table", s2)))  # beat 02 blank (prose)
  expect_equal(readLines(file.path(out, "steps", "02-eda", "packages.txt")), "janitor")

  # full — all solved
  full <- readLines(file.path(out, "full", "full.R"))
  expect_true(any(grepl('"toy.csv"', full)))
  expect_false(any(grepl("___", full)))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: FAIL with "could not find function \"materialize_workshop\"".

- [ ] **Step 3: Implement**

`dev/mltbuild/R/materialize.R`:
```r
# Materialize a generated workshop tree (steps/ + full/) from a read_workshop() object.

.write_lines <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.copy_data_raw <- function(authoring_dir, dest_dir) {
  src <- file.path(authoring_dir, "data-raw")
  if (dir.exists(src)) {
    dir.create(file.path(dest_dir, "data-raw"), recursive = TRUE, showWarnings = FALSE)
    file.copy(list.files(src, full.names = TRUE), file.path(dest_dir, "data-raw"),
              recursive = TRUE)
  }
}

materialize_workshop <- function(wk, out_dir) {
  beats <- lapply(wk$steps, `[[`, "beat")
  metas <- lapply(wk$steps, `[[`, "meta")
  unlink(out_dir, recursive = TRUE)

  for (n in seq_along(wk$steps) - 1L) {           # 0-based index
    slug <- wk$steps[[n + 1L]]$slug
    step_dir <- file.path(out_dir, "steps", slug)
    .write_lines(assemble_step(beats, n), file.path(step_dir, paste0(slug, ".R")))
    .write_lines(packages_through(metas, n), file.path(step_dir, "packages.txt"))
    .write_lines(character(0), file.path(step_dir, ".here"))
    .copy_data_raw(wk$authoring_dir, step_dir)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$authoring_dir, full_dir)
  invisible(out_dir)
}
```

- [ ] **Step 4: Run to verify pass**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (all suites green).

- [ ] **Step 5: Commit**

```bash
git add dev/mltbuild/R/materialize.R dev/mltbuild/tests/testthat/test-materialize.R
git commit -m "mltbuild: materialize_workshop() writes steps/ + full/"
```

---

## Task 8: Build command + gitignore generated output

**Files:**
- Create: `dev/mltbuild/build.R`
- Create: `.claude/commands/mlt-workshop-build.md`
- Modify: `.gitignore`

- [ ] **Step 1: Create the CLI entry**

`dev/mltbuild/build.R`:
```r
# Parse + materialize a workshop's generated tree from its authoring source.
# Plan-1 stub: writes steps/ + full/ to a TEMP dir and reports it. Real wiring into
# workshops/<slug>/{steps,full} + _solved/ + renv.lock lands in plan 2.
# Usage: Rscript dev/mltbuild/build.R <authoring_dir>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
root <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
wk <- read_workshop(args[[1]])
out <- tempfile("mlt-")
materialize_workshop(wk, out)
cat("built workshop:", wk$slug, "(", length(wk$steps), "steps ) ->", out, "\n")
```

> NOTE: the final wiring of `out_dir` to `workshops/<slug>/{steps,full}` plus `_solved/` HTML and
> `renv.lock` generation lands in **plan 2** (needs the R/Quarto env). This task only proves the
> engine runs end-to-end on the fixture and ships the command stub.

- [ ] **Step 2: Run the engine end-to-end on the fixture**

Run:
```bash
"$RS" dev/mltbuild/build.R dev/mltbuild/tests/testthat/fixtures/wkfix
```
Expected: prints `built workshop: wkfix ( 3 steps ) -> <tempdir>` and no error.

- [ ] **Step 3: Create the command file**

`.claude/commands/mlt-workshop-build.md`:
```markdown
---
description: Build a workshop's generated tree (steps/ + full/) from its _authoring/ fragments
---

Build the generated student/teacher tree for one R workshop from its fragment source.

Arguments: $ARGUMENTS (workshop slug, e.g. `mlt-r-basic`).

Steps:

1. Resolve `AUTH=workshops/<slug>/_authoring` (the `OUT` wiring into `workshops/<slug>` lands in plan 2).
2. Run the engine with R 4.6:
   `"/c/Program Files/R/R-4.6.0/bin/Rscript.exe" dev/mltbuild/build.R "$AUTH"`
3. Report the generated `steps/`, `full/` (and, from plan 2 on, `_solved/` + per-step `renv.lock`).

Notes:
- The generated `steps/`, `full/`, `_solved/` are gitignored (build on-demand); only `_authoring/`
  and `data-raw/` are committed.
- HTML tabs, `renv.lock` generation, the Basic migration and parity-vs-oracle live in plan 2.
```

- [ ] **Step 4: Ignore only mltbuild scratch (NOT the legacy tree yet)**

The real ignore of generated output (`workshops/*/{steps,full,_solved}/`) is deferred to plan 2,
because `workshops/mlt-r-*/steps/` is still the *legacy hand-authored* source until the Basic
migration moves it into `_authoring/`. Ignoring it now would hide live sources. For plan 1 append
only a scratch rule to `.gitignore`:
```
# mltbuild scratch (plan 1)
dev/mltbuild/**/_generated/
```

- [ ] **Step 5: Run the full suite once more**

Run: `"$RS" dev/mltbuild/run-tests.R`
Expected: PASS (all tests green).

- [ ] **Step 6: Commit**

```bash
git add dev/mltbuild/build.R .claude/commands/mlt-workshop-build.md .gitignore
git commit -m "mltbuild: build CLI entry + /mlt-workshop-build command stub"
```

---

## What this plan deliberately defers to plan 2

- `renv.lock` **file** generation per step (consume `packages.txt` → `renv::snapshot(packages=…,
  lockfile=…)` against the PPM-pinned library), incl. `renv::init` semantics for step 00.
- **Teacher tabbed HTML** (`::: {.panel-tabset}` To-fill / Solved) via `quarto::quarto_render`.
- **Transform-terminal** authoring + rendering: Basic `05-report` (self-contained Quarto) and
  Advanced `04-targets` (`_targets.R` + `report.qmd` node, `tar_make()`).
- **Migration of the Basic workshop**: extract beats from the current `steps/*/*.qmd` into
  `workshops/mlt-r-basic/_authoring/`, then flip the `.gitignore` to ignore the regenerated tree.
- **Parity oracle**: assert the regenerated Basic solved outputs match the already-built
  `*-solved.html` (this session) modulo seed.
- Advanced **self-seeding** (`00-recap` rebuilds the model from raw), and the **adversarial verifier**
  subagent that checks the §10 invariants.
- **HARDEN `materialize_workshop()` before wiring `out_dir` to a real path (data-loss hazard).** It
  currently runs `unlink(out_dir, recursive = TRUE)` — safe in plan 1 because `out_dir` is always a
  throwaway tempdir. Plan 2 points `out_dir` at `workshops/<slug>/`, which **contains** the committed
  `_authoring/` + `data-raw/` source-of-truth, so a naive call would delete the source on its first
  line. Fix in plan 2: `unlink` only the generated subtrees (`steps/`, `full/`, `_solved/`), or refuse
  to `unlink` any directory containing `_authoring/`/`workshop.yml`. (Flagged by the plan-1 final review.)

---

## Self-Review

- **Spec coverage:** this plan implements the *engine* for §3 (assembly), §4.1 (append), §5 (holes —
  all 3 authored kinds; the "non-executed skeleton" and "multi-hole" are render-time/teacher-HTML
  concerns handled in plan 2), §7 (package set = 00..N-1). Transform/extract (§4.2–4.3), renv.lock,
  HTML, decks (§9), invariants (§10), migration/parity (§11) are explicitly deferred and listed above.
- **Placeholder scan:** none — every step has runnable code/commands. The two `> NOTE:` blocks flag
  *intentional* plan-2 scope boundaries, not missing content.
- **Type consistency:** `parse_beat()` returns segments consumed by `render_beat()`; `assemble_*`
  consume the parsed beats; `read_workshop()$steps[[k]]$beat` is the parsed-beat form; `materialize_*`
  uses `assemble_step/full` + `packages_through`. Names consistent across tasks.
