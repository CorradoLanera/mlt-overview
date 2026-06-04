#!/usr/bin/env python3
"""Build a source-only distributable ZIP for an MLT workshop.

The workshop folder (workshops/<slug>/) holds only the R-project SOURCE. Slide
sources live separately in slides/workshops/<slug>/ and are NOT shipped; instead
the already-rendered, embed-resources deck HTML is injected into the ZIP under
<slug>/slides/. R-project inclusion is driven by `git ls-files` (only tracked
source ships; gitignored renv/library, .quarto, step renders, outputs are
excluded automatically), minus CLAUDE.md (authoring-only). The ZIP has a single
top-level <slug>/ folder so usethis::use_course() unpacks cleanly.

Fragment-built workshops (those with an `_authoring/` source tree) are packaged
from the generated on-disk `steps/`/`full/` tree (Model C), not git ls-files.
For fragment workshops, `main()` also emits a `<slug>-teacher.zip` (student tree
plus `_solved/`) alongside the student ZIP.

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
    workshop_dir = Path(workshop_dir)
    try:
        res = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=str(workshop_dir), capture_output=True, text=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        raise SystemExit(
            f"ERROR: cannot list tracked files in {workshop_dir} "
            f"(is it inside a git repository, with git installed?): {e}"
        )
    return [p for p in res.stdout.split("\0") if p]


def _repo_root(start: Path) -> Path:
    """Absolute path to the git repo root containing `start`."""
    try:
        res = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=str(start), capture_output=True, text=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        raise SystemExit(f"ERROR: {start} is not inside a git repository: {e}")
    return Path(res.stdout.strip())


def included_source(workshop_dir: Path) -> list[str]:
    """Tracked source to ship: git-tracked minus authoring-only files."""
    return [p for p in tracked_files(Path(workshop_dir))
            if Path(p).name not in _EXCLUDE_NAMES]


# --- fragment-aware payload (Model C) --------------------------------------

# Student-shippable top-level entries of a fragment-built workshop.
_FRAGMENT_TOP_FILES = ("README.md",)
_FRAGMENT_TOP_DIRS = ("steps", "full")
# Path segments / names / suffixes that must never ship from the on-disk tree.
_DENY_SEGMENTS = (
    "renv/library", "renv/staging", "renv/local", "renv/cellar",
    "renv/python", "renv/sandbox", ".quarto", ".Rproj.user",
)
_DENY_NAMES = {".Rhistory", ".RData", ".Ruserdata"}
_DENY_SUFFIXES = (".html", ".rds")   # stray renders / model blobs inside steps/full


def is_fragment_workshop(workshop_dir) -> bool:
    """A workshop is fragment-built iff it owns an _authoring/ source tree."""
    return (Path(workshop_dir) / "_authoring").is_dir()


def _walk_shippable(base: Path, *, skip_renders=True):
    """Yield (file_path, rel_posix) under base, skipping runtime junk / stray renders.

    _DENY_SEGMENTS (renv/library etc.) and _DENY_NAMES always apply. Pass
    skip_renders=False to ALSO keep .html/.rds (used for _solved/, whose HTML
    files are the teacher deliverable).
    """
    for p in sorted(base.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(base).as_posix()
        if any(seg in rel for seg in _DENY_SEGMENTS):
            continue
        if p.name in _DENY_NAMES:
            continue
        if skip_renders and any(rel.endswith(suf) for suf in _DENY_SUFFIXES):
            continue
        yield p, rel


def student_payload(workshop_dir):
    """[(abs_src, rel_arc)] for the student ZIP.

    Fragment-built: the GENERATED on-disk tree (steps/ full/ + README),
    NOT git ls-files (the tree is gitignored). Non-migrated: git-tracked source.
    """
    workshop_dir = Path(workshop_dir)
    if not is_fragment_workshop(workshop_dir):
        return [(workshop_dir / rel, rel) for rel in included_source(workshop_dir)]
    out = []
    for name in sorted(_FRAGMENT_TOP_FILES):
        p = workshop_dir / name
        if p.is_file():
            out.append((p, name))
    for d in _FRAGMENT_TOP_DIRS:
        base = workshop_dir / d
        if base.is_dir():
            for src, rel in _walk_shippable(base):
                out.append((src, f"{d}/{rel}"))
    return out


def teacher_payload(workshop_dir):
    """Student payload + the _solved/ teacher tree (fragment-built only)."""
    workshop_dir = Path(workshop_dir)
    out = list(student_payload(workshop_dir))
    sol = workshop_dir / "_solved"
    if sol.is_dir():
        # _solved/ contains rendered HTML solutions — allow .html, only block runtime junk
        for src, rel in _walk_shippable(sol, skip_renders=False):
            out.append((src, f"_solved/{rel}"))
    return out


def rendered_decks(deck_dir: Path) -> list[Path]:
    """The rendered, self-contained deck HTML files to inject under slides/."""
    deck_dir = Path(deck_dir)
    if not deck_dir.is_dir():
        return []
    return sorted(p for p in deck_dir.glob("*.html") if p.is_file())


def build_zip(workshop_dir, deck_dir, out_zip, slug=None, teacher=False) -> Path:
    workshop_dir = Path(workshop_dir)
    deck_dir = Path(deck_dir)
    slug = slug or workshop_dir.name
    out_zip = Path(out_zip)
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    payload = teacher_payload(workshop_dir) if teacher else student_payload(workshop_dir)
    with tempfile.TemporaryDirectory() as td:
        staging = Path(td) / slug
        # 1. payload (source tree, Model C for fragment-built workshops)
        for src, rel in payload:
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
                         "(default: <repo-root>/slides/workshops/<slug>)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args(argv)
    ws = Path(args.workshop_dir).resolve()
    root = _repo_root(ws)
    deck_dir = (Path(args.deck_dir).resolve() if args.deck_dir
                else root / "slides" / "workshops" / ws.name)
    out = (Path(args.out).resolve() if args.out
           else root / "dist" / f"{ws.name}.zip")
    decks = rendered_decks(deck_dir)
    if not decks:
        print(f"ERROR: no rendered deck in {deck_dir}. "
              f"Render it first (e.g. `quarto render {deck_dir}`).", file=sys.stderr)
        return 2
    build_zip(ws, deck_dir, out)
    print(f"built {out} ({out.stat().st_size/1_000_000:.1f} MB; {len(decks)} deck(s); student)", file=sys.stderr)
    if is_fragment_workshop(ws):
        tout = out.with_stem(out.stem + "-teacher")
        build_zip(ws, deck_dir, tout, teacher=True)
        print(f"built {tout} ({tout.stat().st_size/1_000_000:.1f} MB; teacher)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
