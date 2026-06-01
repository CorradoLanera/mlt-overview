#!/usr/bin/env python3
"""Build the live public site into /docs.

Two parts:
  - write_partials(root, out): generate site/_generated/*.md from course sources (unit-tested).
  - main(): orchestrate the full build (partials -> quarto render site -> 3 decks non-embed
    into docs/slides -> copy img -> write .nojekyll). Implemented in a later task.

Stdlib only; Quarto invoked via subprocess. Deterministic: same inputs -> same /docs.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import site_content as sc  # noqa: E402

WORKSHOPS = [("mlt-r-basic", "basic"), ("mlt-r-advanced", "advanced")]
# Candidate syllabus source paths (forward-compatible; first existing wins).
SYLLABUS_SOURCES = {
    "theory":   ["course/_global/syllabus.md", "course/_global/syllabus-overview.md"],
    "basic":    ["workshops/mlt-r-basic/syllabus.md"],
    "advanced": ["workshops/mlt-r-advanced/syllabus.md"],
}
_SYLLABUS_PLACEHOLDER = "_Syllabus in preparation — it will appear here once finalised._\n"


def _syllabus_partial(root: Path, key: str) -> str:
    for rel in SYLLABUS_SOURCES.get(key, []):
        p = root / rel
        if p.exists():
            return p.read_text(encoding="utf-8", errors="replace")
    return _SYLLABUS_PLACEHOLDER


def _theory_chapters_md(root: Path) -> str:
    manifest = (root / "course" / "_manifest.yml").read_text(encoding="utf-8", errors="replace")
    out = ["## Chapters", ""]
    total = 0
    for ch in sc.chapters_from_manifest(manifest):
        if not ch["include"]:
            continue
        total += ch["minutes"]
        num = ch["slug"].split("-")[0]
        out.append(f"### {num} · {ch['title']} · {ch['minutes']} min")
        out.append("")
        obj_file = root / "course" / ch["slug"] / "objectives.md"
        obj = sc.extract_objectives(obj_file.read_text(encoding="utf-8", errors="replace")) \
            if obj_file.exists() else ""
        out.append(obj if obj else "_Objectives to be published._")
        out.append("")
    out.append(f"**Total contact time: {total} min.**")
    out.append("")
    return "\n".join(out)


def _timeline_md(root: Path, slug: str) -> str:
    fdir = root / "slides" / "workshops" / slug / "formatives"
    names = [p.name for p in fdir.glob("*.md")] if fdir.is_dir() else []
    rows = sc.timeline_from_formatives(names)
    if not rows:
        return "_Timeline to be published._\n"
    out = ["| Minute | Checkpoint |", "|---|---|"]
    for r in rows:
        out.append(f"| min {r['minute']} | {r['label']} |")
    return "\n".join(out) + "\n"


def _overview_md(root: Path, slug: str) -> str:
    readme = (root / "workshops" / slug / "README.md").read_text(encoding="utf-8", errors="replace")
    chunks = []
    for h in ("What you will build", "Dataset", "Prerequisites"):
        body = sc.readme_section(readme, h)
        if body:
            chunks.append(f"## {h}\n\n{body}")
    return ("\n\n".join(chunks) if chunks else "_Overview to be published._") + "\n"


def write_partials(root: Path, out_dir: Path) -> list[Path]:
    root = Path(root)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    def _emit(name: str, text: str) -> None:
        p = out_dir / name
        p.write_text(text, encoding="utf-8")
        written.append(p)

    _emit("theory-chapters.md", _theory_chapters_md(root))
    _emit("theory-syllabus.md", _syllabus_partial(root, "theory"))

    sched = ["## Module 1 · Theory Overview", "", _theory_chapters_md(root)]
    for slug, key in WORKSHOPS:
        label = "Basic" if key == "basic" else "Advanced"
        sched += [f"## Module {2 if key=='basic' else 3} · Practice — {label} (≈4h)", "",
                  _timeline_md(root, slug), ""]
    _emit("schedule.md", "\n".join(sched))

    for slug, key in WORKSHOPS:
        _emit(f"{key}-overview.md", _overview_md(root, slug))
        _emit(f"{key}-timeline.md", _timeline_md(root, slug))
        _emit(f"{key}-syllabus.md", _syllabus_partial(root, key))

    return written


# --- orchestration (implemented in a later task) ---------------------------

def main(argv=None) -> int:  # pragma: no cover
    raise SystemExit("build_site.main is implemented in a later task")


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
