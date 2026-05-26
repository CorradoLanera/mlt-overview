"""Generate the master revealjs deck (slides/slides.qmd) from the manifest.

Only chapters with include: true are listed, in manifest order, via Quarto
include shortcodes. Per-chapter slides/chapters/<slug>.qmd are produced by the
mlt-quarto-build skill (Fase B2) from each chapter's storyboard.
"""
from __future__ import annotations


def enabled_slugs(m: dict) -> list[str]:
    return [c["slug"] for c in m.get("chapters", []) if c.get("include")]


def build_slides_master(m: dict) -> str:
    course = m.get("course", {})
    title = course.get("title", "Course")
    header = (
        "---\n"
        f'title: "{title}"\n'
        "format:\n"
        "  revealjs:\n"
        "    theme: [default, theme.scss]\n"
        "    slide-number: true\n"
        "    incremental: false\n"
        "    html-math-method: mathjax\n"
        "---\n\n"
    )
    body = "\n".join(f"{{{{< include chapters/{s}.qmd >}}}}" for s in enabled_slugs(m))
    return header + body + "\n"
