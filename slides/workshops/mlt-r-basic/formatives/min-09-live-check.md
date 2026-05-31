# Formative · min 9 · live-check (after Step 00)

- **Type:** live-check (GREEN / RED show of hands or poll)
- **Concept-graph node checked:** `PROJ` — Reproducible project (renv + here + rio)

## Prompt

Run these three checks and signal **GREEN** if all pass, **RED** if any fails:

1. Is your **`.Rproj`** open (the project, not a loose script)?
2. Does **`renv::status()`** report the library **in sync** with the lockfile?
3. Does **`here::here()`** point to the **project root**?

## Expected answer (GREEN)

All three pass:

- the `.Rproj` is open, so the working directory is anchored to the project;
- `renv::status()` says "The project is already synchronized with the lockfile";
- `here::here()` returns the project-root path (where the `.Rproj` / `.here` lives).

If any is RED, fix it now (re-open the `.Rproj`, run `renv::restore()`, or check the
`.here` sentinel) before the hands-on starts — a healthy environment is the
precondition for everything that follows.
