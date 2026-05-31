#!/usr/bin/env python3
"""Build a source-only distributable ZIP for an MLT workshop.

Prunes to source-only, vendors the shared brand SCSS partial into the workshop's
slides/ (rewriting the theme path), and zips with a top-level <slug>/ folder so
usethis::use_course() unpacks cleanly. The shipped deck HTML must already be
rendered with embed-resources:true so its *_files/ dir can be excluded.

Usage:
  python scripts/build_workshop_zip.py workshops/mlt-r-basic
  python scripts/build_workshop_zip.py workshops/mlt-r-basic --out dist/mlt-r-basic.zip
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

DEFAULT_BRAND = Path("styles/_brand.scss")
_EXCLUDE_NAMES = {".Rhistory", ".DS_Store", "Thumbs.db", "CLAUDE.md"}
_EXCLUDE_PART_DIRS = {".quarto", ".Rproj.user", ".git"}


def is_excluded(rel_posix: str) -> bool:
    """True if the relative POSIX path should be left out of the ZIP."""
    parts = rel_posix.split("/")
    name = parts[-1]
    if rel_posix == "renv/library" or rel_posix.startswith("renv/library/"):
        return True
    if rel_posix == "renv/staging" or rel_posix.startswith("renv/staging/"):
        return True
    if rel_posix == "dist" or rel_posix.startswith("dist/"):
        return True
    if any(p in _EXCLUDE_PART_DIRS for p in parts):
        return True
    if any(p.endswith("_files") for p in parts):
        return True
    if name in _EXCLUDE_NAMES:
        return True
    return False


def vendor_brand(staging: Path, brand_src: Path) -> None:
    """Copy the shared brand partial into staging/slides and rewrite the theme path."""
    slides = staging / "slides"
    if not slides.is_dir():
        return
    shutil.copy2(brand_src, slides / "_brand.scss")
    qfile = slides / "_quarto.yml"
    if qfile.exists():
        text = qfile.read_text(encoding="utf-8")
        text = text.replace("../../../styles/_brand.scss", "_brand.scss")
        qfile.write_text(text, encoding="utf-8")


def _kept_files(workshop_dir: Path) -> list[Path]:
    out = []
    for p in sorted(workshop_dir.rglob("*")):
        if p.is_file() and not is_excluded(p.relative_to(workshop_dir).as_posix()):
            out.append(p)
    return out


def build_zip(workshop_dir: Path, brand_src: Path, out_zip: Path, slug: str | None = None) -> Path:
    workshop_dir = Path(workshop_dir)
    slug = slug or workshop_dir.name
    out_zip = Path(out_zip)
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        staging = Path(td) / slug
        for f in _kept_files(workshop_dir):
            dest = staging / f.relative_to(workshop_dir)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
        vendor_brand(staging, brand_src)
        with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(staging.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(staging.parent).as_posix())
    return out_zip


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workshop_dir")
    ap.add_argument("--brand", default=str(DEFAULT_BRAND))
    ap.add_argument("--out", default=None)
    args = ap.parse_args(argv)
    ws = Path(args.workshop_dir)
    out = Path(args.out) if args.out else Path("dist") / f"{ws.name}.zip"
    build_zip(ws, Path(args.brand), out)
    size_mb = out.stat().st_size / 1_000_000
    print(f"built {out} ({size_mb:.1f} MB)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
