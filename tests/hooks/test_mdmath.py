import shutil, sys
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "hooks" / "lib"))
import mdmath  # noqa: E402

pandoc_missing = shutil.which("pandoc") is None and not mdmath.find_pandoc()
skip_no_pandoc = pytest.mark.skipif(pandoc_missing, reason="pandoc not found")


def test_should_render_only_course_md():
    assert mdmath.should_render("course/01-introduction/narrative.md") is True
    assert mdmath.should_render("course/_global/spine.md") is True
    assert mdmath.should_render("README.md") is False
    assert mdmath.should_render("course/01-introduction/slides.qmd") is False
    assert mdmath.should_render(".claude/CLAUDE.md") is False


def test_derive_title_from_first_heading(tmp_path):
    p = tmp_path / "x.md"
    p.write_text("# Hello World\n\nbody\n", encoding="utf-8")
    assert mdmath.derive_title(p) == "Hello World"


def test_derive_title_falls_back_to_filename(tmp_path):
    p = tmp_path / "item_01_knn_mcq.md"
    p.write_text("no heading here\n", encoding="utf-8")
    assert mdmath.derive_title(p) == "item_01_knn_mcq"


@skip_no_pandoc
def test_render_inline_math_to_mathml(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\nThe loss is $E = mc^2$ here.\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    assert "<math" in html  # pandoc --mathml emits MathML elements


@skip_no_pandoc
def test_render_is_self_contained(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\n![x](nonexistent-but-ok.png)\n\ntext\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    # no external resource fetches (CDN scripts/styles)
    assert 'src="http' not in html
    assert 'href="http' not in html.split("<body")[0]  # head has no remote links


@skip_no_pandoc
def test_no_duplicate_title_block(tmp_path):
    # The body H1 must be the only visible title; pandoc's metadata-title block
    # (id="title-block-header") would duplicate it. We set pagetitle instead.
    p = tmp_path / "m.md"
    p.write_text("# My Heading\n\nbody\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    assert "title-block-header" not in html
    assert "My Heading" in html  # still present as the body H1
    assert "<title>My Heading</title>" in html  # tab title set


@skip_no_pandoc
def test_render_table_and_code(tmp_path):
    p = tmp_path / "m.md"
    p.write_text("# T\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\n```r\nx <- 1\n```\n", encoding="utf-8")
    html = mdmath.render_to_html(p)
    assert "<table" in html
    assert "<code" in html


@skip_no_pandoc
def test_render_accepts_relative_path(tmp_path, monkeypatch):
    # Regression: hook passes a path relative to the project cwd, while
    # render_to_html changes cwd to the file's parent for resource embedding.
    (tmp_path / "sub").mkdir()
    (tmp_path / "sub" / "x.md").write_text("# T\n\n$a_1$\n", encoding="utf-8")
    monkeypatch.chdir(tmp_path)
    html = mdmath.render_to_html(Path("sub/x.md"))
    assert "<math" in html


@skip_no_pandoc
def test_write_sibling_html(tmp_path):
    p = tmp_path / "narrative.md"
    p.write_text("# Title\n\n$a_1$\n", encoding="utf-8")
    out = mdmath.write_sibling_html(p)
    assert out == p.with_suffix(".html")
    assert out.exists()
    assert "<math" in out.read_text(encoding="utf-8")
