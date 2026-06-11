import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
import check_register as cr  # noqa: E402


def test_emdash_in_prose_flagged():
    hits = cr.scan_text("Live check — did it work?")
    assert (1, "em-dash", "—") in hits


def test_emdash_in_fence_skipped():
    text = "```\nx <- 1  # a — b\n```\nclean line\n"
    assert cr.scan_text(text) == []


def test_inline_code_emdash_skipped():
    assert cr.scan_text("see `a — b` only") == []


def test_register_word_flagged():
    hits = cr.scan_text("This is obviously the best.")
    assert "register" in [c for _, c, _ in hits]


def test_reload_term_flagged():
    hits = cr.scan_text("Advanced reopens the model on day one.")
    assert "reload" in [c for _, c, _ in hits]


def test_clean_text_no_hits():
    assert cr.scan_text("We rebuild the model live, then push past it.") == []
