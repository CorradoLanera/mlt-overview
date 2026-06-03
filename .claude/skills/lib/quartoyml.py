"""Generate the master revealjs deck (slides/course.qmd) from the manifest.

Only chapters with include: true are listed, in manifest order, via Quarto
include shortcodes. Per-chapter slides/course/<slug>.qmd are produced by the
mlt-quarto-build skill (Fase B2) from each chapter's storyboard.

The master deck also includes two framing minidecks NOT listed in the manifest:
- course/_opening.qmd  — presentation card + credits (before the chapters)
- course/_closing.qmd  — thanks + contacts + reading suggestions (after)

`embed-resources: true` makes the rendered HTML a portable single-file deck
(images, fonts, MathJax all base64-embedded).
"""
from __future__ import annotations


def enabled_slugs(m: dict) -> list[str]:
    return [c["slug"] for c in m.get("chapters", []) if c.get("include")]


def build_slides_master(m: dict) -> str:
    course = m.get("course", {})
    title = course.get("title", "Course")
    # `pagetitle:` populates the HTML <title> for the browser tab without
    # generating Quarto's auto title slide — the custom title slide lives in
    # course/_opening.qmd and we don't want it duplicated.
    header = (
        "---\n"
        f'pagetitle: "{title}"\n'
        "format:\n"
        "  revealjs:\n"
        "    theme: [default, ../styles/_brand.scss, theme.scss]\n"
        "    slide-number: true\n"
        "    incremental: false\n"
        "    embed-resources: true\n"
        "    html-math-method: mathjax\n"
        "---\n\n"
    )
    parts = ["{{< include course/_opening.qmd >}}"]
    parts += [f"{{{{< include course/{s}.qmd >}}}}" for s in enabled_slugs(m)]
    parts.append("{{< include course/_closing.qmd >}}")
    return header + "\n".join(parts) + "\n"
