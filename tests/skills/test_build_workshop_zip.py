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
    (ws / "steps" / "01-import" / "output").mkdir()
    (ws / "steps" / "01-import" / "output" / ".keep").write_text("", encoding="utf-8")
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


def test_build_zip_without_deck_ships_source_only(tmp_path):
    ws = _make_workshop(tmp_path)
    out = tmp_path / "dist" / "mlt-r-basic.zip"
    bwz.build_zip(ws, tmp_path / "no_such_deck_dir", out)
    names = set(zipfile.ZipFile(out).namelist())
    assert "mlt-r-basic/renv.lock" in names
    assert not any(n.startswith("mlt-r-basic/slides/") for n in names)


def test_keep_files_preserve_empty_step_dirs(tmp_path):
    ws = _make_workshop(tmp_path)
    deck = tmp_path / "slides_src"
    deck.mkdir()
    (deck / "00-basic-deck.html").write_text("<html>", encoding="utf-8")
    out = tmp_path / "dist" / "mlt-r-basic.zip"
    bwz.build_zip(ws, deck, out)
    names = set(zipfile.ZipFile(out).namelist())
    assert "mlt-r-basic/steps/01-import/output/.keep" in names


def test_main_errors_when_no_deck(tmp_path):
    ws = _make_workshop(tmp_path)
    # ws is its own git repo with no slides/workshops/<slug> -> no deck -> exit 2
    assert bwz.main([str(ws)]) == 2


def _make_fragment_workshop(tmp_path):
    """A fragment-built workshop: has _authoring/ + a generated (gitignored) tree."""
    ws = tmp_path / "mlt-r-basic"
    (ws / "_authoring" / "00-setup").mkdir(parents=True)
    (ws / "_authoring" / "00-setup" / "beat.R").write_text("# beat", encoding="utf-8")
    (ws / "README.md").write_text("# ws", encoding="utf-8")
    (ws / "CLAUDE.md").write_text("authoring", encoding="utf-8")
    (ws / "_manifest.yml").write_text("slug: mlt-r-basic\n", encoding="utf-8")
    (ws / "requirements.R").write_text("# reqs", encoding="utf-8")
    (ws / "R").mkdir()
    (ws / "R" / "seed-data.R").write_text("# seed", encoding="utf-8")
    (ws / "data-raw").mkdir()
    (ws / "data-raw" / "heart_failure.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    # generated (gitignored) tree — Model C
    s0 = ws / "steps" / "00-setup"
    s0.mkdir(parents=True)
    (s0 / "00-setup.R").write_text("# step 0", encoding="utf-8")
    (s0 / "00-setup.Rproj").write_text("Version: 1.0\n", encoding="utf-8")
    (s0 / ".here").write_text("", encoding="utf-8")
    (s0 / "data-raw").mkdir()
    (s0 / "data-raw" / "heart_failure.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    s1 = ws / "steps" / "01-import"
    (s1 / "renv").mkdir(parents=True)
    (s1 / "01-import.R").write_text("library(rio)\n", encoding="utf-8")
    (s1 / "01-import.Rproj").write_text("Version: 1.0\n", encoding="utf-8")
    (s1 / ".Rprofile").write_text('source("renv/activate.R")', encoding="utf-8")
    (s1 / "renv.lock").write_text("{}", encoding="utf-8")
    (s1 / "renv" / "activate.R").write_text("# activate", encoding="utf-8")
    (s1 / "renv" / ".gitignore").write_text("library/\n", encoding="utf-8")
    (s1 / "renv" / "library").mkdir()  # runtime junk that must NOT ship
    (s1 / "renv" / "library" / "pkg.txt").write_text("x", encoding="utf-8")
    (s1 / "01-import.html").write_text("<html>", encoding="utf-8")  # stray render, must NOT ship
    full = ws / "full"
    (full / "renv").mkdir(parents=True)
    (full / "full.R").write_text("# full", encoding="utf-8")
    (full / "renv.lock").write_text("{}", encoding="utf-8")
    sol = ws / "_solved"
    sol.mkdir()
    (sol / "00-setup.html").write_text("<html>solved0</html>", encoding="utf-8")
    (sol / "01-import.html").write_text("<html>solved1</html>", encoding="utf-8")
    return ws


def test_is_fragment_workshop(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    assert bwz.is_fragment_workshop(frag) is True
    nonfrag = tmp_path / "mlt-r-advanced"
    nonfrag.mkdir()
    assert bwz.is_fragment_workshop(nonfrag) is False


def test_student_payload_fragment_from_disk(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    rels = {arc for _src, arc in bwz.student_payload(frag)}
    assert "steps/00-setup/00-setup.R" in rels
    assert "steps/00-setup/00-setup.Rproj" in rels
    assert "steps/01-import/renv.lock" in rels
    assert "steps/01-import/renv/activate.R" in rels
    assert "full/full.R" in rels
    assert "data-raw/heart_failure.csv" in rels
    assert "README.md" in rels
    # excluded:
    assert not any(a.startswith("_solved/") for a in rels)        # teacher-only
    assert "renv.lock" not in rels                                # NO root lock
    assert not any(a.startswith("renv/") for a in rels)           # no root renv project
    assert not any(a.startswith("_authoring/") for a in rels)     # authoring source
    assert "CLAUDE.md" not in rels and "_manifest.yml" not in rels
    assert "requirements.R" not in rels
    assert not any(a.startswith("R/") for a in rels)              # maintainer helpers
    assert not any("renv/library" in a for a in rels)             # runtime junk
    assert "steps/01-import/01-import.html" not in rels           # stray render


def test_teacher_payload_adds_solved(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    rels = {arc for _src, arc in bwz.teacher_payload(frag)}
    assert "_solved/00-setup.html" in rels and "_solved/01-import.html" in rels
    assert "steps/01-import/01-import.R" in rels   # superset of student tree


def test_build_zip_teacher_contains_solved(tmp_path):
    frag = _make_fragment_workshop(tmp_path)
    deck = tmp_path / "deck"
    deck.mkdir()
    (deck / "deck.html").write_text("<html>", encoding="utf-8")
    out = tmp_path / "mlt-r-basic-teacher.zip"
    bwz.build_zip(frag, deck, out, teacher=True)
    names = set(zipfile.ZipFile(out).namelist())
    assert any(n.startswith("mlt-r-basic/_solved/") for n in names)
    assert "mlt-r-basic/steps/00-setup/00-setup.R" in names   # superset


def test_student_zip_has_no_teacher_zip_for_nonfragment(tmp_path):
    ws = _make_workshop(tmp_path)            # non-fragment git workshop (existing helper)
    deck = tmp_path / "slides_src"
    deck.mkdir()
    (deck / "00-basic-deck.html").write_text("<html>", encoding="utf-8")
    assert bwz.is_fragment_workshop(ws) is False
