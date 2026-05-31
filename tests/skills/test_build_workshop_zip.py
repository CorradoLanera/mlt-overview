import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_workshop_zip as bwz  # noqa: E402


def test_is_excluded_drops_library_cache_and_authoring():
    assert bwz.is_excluded("renv/library/foo/DESCRIPTION") is True
    assert bwz.is_excluded("renv/staging/1/pkg") is True
    assert bwz.is_excluded("slides/.quarto/idx.json") is True
    assert bwz.is_excluded("slides/00-basic-deck_files/x.js") is True
    assert bwz.is_excluded("CLAUDE.md") is True
    assert bwz.is_excluded(".Rhistory") is True
    assert bwz.is_excluded("dist/mlt-r-basic.zip") is True


def test_is_excluded_keeps_source():
    assert bwz.is_excluded("renv.lock") is False
    assert bwz.is_excluded("renv/activate.R") is False
    assert bwz.is_excluded("steps/01-import/01-import.qmd") is False
    assert bwz.is_excluded("slides/00-basic-deck.html") is False
    assert bwz.is_excluded("slides/theme.scss") is False
    assert bwz.is_excluded("README.md") is False


def test_vendor_brand_copies_partial_and_rewrites_theme(tmp_path):
    slides = tmp_path / "slides"
    slides.mkdir()
    (slides / "_quarto.yml").write_text(
        "format:\n  revealjs:\n    theme: [default, ../../../styles/_brand.scss, theme.scss]\n",
        encoding="utf-8",
    )
    brand = tmp_path / "_brand_src.scss"
    brand.write_text("/*-- scss:defaults --*/\n$x: 1;\n", encoding="utf-8")

    bwz.vendor_brand(tmp_path, brand)

    assert (slides / "_brand.scss").read_text(encoding="utf-8").startswith("/*-- scss:defaults")
    rewritten = (slides / "_quarto.yml").read_text(encoding="utf-8")
    assert "../../../styles/_brand.scss" not in rewritten
    assert "theme: [default, _brand.scss, theme.scss]" in rewritten


def test_build_zip_prunes_and_vendors(tmp_path):
    ws = tmp_path / "mlt-r-basic"
    (ws / "renv" / "library" / "pkg").mkdir(parents=True)
    (ws / "renv" / "library" / "pkg" / "DESCRIPTION").write_text("x", encoding="utf-8")
    (ws / "renv").mkdir(exist_ok=True)
    (ws / "renv" / "activate.R").write_text("# activate", encoding="utf-8")
    (ws / "renv.lock").write_text("{}", encoding="utf-8")
    (ws / "CLAUDE.md").write_text("authoring", encoding="utf-8")
    (ws / "slides").mkdir()
    (ws / "slides" / "_quarto.yml").write_text(
        "format:\n  revealjs:\n    theme: [default, ../../../styles/_brand.scss, theme.scss]\n",
        encoding="utf-8",
    )
    (ws / "slides" / "00-basic-deck.html").write_text("<html></html>", encoding="utf-8")
    brand = tmp_path / "_brand_src.scss"
    brand.write_text("/*-- scss:defaults --*/\n$x: 1;\n", encoding="utf-8")
    out = tmp_path / "dist" / "mlt-r-basic.zip"
    out.parent.mkdir()

    bwz.build_zip(ws, brand, out)

    names = set(zipfile.ZipFile(out).namelist())
    assert "mlt-r-basic/renv.lock" in names
    assert "mlt-r-basic/renv/activate.R" in names
    assert "mlt-r-basic/slides/00-basic-deck.html" in names
    assert "mlt-r-basic/slides/_brand.scss" in names           # vendored
    assert "mlt-r-basic/CLAUDE.md" not in names                # authoring excluded
    assert not any("renv/library" in n for n in names)         # heavy lib excluded
