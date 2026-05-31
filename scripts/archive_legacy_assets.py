#!/usr/bin/env python3
"""Classify and relocate the assets referenced by the legacy xaringan sources.

Assets referenced ONLY by the xaringan sources (index.Rmd / index-full.Rmd) are
git-moved into _archive/legacy-xaringan/ (decluttering img/). Assets also used by
the live tree (course/ slides/ workshops/) are copied (keeping the live build intact).

Usage:
  python scripts/archive_legacy_assets.py            # report only
  python scripts/archive_legacy_assets.py --apply    # perform git mv + copies
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ARCHIVE = Path("_archive/legacy-xaringan")
XARINGAN_SOURCES = [Path("index.Rmd"), Path("index-full.Rmd")]
LIVE_DIRS = [Path("course"), Path("slides"), Path("workshops")]
LIVE_TEXT_SUFFIXES = {".qmd", ".rmd", ".md", ".html", ".scss", ".css", ".yml", ".yaml"}

_REF_RE = re.compile(
    r'!\[[^\]]*\]\(([^)\s]+)\)'           # markdown image
    r'|src\s*=\s*["\']([^"\']+)["\']'      # html src
    r'|href\s*=\s*["\']([^"\']+)["\']'     # html href (css link)
    r'|url\(\s*["\']?([^)"\']+)["\']?\s*\)'  # css url()
    r'|include_graphics\(\s*["\']([^"\']+)["\']',  # knitr
    re.IGNORECASE,
)
_ASSET_EXT_RE = re.compile(r"\.(png|jpe?g|gif|svg|webp|css|mp4|webm|pdf)$", re.IGNORECASE)


def extract_refs(text: str) -> set[str]:
    """Local asset paths referenced in `text` (remote URLs and anchors dropped)."""
    refs: set[str] = set()
    for m in _REF_RE.finditer(text):
        for g in m.groups():
            if not g:
                continue
            g = g.strip().strip("'\"")
            if "://" in g or g.startswith("#") or g.startswith("data:"):
                continue
            if _ASSET_EXT_RE.search(g):
                refs.add(g.lstrip("./"))
    return refs


def classify(referenced: set[str], live_blob: str) -> tuple[set[str], set[str]]:
    """Split referenced assets into (to_move, to_copy).

    to_copy = basename also present in the live tree text; to_move = xaringan-only.
    """
    to_move: set[str] = set()
    to_copy: set[str] = set()
    for rel in referenced:
        base = rel.rsplit("/", 1)[-1]
        if base and base in live_blob:
            to_copy.add(rel)
        else:
            to_move.add(rel)
    return to_move, to_copy


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def _live_blob(root: Path) -> str:
    chunks = []
    for d in LIVE_DIRS:
        base = root / d
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if p.is_file() and p.suffix.lower() in LIVE_TEXT_SUFFIXES:
                chunks.append(_read(p))
    return "\n".join(chunks)


def _archive_abs(root: Path) -> Path:
    return root / ARCHIVE


def _git_mv(root: Path, rel: str) -> None:
    src = root / rel
    dst = _archive_abs(root) / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "mv", str(src), str(dst)], cwd=str(root), check=True)


def _copy(root: Path, rel: str) -> None:
    src = root / rel
    dst = _archive_abs(root) / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="perform git mv + copies")
    ap.add_argument("--root", default=".", help="repo root")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()

    referenced: set[str] = set()
    for src in XARINGAN_SOURCES:
        referenced |= extract_refs(_read(root / src))

    blob = _live_blob(root)
    to_move, to_copy = classify(referenced, blob)
    # never move/copy something that doesn't exist on disk
    to_move = {r for r in to_move if (root / r).exists()}
    to_copy = {r for r in to_copy if (root / r).exists()}

    print(f"to_move (xaringan-only): {len(to_move)}", file=sys.stderr)
    print(f"to_copy (shared):        {len(to_copy)}", file=sys.stderr)
    for r in sorted(to_move):
        print(f"  MOVE {r}", file=sys.stderr)
    for r in sorted(to_copy):
        print(f"  COPY {r}", file=sys.stderr)

    if args.apply:
        for r in sorted(to_copy):
            _copy(root, r)
        for r in sorted(to_move):
            _git_mv(root, r)
        print("applied.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
