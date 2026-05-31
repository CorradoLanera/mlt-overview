import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_workshop_zip as bwz  # noqa: E402


def _git(cwd, *args):
    subprocess.run(["git", *args], cwd=str(cwd), check=True, capture_output=True)


def _make_workshop(tmp_path):
    ws = tmp_path / "mlt-r-basic"
    (ws / "renv").mkdir(parents=True)
    (ws / "renv" / "activate.R").write_text("# activate", encoding="utf-8")
    (ws / "renv.lock").write_text("{}", encoding="utf-8")
    (ws / "CLAUDE.md").write_text("authoring", encoding="utf-8")
    (ws / "README.md").write_text("# ws", encoding="utf-8")
    (ws / "steps" / "01-import").mkdir(parents=True)
    (ws / "steps" / "01-import" / "01-import.qmd").write_text("# step", encoding="utf-8")
    (ws / "data-raw").mkdir()
    (ws / "data-raw" / "heart_failure.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    _git(ws, "init", "-q")
    _git(ws, "config", "user.email", "t@t")
    _git(ws, "config", "user.name", "t")
    (ws / ".gitignore").write_text("renv/library/\n*.rds\nsteps/**/*.html\n", encoding="utf-8")
    # gitignored junk that must NOT ship
    (ws / "renv" / "library").mkdir()
    (ws / "renv" / "library" / "pkg.txt").write_text("x", encoding="utf-8")
    (ws / "steps" / "01-import" / "01-import.html").write_text("<html>", encoding="utf-8")
    (ws / "steps" / "01-import" / "out.rds").write_text("bin", encoding="utf-8")
    _git(ws, "add", "-A")
    _git(ws, "commit", "-qm", "init")
    return ws


def test_included_source_is_tracked_minus_claude(tmp_path):
    ws = _make_workshop(tmp_path)
    inc = set(bwz.included_source(ws))
    assert "renv.lock" in inc
    assert "renv/activate.R" in inc
    assert "steps/01-import/01-import.qmd" in inc
    assert "data-raw/heart_failure.csv" in inc
    assert "README.md" in inc
    assert "CLAUDE.md" not in inc                       # authoring excluded
    assert not any("renv/library" in p for p in inc)    # gitignored, untracked
    assert "steps/01-import/01-import.html" not in inc  # gitignored
    assert "steps/01-import/out.rds" not in inc         # gitignored


def test_rendered_decks_globs_only_html(tmp_path):
    deck = tmp_path / "deck"
    deck.mkdir()
    (deck / "00-basic-deck.html").write_text("<html>", encoding="utf-8")
    (deck / "00-basic-deck.qmd").write_text("src", encoding="utf-8")
    got = [p.name for p in bwz.rendered_decks(deck)]
    assert got == ["00-basic-deck.html"]


def test_rendered_decks_missing_dir_is_empty(tmp_path):
    assert bwz.rendered_decks(tmp_path / "nope") == []


def test_build_zip_ships_source_and_injects_deck(tmp_path):
    ws = _make_workshop(tmp_path)
    deck = tmp_path / "slides_src"
    deck.mkdir()
    (deck / "00-basic-deck.html").write_text("<html>deck</html>", encoding="utf-8")
    out = tmp_path / "dist" / "mlt-r-basic.zip"
    bwz.build_zip(ws, deck, out)
    names = set(zipfile.ZipFile(out).namelist())
    assert "mlt-r-basic/renv.lock" in names
    assert "mlt-r-basic/steps/01-import/01-import.qmd" in names
    assert "mlt-r-basic/data-raw/heart_failure.csv" in names
    assert "mlt-r-basic/slides/00-basic-deck.html" in names      # injected deck
    assert "mlt-r-basic/CLAUDE.md" not in names                  # authoring excluded
    assert not any("renv/library" in n for n in names)           # gitignored junk excluded
    assert "mlt-r-basic/steps/01-import/01-import.html" not in names  # gitignored
