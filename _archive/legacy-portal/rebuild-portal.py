#!/usr/bin/env python3
"""PostToolUse hook: rebuild portal.html when a portal-relevant file changes.

Triggers `python scripts/build_portal.py` when the just-written path is:
  - course/**/*.md           (chapter content authoring)
  - course/_manifest.yml     (chapter inclusion/order changed)
  - slides/**/*.html         (master deck or per-chapter deck compiled)

Reads the hook payload JSON from stdin. Never blocks: exits 0 on any error.
"""
import json
import os
import subprocess
import sys
from pathlib import Path


def extract_path(payload: dict) -> str | None:
    ti = payload.get("tool_input") or {}
    return ti.get("file_path") or ti.get("path") or ti.get("notebook_path")


def is_portal_trigger(path: str) -> bool:
    norm = str(path).replace("\\", "/")
    sentinel = f"/{norm}"
    if "/course/" in sentinel and norm.endswith(".md"):
        return True
    if norm.endswith("/course/_manifest.yml") or norm.endswith("course/_manifest.yml"):
        return True
    if "/slides/" in sentinel and norm.endswith(".html"):
        return True
    return False


def repo_root_from_env() -> Path:
    # Claude Code sets CLAUDE_PROJECT_DIR in the hook environment
    env_root = os.environ.get("CLAUDE_PROJECT_DIR")
    if env_root:
        return Path(env_root)
    # Fallback: this file lives at <repo>/.claude/hooks/rebuild-portal.py
    return Path(__file__).resolve().parents[2]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = extract_path(payload)
    if not path or not is_portal_trigger(path):
        return 0
    try:
        repo = repo_root_from_env()
        script = repo / "scripts" / "build_portal.py"
        if not script.exists():
            return 0
        # On Windows the child's stderr defaults to cp1252; force UTF-8 both
        # for the child (PYTHONIOENCODING) and for our decoding (errors=replace
        # as a safety net), so a stray non-ASCII glyph never crashes the hook.
        child_env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
        res = subprocess.run(
            [sys.executable, str(script)],
            capture_output=True, text=True,
            encoding="utf-8", errors="replace",
            cwd=str(repo), env=child_env, timeout=15,
        )
        # Forward the build script's own stderr summary line
        if res.stderr:
            print(res.stderr.strip(), file=sys.stderr)
        if res.returncode != 0 and res.stdout:
            print(res.stdout.strip(), file=sys.stderr)
    except Exception as e:
        print(f"[rebuild-portal] skipped ({e})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
