# Allineamento sezione 00 Advanced (reload→live) + sweep registro — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allineare la narrazione del workshop Advanced (deck, syllabus, README, manifest, sito) al codice già implementato — che ricostruisce dal vivo il modello di Basic invece di ricaricarlo — e ripulire il registro delle slide EN della sezione 00, lasciando un processo riusabile per le sezioni successive.

**Architecture:** Quattro cambiamenti logici (= 4 commit) + rebuild: (1) linter di registro `scripts/check_register.py` con test; (2) correzione fattuale `reload→live` sul filo narrativo Advanced (deck + sorgenti course-level); (3) micro-fix fattuale del pre-hook nel deck Basic; (4) sweep di registro sulla sola sezione 00 del deck Advanced; poi rebuild di step+deck+sito e commit di `docs/`. Tutte le superfici sono **sorgenti**: `docs/` è generato da `scripts/build_site.py` e va solo ricostruito, mai editato a mano.

**Tech Stack:** Python 3 (stdlib, pytest), Quarto/revealjs (`.qmd`), R 4.6.0 (`dev/mltbuild/rebuild.R`), Markdown/YAML.

**Spec:** `dev-docs/superpowers/specs/2026-06-11-mlt-advanced-section-alignment-design.md`

---

## File structure

**Create**

- `scripts/check_register.py` — linter di registro (pure `scan_text` + CLI), stdlib only.
- `tests/skills/test_check_register.py` — test del linter.

**Modify (sorgenti)**

- `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` — filo reload→live (cover/divider/step00/closing) + sweep registro 00.
- `workshops/mlt-r-advanced/syllabus.md` — premessa reload→live.
- `workshops/mlt-r-advanced/README.md` — premessa reload→live.
- `workshops/mlt-r-advanced/_manifest.yml` — stringa dataset.
- `workshops/mlt-r-advanced/requirements.R` — commento.
- `workshops/mlt-r-advanced/_authoring/00-recap/meta.yml` — `summary:` (→ timeline sito).
- `workshops/mlt-r-advanced/_authoring/00-recap/beat.R` — commento.
- `slides/workshops/mlt-r-basic/00-basic-deck.qmd` — pre-hook (solo fattuale).
- `C:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md` — tracking (no commit git).

**Generated (commit dopo rebuild, mai a mano)**

- `docs/**` (`advanced.html`, `schedule.html`, `docs/slides/workshops/**/*.html`, `docs/solutions/mlt-r-advanced/00-recap.html`).

**Out of scope (annotato, NON in questo piano)**

- `workshops/mlt-r-advanced/_authoring/04-targets/report.qmd` L3/L45 ("*reloaded* Basic random forest") → si corregge alla sezione 04.
- Sweep di registro sulle sezioni 01-04 del deck e sul frame condiviso → ai loro turni.
- Sweep di registro sul deck Basic → verifica globale di fine progetto.

---

## Task 1: Linter di registro (`scripts/check_register.py`)

**Files:**
- Create: `scripts/check_register.py`
- Test: `tests/skills/test_check_register.py`

- [ ] **Step 1: Write the failing test**

`tests/skills/test_check_register.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tests/skills/test_check_register.py -q`
Expected: FAIL with `ModuleNotFoundError: No module named 'check_register'`.

- [ ] **Step 3: Write minimal implementation**

`scripts/check_register.py`:

