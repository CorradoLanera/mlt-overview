#!/usr/bin/env python3
"""Build a source-only distributable ZIP for an MLT workshop.

The workshop folder (workshops/<slug>/) holds only the R-project SOURCE. Slide
sources live separately in slides/workshops/<slug>/ and are NOT shipped; instead
the already-rendered, embed-resources deck HTML is injected into the ZIP under
<slug>/slides/. R-project inclusion is driven by `git ls-files` (only tracked
source ships; gitignored renv/library, .quarto, step renders, outputs are
excluded automatically), minus CLAUDE.md (authoring-only). The ZIP has a single
top-level <slug>/ folder so usethis::use_course() unpacks cleanly.

Usage:
  python scripts/build_workshop_zip.py workshops/mlt-r-basic
  python scripts/build_workshop_zip.py workshops/mlt-r-basic \\
      --deck-dir slides/workshops/mlt-r-basic --out dist/mlt-r-basic.zip
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

_EXCLUDE_NAMES = {"CLAUDE.md"}


def tracked_files(workshop_dir: Path) -> list[str]:
    """Git-tracked files under workshop_dir, POSIX paths relative to it."""
    res = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=str(workshop_dir), capture_output=True, text=True, check=True,
    )
    return [p for p in res.stdout.split("\0") if p]


def included_source(workshop_dir: Path) -> list[str]:
    """Tracked source to ship: git-tracked minus authoring-only files."""
    return [p for p in tracked_files(Path(workshop_dir))
            if Path(p).name not in _EXCLUDE_NAMES]


def rendered_decks(deck_dir: Path) -> list[Path]:
    """The rendered, self-contained deck HTML files to inject under slides/."""
    deck_dir = Path(deck_dir)
    if not deck_dir.is_dir():
        return []
    return sorted(p for p in deck_dir.glob("*.html") if p.is_file())


def build_zip(workshop_dir, deck_dir, out_zip, slug=None) -> Path:
    workshop_dir = Path(workshop_dir)
    deck_dir = Path(deck_dir)
    slug = slug or workshop_dir.name
    out_zip = Path(out_zip)
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        staging = Path(td) / slug
        # 1. tracked R-project source (minus CLAUDE.md)
        for rel in included_source(workshop_dir):
            src = workshop_dir / rel
            if not src.is_file():
                continue
            dest = staging / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
        # 2. inject the rendered deck(s) under <slug>/slides/
        decks = rendered_decks(deck_dir)
        if decks:
            (staging / "slides").mkdir(parents=True, exist_ok=True)
            for d in decks:
                shutil.copy2(d, staging / "slides" / d.name)
        # 3. zip with a single top-level <slug>/ folder
        with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(staging.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(staging.parent).as_posix())
    return out_zip


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workshop_dir")
    ap.add_argument("--deck-dir", default=None,
                    help="slides source dir holding the rendered deck "
                         "(default: slides/workshops/<slug>)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args(argv)
    ws = Path(args.workshop_dir)
    deck_dir = Path(args.deck_dir) if args.deck_dir else Path("slides/workshops") / ws.name
    out = Path(args.out) if args.out else Path("dist") / f"{ws.name}.zip"
    decks = rendered_decks(deck_dir)
    if not decks:
        print(f"WARNING: no rendered deck in {deck_dir} — run "
              f"`quarto render {deck_dir}` first", file=sys.stderr)
    build_zip(ws, deck_dir, out)
    size_mb = out.stat().st_size / 1_000_000
    print(f"built {out} ({size_mb:.1f} MB; {len(decks)} deck(s) injected)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
