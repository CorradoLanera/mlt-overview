#!/usr/bin/env python3
"""Pure content-extraction helpers for the public course site build.

Stdlib only, no I/O: each function takes text (or a list of names) and returns
plain data / markdown ready to be written into site/_generated/*.md. Unit-tested.
"""
from __future__ import annotations

import re

_CHAPTER_RE = re.compile(
    r"slug:\s*([A-Za-z0-9_-]+)\s*,"
    r'\s*title:\s*"([^"]+)"\s*,'
    r"\s*include:\s*(true|false)\s*,"
    r"\s*minutes:\s*(\d+)",
)

_FORMATIVE_RE = re.compile(r"min-(\d+)-(.+)\.md$")


def chapters_from_manifest(text: str) -> list[dict]:
    """Parse the `chapters:` list of course/_manifest.yml into ordered dicts."""
    idx = text.find("\nchapters:")
    scan = text[idx:] if idx != -1 else text
    out = []
    for m in _CHAPTER_RE.finditer(scan):
        out.append({
            "slug": m.group(1),
            "title": m.group(2),
            "include": m.group(3) == "true",
            "minutes": int(m.group(4)),
        })
    return out


def extract_objectives(md_text: str) -> str:
    """Markdown of the `## Learning objectives` block only (English).

    Stops at the first `*Nota docente:*` line or the next `## ` heading, so
    Italian teacher notes and the summative exercise are excluded. "" if absent.
    """
    lines = md_text.splitlines()
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().lower().startswith("## learning objectives"):
            start = i + 1
            break
    if start is None:
        return ""
    body = []
    for ln in lines[start:]:
        s = ln.strip()
        if s.startswith("## ") or s.startswith("*Nota docente"):
            break
        body.append(ln)
    return "\n".join(body).strip()


def timeline_from_formatives(names: list[str]) -> list[dict]:
    """Map `min-NN-<slug>.md` filenames -> [{minute, label}] sorted by minute."""
    rows = []
    for n in names:
        base = n.replace("\\", "/").split("/")[-1]
        m = _FORMATIVE_RE.search(base)
        if not m:
            continue
        rows.append({"minute": int(m.group(1)), "label": m.group(2).replace("-", " ")})
    rows.sort(key=lambda r: r["minute"])
    return rows


def readme_section(md_text: str, heading: str) -> str:
    """Body under `## <heading>` up to the next `## ` (or EOF). "" if absent."""
    lines = md_text.splitlines()
    target = f"## {heading}".lower()
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().lower() == target:
            start = i + 1
            break
    if start is None:
        return ""
    body = []
    for ln in lines[start:]:
        if ln.strip().startswith("## "):
            break
        body.append(ln)
    return "\n".join(body).strip()
