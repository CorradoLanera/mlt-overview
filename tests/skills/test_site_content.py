import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import site_content as sc  # noqa: E402

MANIFEST = """\
course:
  title: "MLT"
chapters:
  - { slug: 01-introduction, title: "What is Machine Learning?", include: true,  minutes: 25, objectives: [] }
  - { slug: 02-classifiers,  title: "Classifiers",               include: true,  minutes: 20, objectives: [] }
  - { slug: 99-cut,          title: "Cut chapter",               include: false, minutes: 10, objectives: [] }
"""

OBJECTIVES = """\
# 01 — title

## Learning objectives

By the end of this chapter, students can:

1. **Frame** a clinical problem as ML.
2. **Contrast** ML with traditional programming.

*Nota docente:* tre obiettivi per stare nei 25'.

## Summative live exercise

(internal stuff)
"""


def test_chapters_from_manifest_parses_included_in_order():
    chs = sc.chapters_from_manifest(MANIFEST)
    assert [c["slug"] for c in chs] == ["01-introduction", "02-classifiers", "99-cut"]
    assert chs[0] == {"slug": "01-introduction", "title": "What is Machine Learning?",
                      "include": True, "minutes": 25}
    assert chs[2]["include"] is False


def test_extract_objectives_keeps_en_list_stops_at_nota_docente():
    out = sc.extract_objectives(OBJECTIVES)
    assert "**Frame**" in out and "**Contrast**" in out
    assert "Nota docente" not in out
    assert "Summative" not in out


def test_extract_objectives_absent_returns_empty():
    assert sc.extract_objectives("# x\n\nno section here\n") == ""


def test_timeline_from_formatives_sorts_and_ignores_noise():
    names = ["min-30-yourturn-wrangle.md", "min-09-live-check.md", "README.md",
             "min-165-predict-output.md"]
    rows = sc.timeline_from_formatives(names)
    assert [r["minute"] for r in rows] == [9, 30, 165]
    assert rows[0]["label"] == "live check"


def test_readme_section_extracts_body_until_next_heading():
    md = "# t\n\n## Prerequisites\n\nNeed R.\nAnd RStudio.\n\n## Dataset\n\nheart failure\n"
    assert sc.readme_section(md, "Prerequisites") == "Need R.\nAnd RStudio."
    assert sc.readme_section(md, "Missing") == ""


def test_readme_section_heading_is_case_insensitive():
    md = "## Prerequisites\n\nContent here.\n"
    assert sc.readme_section(md, "prerequisites") == "Content here."


def test_solutions_tabset_md_one_tab_per_step():
    md = sc.solutions_tabset_md("mlt-r-basic", ["00-setup", "01-import", "05-report"])
    assert "::: {.panel-tabset}" in md
    assert "## 00-setup" in md and "## 05-report" in md
    assert 'src="solutions/mlt-r-basic/00-setup.html"' in md
    assert md.count("<iframe") == 3
    assert md.strip().endswith(":::")


def test_solutions_tabset_md_empty_when_no_steps():
    assert sc.solutions_tabset_md("mlt-r-basic", []) == ""
