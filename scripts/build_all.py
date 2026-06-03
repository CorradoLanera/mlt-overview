#!/usr/bin/env python3
"""One idempotent entrypoint that rebuilds every consumable MLT artifact.

Chains (per dependency order):
  rebuild.R -> check-masking.R -> render decks -> from-disk ZIP (+teacher)
  -> build_release.py (optional) -> build_site.py.

Each stage is also runnable on its own; this only adds ordering. plan_commands()
is pure (unit-tested); main() executes the plan via subprocess.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def _workshops(root: Path) -> list[str]:
    wdir = root / "workshops"
    if not wdir.is_dir():
        return []
    return sorted(p.name for p in wdir.iterdir()
                  if p.is_dir() and (p / f"{p.name}.Rproj").exists())


def plan_commands(slugs, fragment_slugs, release, no_site, skip_masking):
    """Ordered [(label, argv)] for the given workshops + flags. Pure.

    slugs: all workshops to render+zip. fragment_slugs: the subset that is
    fragment-built (has _authoring/) and therefore gets rebuild + masking.
    """
    assert set(fragment_slugs) <= set(slugs), "fragment_slugs must be a subset of slugs"
    rscript = os.environ.get("MLT_RSCRIPT", "Rscript")
    cmds: list[tuple[str, list[str]]] = []
    if fragment_slugs:
        cmds.append(("rebuild", [rscript, "dev/mltbuild/rebuild.R", *fragment_slugs]))
        if not skip_masking:
            for slug in fragment_slugs:
                cmds.append(("check-masking",
                             [rscript, "dev/mltbuild/check-masking.R", f"workshops/{slug}"]))
    # Render every deck before zipping any, so a deck failure aborts before packaging.
    for slug in slugs:
        cmds.append(("render-deck",
                     ["quarto", "render", f"slides/workshops/{slug}"]))
    for slug in slugs:
        cmds.append(("zip",
                     [sys.executable, "scripts/build_workshop_zip.py",
                      f"workshops/{slug}"]))
    if release:
        cmds.append(("release", [sys.executable, "scripts/build_release.py"]))
    if not no_site:
        cmds.append(("site", [sys.executable, "scripts/build_site.py"]))
    return cmds


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Build every MLT artifact in order")
    ap.add_argument("--workshop", action="append", dest="workshops",
                    help="slug to build (repeatable; default: all with a .Rproj)")
    ap.add_argument("--root", default=".")
    ap.add_argument("--release", action="store_true",
                    help="also assemble dev/release-assets/ (embed decks + ZIPs)")
    ap.add_argument("--no-site", action="store_true", help="skip the docs/ build")
    ap.add_argument("--skip-masking", action="store_true",
                    help="skip the numeric hoist-safety gate")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    slugs = args.workshops or _workshops(root)
    if not slugs:
        print("no workshops found under workshops/", file=sys.stderr)
        return 1
    fragment_slugs = [s for s in slugs
                      if (root / "workshops" / s / "_authoring").is_dir()]
    for label, cmd in plan_commands(slugs, fragment_slugs, args.release,
                                    args.no_site, args.skip_masking):
        print(f"[build-all] {label}: {' '.join(cmd)}", file=sys.stderr)
        try:
            subprocess.run(cmd, cwd=str(root), check=True)
        except subprocess.CalledProcessError as e:
            print(f"[build-all] FAILED at '{label}': exit {e.returncode}", file=sys.stderr)
            return 1
    print("[build-all] done", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
