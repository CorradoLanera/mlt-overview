import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import archive_legacy_assets as ala  # noqa: E402


def test_extract_refs_finds_markdown_html_url_and_knitr():
    text = (
        "![cap](img/MLvsTrad.png)\n"
        '<img src="img/Hierarchy_of_Evidence.png">\n'
        "background-image: url(img/100M-users.png)\n"
        'knitr::include_graphics("img/agents.gif")\n'
        '<link rel="stylesheet" href="xaringan-themer.css">\n'
        "[external](https://example.com/x.png)\n"
    )
    refs = ala.extract_refs(text)
    assert "img/MLvsTrad.png" in refs
    assert "img/Hierarchy_of_Evidence.png" in refs
    assert "img/100M-users.png" in refs
    assert "img/agents.gif" in refs
    assert "xaringan-themer.css" in refs
    # remote URLs are dropped
    assert "https://example.com/x.png" not in refs


def test_classify_splits_shared_and_xaringan_only():
    referenced = {"img/MLvsTrad.png", "img/old_only.png", "xaringan-themer.css"}
    live_blob = "see ![](../img/MLvsTrad.png) in a chapter and url(../img/other.png)"
    to_move, to_copy = ala.classify(referenced, live_blob)
    # MLvsTrad.png basename appears in the live blob -> shared -> copy
    assert "img/MLvsTrad.png" in to_copy
    # old_only.png + the xaringan css are not in the live blob -> move
    assert to_move == {"img/old_only.png", "xaringan-themer.css"}


def test_extract_refs_handles_here_here_nested_call():
    text = (
        'knitr::include_graphics(here::here("img/class-reg.png"))\n'
        '```{r, out.width="60%"}\nknitr::include_graphics(\n  here::here("img/full_transformer.png")\n)\n```\n'
    )
    refs = ala.extract_refs(text)
    assert "img/class-reg.png" in refs
    assert "img/full_transformer.png" in refs
