#!/usr/bin/env python3
"""Flag register / em-dash / reload-residue smells in text sources.

Usage: python scripts/check_register.py PATH [PATH ...]
Prints `file:line: [category] match` for every hit; exit 1 if any, else 0.

Categories:
  em-dash : a U+2014 '—' in prose (fenced ``` blocks skipped; `inline code` stripped)
  register: self-certifying / hype words from CLAUDE.md "Registro di scrittura"
  reload  : stale 'reload/reopen/...' narrative claims (the Advanced workshop rebuilds
            Basic's model live, so these words are factually wrong as claims)

It flags; it does not edit. Filler intensifiers (really/just/very/actually) are
context-sensitive and left to manual judgement. False positives are expected — triage
by hand. Backticked code refs (e.g. `final_fit.rds`) are intentionally NOT flagged.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

EMDASH = "—"

REGISTER_WORDS = [
    "honestly", "truly", "clearly", "obviously", "genuinely",
    "sincerely", "of course", "the punchline", "killer",
    "knob", "knobs",  # jargon the teacher does not use; prefer "setting"
]
_REGISTER_RE = re.compile(r"(?i)\b(" + "|".join(re.escape(w) for w in REGISTER_WORDS) + r")\b")

RELOAD_TERMS = [
    "reload", "reopen", "re-open", "final_fit.rds",
    "never retrain", "not retrained", "baked in",
]
_RELOAD_RE = re.compile(r"(?i)(" + "|".join(re.escape(w) for w in RELOAD_TERMS) + r")")

_INLINE_CODE_RE = re.compile(r"`[^`]*`")
_FENCE_RE = re.compile(r"^\s*(```|~~~)")


def _strip_inline_code(line: str) -> str:
    """Blank out `inline code` spans so matches inside them are ignored."""
    return _INLINE_CODE_RE.sub(lambda m: " " * len(m.group(0)), line)


def scan_text(text: str) -> list[tuple[int, str, str]]:
    """Return [(lineno, category, match)] for register/em-dash/reload smells.

    Lines inside fenced code blocks (``` or ~~~) are skipped; `inline code` is stripped.
    """
    hits: list[tuple[int, str, str]] = []
    in_fence = False
    for i, raw in enumerate(text.splitlines(), start=1):
        if _FENCE_RE.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        line = _strip_inline_code(raw)
        if EMDASH in line:
            hits.append((i, "em-dash", EMDASH))
        for m in _REGISTER_RE.finditer(line):
            hits.append((i, "register", m.group(0)))
        for m in _RELOAD_RE.finditer(line):
            hits.append((i, "reload", m.group(0)))
    return hits


def scan_file(path: Path) -> list[tuple[int, str, str]]:
    return scan_text(path.read_text(encoding="utf-8", errors="replace"))


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv:
        print("usage: check_register.py PATH [PATH ...]", file=sys.stderr)
        return 2
    total = 0
    for arg in argv:
        p = Path(arg)
        files = [p] if p.is_file() else (sorted(p.rglob("*")) if p.is_dir() else [])
        for f in files:
            if not f.is_file():
                continue
            for lineno, cat, match in scan_file(f):
                print(f"{f}:{lineno}: [{cat}] {match}")
                total += 1
    print(f"[check-register] {total} hit(s)", file=sys.stderr)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
