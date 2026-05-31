import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location(
    "remind_workshop_dist", ROOT / ".claude" / "hooks" / "remind-workshop-dist.py"
)
rwd = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rwd)


def test_reminds_on_workshop_r_source():
    assert rwd.should_remind("workshops/mlt-r-basic/steps/01-import/01-import.qmd") is True
    assert rwd.should_remind("workshops/mlt-r-basic/R/seed-data.R") is True
    assert rwd.should_remind("workshops/mlt-r-basic/data-raw/heart_failure.csv") is True


def test_reminds_on_workshop_slide_source():
    assert rwd.should_remind("slides/workshops/mlt-r-basic/00-basic-deck.qmd") is True
    assert rwd.should_remind("slides/workshops/mlt-r-basic/theme.scss") is True


def test_reminds_on_shared_brand():
    assert rwd.should_remind("styles/_brand.scss") is True


def test_ignores_cache_rendered_zip_and_unrelated():
    assert rwd.should_remind("slides/workshops/mlt-r-basic/.quarto/idx.json") is False
    assert rwd.should_remind("slides/workshops/mlt-r-basic/00-basic-deck.html") is False
    assert rwd.should_remind("workshops/mlt-r-basic/slides/00-basic-deck_files/x.js") is False
    assert rwd.should_remind("dist/mlt-r-basic.zip") is False
    assert rwd.should_remind("course/01-introduction/narrative.md") is False
    assert rwd.should_remind("slides/slides.qmd") is False
