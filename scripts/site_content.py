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

_STEPS_RE = re.compile(r"^\s*steps:\s*\[([^\]]*)\]", re.MULTILINE)
_META_TITLE_RE = re.compile(r'^\s*title:\s*"([^"]*)"', re.MULTILINE)
_META_MINUTES_RE = re.compile(r"^\s*minutes:\s*(\d+)\s*$", re.MULTILINE)
_META_SUMMARY_RE = re.compile(r'^\s*summary:\s*"([^"]*)"', re.MULTILINE)


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


def workshop_step_order(workshop_yml: str) -> list[str]:
    """Slugs in `steps: [a, b, c]` order from a workshop.yml. [] if absent."""
    m = _STEPS_RE.search(workshop_yml)
    if not m:
        return []
    return [s.strip() for s in m.group(1).split(",") if s.strip()]


def parse_step_meta(meta_text: str) -> dict:
    """title/minutes/summary from a step meta.yml (stdlib only, no yaml dep)."""
    t = _META_TITLE_RE.search(meta_text)
    mins = _META_MINUTES_RE.search(meta_text)
    s = _META_SUMMARY_RE.search(meta_text)
    return {
        "title": t.group(1) if t else None,
        "minutes": int(mins.group(1)) if mins else None,
        "summary": s.group(1) if s else None,
    }


def workshop_steps(workshop_yml: str, metas: dict) -> list[dict]:
    """Ordered [{slug,title,minutes,summary}] for a workshop timeline.

    `metas`: {slug: parse_step_meta(...)}. Steps missing a title OR minutes are
    skipped (incomplete metadata -> not shown). Order from workshop.yml.
    """
    out = []
    for slug in workshop_step_order(workshop_yml):
        m = metas.get(slug)
        if not m or not m.get("title") or m.get("minutes") is None:
            continue
        out.append({
            "slug": slug,
            "title": m["title"],
            "minutes": m["minutes"],
            "summary": m.get("summary") or "",
        })
    return out


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


def solutions_tabset_md(slug: str, steps: list[str]) -> str:
    """Quarto panel-tabset embedding one iframe per step's _solved HTML.

    Each iframe points at solutions/<slug>/<step>.html (copied into docs/ by
    build_site). "" when there are no steps.
    """
    if not steps:
        return ""
    out = ["::: {.panel-tabset}", ""]
    # slug/step are controlled (WORKSHOPS constant + filesystem stems) -> no HTML escaping needed.
    for step in steps:
        out.append(f"## {step}")
        out.append("")
        out.append(
            f'<iframe src="solutions/{slug}/{step}.html" '
            f'style="width:100%;height:75vh;border:1px solid #ddd;" '
            f'title="{slug} {step} solution"></iframe>'
        )
        out.append("")
    out.append(":::")
    return "\n".join(out)
