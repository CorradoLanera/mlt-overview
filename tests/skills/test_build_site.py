import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_site as bs  # noqa: E402


def _mini_repo(tmp: Path) -> Path:
    (tmp / "course" / "01-introduction").mkdir(parents=True)
    (tmp / "course" / "_manifest.yml").write_text(
        'chapters:\n'
        '  - { slug: 01-introduction, title: "Intro", include: true, minutes: 25, objectives: [] }\n',
        encoding="utf-8",
    )
    (tmp / "course" / "01-introduction" / "objectives.md").write_text(
        "## Learning objectives\n\n1. **Frame** it.\n\n*Nota docente:* hidden.\n", encoding="utf-8"
    )
    fm = tmp / "slides" / "workshops" / "mlt-r-basic" / "formatives"
    fm.mkdir(parents=True)
    (fm / "min-09-live-check.md").write_text("x", encoding="utf-8")
    (fm / "min-30-yourturn-wrangle.md").write_text("x", encoding="utf-8")
    (fm / "README.md").write_text("x", encoding="utf-8")
    (tmp / "workshops" / "mlt-r-basic").mkdir(parents=True)
    (tmp / "workshops" / "mlt-r-basic" / "README.md").write_text(
        "# Basic\n\n## What you will build\n\nA model.\n\n## Prerequisites\n\nSome R.\n",
        encoding="utf-8",
    )
    fa = tmp / "slides" / "workshops" / "mlt-r-advanced" / "formatives"
    fa.mkdir(parents=True)
    (fa / "min-10-live-check.md").write_text("x", encoding="utf-8")
    (tmp / "workshops" / "mlt-r-advanced").mkdir(parents=True)
    (tmp / "workshops" / "mlt-r-advanced" / "README.md").write_text(
        "# Adv\n\n## What you will build\n\nInterpretability.\n", encoding="utf-8"
    )
    return tmp


def test_write_partials_emits_expected_files(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    written = bs.write_partials(root, out)
    names = {p.name for p in written}
    for expected in {
        "theory-chapters.md", "schedule.md",
        "basic-overview.md", "basic-timeline.md", "basic-syllabus.md",
        "advanced-overview.md", "advanced-timeline.md", "advanced-syllabus.md",
        "theory-syllabus.md",
    }:
        assert expected in names
        assert (out / expected).exists()


def test_theory_chapters_has_objectives_no_nota_and_total(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    text = (out / "theory-chapters.md").read_text(encoding="utf-8")
    assert "Intro" in text and "**Frame**" in text
    assert "Nota docente" not in text
    assert "25 min" in text


def test_basic_timeline_and_overview(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    tl = (out / "basic-timeline.md").read_text(encoding="utf-8")
    assert "min 9" in tl and "min 30" in tl
    ov = (out / "basic-overview.md").read_text(encoding="utf-8")
    assert "A model." in ov and "Some R." in ov


def test_syllabus_placeholder_when_absent(tmp_path):
    root = _mini_repo(tmp_path)
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)
    syl = (out / "theory-syllabus.md").read_text(encoding="utf-8")
    assert "preparation" in syl.lower() or "preparazione" in syl.lower()


def test_overview_placeholder_when_readme_absent(tmp_path):
    root = _mini_repo(tmp_path)
    (root / "workshops" / "mlt-r-advanced" / "README.md").unlink()
    out = tmp_path / "site" / "_generated"
    bs.write_partials(root, out)  # must not raise
    ov = (out / "advanced-overview.md").read_text(encoding="utf-8")
    assert "to be published" in ov.lower()
