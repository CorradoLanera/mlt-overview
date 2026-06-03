# Legacy portal (archived)

`portal.html` + `build_portal.py` were the **pre-Quarto author dashboard** for the MLT course.
They are **superseded** by the public Quarto site (`site/` → `docs/`, GitHub Pages) built by
`scripts/build_site.py`. They are **not** part of the build/release pipeline (`scripts/build_all.py`)
and the `rebuild-portal.py` PostToolUse hook has been disabled. Kept here for history only — do not
wire back into the build.
