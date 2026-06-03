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


def test_workshop_step_order_parses_flow_list():
    wf = 'slug: mlt-r-basic\nsteps: [00-setup, 01-import, 05-report]\n'
    assert sc.workshop_step_order(wf) == ["00-setup", "01-import", "05-report"]


def test_workshop_step_order_absent_returns_empty():
    assert sc.workshop_step_order("slug: x\n") == []


def test_parse_step_meta_pulls_title_minutes_summary():
    meta = ('type: append\ntitle: "Step 01 — Import & wrangle"\n'
            'minutes: 35\nsummary: "Import the data."\npackages: [rio]\n')
    m = sc.parse_step_meta(meta)
    assert m["title"] == "Step 01 — Import & wrangle"
    assert m["minutes"] == 35
    assert m["summary"] == "Import the data."


def test_parse_step_meta_missing_fields_are_none():
    m = sc.parse_step_meta('type: append\nslug: 00-setup\n')
    assert m == {"title": None, "minutes": None, "summary": None}


def test_workshop_steps_orders_and_skips_incomplete():
    wf = 'steps: [00-setup, 01-import, 99-bad]\n'
    metas = {
        "00-setup": {"title": "Step 00 — Setup", "minutes": 25, "summary": "Init."},
        "01-import": {"title": "Step 01 — Import", "minutes": 35, "summary": ""},
        "99-bad": {"title": None, "minutes": None, "summary": None},
    }
    steps = sc.workshop_steps(wf, metas)
    assert [s["slug"] for s in steps] == ["00-setup", "01-import"]
    assert steps[0] == {"slug": "00-setup", "title": "Step 00 — Setup",
                        "minutes": 25, "summary": "Init."}
    assert steps[1]["summary"] == ""
