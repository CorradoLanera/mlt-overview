#!/usr/bin/env python3
"""Build portal.html — a single-file index over all course artifacts.

Reads course/_manifest.yml as the single source of truth for chapter order and
inclusion, then scans each chapter folder for the canonical sibling .html files
produced by the md-to-html-math hook. Outputs a self-contained portal.html at
the repo root: a left sidebar (chapters and their artifacts) + a right iframe
that loads the selected artifact. No CDN, no build step beyond Python.

Run from the repo root:
    python scripts/build_portal.py
"""
from __future__ import annotations
import argparse
import html
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml


# Canonical per-chapter artifacts that live INSIDE the chapter folder.
# Each tuple is (filename, label, short-code). Missing files become "gaps".
CHAPTER_ARTIFACTS: list[tuple[str, str, str]] = [
    ("objectives.html",       "Objectives",        "obj"),
    ("narrative.html",        "Narrative",         "nar"),
    ("storyboard.html",       "Storyboard",        "sto"),
    ("subunits.html",         "Sub-units",         "sub"),
    ("items_valutativi.html", "Assessment items",  "items"),
]

# Per-chapter artifacts that live OUTSIDE the chapter folder (e.g. compiled
# slide decks under slides/chapters/). Path template uses {slug} and is resolved
# against the repo root. Same display semantics as CHAPTER_ARTIFACTS.
EXTERNAL_ARTIFACTS: list[tuple[str, str, str]] = [
    ("slides/chapters/{slug}.html", "Slides", "slides"),
]

ALL_ARTIFACT_CODES = (
    [code for _, _, code in CHAPTER_ARTIFACTS]
    + [code for _, _, code in EXTERNAL_ARTIFACTS]
)
ARTIFACT_DISPLAY_ORDER: list[tuple[str, str]] = (
    [(code, label) for _, label, code in CHAPTER_ARTIFACTS]
    + [(code, label) for _, label, code in EXTERNAL_ARTIFACTS]
)


@dataclass
class Chapter:
    slug: str
    title: str
    minutes: int
    include: bool
    folder: Path
    artifacts: dict[str, Path] = field(default_factory=dict)   # code -> file
    extras: list[Path] = field(default_factory=list)            # items/, rubriche/

    @property
    def coverage(self) -> tuple[int, int]:
        return (len(self.artifacts), len(ALL_ARTIFACT_CODES))


