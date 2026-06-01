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
ZIP_ASSETS = ["mlt-r-basic.zip", "mlt-r-advanced.zip"]
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
        if srcz.exists():
            shutil.copy2(srcz, out / z)
            made.append(out / z)
        else:
            print(f"WARNING: {srcz} missing — run /mlt-dist first", file=sys.stderr)
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
