#!/usr/bin/env python3
"""Assemble per-cohort GitHub Release assets into dev/release-assets/ (gitignored).

Renders the 3 decks self-contained (embed-resources:true) under contractual names,
and copies the workshop ZIPs from dist/ (build them first via /mlt-dist). The user
then tags the cohort and uploads these assets. Stdlib only; Quarto via subprocess.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

OUT = Path("dev/release-assets")
DECK_ASSETS = {
    "theory":   "mlt-overview-theory-deck.html",
    "basic":    "mlt-r-basic-deck.html",
    "advanced": "mlt-r-advanced-deck.html",
}
ZIP_ASSETS = [
    "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
    "mlt-r-advanced.zip",
    # "mlt-r-advanced-teacher.zip" — added once Advanced is fragment-built (W3);
    # until then it is never produced, so listing it would warn on every release.
]
_DECK_SRC = {
    "theory":   "slides/slides.qmd",
    "basic":    "slides/workshops/mlt-r-basic",
    "advanced": "slides/workshops/mlt-r-advanced",
}


def _run(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=str(cwd), check=True)


def _rendered_html(root: Path, key: str) -> Path:
    src = _DECK_SRC[key]
    if key == "theory":
        return root / "slides" / "slides.html"
    html_files = list((root / src).glob("*.html"))
    if not html_files:
        raise FileNotFoundError(
            f"No HTML found in {root / src} — did 'quarto render {src}' succeed?"
        )
    return html_files[0]


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


def build(root: Path) -> list[Path]:
    out = root / OUT
    out.mkdir(parents=True, exist_ok=True)
    made: list[Path] = []
    for key, src in _DECK_SRC.items():
        _run(["quarto", "render", src, "-M", "embed-resources:true"], root)
        dst = out / DECK_ASSETS[key]
        shutil.copy2(_rendered_html(root, key), dst)
        made.append(dst)
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
    return made


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    made = build(root)
    print("release assets in dev/release-assets/:", file=sys.stderr)
    for p in made:
        print(f"  {p.name} ({p.stat().st_size/1_000_000:.1f} MB)", file=sys.stderr)
    print("Next (manual): git tag coorte-AAAA -> create the Release -> upload these assets.",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
