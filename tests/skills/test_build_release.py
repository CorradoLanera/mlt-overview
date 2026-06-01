import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_release as br  # noqa: E402


def test_asset_names_are_contractual():
    assert br.DECK_ASSETS["theory"] == "mlt-overview-theory-deck.html"
    assert br.DECK_ASSETS["basic"] == "mlt-r-basic-deck.html"
    assert br.DECK_ASSETS["advanced"] == "mlt-r-advanced-deck.html"
    assert br.ZIP_ASSETS == ["mlt-r-basic.zip", "mlt-r-advanced.zip"]
