---
description: Scaffold a new authoring beat (meta.yml + beat.R/report.qmd) in a workshop's _authoring/ and wire it into workshop.yml
---

Scaffold one new authoring *beat* for an R workshop with the correct marker grammar, so the author
doesn't have to remember it. Full conventions: `dev/mltbuild/README.md`.

Arguments: $ARGUMENTS = `<workshop-slug> <NN-slug> [type]`
- e.g. `mlt-r-basic 06-calibration` → an `append` beat (default).
- `type` = `transform-terminal` for a report-style step (creates `report.qmd` instead of `beat.R`).

Steps:

1. Parse `<workshop-slug>` and `<NN-slug>` (and optional `type`) from $ARGUMENTS. Confirm
   `workshops/<workshop-slug>/_authoring/workshop.yml` exists. If
   `workshops/<workshop-slug>/_authoring/<NN-slug>/` already exists, STOP and report (never overwrite).
2. Create `workshops/<workshop-slug>/_authoring/<NN-slug>/meta.yml` from the matching template below.
3. For an `append` beat, create `<NN-slug>/beat.R` from the template below — a *structurally* valid
   skeleton (one example `fill` hole + a section banner). It is NOT runnable until you replace the
   `<...>` placeholders. For `transform-terminal`, create `<NN-slug>/report.qmd` with a YAML header and
   one `{{frag:<id>}}` example token.
4. Read `workshop.yml`, insert `<NN-slug>` into the `steps:` list in the intended position (ask the user
   where if it isn't obvious from the number), and write it back.
5. Tell the user: fill the placeholders, then rebuild + gate —
   `Rscript dev/mltbuild/build.R workshops/<workshop-slug>` then
   `Rscript dev/mltbuild/parity.R workshops/<workshop-slug>` (or `/mlt-workshop-build <workshop-slug>`).

`meta.yml` (append):

```yaml
type: append
slug: <NN-slug>
title: "Step NN — <title>"
packages: [<pkg this beat introduces>]
```

`beat.R` (append) — fill the `<...>`; `library()` calls go where the new package is introduced (the build
hoists them to the top automatically), `set.seed(123)` only if/where you consume RNG:

```r
# <Section> ----
library(<pkg>)

# >>>hole id=<id> kind=fill prompt=<one-line instruction; MUST be the LAST field on this header line>
#   solved:
<the correct code>
#   blank:
<the same code, with ___ where the student fills in>
# <<<hole
```

`meta.yml` + `report.qmd` (transform-terminal):

```yaml
type: transform-terminal
slug: <NN-slug>
title: "Step NN — <title>"
template: report.qmd
packages: []
```

```
---
title: "<Report title>"
format:
  html:
    embed-resources: true
    toc: true
execute:
  warning: false
  message: false
---

<prose>

```{r}
{{frag:<id-defined-in-an-earlier-beat>}}
```
```

Conventions (see `dev/mltbuild/README.md`):
- `packages` lists ONLY what this beat introduces (cumulative → per-step `renv.lock`; step 00 ships no lock).
- hole kinds: `fill` (solved+blank), `prose` (solved only → `# TODO: <prompt>`), `parsons` (solved only → reordered).
- To reuse a canonical block in a transform report, wrap it `# >>>frag id=<id> … # <<<frag` (define each id once)
  and reference it as `{{frag:<id>}}` in the template.
- R style for the code: the workshop's `CLAUDE.md` (native pipe, `here::here()`, `# Section ----`, etc.).
