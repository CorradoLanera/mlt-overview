#!/usr/bin/env python3
"""PostToolUse hook: render course/**/*.md to a sibling self-contained .html.

Reads the hook payload JSON from stdin, extracts the written file path, and (if it
is a course Markdown file) regenerates its HTML. Never blocks: exits 0 on any error.
"""
import json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
import mdmath  # noqa: E402


def extract_path(payload: dict) -> str | None:
    ti = payload.get("tool_input") or {}
    return ti.get("file_path") or ti.get("path") or ti.get("notebook_path")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = extract_path(payload)
    if not path or not mdmath.should_render(path):
        return 0
    try:
        if Path(path).exists():
            out = mdmath.write_sibling_html(Path(path))
            print(f"[md-to-html-math] rendered {out}", file=sys.stderr)
    except Exception as e:  # non-blocking by design
        print(f"[md-to-html-math] skipped ({e})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
