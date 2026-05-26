import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude" / "skills" / "lib"))
import manifest  # noqa: E402

SAMPLE = """\
course:
  title: "T"
  slug: demo
  language: en
chapters:
  - { slug: 01-a, title: "A", include: true,  minutes: 10 }
  - { slug: 02-b, title: "B", include: false, minutes: 10 }
  - { slug: 03-c, title: "C", include: true,  minutes: 10 }
  - { slug: 04-d, title: "D", include: true,  minutes: 10 }
"""


def _write(tmp_path):
    p = tmp_path / "_manifest.yml"
    p.write_text(SAMPLE, encoding="utf-8")
    return p


def test_load_returns_chapters(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert m["course"]["slug"] == "demo"
    assert len(m["chapters"]) == 4


def test_enabled_chapters_filters_include_false(tmp_path):
    m = manifest.load(_write(tmp_path))
    slugs = [c["slug"] for c in manifest.enabled_chapters(m)]
    assert slugs == ["01-a", "03-c", "04-d"]


def test_next_enabled_skips_disabled(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "01-a")["slug"] == "03-c"


def test_next_enabled_after_disabled_chapter(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "02-b")["slug"] == "03-c"


def test_next_enabled_last_is_none(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "04-d") is None


def test_next_enabled_unknown_is_none(tmp_path):
    m = manifest.load(_write(tmp_path))
    assert manifest.next_enabled(m, "99-x") is None


def test_artifact_status_reads_filesystem(tmp_path):
    m = manifest.load(_write(tmp_path))
    (tmp_path / "01-a" / "items").mkdir(parents=True)
    (tmp_path / "01-a" / "objectives.md").write_text("x", encoding="utf-8")
    (tmp_path / "01-a" / "items" / "item_01_a_mcq.md").write_text("x", encoding="utf-8")
    st = manifest.artifact_status(m, root=tmp_path)
    assert st["01-a"]["objectives"] is True
    assert st["01-a"]["narrative"] is False
    assert st["01-a"]["items"] == 1
    assert st["03-c"]["objectives"] is False