```python
#!/usr/bin/env python3
"""Flag register / em-dash / reload-residue smells in text sources.

Usage: python scripts/check_register.py PATH [PATH ...]
Prints `file:line: [category] match` for every hit; exit 1 if any, else 0.

Categories:
  em-dash : a U+2014 '—' in prose (fenced ``` blocks skipped; `inline code` stripped)
  register: self-certifying / hype words from CLAUDE.md "Registro di scrittura"
  reload  : stale 'reload/reopen/...' narrative claims (the Advanced workshop rebuilds
            Basic's model live, so these words are factually wrong as claims)

It flags; it does not edit. Filler intensifiers (really/just/very/actually) are
context-sensitive and left to manual judgement. False positives are expected — triage
by hand. Backticked code refs (e.g. `final_fit.rds`) are intentionally NOT flagged.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

EMDASH = "—"

REGISTER_WORDS = [
    "honestly", "truly", "clearly", "obviously", "genuinely",
    "sincerely", "of course", "the punchline", "killer",
]
_REGISTER_RE = re.compile(r"(?i)\b(" + "|".join(re.escape(w) for w in REGISTER_WORDS) + r")\b")

RELOAD_TERMS = [
    "reload", "reopen", "re-open", "final_fit.rds",
    "never retrain", "not retrained", "baked in",
]
_RELOAD_RE = re.compile(r"(?i)(" + "|".join(re.escape(w) for w in RELOAD_TERMS) + r")")

_INLINE_CODE_RE = re.compile(r"`[^`]*`")
_FENCE_RE = re.compile(r"^\s*(```|~~~)")


def _strip_inline_code(line: str) -> str:
    """Blank out `inline code` spans so matches inside them are ignored."""
    return _INLINE_CODE_RE.sub(lambda m: " " * len(m.group(0)), line)


def scan_text(text: str) -> list[tuple[int, str, str]]:
    """Return [(lineno, category, match)] for register/em-dash/reload smells.

    Lines inside fenced code blocks (``` or ~~~) are skipped; `inline code` is stripped.
    """
    hits: list[tuple[int, str, str]] = []
    in_fence = False
    for i, raw in enumerate(text.splitlines(), start=1):
        if _FENCE_RE.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        line = _strip_inline_code(raw)
        if EMDASH in line:
            hits.append((i, "em-dash", EMDASH))
        for m in _REGISTER_RE.finditer(line):
            hits.append((i, "register", m.group(0)))
        for m in _RELOAD_RE.finditer(line):
            hits.append((i, "reload", m.group(0)))
    return hits


def scan_file(path: Path) -> list[tuple[int, str, str]]:
    return scan_text(path.read_text(encoding="utf-8", errors="replace"))


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv:
        print("usage: check_register.py PATH [PATH ...]", file=sys.stderr)
        return 2
    total = 0
    for arg in argv:
        p = Path(arg)
        files = [p] if p.is_file() else (sorted(p.rglob("*")) if p.is_dir() else [])
        for f in files:
            if not f.is_file():
                continue
            for lineno, cat, match in scan_file(f):
                print(f"{f}:{lineno}: [{cat}] {match}")
                total += 1
    print(f"[check-register] {total} hit(s)", file=sys.stderr)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tests/skills/test_check_register.py -q`
Expected: PASS (6 passed).

- [ ] **Step 5: Commit** (commit A)

```bash
git add scripts/check_register.py tests/skills/test_check_register.py
git commit -m "feat(scripts): add check_register linter (em-dash/register/reload smells)"
```

---

## Task 2: reload→live — deck Advanced + sorgenti course-level (commit B, parte 1)

Solo correzione **fattuale**: ogni riga che porta contenuto reload viene riscritta (e, dato che la riscrivo, la scrivo già pulita di registro). Le righe con SOLO registro (no reload) restano al Task 4.

**File:** `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`

- [ ] **Step 1: Cover (L14)**

old:
```
<span style="color:#E8741E;">Advanced</span> — Open the validated model: interpret it, go deep, reach an LLM, seal it
```
new:
```
<span style="color:#E8741E;">Advanced</span> · Rebuild Basic's validated model, then go further: interpret it, go deep, reach an LLM, seal it
```

- [ ] **Step 2: Divider title (L81)**

old:
```
# Open the model you validated in Basic {.center}
```
new:
```
# Rebuild the model you validated in Basic {.center}
```

- [ ] **Step 3: Divider notes (L84-86)**

old:
```
Voce docente (IT): apertura. L'arco RIAPRE il modello validato in Basic — non si
ricostruisce nulla. Quattro tappe: interpretare (VIMP/SHAP) → deep learning (torch/
```
new:
```
Voce docente (IT): apertura. L'arco RICOSTRUISCE dal vivo il modello validato in Basic
(replay completo della selezione di Basic), non lo ricarica. Quattro tappe: interpretare (VIMP/SHAP) → deep learning (torch/
```

- [ ] **Step 4: Divider body (L92-93)**

old:
```
The model you built in Basic is not the end — it is the **subject**. We **open** the
random forest you built and validated in Basic, then push past it.
```
new:
```
The model you built in Basic is the **subject** of today. We **rebuild** that validated
random forest live, then push past it.
```

- [ ] **Step 5: Hidden timing comment (L104)**

old:
```
<!-- Step 00 (demo, 12 min): reload Basic's finalized workflow; predict 1 row; pre-warm torch. -->
```
new:
```
<!-- Step 00 (~30 min): rebuild Basic's full selection live to final_fit; predict 1 row; pre-warm torch. -->
```

- [ ] **Step 6: "Why first" (L106)**

old:
```
**Why first.** Advanced doesn't rebuild anything — it **reopens** the model you validated in Basic. Day one reloads that exact `final_fit`, so a clean, warm session is the precondition for everything that follows.
```
new:
```
**Why first.** Advanced starts by **rebuilding** the model you validated in Basic, live: day one re-runs that exact selection to land `final_fit` again, so a clean, warm session is the precondition for everything that follows.
```

- [ ] **Step 7: Step-00 bullets (L108-109)**

old:
```
- Reload Basic's finalized random forest: `extract_workflow(readRDS("final_fit.rds"))`.
- `predict()` on **one** patient row — a probability, not yet an explanation.
```
new:
```
- Rebuild Basic's selection live, then `extract_workflow(final_fit)` on the finalized random forest.
- `predict()` on **one** patient row: a probability, not yet an explanation.
```

- [ ] **Step 8: Step-00 notes (L112-116)**

old:
```
Voce docente (IT): demo (~12 min). Si RICARICA, non si riaddestra. Live-check al
min 10: reload + `predict` su 1 riga + `torch_tensor(1)` SENZA download (torch caldo).
GREEN/RED. Su questa macchina di build `cuda_is_available()` è FALSE; in aula, sulla
NVIDIA, è TRUE. Il punto: una probabilità non è una spiegazione → apre lo step 01.
```
new:
```
Voce docente (IT): demo (~30 min, replay completo della selezione di Basic dal vivo).
Si RICOSTRUISCE, non si ricarica. Live-check al min 10: `predict` su 1 riga sul workflow
appena fittato + `torch_tensor(1)` SENZA download (torch caldo). GREEN/RED. Su questa
macchina di build `cuda_is_available()` è FALSE; in aula, sulla NVIDIA, è TRUE. Il punto:
una probabilità non è una spiegazione → apre lo step 01.
```

- [ ] **Step 9: Live-check title (L119)**

old:
```
## Live check — did the model reload, is torch warm?
```
new:
```
## Live check: is the model rebuilt, is torch warm?
```

- [ ] **Step 10: Live-check body (L121-125)**

old:
```
Run three checks. Signal **GREEN** if all pass, **RED** if any fails:

1. Does `predict(fitted_wf, hf_tbl[1, ], type = "prob")` return a **1-row tibble** (no error, no retrain)?
2. Does **`torch_tensor(1)`** run **without a download** — backend loads instantly (torch pre-warmed)?
3. Is the loaded object the **finalized workflow from Basic** (the one that passed `last_fit()`)?
```
new:
```
Run three checks. Signal **GREEN** if all pass, **RED** if any fails:

1. Does `predict(fitted_wf, hf_tbl[1, ], type = "prob")` return a **1-row tibble** from the workflow we just fitted?
2. Does **`torch_tensor(1)`** run **without a download** (backend loads instantly, torch pre-warmed)?
3. Is `final_fit` the **finalized workflow** from the live selection (the one that passed `last_fit()`)?
```

- [ ] **Step 11: GREEN title (L131)**

old:
```
## GREEN — Basic's model, reopened (not retrained)
```
new:
```
## GREEN: Basic's model, rebuilt live
```

- [ ] **Step 12: GREEN body (L133-139)**

old:
```
All three pass:

- `predict()` on the extracted `fitted_wf` returns immediately — the model is baked in, no `fit()`;
- `torch_tensor(1)` runs without downloading libtorch — the session was pre-warmed at setup;
- the object is Basic's finalized `last_fit` workflow (`model/final_fit.rds` → `readRDS()` → `extract_workflow()`).

**RED on torch?** Run `library(torch)` now and wait for backend init — normal once per session, never mid-workshop. **RED on the model?** Reload from the checkpoint before continuing — all of Step 01 depends on it.
```
new:
```
All three pass:

- `predict()` on the extracted `fitted_wf` returns a probability; `final_fit` came from the live selection we just ran;
- `torch_tensor(1)` runs without downloading libtorch (the session was pre-warmed at setup);
- the object is the finalized `last_fit` workflow from the selection (`extract_workflow(final_fit)`), the random forest that won on `roc_auc`.

**RED on torch?** Run `library(torch)` now and wait for backend init (normal once per session, never mid-workshop). **RED on the model?** Re-run the selection block before continuing; all of Step 01 depends on `final_fit`.
```

- [ ] **Step 13: Go-to-code body (L148-151)** (il titolo L146 resta al Task 4)

old:
```
**Follow along.** Open `steps/00-recap/`: reload Basic's `final_fit`, `predict()` one row, pre-warm torch.

- Live check at minute 10: GREEN / RED.
- We never retrain — Advanced opens the model Basic validated.
```
new:
```
**Follow along.** Open `steps/00-recap/`: rebuild Basic's selection live to `final_fit`, `predict()` one row, pre-warm torch.

- Live check at minute 10: GREEN / RED.
- We rebuild it live: Advanced re-derives the model Basic validated.
```

- [ ] **Step 14: Closing payoff (L799-802)**

old:
```
- Basic **promised** that Advanced would reload its validated model. **We delivered:** day one
  reopened that exact `final_fit`, and we never retrained it.

The loop is closed — from a validated model to a reproducible pipeline a colleague can re-run.
```
new:
```
- Basic **built** the validated model; Advanced **re-derived it live** on day one and pushed
  past it.

The loop is closed: from a validated model to a reproducible pipeline a colleague can re-run.
```

- [ ] **Step 15: Closing notes (L805-807)**

old:
```
Voce docente (IT): chiusura. Chiude il loop Basic↔Advanced: Basic prometteva che Advanced
RICARICA il modello (pre-hook), e l'abbiamo mantenuto — step 00 ha riaperto `final_fit`
senza retrain. Il payoff finale è la consegnabilità: la pipeline spiegata-deep-LLM è
```
new:
```
Voce docente (IT): chiusura. Chiude il loop Basic↔Advanced: Basic prometteva che Advanced
RICOSTRUISCE dal vivo il modello (pre-hook), e l'abbiamo mantenuto: step 00 ha ri-derivato
`final_fit` dal vivo. Il payoff finale è la consegnabilità: la pipeline spiegata-deep-LLM è
```

---

## Task 3: reload→live — sorgenti course-level (commit B, parte 2)

- [ ] **Step 1: `workshops/mlt-r-advanced/syllabus.md` — description (L18)**

old:
```
we reopen a validated clinical ML model and push it further. Starting from the **validated heart-failure random forest built in the Basic workshop** (bundled in the project), we:
```
new:
```
we rebuild a validated clinical ML model live and push it further. We re-run the **heart-failure random forest selection from the Basic workshop** live, then we:
```

- [ ] **Step 2: syllabus dataset (L44)**

old:
```
The workshop reloads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients, ~32% event rate) from `data-raw/heart_failure.csv` (bundled) and the already-fitted random forest from `model/final_fit.rds` (bundled). It adds ~12 synthetic, de-identified clinical notes in `data-raw/hf_notes.csv` for the LLM extraction step. **No PHI** is present in any bundled file.
```
new:
```
The workshop loads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients, ~32% event rate) from `data-raw/heart_failure.csv` (bundled) and **rebuilds the random forest live** from that data: nothing is pre-fitted on disk. It adds ~12 synthetic, de-identified clinical notes in `data-raw/hf_notes.csv` for the LLM extraction step. **No PHI** is present in any bundled file.
```

- [ ] **Step 3: syllabus prerequisites (L52)**

old:
```
the validated random forest it produces is the starting point here (bundled, so you do not need it on disk).
```
new:
```
the validated random forest it produces is the starting point here (rebuilt live from the bundled data, so you do not need the model on disk).
```

- [ ] **Step 4: `workshops/mlt-r-advanced/README.md` — intro (L5-6)**

old:
```
A ~4-hour, live-coded workshop in which we reopen a validated clinical ML model and push it
further: we interpret it with agnostic SHAP, go deeper with neural networks, extract structured
```
new:
```
A ~4-hour, live-coded workshop in which we rebuild a validated clinical ML model live and push it
further: we interpret it with agnostic SHAP, go deeper with neural networks, extract structured
```

- [ ] **Step 5: README "What you will build" (L13-14)**

old:
```
Starting from the **validated heart-failure random forest built in the Basic workshop** (bundled
in this project), we:
```
new:
```
We rebuild live the **validated heart-failure random forest from the Basic workshop** (from the
bundled data), then we:
```

- [ ] **Step 6: README prerequisites (L29-32)**

old:
```
You must have completed the **Basic workshop** (Module 2). You should understand the validated
heart-failure model this workshop reopens: a tuned random forest, outcome `died` / `survived`,
validated with `last_fit` on held-out data, scored on AUC-ROC and AUC-PR. You do **not** need
to have it on disk: this project **bundles** it (`model/final_fit.rds`).
```
new:
```
You must have completed the **Basic workshop** (Module 2). You should understand the validated
heart-failure model this workshop rebuilds: a tuned random forest, outcome `died` / `survived`,
validated with `last_fit` on held-out data, scored on AUC-ROC and AUC-PR. You do **not** need
the fitted model on disk: this project **bundles the data** (`data-raw/heart_failure.csv`) and
rebuilds the model live.
```

- [ ] **Step 7: README dataset (L84-88)**

old:
```
This workshop reloads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients,
~32% event rate) from `data-raw/heart_failure.csv` (bundled) and the already-fitted random
forest from `model/final_fit.rds` (bundled). It also adds ~12 synthetic, de-identified clinical
notes in `data-raw/hf_notes.csv` for the LLM extraction step. No PHI is present in any bundled
file.
```
new:
```
This workshop loads the **heart-failure clinical records** (Chicco & Jurman 2020; 299 patients,
~32% event rate) from `data-raw/heart_failure.csv` (bundled) and **rebuilds the random forest
live** from that data: nothing is pre-fitted on disk. It also adds ~12 synthetic, de-identified
clinical notes in `data-raw/hf_notes.csv` for the LLM extraction step. No PHI is present in any
bundled file.
```

- [ ] **Step 8: `workshops/mlt-r-advanced/_manifest.yml` (L6)**

old:
```
  dataset: "heart_failure clinical records (reloaded Basic model) + synthetic notes"
