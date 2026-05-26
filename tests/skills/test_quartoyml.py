import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "skills" / "lib"))
import quartoyml  # noqa: E402

M = {
    "course": {"title": "MLT", "slug": "mlt", "language": "en"},
    "chapters": [
        {"slug": "01-a", "title": "A", "include": True},
        {"slug": "02-b", "title": "B", "include": False},
        {"slug": "03-c", "title": "C", "include": True},
    ],
}


def test_enabled_slugs_order_and_filter():
    assert quartoyml.enabled_slugs(M) == ["01-a", "03-c"]


def test_master_includes_only_enabled_in_order():
    out = quartoyml.build_slides_master(M)
    assert "{{< include chapters/01-a.qmd >}}" in out
    assert "{{< include chapters/03-c.qmd >}}" in out
    assert "02-b" not in out
    assert out.index("01-a.qmd") < out.index("03-c.qmd")


def test_master_has_revealjs_header_and_theme():
    out = quartoyml.build_slides_master(M)
    assert out.startswith("---")
    assert "format:" in out and "revealjs:" in out
    assert "theme:" in out and "theme.scss" in out
    assert 'title: "MLT"' in out
