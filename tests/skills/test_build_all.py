import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import build_all as ba  # noqa: E402


def _labels(cmds):
    return [label for label, _argv in cmds]


def test_plan_order_default_fragment():
    cmds = ba.plan_commands(["mlt-r-basic"], ["mlt-r-basic"],
                            release=False, no_site=False, skip_masking=False)
    assert _labels(cmds) == ["rebuild", "check-masking", "render-deck", "zip", "site"]


def test_plan_skip_masking_and_no_site():
    cmds = ba.plan_commands(["mlt-r-basic"], ["mlt-r-basic"],
                            release=False, no_site=True, skip_masking=True)
    assert _labels(cmds) == ["rebuild", "render-deck", "zip"]


def test_plan_release_adds_release_stage_before_site():
    cmds = ba.plan_commands(["mlt-r-basic"], ["mlt-r-basic"],
                            release=True, no_site=False, skip_masking=True)
    assert _labels(cmds) == ["rebuild", "render-deck", "zip", "release", "site"]


def test_nonfragment_workshop_skips_rebuild_and_masking():
    # advanced not fragment-built -> no rebuild, no masking; still render + zip
    cmds = ba.plan_commands(["mlt-r-advanced"], [],
                            release=False, no_site=True, skip_masking=False)
    assert _labels(cmds) == ["render-deck", "zip"]


def test_mixed_fragment_and_nonfragment():
    cmds = ba.plan_commands(["mlt-r-basic", "mlt-r-advanced"], ["mlt-r-basic"],
                            release=False, no_site=True, skip_masking=False)
    # rebuild only names the fragment slug
    rebuild = [argv for label, argv in cmds if label == "rebuild"][0]
    assert "mlt-r-basic" in rebuild and "mlt-r-advanced" not in rebuild
    # masking targets the PATH workshops/<slug>, only for the fragment slug
    masking = [argv for label, argv in cmds if label == "check-masking"]
    assert len(masking) == 1 and "workshops/mlt-r-basic" in masking[0]
    # render + zip cover BOTH workshops
    zips = [" ".join(argv) for label, argv in cmds if label == "zip"]
    assert any("workshops/mlt-r-basic" in z for z in zips)
    assert any("workshops/mlt-r-advanced" in z for z in zips)


def test_check_masking_uses_workshops_path():
    cmds = ba.plan_commands(["mlt-r-basic"], ["mlt-r-basic"],
                            release=False, no_site=True, skip_masking=False)
    masking = [argv for label, argv in cmds if label == "check-masking"][0]
    assert masking[-1] == "workshops/mlt-r-basic"   # path, not bare slug


def test_plan_commands_rejects_fragment_not_in_slugs():
    with pytest.raises(AssertionError):
        ba.plan_commands(["mlt-r-basic"], ["mlt-r-advanced"],
                         release=False, no_site=True, skip_masking=True)


def test_mlt_rscript_env_is_read_at_call_time(monkeypatch):
    monkeypatch.setenv("MLT_RSCRIPT", "/custom/Rscript.exe")
    cmds = ba.plan_commands(["mlt-r-basic"], ["mlt-r-basic"],
                            release=False, no_site=True, skip_masking=False)
    rebuild = [argv for label, argv in cmds if label == "rebuild"][0]
    assert rebuild[0] == "/custom/Rscript.exe"
