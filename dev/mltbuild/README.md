# mltbuild — the workshop fragment-build engine

Turns a workshop's `_authoring/` fragments into the generated student + teacher tree.
Pure base-R engine in `R/`, `{testthat}` suite in `tests/`.

## Build a workshop

Two ways, same result — use whichever you remember:

```sh
RS='/c/Program Files/R/R-4.6.0/bin/Rscript.exe'   # R 4.6 on this machine

# One command for everything (build + structural gate), all workshops or a named one:
"$RS" dev/mltbuild/rebuild.R                       # every workshop with an _authoring/ source
"$RS" dev/mltbuild/rebuild.R mlt-r-basic           # just one

# …or the underlying steps directly:
"$RS" dev/mltbuild/build.R   workshops/<slug>      # → steps/ + full/ + _solved/ + per-step renv.lock
"$RS" dev/mltbuild/parity.R  workshops/<slug>      # structural gate: every step renders the expected output kinds
"$RS" dev/mltbuild/run-tests.R                     # engine unit tests
```

From inside Claude Code you (or Claude, on request) can run `/mlt-workshop-build` (no arg = rebuild all)
— it just calls `rebuild.R`.

`steps/`, `full/`, `_solved/` are **gitignored** — only `_authoring/` + `data-raw/` + the workshop
`renv.lock` are committed. Edit a fragment, rebuild, and the change propagates to every downstream
cumulative step automatically (**drift zero**).

Generated `.R` scripts get all their `library()` calls **hoisted to the top** (first-appearance order,
deduped); `set.seed()` stays exactly where it acts. Because hoisting changes *when* packages load
relative to the code, there is an on-demand **hoist-safety certification** (heavier — runs the analysis
twice; use after changing package loading or before a release, not on every edit):

```sh
"$RS" dev/mltbuild/check-masking.R workshops/<slug>   # → MASKING CHECK OK
```

It runs `full.R` with libraries interleaved vs hoisted and asserts the deterministic result metrics are
identical — i.e. no beat uses a function a later package masks differently. If it fails, qualify the
offending call as `pkg::fun`.

## Authoring a workshop — `workshops/<slug>/_authoring/`

```
workshop.yml                  # slug, r_version, ppm_snapshot, dataset, ordered steps[]
NN-slug/ meta.yml beat.R      # an "append" beat (one new teaching beat per step)
NN-slug/ meta.yml report.qmd  # a "transform-terminal" step (see below)
```

R style inside `beat.R` is the workshop's own — see its `CLAUDE.md` (native pipe `|>`, `here::here()`,
`# Section ----` banners, `set.seed(123)`, one arg per line, …). The build only adds the *structure*
below; it never reformats your R.

### `meta.yml`

```yaml
type: append            # or: transform-terminal   (default: append)
slug: NN-slug
title: "Step NN — …"    # shown as the teacher-HTML title
packages: [pkg, …]      # packages this beat INTRODUCES
template: report.qmd    # transform-terminal only
```

`packages` is cumulative and defines the **START state** of each step: step N's `renv.lock` = the union
of packages from beats `00..N-1`. Step 00 ships with **no** lock (it teaches `renv::init()`); from step 01
on, students `renv::restore()`. A beat that introduces a new package is the moment the student installs it.

### Hole markers — the live-coding blanks

A beat has zero or more holes. The build renders **prior** beats *solved* and the **current** beat *blank*
into the student `.R`; the teacher HTML shows both as To-fill / Solved tabs.

```r
# >>>hole id=<id> kind=fill|parsons|prose [prompt=<text to end of line>]
#   solved:
<real code>
#   blank:
<code with ___>          # fill kind only
# <<<hole
```

- `fill` (default): both sections present; the blank render keeps the `blank:` lines (with `___`).
- `prose`: only `solved:`; blank render = a single `# TODO: <prompt>` line.
- `parsons`: only `solved:`; blank render = the solved lines reversed, under `# Reorder the lines to: <prompt>`.

`prompt=` must be the **last** field on the header line (it is captured to end-of-line). A step may have no
hole at all (a demo / given step).

### Fragment markers — DRY shared code for the report

Mark a canonical region so a transform-terminal template can reuse it **verbatim**:

```r
# >>>frag id=<id>
<canonical solved lines>
# <<<frag
```

Fragment markers are stripped from every student / teacher / `full` artifact, and sliced out by id only to
substitute `{{frag:id}}` tokens in a transform-terminal template. A frag may sit **inside** a hole's
`solved:` section (e.g. a pipe tail) — keep its indentation as it should appear when inlined. Define each id
**once** (a duplicate id warns at build time).

### transform-terminal steps

A step with `type: transform-terminal` is **not** appended to the cumulative `.R`. Its `report.qmd` template
is shipped as a self-contained Quarto document with the shared code inlined from `{{frag:id}}` tokens — so
the deliverable a colleague receives has **all code inline** (no runtime `include`/child docs). Example:
Basic `05-report`. The teacher HTML for such a step is just the rendered report (no tabs).

## What the build emits per step

```
steps/NN-slug/NN-slug.R    # student: prior beats solved + this beat blank      (append)
steps/NN-slug/report.qmd   # shipped self-contained report                      (transform-terminal)
steps/NN-slug/renv.lock    # cumulative 00..N-1   (absent at step 00)
steps/NN-slug/.here        # here() sentinel — anchors here() to this folder
steps/NN-slug/data-raw/    # the seed data, copied in
full/full.R                # every beat solved — a structural reference of the finished project
_solved/NN-slug.html       # teacher: To-fill / Solved tabs (append) or the rendered report (transform)
```

## For the teacher (running the workshop)

Keep the per-step `_solved/NN-slug.html` open on a second screen: the **To-fill** tab is exactly what the
student sees in `steps/NN-slug/NN-slug.R`; the **Solved** tab is the same code executed, with outputs. Close
each as you finish a step. Students who fall behind just open the next `steps/` folder — it already contains
the prior solutions as *given*.
