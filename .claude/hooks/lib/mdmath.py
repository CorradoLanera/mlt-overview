"""Render a course Markdown file to a self-contained HTML with rendered math.

Uses pandoc (bundled with Quarto) for robust Markdown + LaTeX handling:
--standalone --embed-resources inlines everything; --mathml turns $...$ into
offline MathML (no CDN, no JS). Glue is pure stdlib.
"""
from __future__ import annotations
import os, re, shutil, subprocess
from pathlib import Path

LIB = Path(__file__).resolve().parent
THEME_CSS = LIB / "theme.css"


def find_pandoc() -> str | None:
    """Locate pandoc: PATH, then the Quarto bundle on Windows."""
    p = shutil.which("pandoc")
    if p:
        return p
    pf = Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
    candidates = [
        pf / "Quarto" / "bin" / "tools" / "pandoc.exe",
        pf / "Quarto" / "bin" / "tools" / "x86_64" / "pandoc.exe",
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    return None


def should_render(path: str) -> bool:
    """True only for Markdown files under course/ (POSIX-normalised)."""
    norm = str(path).replace("\\", "/")
    return "/course/" in f"/{norm}" and norm.endswith(".md")


def derive_title(md_path: Path) -> str:
    """First ATX H1, else the filename stem."""
    try:
        for line in Path(md_path).read_text(encoding="utf-8").splitlines():
            m = re.match(r"^#\s+(.+?)\s*$", line)
            if m:
                return m.group(1)
    except OSError:
        pass
    return Path(md_path).stem


def render_to_html(md_path: Path) -> str:
    """Return self-contained HTML for md_path. Raises if pandoc is unavailable."""
    pandoc = find_pandoc()
    if not pandoc:
        raise RuntimeError("pandoc not found (expected via Quarto install)")
    md_path = Path(md_path)
    cmd = [
        pandoc, str(md_path),
        "--from", "gfm+tex_math_dollars",
        "--to", "html5",
        "--standalone", "--embed-resources", "--mathml",
        "--metadata", f"title={derive_title(md_path)}",
        "--css", str(THEME_CSS),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                         cwd=str(md_path.parent))
    if res.returncode != 0:
        raise RuntimeError(f"pandoc failed: {res.stderr.strip()}")
    return res.stdout


def write_sibling_html(md_path: Path) -> Path:
    """Write <file>.html next to <file>.md; return its Path."""
    md_path = Path(md_path)
    out = md_path.with_suffix(".html")
    out.write_text(render_to_html(md_path), encoding="utf-8")
    return out
