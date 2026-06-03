# MLT repo reorg — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, with checkpoints) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Riordinare la struttura del repo (slides simmetriche `slides/course/`, master `course.qmd` coerente sorgente→pubblicato, ritiro `doc/`, pulizia `dev/`, fix bug `_brand.scss`, drop `data-raw/` ridondante negli ZIP) e riportare a bolla README/CLAUDE.md/vault/memoria — senza rompere build, sito, engine, skill, comandi, hook, test.

**Architecture:** Due fasi. **Fase 1** = commit indipendenti a rischio ~0 (rimozioni, fix generatore, allineamento doc). **Fase 2** = un commit atomico per il rename slides (folder + master + tutti i generatori/riferimenti in lockstep) e uno per il ritiro `doc/`. Gate di verifica (rigenerazione generatore, `pytest`, `quarto render`, `build_site.py`, QA visiva) prima dei commit di Fase 2. Branch: `repo-reorg` (già creato; FF-merge in `main` a fine lavoro, push solo dall'utente).

**Tech Stack:** Python 3 (stdlib + pytest), Quarto/revealjs, R engine `dev/mltbuild`, git. Spec di riferimento: `dev-docs/superpowers/specs/2026-06-04-mlt-repo-reorg-design.md`.

**Convenzioni:** un cambiamento logico per commit; nessun `git push`/`gh release upload` (li fa l'utente); QA visiva obbligatoria sugli HTML (chrome-devtools); riga vuota prima di ogni lista in `.md`.

---

## FASE 1 — Coerenza & pulizia (rischio ~0)

### Task 1: Finalizzare la rilocazione di `data/`

**Files:**
- Remove (git): `data/PubMed_Timeline_Results_by_Year.csv` (già cancellato su disco, deletion non in stage)
- Modify: `.claude/commands/mlt-scaffold.md` (togliere la menzione di `data/` come dir protetta)

- [ ] **Step 1: Verifica lo stato e che il CSV canonico esista nell'archivio**

```bash
git status --short data/
ls _archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv
```
Expected: ` D data/PubMed_Timeline_Results_by_Year.csv`; il file in `_archive/legacy-xaringan/data/` esiste (copia canonica).

- [ ] **Step 2: Stage la rimozione + rimuovi la dir vuota**

```bash
git rm data/PubMed_Timeline_Results_by_Year.csv
```
Se la dir `data/` resta vuota su disco, rimuovila: `rmdir data 2>$null` (PowerShell) — git non traccia dir vuote, ok se già sparita.

- [ ] **Step 3: Aggiorna `.claude/commands/mlt-scaffold.md`**

Apri il file, trova la riga ~8 che elenca `data/` tra le dir da non toccare (es. "do not touch ... img/, or data/"). Rimuovi il riferimento a `data/` (l'archivio ora ospita il CSV; `data/` non esiste più). Grep di conferma:
```bash
grep -n "data/" .claude/commands/mlt-scaffold.md
```
Expected dopo l'edit: nessun match a `data/` come dir-sorgente protetta.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/mlt-scaffold.md
git commit -m "chore: finalize data/ CSV relocation to _archive

The CSV now lives tracked at _archive/legacy-xaringan/data/; git rm the
old data/ path (half-done git mv) and drop the stale data/ mention from
mlt-scaffold.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Rimuovere lo scratch `dev/` superato

**Files:**
- Remove (git): `dev/00-setup.R`, `dev/esame.txt`

- [ ] **Step 1: Conferma che sono tracciati e non referenziati**

```bash
git ls-files dev/00-setup.R dev/esame.txt
grep -rn "00-setup.R\|esame.txt" scripts/ .claude/ dev/mltbuild/ README.md 2>/dev/null | grep -v "steps/00-setup"
```
Expected: entrambi tracciati; nessun riferimento (i match `steps/00-setup.R` sono altri file, ignorali).

- [ ] **Step 2: Rimuovi e committa**

```bash
git rm dev/00-setup.R dev/esame.txt
git commit -m "chore(dev): remove superseded pre-Quarto scratch

dev/00-setup.R = pre-Quarto xaringan renv bootstrap (superseded by per-module
renv + _archive/legacy-xaringan). dev/esame.txt = flat IT quiz, off-convention,
superseded by per-chapter course/*/items_valutativi. Both tracked-but-orphan.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Spostare il generatore label in `scripts/`

**Files:**
- Move (git): `dev/label-summative-arrows.py` → `scripts/label-summative-arrows.py`

- [ ] **Step 1: Sposta**

```bash
git mv dev/label-summative-arrows.py scripts/label-summative-arrows.py
```

- [ ] **Step 2: Verifica i path interni (CWD-relative, non vanno toccati)**

```bash
grep -n "Path(" scripts/label-summative-arrows.py
```
Expected: `SRC = Path("img/storyboard/sb-05_05.png")`, `OUT = Path("img/storyboard/sb-05_05_labeled.png")`, `DEBUG = Path("dev/sb-05_05_labeled_debug.png")` — tutti relativi alla CWD (root), corretti senza modifiche.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore(scripts): move storyboard-label generator out of dev

dev/label-summative-arrows.py is a tracked, hand-run generator of the committed
img/storyboard/sb-05_05_labeled.png (used in slides/chapters/05-deep-learning.qmd).
Move it next to the other generators in scripts/. CWD-relative paths unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Fix bug `_brand.scss` nel generatore deck

Il generatore emette `theme: [default, theme.scss]` (senza `../styles/_brand.scss`) → una rigenerazione del master perde il brand. TDD.

**Files:**
- Modify: `.claude/skills/lib/quartoyml.py:32`
- Test: `tests/skills/test_quartoyml.py:30-35`

- [ ] **Step 1: Aggiorna il test perché richieda il brand**

In `tests/skills/test_quartoyml.py`, dentro `test_master_has_revealjs_header_and_theme`, aggiungi dopo la riga `assert "theme:" in out and "theme.scss" in out`:
```python
    assert "../styles/_brand.scss" in out
```

- [ ] **Step 2: Esegui il test → deve FALLIRE**

```bash
python -m pytest tests/skills/test_quartoyml.py::test_master_has_revealjs_header_and_theme -v
```
Expected: FAIL (`../styles/_brand.scss` non presente nell'output del generatore).

- [ ] **Step 3: Fix del generatore**

In `.claude/skills/lib/quartoyml.py`, riga 32, sostituisci:
```python
        "    theme: [default, theme.scss]\n"
```
con:
```python
        "    theme: [default, ../styles/_brand.scss, theme.scss]\n"
```

- [ ] **Step 4: Esegui i test del generatore → PASS**

```bash
python -m pytest tests/skills/test_quartoyml.py -v
```
Expected: tutti PASS.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/lib/quartoyml.py tests/skills/test_quartoyml.py
git commit -m "fix(skills): generated master deck includes ../styles/_brand.scss

build_slides_master emitted theme: [default, theme.scss] without the shared
brand partial, so regenerating slides/slides.qmd silently dropped the deck
brand. Emit it (matches the committed master) and pin it with a test.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Drop della `data-raw/` top-level ridondante negli ZIP workshop

Ogni `steps/<NN>/` e `full/` portano già la propria `data-raw/` (`here()`-ancorata); la copia top-level nello ZIP è irraggiungibile. TDD.

**Files:**
- Modify: `scripts/build_workshop_zip.py:73`
- Test: `tests/skills/test_build_workshop_zip.py:163-183` (`test_student_payload_fragment_from_disk`)

- [ ] **Step 1: Aggiorna il test**

In `tests/skills/test_build_workshop_zip.py`, in `test_student_payload_fragment_from_disk`, sostituisci la riga:
```python
    assert "data-raw/heart_failure.csv" in rels
```
con:
```python
    assert "data-raw/heart_failure.csv" not in rels           # redundant top-level dropped
    assert "steps/00-setup/data-raw/heart_failure.csv" in rels  # per-step copy stays
```

- [ ] **Step 2: Esegui il test → deve FALLIRE**

```bash
python -m pytest "tests/skills/test_build_workshop_zip.py::test_student_payload_fragment_from_disk" -v
```
Expected: FAIL (oggi la `data-raw/` top-level È spedita).

- [ ] **Step 3: Modifica il payload**

In `scripts/build_workshop_zip.py`, riga 73, sostituisci:
```python
_FRAGMENT_TOP_DIRS = ("steps", "full", "data-raw")
```
con:
```python
_FRAGMENT_TOP_DIRS = ("steps", "full")
```

- [ ] **Step 4: Esegui la suite ZIP → PASS**

```bash
python -m pytest tests/skills/test_build_workshop_zip.py -v
```
Expected: tutti PASS (incluso `test_build_zip_ships_source_and_injects_deck`, che usa il path NON-fragment dove `data-raw` resta legittimo via git ls-files).

- [ ] **Step 5: Commit**

```bash
git add scripts/build_workshop_zip.py tests/skills/test_build_workshop_zip.py
git commit -m "refactor(zip): drop redundant top-level data-raw/ from fragment ZIPs

Each materialized steps/<NN>/ and full/ already carries its own data-raw/
(here()-anchored); the top-level copy in the shipped tree is unreachable
(the ZIP root is not an R project). Source-of-truth workshops/<slug>/data-raw/
and the per-step copies are untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Completare la "Repository map" del README

**Files:**
- Modify: `README.md:44-55`

- [ ] **Step 1: Aggiungi i bullet mancanti**

In `README.md`, nella sezione "## Repository map", aggiungi (mantenendo lo stile e l'ordine sensato; riga vuota già presente prima della lista):
```markdown
- `dev/` — build engine + author scratch: `dev/mltbuild/` (the tracked fragment-build engine) plus gitignored scratch (`dev/*.png`, `dev/release-assets/`).
- `img/` — shared figures and storyboard images consumed by the decks (referenced via relative paths from `slides/`).
- `tests/` — pytest suite for the repo tooling (`tests/hooks/`, `tests/skills/`).
```
e allarga il bullet `_archive`:
```markdown
- `_archive/` — frozen, reproducible pre-Quarto artifacts: `legacy-xaringan/` (the old deck, still the manifest `base_source`) and `legacy-portal/` (the old portal, rebuild hook disabled).
```
Non aggiungere alcun bullet `doc/` (verrà ritirata in Fase 2).

- [ ] **Step 2: Verifica**

```bash
grep -nE "^- \`(dev/|img/|tests/|_archive/)" README.md
```
Expected: i quattro bullet presenti.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): complete repository map (dev/, img/, tests/, _archive)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Riallineare `.claude/CLAUDE.md`

**Files:**
- Modify: `.claude/CLAUDE.md` (header spec ref, Strumenti, Stato build, Architettura)

- [ ] **Step 1: Header — puntatore spec**

Sostituisci la riga header `Rinnovazione: vedi dev-docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md.` con un riferimento al design-of-record corrente, es.:
```markdown
Rinnovazione: architettura unificata `dev-docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md` + riordino `dev-docs/superpowers/specs/2026-06-04-mlt-repo-reorg-design.md` (storico: `2026-05-26-mlt-course-toolkit-design.md`).
```

- [ ] **Step 2: Strumenti — inventario corretto**

Sostituisci i due bullet "Skill/command project-local" e "Hook" con:
```markdown
- Skill project-local: `mlt-narrative`, `mlt-objectives`, `mlt-subunits`, `mlt-quarto-build`, `mlt-pilot`.
- Command project-local: `/mlt` (orchestratore), `/mlt-scaffold`, `/mlt-build`, `/mlt-beat`, `/mlt-workshop-build`, `/mlt-dist` (deprecato → usa `/mlt-build`).
- Hook `md-to-html-math.py`: ogni `course/**/*.md` scritto → `.html` self-contained con matematica.
- Hook `remind-workshop-dist.py`: dopo Write/Edit in `workshops/**` ∨ `slides/workshops/**` ∨ `styles/_brand.scss`, ricorda di rilanciare `/mlt-build`.
```

- [ ] **Step 3: Stato build — realtà corrente**

Sostituisci il blocco "## Stato build" con:
```markdown
## Stato build

- Tutte le fasi completate e mergiate in `main` (2026-06-03): overview deck Quarto (10 cap.), item valutativi per capitolo, due workshop R (Basic+Advanced) fragment-built, sito Quarto pubblicato in `docs/`, dist ZIP + release assets. Build idempotente via `python scripts/build_all.py` (`/mlt-build`).
```

- [ ] **Step 4: Architettura — togli "da creare"**

Nella sezione "## Architettura (3 moduli)", cambia `**pratica advanced** (\`workshops/mlt-r-advanced/\`, da creare)` in `**pratica advanced** (\`workshops/mlt-r-advanced/\`)`.

- [ ] **Step 5: Verifica**

```bash
grep -n "da creare\|Fase 0 (fondazione)\|mlt-pilot\|remind-workshop-dist" .claude/CLAUDE.md
```
Expected: nessun "da creare", nessun "Fase 0 ... in corso"; presenti `mlt-pilot` e `remind-workshop-dist`.

- [ ] **Step 6: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "docs(claude): refresh build state, tool inventory, architecture

Stato build was stuck at 'Fase 0 in corso / A,B da fare' (all phases shipped &
merged); advanced marked 'da creare' (it is built); Strumenti omitted skill
mlt-pilot, four commands, and the remind-workshop-dist hook; header pointed only
at the 2026-05-26 toolkit spec.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Fix dei 3 file di memoria con `docs/superpowers/` errato

**Files:**
- Modify (non-git): `~/.claude/projects/c--Users-corra-github-cl-mlt-overview/memory/unified-course-architecture.md:12`, `advanced-build-state.md:10`, `r-workshops-design.md:10`

- [ ] **Step 1: Sostituisci `docs/superpowers/` → `dev-docs/superpowers/`**

In ciascuno dei tre file, cambia ogni occorrenza di `docs/superpowers/` in `dev-docs/superpowers/` (path già errati oggi, indipendenti dal reorg). Verifica:
```bash
grep -rn "docs/superpowers/" "C:/Users/corra/.claude/projects/c--Users-corra-github-cl-mlt-overview/memory/"
```
Expected dopo l'edit: nessun match (tutti diventati `dev-docs/superpowers/`).

- [ ] **Step 2: Nessun commit** — la cartella memory non è un repo git. (Verifica solo che i file siano salvati.)

---

### Task 9: Allineare il vault (repo separato — NO commit/push da Claude)

**Files:**
- Modify: `c:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md`

- [ ] **Step 1: Replace path engineering-doc**

Sostituisci nel file ogni `docs/superpowers/` → `dev-docs/superpowers/` e ogni `docs/sources/` → `dev-docs/sources/` (righe ~30, 65, 66, 67, 109, 110, 117–120). Verifica:
```bash
grep -nE "docs/(superpowers|sources)/" "c:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/mlt-overview.md"
```
Expected: nessun match residuo a `docs/superpowers/` o `docs/sources/`.

- [ ] **Step 2: Spunta la checklist statica e riconcilia le contraddizioni**

In `mlt-overview.md` (righe ~34–46), spunta come fatti Fase A, Fase B e W3 (Advanced fragment-build, FATTO 2026-06-03). Riconcilia L37 (storia-companion) con L116: la versione in uso è v2, skill canonica `itembank` (non `itembank-bloom`).

- [ ] **Step 3: Nuova voce datata**

In cima al log (LIFO), aggiungi una voce `2026-06-04 — Riordino strutturale repo` che riassume: rename `slides/chapters→slides/course`, `slides.qmd→course.qmd` (sorgente==pubblicato), ritiro `doc/`→vault, pulizia `dev/`, fix `_brand.scss`, drop `data-raw` ridondante ZIP, riallineamento README/CLAUDE.md/memoria. Linka `[[claude-never-pushes]]`.

- [ ] **Step 4: NON committare il vault** — è materiale privato in un repo separato; il commit/push lo fa l'utente. Segnala all'utente che il vault è aggiornato e pronto per il suo commit.

---

## FASE 2 — Rename strutturali (atomici, con gate)

### Task 10: Rename slides (`chapters→course`, `slides.qmd→course.qmd`) — UN commit atomico

> Questo è l'unico punto con blast-radius. Tutti gli edit vanno insieme, poi i gate, poi UN commit. Niente push.

**Files (modify/move):**
- `slides/chapters/` → `slides/course/` (git mv)
- `slides/slides.qmd` → `slides/course.qmd` (git mv) + includes
- `.claude/skills/lib/quartoyml.py` (includes 39–41 + docstring 1,4,8–9)
- `.claude/skills/lib/manifest.py:43` (+docstring 40)
- `tests/skills/test_quartoyml.py:24–25`
- `scripts/build_site.py:185,187,190,193,194,196`
- `scripts/build_release.py:27,40`
- `site/index.qmd:13`, `site/theory.qmd:5`
- `.claude/skills/mlt-quarto-build/SKILL.md:26,56–58,64,70`
- `.claude/skills/mlt-pilot/SKILL.md:21,54`
- `.gitignore:18,21–22`
- `tests/skills/test_remind_workshop_dist.py:33`
- doc/memoria: `mermaid-deck-font-race.md:23`, `closing-workshops.md:10`, `notes-gobbo-standard.md:10`, `MEMORY.md` (righe indice)
- Remove (git): `docs/slides/slides.html`, `docs/slides/slides_files/`

- [ ] **Step 1: git mv folder + master**

```bash
git mv slides/chapters slides/course
git mv slides/slides.qmd slides/course.qmd
```

- [ ] **Step 2: Includes in `slides/course.qmd` (ponte; il master è canonicamente rigenerato in GATE 1)**

Aggiorna gli include in `slides/course.qmd` da `chapters/` a `course/` (`chapters/_opening.qmd`→`course/_opening.qmd`, ogni `chapters/NN-*.qmd`→`course/NN-*.qmd`, `chapters/_closing.qmd`→`course/_closing.qmd`). Questo è un **ponte**: il master è un file *generato* e verrà rigenerato dal generatore in GATE 1 (autoritativo), quindi non fissare un conteggio qui. Verifica solo l'assenza di residui:
```bash
grep -c "include chapters/" slides/course.qmd
```
Expected: 0.

- [ ] **Step 3: `quartoyml.py` — SOLO i path-include (NON `m.get("chapters")`)**

Cambia righe 39–41:
```python
    parts = ["{{< include course/_opening.qmd >}}"]
    parts += [f"{{{{< include course/{s}.qmd >}}}}" for s in enabled_slugs(m)]
    parts.append("{{< include course/_closing.qmd >}}")
```
NON toccare riga 18 (`m.get("chapters", [])` = chiave-dati manifest). Aggiorna le prose docstring riga 1 (`slides/slides.qmd`→`slides/course.qmd`), righe 4,8–9 (`slides/chapters/<slug>.qmd`→`slides/course/<slug>.qmd`, `chapters/_opening.qmd`→`course/_opening.qmd`, `chapters/_closing.qmd`→`course/_closing.qmd`).

- [ ] **Step 4: `manifest.py` — sub-path slide**

Riga 43: `Path(slides_root) / "chapters"` → `Path(slides_root) / "course"`. Docstring riga 40: `<slides_root>/chapters/<slug>.qmd` → `<slides_root>/course/<slug>.qmd`. NON toccare l'iterazione sulla lista capitoli del manifest.

- [ ] **Step 5: `test_quartoyml.py`**

Righe 24–25: `chapters/01-a.qmd`→`course/01-a.qmd`, `chapters/03-c.qmd`→`course/03-c.qmd`. (Riga 27 usa il bare filename `01-a.qmd`/`03-c.qmd`: invariata.)

- [ ] **Step 6: `build_site.py`**

```python
# 185 docstring:
    """Render slides/course.qmd non-embed; copy html + _files into docs/slides/."""
# 187:
        _run(["quarto", "render", "slides/course.qmd", "--metadata-file", str(meta)], cwd=root)
# 190:
    src = root / "slides" / "course.html"
# 193:
    shutil.copy2(src, docs_slides / "course.html")
# 194:
    files = root / "slides" / "course_files"
# 196:
        shutil.copytree(files, docs_slides / "course_files", dirs_exist_ok=True)
```

- [ ] **Step 7: `build_release.py`**

```python
# 27:
    "theory":   "slides/course.qmd",
# 40:
        return root / "slides" / "course.html"
```

- [ ] **Step 8: Link del sito**

`site/index.qmd:13` e `site/theory.qmd:5`: `slides/slides.html` → `slides/course.html` (il path è relativo a `docs/`, e `build_site.py` ora pubblica `docs/slides/course.html`).

- [ ] **Step 9: Skill SKILL.md**

`.claude/skills/mlt-quarto-build/SKILL.md`: riga 56–58 (write + render) `slides/slides.qmd`→`slides/course.qmd` (CRITICO: evita la resurrezione); righe 26,64,70 `slides/chapters/<slug>.qmd`→`slides/course/<slug>.qmd` e `slides/slides.qmd`→`slides/course.qmd`. `.claude/skills/mlt-pilot/SKILL.md`: riga 21 `slides/chapters/<slug>.qmd`→`slides/course/<slug>.qmd`; riga 54 `slides/slides.qmd`→`slides/course.qmd`.

- [ ] **Step 10: `.gitignore`**

Riga 18: `slides/slides.html` → `slides/course.html`. Righe 21–22: `slides/chapters/*.html`→`slides/course/*.html`, `slides/chapters/*_files/`→`slides/course/*_files/`. (Riga 19 `slides/*_files/` copre già `slides/course_files/`.)

- [ ] **Step 11: Igiene test + memoria**

`tests/skills/test_remind_workshop_dist.py:33`: `slides/slides.qmd`→`slides/course.qmd`. Memoria (non-git): `mermaid-deck-font-race.md:23` (`slides/slides.qmd`+`slides/chapters/`→`slides/course.qmd`+`slides/course/`), `closing-workshops.md:10` (`slides/chapters/10-best-practices.qmd`→`slides/course/10-best-practices.qmd`), `notes-gobbo-standard.md:10` (`slides/chapters/`→`slides/course/`), e le righe indice di `MEMORY.md` che citano questi path.

- [ ] **Step 12: Rimuovi il deck pubblicato vecchio**

```bash
git rm docs/slides/slides.html
git rm -r docs/slides/slides_files
```

- [ ] **GATE 1 — Rigenerazione canonica del master + idempotenza**

Il master è un file *generato*: rigeneralo dal generatore (ora corretto) così è canonico, poi verifica che sia corretto e idempotente:
```bash
python -c "import sys; sys.path.insert(0,'.claude/skills/lib'); import quartoyml, manifest; open('slides/course.qmd','w',encoding='utf-8').write(quartoyml.build_slides_master(manifest.load()))"
python -c "import sys; sys.path.insert(0,'.claude/skills/lib'); import quartoyml, manifest; s=quartoyml.build_slides_master(manifest.load()); print('CHAPTERS_LEFT', s.count('include chapters/')); print('COURSE_INCLUDES', s.count('include course/')); print('BRAND', s.count('../styles/_brand.scss'))"
git diff --stat slides/course.qmd
```
Expected: `CHAPTERS_LEFT 0`; `COURSE_INCLUDES` = (capitoli con `include:true` nel manifest) + 2 (opening/closing); `BRAND 1`. La doppia generazione identica prova l'idempotenza → nessuna resurrezione del nome vecchio, nessun brand perso. `git diff` mostra solo le modifiche attese (include `course/` + eventuale riga brand).

- [ ] **GATE 2 — pytest**

```bash
python -m pytest tests/ -q
```
Expected: tutto verde.

- [ ] **GATE 3 — render + QA visiva**

```bash
quarto render slides/course.qmd
```
Expected: produce `slides/course.html` + `slides/course_files/` senza errori. Poi **QA visiva** (chrome-devtools): apri `slides/course.html`, verifica su 2–3 slide che il brand (arancio/teal) sia applicato e la matematica renderizzi.

- [ ] **GATE 4 — sito**

```bash
python scripts/build_site.py
ls docs/slides/course.html
ls docs/slides/slides.html 2>$null
grep -n "slides/course.html" docs/index.html docs/theory.html
```
Expected: `docs/slides/course.html` esiste; `docs/slides/slides.html` NON esiste; i due `docs/*.html` linkano `slides/course.html`. QA visiva: pulsante "Open slides" del portale apre il deck.

- [ ] **Step 13: Commit atomico**

```bash
git add -A
git status   # rivedi: solo i file attesi (slides/course*, generatori, scripts, site, docs rigenerati, .gitignore, tests)
git commit -m "refactor(slides): rename chapters/->course/ and slides.qmd->course.qmd

Symmetric slides/<module>/ (slides/course mirrors course/, slides/workshops
mirrors workshops). Master renamed to course.qmd; source==published everywhere
(docs/slides/course.html), no slides.html drift. Generators (quartoyml.py write
+ manifest.py probe), build_site/build_release, site links, .gitignore, skill
docs and tests updated in lockstep; old docs/slides/slides.html removed.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Ritirare `doc/` (PDF nel vault)

**Files:**
- Move (filesystem): `doc/BM_Lanera.pdf`, `doc/Offerta Formativa 2025-2026_…_Lanera.pdf` → `obsidian-vault/progetti/mlt-overview/reference/`
- Remove (git): `doc/.gitignore`
- Modify (non-git): memoria `offerta-formativa-official-facts.md:10`

- [ ] **Step 1: Sposta i PDF nel vault**

```bash
New-Item -ItemType Directory -Force "c:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/reference" | Out-Null
Move-Item "doc/BM_Lanera.pdf" "c:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/reference/"
Move-Item "doc/Offerta Formativa 2025-2026_Medicina Specialistica Traslazionale GB Morgagni_ITA_Lanera.pdf" "c:/Users/corra/github/cl/obsidian-vault/progetti/mlt-overview/reference/"
```
(I PDF sono gitignorati: lo spostamento è invisibile a git.)

- [ ] **Step 2: Rimuovi la dir dal repo**

```bash
git rm doc/.gitignore
rmdir doc 2>$null
```

- [ ] **Step 3: Aggiorna la memoria**

`offerta-formativa-official-facts.md:10`: cambia il prefisso path da `doc/Offerta Formativa …pdf` alla nuova sede vault `progetti/mlt-overview/reference/Offerta Formativa …pdf`.

- [ ] **Step 4: Verifica e commit**

```bash
git status --short
test ! -e doc && echo "doc/ removed"
git commit -m "chore: retire doc/ (personal PDFs moved to private vault)

doc/ held only a one-line .gitignore plus two gitignored personal PDFs (CV +
official Offerta Formativa), with zero build references and a name colliding
with docs/ (the Pages site). PDFs relocated to the private vault.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Ripubblicazione (build locale + handoff all'utente)

> Nessun `git push`/`gh release upload` da Claude: si preparano gli asset in locale e si consegnano i comandi.

**Files:** nessuna modifica sorgente; rigenera artefatti.

- [ ] **Step 1: Rebuild completo + release assets (locale)**

```bash
python scripts/build_all.py --release
```
Expected: rigenera workshop trees → decks → ZIP → `dev/release-assets/` (3 deck + 4 ZIP) → `docs/`. Verifica che `dev/release-assets/mlt-overview-theory-deck.html` sia stato ri-renderizzato da `slides/course.qmd`.

- [ ] **Step 2: QA finale del sito**

QA visiva (chrome-devtools) su `docs/index.html` e `docs/slides/course.html`: pulsante "Open slides" funziona, brand ok. `git status` pulito (gli artefatti gitignorati non compaiono).

- [ ] **Step 3: Commit `docs/` rigenerato (se cambia oltre Task 10)**

Se `build_all.py` ha aggiornato altri file in `docs/` (es. timeline/syllabi), committa:
```bash
git add docs/
git commit -m "build(site): rebuild docs after structural reorg

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 4: Handoff all'utente (azioni esterne)**

Fornisci all'utente i comandi esatti da eseguire LUI:
```bash
git checkout main && git merge --ff-only repo-reorg
git push
gh release upload coorte-2026 \
  dev/release-assets/mlt-overview-theory-deck.html \
  dev/release-assets/mlt-r-basic-deck.html \
  dev/release-assets/mlt-r-advanced-deck.html \
  dev/release-assets/mlt-r-basic.zip dev/release-assets/mlt-r-basic-teacher.zip \
  dev/release-assets/mlt-r-advanced.zip dev/release-assets/mlt-r-advanced-teacher.zip \
  --clobber
```
Poi aggiorna la memoria `final-revision-state` con il nuovo stato (riordino fatto; eventuale upload eseguito).

---

## Note di rollback

- Fase 1: ogni Task è un commit indipendente, revertabile singolarmente (`git revert <sha>`).
- Fase 2 Task 10 è atomico: un solo `git revert` ripristina tutti i path vecchi in lockstep.
- Branch `repo-reorg`: se qualcosa va storto prima del merge, `git checkout main` lascia `main` intatto.
- I gate (rigenerazione, pytest, render, build_site) precedono il commit di Task 10: non si committa con build rotta.
