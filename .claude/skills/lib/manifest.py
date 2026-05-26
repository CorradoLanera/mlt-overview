"""Read-only helpers over course/_manifest.yml.

The manifest is the hand-edited source of truth for course STRUCTURE
(slug/title/include/minutes). Generated content lives in per-chapter .md files;
status is derived from the filesystem here. Nothing in this module writes the
manifest (avoids pyyaml round-trip dropping comments/flow style).
"""
from __future__ import annotations
from pathlib import Path
import yaml


def load(path="course/_manifest.yml") -> dict:
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


def enabled_chapters(m: dict) -> list[dict]:
    return [c for c in m.get("chapters", []) if c.get("include")]


def next_enabled(m: dict, slug: str) -> dict | None:
    """First enabled chapter positioned after `slug` in the full order."""
    chapters = m.get("chapters", [])
    idx = next((i for i, c in enumerate(chapters) if c.get("slug") == slug), None)
    if idx is None:
        return None
    for c in chapters[idx + 1:]:
        if c.get("include"):
            return c
    return None


def chapter_dir(slug: str, root="course") -> Path:
    return Path(root) / slug


def artifact_status(m: dict, root="course") -> dict:
    """Per chapter: which artifacts exist (bool) and item count (int)."""
    out = {}
    for c in m.get("chapters", []):
        d = Path(root) / c["slug"]
        items_dir = d / "items"
        out[c["slug"]] = {
            "objectives": (d / "objectives.md").exists(),
            "narrative": (d / "narrative.md").exists(),
            "subunits": (d / "subunits.md").exists(),
            "storyboard": (d / "storyboard.md").exists(),
            "items": len(list(items_dir.glob("item_*.md"))) if items_dir.exists() else 0,
        }
    return out