```
new:
```
  dataset: "heart_failure clinical records + synthetic notes"
```

- [ ] **Step 9: `workshops/mlt-r-advanced/requirements.R` (L8)**

old:
```
  "tidymodels", "workflowsets", "ranger",       # reload the Basic RF
```
new:
```
  "tidymodels", "workflowsets", "ranger",       # rebuild the Basic RF live
```

- [ ] **Step 10: `workshops/mlt-r-advanced/_authoring/00-recap/meta.yml` (L4)**

old:
```
summary: "Reopen the validated Basic random forest and warm up the `torch` backend."
```
new:
```
summary: "Rebuild Basic's validated random forest live and warm up the `torch` backend."
```

- [ ] **Step 11: `workshops/mlt-r-advanced/_authoring/00-recap/beat.R` (L1)**

old:
```
# Sanity-check the reloaded Basic model — one-row probability prediction (no retraining) ----
```
new:
```
# Sanity-check the model we just rebuilt: one-row probability prediction ----
```

- [ ] **Step 12: Verify no residual reload in the edited sources**

Run:
```bash
python scripts/check_register.py workshops/mlt-r-advanced/syllabus.md workshops/mlt-r-advanced/README.md workshops/mlt-r-advanced/_manifest.yml workshops/mlt-r-advanced/requirements.R workshops/mlt-r-advanced/_authoring/00-recap/meta.yml workshops/mlt-r-advanced/_authoring/00-recap/beat.R
```
Expected: `[check-register] 0 hit(s)` (exit 0). If any `[reload]` or `[em-dash]` hit appears, fix that line.

- [ ] **Step 13: Commit** (commit B)

```bash
git add slides/workshops/mlt-r-advanced/00-advanced-deck.qmd workshops/mlt-r-advanced/syllabus.md workshops/mlt-r-advanced/README.md workshops/mlt-r-advanced/_manifest.yml workshops/mlt-r-advanced/requirements.R workshops/mlt-r-advanced/_authoring/00-recap/meta.yml workshops/mlt-r-advanced/_authoring/00-recap/beat.R
git commit -m "fix(advanced): align narrative to live rebuild (drop the dead reload framing)"
```

---

## Task 4: Pre-hook Basic — solo fattuale (commit C)

**File:** `slides/workshops/mlt-r-basic/00-basic-deck.qmd`. Cambiare SOLO la parola reload→rebuild; em-dash/registro del Basic restano (workshop 1, verifica globale).

- [ ] **Step 1: Step-05 bridge bullet (L1120)**

old:
```
- This validated `final_fit` is exactly what **Advanced reopens** on day one.
```
new:
```
- This validated `final_fit` is exactly what **Advanced rebuilds live** on day one.
```

- [ ] **Step 2: Step-05 bridge notes (L1123-1124)**

old:
```
Voce docente (IT): chiusura Step 05 (demo → "follow along"). Ponte all'Advanced: il workflow
finalizzato di Basic è ciò che l'Advanced ricarica al giorno uno (pre-hook).
```
new:
```
Voce docente (IT): chiusura Step 05 (demo → "follow along"). Ponte all'Advanced: il workflow
finalizzato di Basic è ciò che l'Advanced ricostruisce dal vivo al giorno uno (pre-hook).
```

- [ ] **Step 3: "Next" divider title (L1160)** (em-dash lasciato di proposito)

old:
```
## Next: open the model — Advanced {.center}
```
new:
```
## Next: rebuild the model — Advanced {.center}
```

- [ ] **Step 4: "Next" body (L1162)**

old:
```
You built and validated a model. **Advanced opens this very model:**
```
new:
```
You built and validated a model. **Advanced rebuilds this very model, then extends it:**
```

- [ ] **Step 5: "Next" payoff line (L1168)**

old:
```
The validated `final_fit` you just produced is exactly what Advanced **reloads** on day one.
```
new:
```
The validated `final_fit` you just produced is exactly what Advanced **rebuilds live** on day one.
```

- [ ] **Step 6: "Next" notes (L1171-1172)**

old:
```
Voce docente (IT): pre-hook ad Advanced (spec §11). L'Advanced apre RICARICANDO il workflow
finalizzato di Basic e fa `predict` su una riga — niente retrain. Poi: interpretability
```
new:
```
Voce docente (IT): pre-hook ad Advanced (spec §11). L'Advanced RICOSTRUISCE dal vivo il workflow
finalizzato di Basic e fa `predict` su una riga. Poi: interpretability
```

- [ ] **Step 7: Commit** (commit C)

```bash
git add slides/workshops/mlt-r-basic/00-basic-deck.qmd
git commit -m "fix(basic): pre-hook to Advanced says rebuild-live, not reload"
```

---

## Task 5: Sweep registro — sezione 00 Advanced (commit D)

**File:** `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`. Solo le righe della sezione 00 con registro residuo (em-dash) NON già toccate dal Task 2.

- [ ] **Step 1: Divider four-verb bullets (L95-98)**

old:
```
- **Interpret it** — permutation VIMP and agnostic SHAP, anchored on a logistic regression.
- **Go deep** — a live `brulee` MLP (`torch` / `luz` / `brulee`), then CNN/RNN/fused nets written (not trained).
- **Reach an LLM** — `ellmer` as a typed, reproducible LLM-as-ETL.
- **Seal it** — a `targets` pipeline that re-derives the explanation, all-skip on re-run.
```
new:
```
- **Interpret it:** permutation VIMP and agnostic SHAP, anchored on a logistic regression.
- **Go deep:** a live `brulee` MLP (`torch` / `luz` / `brulee`), then CNN/RNN/fused nets written (not trained).
- **Reach an LLM:** `ellmer` as a typed, reproducible LLM-as-ETL.
- **Seal it:** a `targets` pipeline that re-derives the explanation, all-skip on re-run.
```

- [ ] **Step 2: Go-to-code title (L146)**

old:
```
## Go to code — `steps/00-recap/` {.center}
```
new:
```
## Go to code: `steps/00-recap/` {.center}
```

- [ ] **Step 3: Verify the 00 through-line is register-clean**

Run:
```bash
python scripts/check_register.py slides/workshops/mlt-r-advanced/00-advanced-deck.qmd
```
Expected: hits ONLY at line numbers OUTSIDE the 00 through-line (`14`, `81–156`, `799–802`). Any `[em-dash]`/`[reload]` hit at lines 14 or 81–156 or 799–802 is a miss — fix it. Hits at other lines (177, 193, 252, 304, 334, …) are sezioni 01–04 + frame condiviso, **deferred** — leave them.

- [ ] **Step 4: Commit** (commit D)

```bash
git add slides/workshops/mlt-r-advanced/00-advanced-deck.qmd
git commit -m "style(advanced): register sweep of the step-00 slides (em-dash to colon)"
```

---

## Task 6: Rebuild + verify + commit `docs/` (commit E)

`beat.R`/`meta.yml` cambiati richiedono il rebuild dello step (rigenera `steps/00-recap/00-recap.R` + `_solved/00-recap.html`); i deck e i sorgenti syllabus/README richiedono `build_site.py` (che ri-renderizza ENTRAMBI i deck workshop + il deck teoria + rigenera i partial del sito + copia `_solved/` in `docs/solutions/`).

- [ ] **Step 1: Point Rscript at R 4.6.0** (PowerShell)

```powershell
$env:MLT_RSCRIPT = "C:\Program Files\R\R-4.6.0\bin\Rscript.exe"
```
(Col default R 4.5.2, `rebuild.R` fallisce `no package called 'quarto'`.)

- [ ] **Step 2: Rebuild the Advanced steps from `_authoring/`**

```powershell
& $env:MLT_RSCRIPT dev/mltbuild/rebuild.R mlt-r-advanced
```
Expected: completa senza errori; rigenera `workshops/mlt-r-advanced/steps/`, `full/`, `_solved/` (artefatti gitignored).

- [ ] **Step 3: Verify the rebuilt step dropped the stale comment**

```bash
python scripts/check_register.py workshops/mlt-r-advanced/_solved/00-recap.html
```
Expected: nessun `[reload]` hit (il commento "reloaded" è sparito dalla soluzione renderizzata). Em-dash residui in HTML di libreria non sono nel nostro perimetro: ignora hit non attribuibili al testo dello step.

- [ ] **Step 4: Rebuild the site (re-renders both decks + partials)**

```bash
python scripts/build_site.py
```
Expected: `site built into .../docs`. Ri-renderizza `docs/slides/workshops/mlt-r-advanced/00-advanced-deck.html`, `.../mlt-r-basic/00-basic-deck.html`, e rigenera `docs/advanced.html` + `docs/schedule.html` dai sorgenti aggiornati.

- [ ] **Step 5: Spot-check the generated site text**

```bash
python scripts/check_register.py docs/advanced.html docs/schedule.html
```
Expected: nessun `[reload]` hit nel testo della pagina Advanced/schedule (em-dash residui appartengono a sezioni deferred / frame). Confermare a occhio che `docs/schedule.html` per lo Step 00 mostri la nuova `summary` ("Rebuild Basic's validated random forest live …").

- [ ] **Step 6: Commit the regenerated docs** (commit E)

```bash
git add docs
git status --short   # confermare che siano cambiati SOLO file sotto docs/ (artefatti gitignored esclusi)
git commit -m "build(site): rebuild docs after step-00 reload->live alignment"
```

---

## Task 7: Vault tracking + nota verifica globale (no git commit)

**File:** `C:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md`

- [ ] **Step 1: Add the deferred global-check task to the static "Da fare" list** (dopo la voce W3, riga ~46)

Inserire:
```
- [ ] **Verifica globale di registro** (em-dash, auto-certificazioni, intensificatori) su overview (10 cap.) + Basic + Advanced via `scripts/check_register.py`, **dopo** aver chiuso e servito il workshop 2. Vedi spec `2026-06-11-mlt-advanced-section-alignment-design.md`.
```

- [ ] **Step 2: Prepend a LIFO entry to "Stato corrente"** (subito dopo `(LIFO: voci nuove in cima.)`)

```
- 2026-06-11: **✅ Sezione 00 Advanced allineata al codice (banco di prova) + linter di registro.** Il deck/syllabus/README/sito dicevano "reload del modello validato di Basic", ma `steps/00-recap/00-recap.R` lo **ricostruisce dal vivo** (replay completo della selezione: 4 modelli + CV + `last_fit`); nessun `model/final_fit.rds` esiste. Allineato il filo reload→live (cover/apertura/step00/chiusura Advanced + pre-hook Basic, fattuale) e fatta la passata piena di registro sulle slide 00. Nuovo `scripts/check_register.py` (em-dash/registro/reload) + test. Rebuild via `rebuild.R` (R 4.6.0) + `build_site.py`; `docs/` ricommittato. Branch `advanced-00-alignment`, **non pushato** ([[claude-never-pushes]]). Processo riusabile (checklist per-sezione + linter) nello spec/piano `2026-06-11-*`. **Prossimo:** propagare alle sezioni 01-04; correggere `04-targets/report.qmd` ("reloaded"); verifica globale di registro a fine progetto.
```

(Il vault è sincronizzato a parte: **non** fare `git` qui.)

---

## Self-review (eseguito in scrittura)

- **Spec coverage:** §4a→Task 2; §4b→Task 3; §4c→Task 4; §5→Task 5 (+ righe reload riscritte già pulite in Task 2); §6 checklist→processo riflesso nei task; §7 linter→Task 1; §8 build/DoD→Task 6 + vault Task 7; §3 deferred (04 report, sezioni 01-04, Basic registro)→File structure "Out of scope" + nota vault. Coperto.
- **Placeholder scan:** nessun TBD/TODO; ogni edit ha old/new completi; ogni step ha comando + atteso.
- **Type/consistency:** il linter usa `scan_text`/`scan_file`/`main` coerenti tra implementazione e test; le verifiche §Task richiamano `scripts/check_register.py` con gli stessi nomi.
- **Note:** le righe del deck sono indicate per numero; se il file è stato già editato e i numeri sono slittati, abbinare per testo `old` (univoco).
