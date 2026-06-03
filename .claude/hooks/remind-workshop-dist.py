#!/usr/bin/env python3
"""PostToolUse hook: remind to regenerate workshop dist when source changes.

Fires (non-blocking) when the just-written path is workshop R-project source
(workshops/**), workshop slide source (slides/workshops/**), or the shared brand
partial (styles/_brand.scss) — whose change re-themes every workshop deck.
Ignores caches, rendered *.html output, *_files/ dirs, and the built .zip.
Reads the hook payload JSON from stdin; never blocks: exits 0 on any error.
"""
import json
import sys


def extract_path(payload: dict):
    ti = payload.get("tool_input") or {}
    return ti.get("file_path") or ti.get("path") or ti.get("notebook_path")


def should_remind(path: str) -> bool:
    norm = str(path).replace("\\", "/")
    parts = norm.split("/")
    # the shared brand partial re-themes every workshop deck
    if norm == "styles/_brand.scss" or norm.endswith("/styles/_brand.scss"):
        return True
    # workshop R-project source (workshops/**) OR workshop slide source (slides/workshops/**)
    if "workshops/" not in f"/{norm}":
        return False
    # ignore caches, rendered output, sidecar dirs, and the built zip
    if any(p in {".quarto", ".Rproj.user", ".git"} for p in parts):
        return False
    if any(p.endswith("_files") for p in parts):
        return False
    if norm.endswith(".html") or norm.endswith(".zip"):
        return False
    return True


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = extract_path(payload)
    if path and should_remind(path):
        print(
            "[remind] workshop source changed -> rebuild & ship via /mlt-build "
            "(it fragment-builds the tree before zipping) before publishing a release.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
