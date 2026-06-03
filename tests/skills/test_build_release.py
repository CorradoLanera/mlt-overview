import os
import sys
import unittest.mock as mock
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_release as br  # noqa: E402


def test_asset_names_are_contractual():
    assert br.DECK_ASSETS["theory"] == "mlt-overview-theory-deck.html"
    assert br.DECK_ASSETS["basic"] == "mlt-r-basic-deck.html"
    assert br.DECK_ASSETS["advanced"] == "mlt-r-advanced-deck.html"
    assert br.ZIP_ASSETS == [
        "mlt-r-basic.zip", "mlt-r-basic-teacher.zip",
        "mlt-r-advanced.zip", "mlt-r-advanced-teacher.zip",
    ]


def test_zip_is_fresh_passes_when_zip_newer(tmp_path):
    import os
    (tmp_path / "_authoring").mkdir()
    old = tmp_path / "_authoring" / "workshop.yml"
    old.write_text("slug: x\n", encoding="utf-8")
    z = tmp_path / "x.zip"
    z.write_text("zip", encoding="utf-8")
    os.utime(old, (1_000, 1_000))
    os.utime(z, (2_000, 2_000))
    assert br.zip_is_fresh(z, tmp_path) is True


def test_zip_is_fresh_fails_when_authoring_newer(tmp_path):
    import os
    (tmp_path / "_authoring").mkdir()
    a = tmp_path / "_authoring" / "workshop.yml"
    a.write_text("slug: x\n", encoding="utf-8")
    z = tmp_path / "x.zip"
    z.write_text("zip", encoding="utf-8")
    os.utime(z, (1_000, 1_000))
    os.utime(a, (2_000, 2_000))
    assert br.zip_is_fresh(z, tmp_path) is False


def test_zip_is_fresh_true_for_nonfragment(tmp_path):
    # no _authoring/ -> always fresh (non-migrated workshop)
    z = tmp_path / "x.zip"
    z.write_text("zip", encoding="utf-8")
    assert br.zip_is_fresh(z, tmp_path) is True


def test_build_raises_systemexit_on_stale_zip(tmp_path):
    """build() must SystemExit when dist/<zip> exists but is older than _authoring/."""
    (tmp_path / "dist").mkdir()
    auth = tmp_path / "workshops" / "mlt-r-basic" / "_authoring"
    auth.mkdir(parents=True)
    src = auth / "workshop.yml"
    src.write_text("slug: mlt-r-basic\n", encoding="utf-8")
    z = tmp_path / "dist" / "mlt-r-basic.zip"
    z.write_text("zip", encoding="utf-8")
    os.utime(z, (1_000, 1_000))          # zip OLDER than the source
    os.utime(src, (2_000, 2_000))

    deck_html = tmp_path / "deck.html"
    deck_html.write_text("<html/>", encoding="utf-8")

    # Neutralise the deck-render half of build() so the test is fast + offline.
    with mock.patch("build_release._run"), \
         mock.patch("build_release._rendered_html", return_value=deck_html), \
         mock.patch("build_release.shutil.copy2"):
        with pytest.raises(SystemExit, match="STALE"):
            br.build(tmp_path)