def load_manifest(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def scan_chapter(repo_root: Path, course_dir: Path, ch: dict) -> Chapter:
    folder = course_dir / ch["slug"]
    chapter = Chapter(
        slug=ch["slug"],
        title=ch["title"],
        minutes=int(ch.get("minutes", 0)),
        include=bool(ch.get("include", True)),
        folder=folder,
    )
    # In-folder artifacts
    if folder.exists():
        for filename, _label, code in CHAPTER_ARTIFACTS:
            p = folder / filename
            if p.exists():
                chapter.artifacts[code] = p
        # Single items and rubrics, sorted lexicographically (NN-prefixed)
        for sub in ("items", "rubriche"):
            sub_dir = folder / sub
            if sub_dir.exists():
                chapter.extras.extend(sorted(sub_dir.glob("*.html")))
    # External artifacts (e.g. slides/chapters/<slug>.html)
    for path_tpl, _label, code in EXTERNAL_ARTIFACTS:
        p = repo_root / path_tpl.format(slug=chapter.slug)
        if p.exists():
            chapter.artifacts[code] = p
    return chapter


def rel_url(p: Path, root: Path) -> str:
    # Forward slashes for the browser, regardless of OS
    return p.resolve().relative_to(root.resolve()).as_posix()


def coverage_badge(have: int, total: int, *, off: bool = False) -> str:
    if off:
        return '<span class="badge badge-off" title="include: false">off</span>'
    if have == 0:
        cls = "badge-empty"
    elif have < total:
        cls = "badge-partial"
    else:
        cls = "badge-full"
    return f'<span class="badge {cls}">{have}/{total}</span>'


def chapter_number(slug: str) -> str:
    """Extract the leading NN from a slug like '01-introduction' -> '01'.

    Falls back to the full slug if it doesn't start with digits.
    """
    head = slug.split("-", 1)[0]
    return head if head.isdigit() else slug


def render_sidebar_chapter(ch: Chapter, root: Path) -> str:
    have, total = ch.coverage
    badge = coverage_badge(have, total, off=not ch.include)
    classes = "chapter" + (" disabled" if not ch.include else "")
    # Auto-open only if active AND has at least one artifact. Disabled chapters
    # stay collapsed by default to keep the sidebar compact.
    open_attr = " open" if ch.include and have > 0 else ""
    parts: list[str] = []
    parts.append(f'<details class="{classes}"{open_attr}>')
    parts.append(
        '<summary>'
        f'<span class="ch-num" title="{html.escape(ch.slug)}">'
        f'{html.escape(chapter_number(ch.slug))}</span>'
        f'<span class="ch-title">{html.escape(ch.title)}</span>'
        f'{badge}'
        '</summary>'
    )
    parts.append('<ul class="artifact-list">')
    for code, label in ARTIFACT_DISPLAY_ORDER:
        if code in ch.artifacts:
            url = rel_url(ch.artifacts[code], root)
            parts.append(
                f'<li><a href="{html.escape(url)}" target="reader" '
                f'data-href="{html.escape(url)}">{html.escape(label)}</a></li>'
            )
        else:
            parts.append(
                f'<li class="missing"><span title="not yet generated">'
                f'{html.escape(label)}</span></li>'
            )
    parts.append('</ul>')
    if ch.extras:
        parts.append('<details class="extras"><summary>Single items &amp; rubrics</summary>')
        parts.append('<ul class="artifact-list extras-list">')
        for p in ch.extras:
            url = rel_url(p, root)
            parts.append(
                f'<li><a href="{html.escape(url)}" target="reader" '
                f'data-href="{html.escape(url)}">{html.escape(p.stem)}</a></li>'
            )
        parts.append('</ul></details>')
    parts.append('</details>')
    return "\n".join(parts)


def render_global_section(course_dir: Path, root: Path) -> str:
    candidates: list[tuple[Path, str]] = [
        (course_dir / "_global" / "spine.html",         "Narrative spine (global)"),
        (root / "slides" / "slides.html",               "Slide deck (full)"),
    ]
    items: list[str] = []
    for path, label in candidates:
        if path.exists():
            url = rel_url(path, root)
            items.append(
                f'<li><a href="{html.escape(url)}" target="reader" '
                f'data-href="{html.escape(url)}">{html.escape(label)}</a></li>'
            )
    if not items:
        return ""
    return (
        '<details class="chapter global" open>'
        '<summary><span class="ch-title">Global</span></summary>'
        '<ul class="artifact-list">'
        + "\n".join(items)
        + '</ul></details>'
    )


# Inline CSS + JS. Self-contained, no external deps. Light/dark via prefers-color-scheme.
STYLE = r"""
* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  display: grid;
  grid-template-columns: 320px 1fr;
  grid-template-rows: auto 1fr;
  grid-template-areas:
    "head head"
    "side reader";
  color: #1a1a1a;
  background: #f7f7f8;
}
header.portal-head {
  grid-area: head;
  padding: 10px 16px;
  background: #1f2937;
  color: #f9fafb;
  display: flex;
  align-items: baseline;
  gap: 12px;
  border-bottom: 1px solid #111827;
}
header.portal-head h1 {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.2px;
}
header.portal-head .subtitle {
  font-size: 12px;
  color: #9ca3af;
}
header.portal-head .meta {
  margin-left: auto;
  font-size: 11px;
  color: #9ca3af;
}
aside.sidebar {
  grid-area: side;
  background: #ffffff;
  border-right: 1px solid #e5e7eb;
  overflow-y: auto;
  padding: 8px 6px;
  font-size: 13px;
}
main.reader {
  grid-area: reader;
  background: #ffffff;
  position: relative;
  overflow: hidden;
}
iframe#reader {
  width: 100%;
  height: 100%;
  border: 0;
  background: #ffffff;
}
.welcome {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  font-size: 14px;
  padding: 24px;
  text-align: center;
}
details.chapter {
  margin: 2px 0;
  padding: 0;
  border-radius: 6px;
}
details.chapter > summary {
  list-style: none;
  cursor: pointer;
  padding: 6px 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  border-radius: 6px;
  user-select: none;
}
details.chapter > summary::-webkit-details-marker { display: none; }
details.chapter > summary::before {
  content: "▸";
  font-size: 10px;
  color: #6b7280;
  width: 10px;
  display: inline-block;
  transition: transform 120ms ease;
}
details.chapter[open] > summary::before { transform: rotate(90deg); }
details.chapter > summary:hover { background: #f3f4f6; }
.ch-num {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 11px;
  color: #6b7280;
  min-width: 18px;
  text-align: right;
  cursor: help;
}
.ch-title { flex: 1; font-weight: 500; line-height: 1.25; }
.badge {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 999px;
  border: 1px solid;
}
.badge-empty   { color: #9ca3af; border-color: #e5e7eb; background: #f9fafb; }
.badge-partial { color: #92400e; border-color: #fde68a; background: #fffbeb; }
.badge-full    { color: #065f46; border-color: #a7f3d0; background: #ecfdf5; }
.badge-off     { color: #6b7280; border-color: #d1d5db; background: #f3f4f6;
                 text-transform: uppercase; letter-spacing: 0.4px; }
details.chapter.disabled > summary .ch-title { color: #9ca3af; font-weight: 400; }
details.chapter.disabled > summary .ch-num   { color: #cbd5e1; }
details.chapter.disabled ul.artifact-list a,
details.chapter.disabled li.missing { opacity: 0.55; }
ul.artifact-list {
  list-style: none;
  margin: 2px 0 6px 22px;
  padding: 0;
  font-size: 12.5px;
}
ul.artifact-list li { padding: 2px 0; }
ul.artifact-list a {
  display: block;
  padding: 3px 6px;
  border-radius: 4px;
  color: #1f2937;
  text-decoration: none;
}
ul.artifact-list a:hover { background: #eef2ff; }
ul.artifact-list a.active { background: #4f46e5; color: #ffffff; }
li.missing { color: #9ca3af; padding-left: 6px; font-style: italic; font-size: 11.5px; }
details.extras {
  margin: 0 0 6px 22px;
  font-size: 12px;
}
details.extras > summary {
  cursor: pointer;
  padding: 2px 6px;
  color: #6b7280;
  list-style: none;
}
details.extras > summary::-webkit-details-marker { display: none; }
details.extras > summary::before {
  content: "▸";
  font-size: 9px;
  margin-right: 6px;
  display: inline-block;
  transition: transform 120ms ease;
}
details.extras[open] > summary::before { transform: rotate(90deg); }
.extras-list { margin-left: 14px; font-size: 11.5px; }
.extras-list a { color: #4b5563; }
@media (prefers-color-scheme: dark) {
  body { color: #e5e7eb; background: #0f172a; }
  aside.sidebar { background: #111827; border-right-color: #1f2937; }
  main.reader, iframe#reader { background: #1e293b; }
  details.chapter > summary:hover { background: #1f2937; }
  ul.artifact-list a { color: #e5e7eb; }
  ul.artifact-list a:hover { background: #1f2937; }
  .ch-num, .badge-empty { color: #9ca3af; }
  .badge-empty   { border-color: #374151; background: #1f2937; }
  .badge-partial { color: #fbbf24; border-color: #78350f; background: #1c1917; }
  .badge-full    { color: #6ee7b7; border-color: #064e3b; background: #022c22; }
  .badge-off     { color: #9ca3af; border-color: #374151; background: #1f2937; }
  details.chapter.disabled > summary .ch-title { color: #6b7280; }
  details.chapter.disabled > summary .ch-num   { color: #4b5563; }
  details.extras > summary { color: #9ca3af; }
  .extras-list a { color: #9ca3af; }
  .welcome { color: #9ca3af; }
}
"""

SCRIPT = r"""
(function () {
  var iframe = document.getElementById('reader');
  var welcome = document.getElementById('welcome');
  var links = document.querySelectorAll('a[data-href]');

  function setActive(href) {
    for (var i = 0; i < links.length; i++) {
      if (links[i].getAttribute('data-href') === href) {
        links[i].classList.add('active');
      } else {
        links[i].classList.remove('active');
      }
    }
  }

  function loadHref(href, push) {
    if (welcome) welcome.style.display = 'none';
    iframe.src = href;
    setActive(href);
    if (push && window.history && window.history.pushState) {
      window.history.pushState({ href: href }, '', '#' + encodeURIComponent(href));
    }
  }

  for (var i = 0; i < links.length; i++) {
    links[i].addEventListener('click', function (e) {
      e.preventDefault();
      loadHref(this.getAttribute('data-href'), true);
    });
  }

  window.addEventListener('popstate', function (e) {
    if (e.state && e.state.href) loadHref(e.state.href, false);
  });

  // Deep link via #fragment
  if (window.location.hash && window.location.hash.length > 1) {
    var initial = decodeURIComponent(window.location.hash.slice(1));
    loadHref(initial, false);
  }
})();
"""


def build_portal(repo_root: Path, out_path: Path) -> None:
    manifest_path = repo_root / "course" / "_manifest.yml"
    manifest = load_manifest(manifest_path)
    course = manifest.get("course", {})
    course_dir = repo_root / "course"

    chapters = [scan_chapter(repo_root, course_dir, ch) for ch in manifest.get("chapters", [])]
    active = [c for c in chapters if c.include]

    total_artifacts = sum(c.coverage[0] for c in active)
    total_expected = sum(c.coverage[1] for c in active)

    sidebar_blocks: list[str] = []
    global_block = render_global_section(course_dir, repo_root)
    if global_block:
        sidebar_blocks.append(global_block)
    for ch in chapters:
        sidebar_blocks.append(render_sidebar_chapter(ch, repo_root))

    title = course.get("title", "MLT course")
    audience = course.get("audience", "")
    minutes = course.get("total_minutes_gross", 0)

    html_doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{html.escape(title)} — Portal</title>
  <style>{STYLE}</style>
</head>
<body>
  <header class="portal-head">
    <h1>{html.escape(title)}</h1>
    <span class="subtitle">{html.escape(audience)}</span>
    <span class="meta">{minutes} min · coverage {total_artifacts}/{total_expected}</span>
  </header>
  <aside class="sidebar">
    {"".join(sidebar_blocks)}
  </aside>
  <main class="reader">
    <div class="welcome" id="welcome">
      <div>
        <p style="margin:0 0 8px 0">Select an artifact from the sidebar to read it here.</p>
        <small>Tip: bookmarkable links use <code>#path/to/file.html</code></small>
      </div>
    </div>
    <iframe id="reader" name="reader" title="Artifact reader"></iframe>
  </main>
  <script>{SCRIPT}</script>
</body>
</html>
"""
    out_path.write_text(html_doc, encoding="utf-8")
    print(f"[build_portal] wrote {out_path} -- coverage {total_artifacts}/{total_expected} "
          f"across {len(active)} active chapters ({len(chapters)} total)", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(description="Build MLT course portal.html")
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent,
                    help="Repo root (default: parent of scripts/)")
    ap.add_argument("--out", type=Path, default=None,
                    help="Output path (default: <root>/portal.html)")
    args = ap.parse_args()
    out = args.out if args.out else args.root / "portal.html"
    build_portal(args.root, out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
