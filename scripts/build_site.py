#!/usr/bin/env python3
"""Build the live public site into /docs.

Two parts:
  - write_partials(root, out): generate site/_generated/*.md from course sources (unit-tested).
  - main(): orchestrate the full build (partials -> quarto render site -> 3 decks non-embed into docs/slides -> copy img -> write .nojekyll).

Stdlib only; Quarto invoked via subprocess. Deterministic: same inputs -> same /docs.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from contextlib import contextmanager
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
    p = root / "workshops" / slug / "README.md"
    if not p.exists():
        return "_Overview to be published._\n"
    readme = p.read_text(encoding="utf-8", errors="replace")
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
    for i, (slug, key) in enumerate(WORKSHOPS, start=2):
        label = "Basic" if key == "basic" else "Advanced"
        sched += [f"## Module {i} · Practice — {label} (≈4h)", "",
                  _timeline_md(root, slug), ""]
    _emit("schedule.md", "\n".join(sched))

    for slug, key in WORKSHOPS:
        _emit(f"{key}-overview.md", _overview_md(root, slug))
        _emit(f"{key}-timeline.md", _timeline_md(root, slug))
        _emit(f"{key}-syllabus.md", _syllabus_partial(root, key))

    return written


# --- orchestration ----------------------------------------------------------

DOCS = Path("docs")

_NONEMBED_YAML = "format:\n  revealjs:\n    embed-resources: false\n"


@contextmanager
def _nonembed_metadata():
    """Yield the path of a temp metadata file forcing embed-resources:false.

    `-M embed-resources:false` does NOT override a value set in a document's YAML
    front-matter; a --metadata-file does. Cleaned up even if the render fails.
    """
    with tempfile.NamedTemporaryFile(mode="w", suffix=".yml",
                                     delete=False, encoding="utf-8") as tmp:
        tmp.write(_NONEMBED_YAML)
        tmp_path = Path(tmp.name)
    try:
        yield tmp_path
    finally:
        tmp_path.unlink(missing_ok=True)


def _run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)


def render_theory_deck(root: Path) -> None:
    """Render slides/slides.qmd non-embed; copy html + _files into docs/slides/."""
    with _nonembed_metadata() as meta:
        _run(["quarto", "render", "slides/slides.qmd", "--metadata-file", str(meta)], cwd=root)
    docs_slides = root / DOCS / "slides"
    docs_slides.mkdir(parents=True, exist_ok=True)
    src = root / "slides" / "slides.html"
    if not src.exists():
        raise FileNotFoundError(f"Expected rendered deck not found: {src}")
    shutil.copy2(src, docs_slides / "slides.html")
    files = root / "slides" / "slides_files"
    if files.is_dir():
        shutil.copytree(files, docs_slides / "slides_files", dirs_exist_ok=True)


def render_workshop_deck(root: Path, slug: str) -> None:
    """Render a workshop deck non-embed; copy into docs/slides/workshops/<slug>/."""
    wdir = root / "slides" / "workshops" / slug
    with _nonembed_metadata() as meta:
        _run(["quarto", "render", str(wdir), "--metadata-file", str(meta)], cwd=root)
    dst = root / DOCS / "slides" / "workshops" / slug
    dst.mkdir(parents=True, exist_ok=True)
    for p in wdir.glob("*.html"):
        shutil.copy2(p, dst / p.name)
    for d in wdir.glob("*_files"):
        if d.is_dir():
            shutil.copytree(d, dst / d.name, dirs_exist_ok=True)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Build the live public site into /docs")
    ap.add_argument("--root", default=".")
    ap.add_argument("--clean", action="store_true",
                    help="remove docs/ before building (removes stale assets)")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()

    if args.clean:
        shutil.rmtree(root / DOCS, ignore_errors=True)

    write_partials(root, root / "site" / "_generated")
    _run(["quarto", "render", "site"], cwd=root)
    render_theory_deck(root)
    for slug, _key in WORKSHOPS:
        render_workshop_deck(root, slug)
    shutil.copytree(root / "img", root / DOCS / "img", dirs_exist_ok=True)
    (root / DOCS / ".nojekyll").write_text("", encoding="utf-8")

    big = [str(p) for p in (root / DOCS).rglob("*")
           if p.is_file() and p.stat().st_size > 100_000_000]
    if big:
        print("WARNING: files >100MB in docs/: " + ", ".join(big), file=sys.stderr)
    print(f"site built into {root / DOCS}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
