# Riordino strutturale `mlt-overview` — design

- **Data:** 2026-06-04
- **Stato:** approvato (design), in attesa di piano d'esecuzione
- **Tipo:** refactor strutturale + allineamento documentale (no nuove feature)
- **Origine:** audit read-only a ventaglio (10 agenti) del 2026-06-04; richiesta utente di "sistemata" precisa e sicura, vault incluso.

## 1. Contesto e motivazione

Il repo è funzionalmente coerente (build, engine `dev/mltbuild`, contenuti, sito), ma porta tre attriti di leggibilità e alcune derive di documentazione:

- **Asimmetria slide/contenuto.** Le dir-contenuto sono `course/` (teoria) e `workshops/` (pratica). Le slide sono `slides/chapters/` (teoria) e `slides/workshops/` (pratica): la cartella-workshop combacia col contenuto, quella-teoria no. Il master `slides/slides.qmd` sta "fuori" con nome ambiguo (master? capitolo?).
- **Collisione `doc/` vs `docs/`.** `doc/` (singolare) ospita due PDF personali gitignorati (CV + Offerta Formativa) e zero riferimenti di build; `docs/` (plurale) è il sito Pages. Differiscono per un carattere.
- **Scratch stantio tracciato.** `dev/00-setup.R` (bootstrap renv xaringan pre-Quarto) ed `dev/esame.txt` (quiz IT fuori-convenzione) sono tracciati ma orfani; `data/` è vuota con un `git mv` lasciato a metà.
- **Derive documentali.** README ("Repository map" incompleta), `.claude/CLAUDE.md` ("Stato build" stantio, inventario Strumenti incompleto, "advanced da creare"), vault (`docs/superpowers/`→`dev-docs/` non propagato in ~8 punti), 3 file di memoria con path `docs/superpowers/` già errati oggi.
- **Bug latente.** Il generatore `quartoyml.build_slides_master` emette `theme: [default, theme.scss]` **senza** `../styles/_brand.scss`; il `slides.qmd` committato invece lo include. Una rigenerazione perde il brand del deck.
- **Ridondanza ZIP workshop.** Lo ZIP fragment-built spedisce una `data-raw/` top-level *oltre* alla copia che ogni `steps/<NN>/` e `full/` già contengono. La root dello ZIP non è un progetto R (niente `.Rproj`/`.here`), quindi quella copia è irraggiungibile via `here()` e inutile per lo studente.

## 2. Obiettivi e non-obiettivi

**Obiettivi**

- Rendere simmetrico `slides/<modulo>/` rispetto alle dir-contenuto.
- Disambiguare il master deck e ritirare la collisione `doc/`.
- Eliminare lo scratch tracciato e finalizzare il `git mv` di `data/`.
- Riportare "a bolla" README, `.claude/CLAUDE.md`, vault e memoria.
- Correggere il bug `_brand.scss` del generatore.
- Non rompere build, sito, engine, skill, comandi, hook, test.

**Non-obiettivi (e perché)**

- **Non** unificare `dist/` + `dev/release-assets/`: ruoli distinti (output ZIP canonico vs staging d'upload per-cohort), entrambi gitignorati; i 4 ZIP byte-identici sono una copia-per-upload voluta. Unificazione = rischio per valore ~nullo.
- **Non** fondere `styles/_brand.scss` con `site/_brand.scss`: sono brand distinti (deck vs sito), variabili diverse. Il claim del README ("usato da ogni deck") è verificato vero.
- **Non** introdurre una dir `modules/` (vincolo deciso e mergiato).
- **Non** rinominare `dev/` o `dev/mltbuild` (engine load-bearing, nome accettabile).

> **Decisione rivista (utente, 2026-06-04):** niente disaccoppiamento sorgente↔pubblicato. `course.qmd` deve produrre e pubblicare `course.html` *ovunque*; si aggiornano i link del sito e si rimuove il vecchio `docs/slides/slides.html`. Generare `slides.html` da `course.qmd` è drift permanente: vietato.

## 3. Decisioni di naming (finali)

| Da | A | Output renderizzato | Pubblicato |
|----|----|---------------------|------------|
| `slides/chapters/` | `slides/course/` | — | — |
| `slides/slides.qmd` | `slides/course.qmd` | `slides/course.html` + `slides/course_files/` | `docs/slides/course.html` + `docs/slides/course_files/` |

`slides/course.qmd` (file) convive con `slides/course/` (dir): il deck "course" assemblato dalle sue parti `course/`.

**Coerenza sorgente→pubblicato (richiesta esplicita).** Niente nomi diversi tra sorgente e output: `course.qmd` produce e pubblica `course.html` ovunque. Conseguenze: si aggiornano i 2 link del sito (`site/index.qmd`, `site/theory.qmd`), le DEST in `build_site.py`, e si rimuove il vecchio `docs/slides/slides.html` committato. L'URL Pages del deck cambia: `…/slides/slides.html` → `…/slides/course.html`. (L'asset GitHub Release del deck-teoria resta `mlt-overview-theory-deck.html`: nome distributivo della famiglia `*-deck.html`, voluto, non drift.)

## 4. Mappa blast-radius (riferimenti load-bearing)

Tutte le righe seguenti **devono** cambiare in lockstep, o la build si rompe / un generatore "resuscita" il nome vecchio. Numeri di riga dall'audit 2026-06-04 (da riconfermare al momento dell'edit).

### 4.1 `slides/chapters/` → `slides/course/`

| File | Riga | Meccanismo | Azione |
|------|------|-----------|--------|
| `slides/slides.qmd` (→`course.qmd`) | 12–23 | quarto-include | 13 `{{< include chapters/… >}}` → `course/…` |
| `.claude/skills/lib/quartoyml.py` | 39–41 | generator (write) | tre literal `chapters/` → `course/` |
| `.claude/skills/lib/quartoyml.py` | 4, 8–9, 26 | docstring/commenti | aggiorna prosa |
| `.claude/skills/lib/manifest.py` | 43 | probe esistenza | `Path(slides_root)/"chapters"` → `"course"` |
| `.claude/skills/lib/manifest.py` | 40 | docstring | aggiorna |
| `tests/skills/test_quartoyml.py` | 24–25 | assert | `chapters/` → `course/` |
| `.gitignore` | 21–22 | gitignore | `slides/chapters/*.html`,`*_files/` → `slides/course/…` |
| `.claude/skills/mlt-quarto-build/SKILL.md` | 26, 64, 70 | doc-mention | `slides/chapters/` → `slides/course/` |
| `.claude/skills/mlt-pilot/SKILL.md` | 21 | doc-mention | aggiorna path detection |

### 4.2 `slides/slides.qmd` → `slides/course.qmd`

| File | Riga | Meccanismo | Azione |
|------|------|-----------|--------|
| `scripts/build_site.py` | 187 | render src | `slides/slides.qmd` → `slides/course.qmd` |
| `scripts/build_site.py` | 190 | read | `slides/slides.html` → `slides/course.html` |
| `scripts/build_site.py` | 194 | read | `slides/slides_files` → `slides/course_files` |
| `scripts/build_site.py` | 193 | write DEST | `docs/slides/slides.html` → `docs/slides/course.html` |
| `scripts/build_site.py` | 196 | write DEST | `docs/slides/slides_files` → `docs/slides/course_files` |
| `scripts/build_site.py` | 185 | docstring | aggiorna |
| `scripts/build_release.py` | 27 | `_DECK_SRC["theory"]` | `slides/slides.qmd` → `slides/course.qmd` |
| `scripts/build_release.py` | 40 | read | `slides/slides.html` → `slides/course.html` |
| `site/index.qmd` | 13 | url-link | `slides/slides.html` → `slides/course.html` |
| `site/theory.qmd` | 5 | url-link | `slides/slides.html` → `slides/course.html` |
| `.claude/skills/mlt-quarto-build/SKILL.md` | 56–58 | write+render | entrambi `slides/slides.qmd` → `slides/course.qmd` (CRITICO: altrimenti ricrea il file vecchio) |
| `.gitignore` | 18 | gitignore | `slides/slides.html` → `slides/course.html` (riga 19 `slides/*_files/` copre già `course_files`) |
| `.claude/skills/lib/quartoyml.py` | 1 | docstring | aggiorna |
| `.claude/skills/mlt-pilot/SKILL.md` | 54 | doc-mention | aggiorna |
| `tests/skills/test_remind_workshop_dist.py` | 33 | literal (negativo) | igiene: `slides/slides.qmd` → `slides/course.qmd` |

**Pulizia del pubblicato:** `git rm docs/slides/slides.html` e `git rm -r docs/slides/slides_files/` (vecchio deck committato); il rebuild `build_site.py` genera `docs/slides/course.html` + `docs/slides/course_files/`. I `docs/index.html` e `docs/theory.html` si rigenerano da soli col link nuovo. L'elenco completo dei riferimenti al nome pubblicato (audit 2026-06-04, agente slides-master) è: `site/index.qmd`, `site/theory.qmd`, `docs/index.html`, `docs/theory.html`, `docs/slides/slides.html`, cache `site/.quarto/` (auto), `_archive/legacy-portal/` (morto) — nessun altro.

### 4.3 Bug `_brand.scss` nel generatore (indipendente dal rename)

`.claude/skills/lib/quartoyml.py` — `build_slides_master` deve emettere `theme: [default, ../styles/_brand.scss, theme.scss]` (oggi manca `../styles/_brand.scss`). Aggiungere asserzione in `tests/skills/test_quartoyml.py`.

### 4.4 `doc/` → vault

- Spostare `doc/BM_Lanera.pdf` e `doc/Offerta Formativa 2025-2026_…_Lanera.pdf` in `obsidian-vault/progetti/mlt-overview/reference/` (filesystem move; i PDF sono gitignorati).
- `git rm doc/.gitignore`; rimuovere la dir `doc/`.
- Memoria `offerta-formativa-official-facts.md:10`: path → nuova sede vault.
- Prosa opzionale: `dev-docs/superpowers/specs/2026-06-03-mlt-final-revision-design.md:44`, `…/2026-05-31-unified-course-architecture-design.md:132`.

### 4.5 ZIP workshop: non spedire la `data-raw/` top-level ridondante

| File | Riga | Azione |
|------|------|--------|
| `scripts/build_workshop_zip.py` | 73 | `_FRAGMENT_TOP_DIRS = ("steps", "full", "data-raw")` → `("steps", "full")` |
| `tests/skills/test_build_workshop_zip.py` | 171 | `assert "data-raw/heart_failure.csv" in rels` → `not in rels`; aggiungi `assert "steps/00-setup/data-raw/heart_failure.csv" in rels` (la copia per-step resta) |

**Resta invariato** (sorgente-di-verità e self-containment Model C): `workshops/<slug>/data-raw/` tracciato (`config.R:42-45`), e le copie per-step/`full/` materializzate da `materialize.R:80,89`. Cambia *solo* il payload spedito: lo studente riceve i dati dentro ogni step e in `full/`, non più una copia top-level orfana. La riga `README.md:76` ("`data-raw/` è tracciato") descrive il **repo sorgente** e resta corretta.

## 5. Piano per fasi

### Fase 1 — Coerenza & pulizia (rischio ~0, nessun rename)

Commit separati (un cambiamento logico ciascuno):

1. **`chore: finalize data/ CSV relocation`** — `git rm data/PubMed_Timeline_Results_by_Year.csv`; rimuovi dir `data/`; togli la menzione `data/` da `.claude/commands/mlt-scaffold.md:8`.
2. **`chore(dev): remove superseded pre-Quarto scratch`** — `git rm dev/00-setup.R dev/esame.txt`.
3. **`chore(scripts): move storyboard-label generator out of dev`** — `git mv dev/label-summative-arrows.py scripts/`. Verificato: i path interni (righe 18-20) sono CWD-relative, restano corretti eseguendo dalla root → lo spostamento non cambia comportamento. Il PNG di debug continua a finire in `dev/` (gitignorato): ok.
4. **`fix(skills): generator emits ../styles/_brand.scss theme`** — fix §4.3 + test.
5. **`docs(readme): complete repository map`** — README "Repository map": aggiungi `dev/`, `img/`, `tests/`; allarga `_archive/` (anche `legacy-portal/`); niente bullet `doc/` (ritirata).
6. **`docs(claude): refresh build state + tool inventory`** — `.claude/CLAUDE.md`: riscrivi "Stato build"; togli "advanced da creare"; correggi "Strumenti" (skill `mlt-pilot`; comandi `mlt-build/mlt-beat/mlt-dist/mlt-workshop-build`; hook `remind-workshop-dist.py`); aggiorna puntatore spec di riferimento (includi questo spec).
7. **Vault (`obsidian-vault`, repo separato — commit a cura utente)** — replace `docs/superpowers/`→`dev-docs/superpowers/` e `docs/sources/`→`dev-docs/sources/` (L30,65,66,67×2,109,110×2,117–120); spunta checklist L34–46 (Fase A/B + W3 fatti); riconcilia L37↔L116 (storia-companion v2, skill `itembank`); nuova voce datata "riordino strutturale".
8. **Memoria (`~/.claude/.../memory`, non-git)** — fix dei 3 path già errati: `unified-course-architecture.md:12`, `advanced-build-state.md:10`, `r-workshops-design.md:10` → `dev-docs/superpowers/`.
9. **`refactor(zip): drop redundant top-level data-raw/ in fragment workshops`** — applica §4.5 + test. Indipendente dai rename; cambia il payload degli ZIP → vedi §9 (ripubblicazione).

### Fase 2 — Rename strutturali (atomici, con gate)

**Commit A — `refactor(slides): chapters/→course/ + slides.qmd→course.qmd`**

- `git mv slides/chapters slides/course` + `git mv slides/slides.qmd slides/course.qmd`.
- Applica tutta la §4.1 e §4.2.
- Aggiorna in lockstep i riferimenti slide in doc/memoria/vault: `.claude/CLAUDE.md` (se cita slide path), memoria `mermaid-deck-font-race.md:23`, `closing-workshops.md:10`, `notes-gobbo-standard.md:10`, righe indice `MEMORY.md`, e i path slide verificati-accurati nel vault.

**Commit B — `chore: retire doc/ (PDFs to private vault)`** — applica §4.4.

### Ordine doc vs rename

I fix documentali che **non** toccano i path slide stanno in Fase 1. I riferimenti ai path slide (in `.claude/CLAUDE.md`, vault, memoria) si aggiornano **dentro** il commit A, in lockstep col `git mv`, per non lasciare stato intermedio incoerente.

## 6. Gate di verifica (Fase 2, prima di ogni commit)

1. **Sync generatore↔file:** rigenera `course.qmd` via `quartoyml.build_slides_master(manifest.load())` e conferma che produce include `course/` **e** la riga `../styles/_brand.scss` (prova: niente resurrezione del nome, niente brand perso).
2. `quarto render slides/course.qmd` ok + **QA visiva** chrome-devtools su 2–3 slide (brand presente) — obbligo CLAUDE.md.
3. `pytest tests/` verde.
4. `python scripts/build_site.py` → `docs/slides/course.html` apre, branded, e il pulsante "Open slides" del portale punta a `course.html`; nessun `docs/slides/slides.html` residuo; eventuale `build_all.py` end-to-end.
5. `git status` pulito salvo modifiche volute.

## 7. Rischi e rollback

- **Resurrezione del nome vecchio:** mitigata dal gate 1 (rigenerazione) e dall'edit di `mlt-quarto-build/SKILL.md:56-58`.
- **Brand perso al render:** mitigato dal fix §4.3 + gate 1/2.
- **Numeri di riga shiftati** rispetto all'audit: ogni edit ri-verifica il contesto prima di applicare (grep del literal, non riga cieca).
- **Rollback:** Fase 1 e i due commit di Fase 2 sono indipendenti e revertabili singolarmente; nessun push (lo fa l'utente).

## 8. Cosa resta invariato (riassunto)

`course/`, `workshops/`, `site/`, `docs/` (come dir), `dev-docs/`, `img/`, `styles/`, `dev/mltbuild/`, `_archive/`, `dist/`, `dev/release-assets/`, gli URL/asset GitHub Release (`*-deck.html`, `*.zip` invariati), gli hook e i comandi (a parte le doc-mention). **Cambia** solo l'URL Pages del deck-teoria: `…/slides/slides.html` → `…/slides/course.html`.

## 9. Continuità Release/Pages e ripubblicazione

Cosa cambia negli artefatti distribuiti e perché **nessun link si rompe** se si sequenzia bene:

| Artefatto | Cambia? | Link/URL a rischio? |
|-----------|---------|---------------------|
| Pages — deck teoria | `docs/slides/slides.html` → `course.html` | solo bookmark all'URL grezzo vecchio; il pulsante "Open slides" è aggiornato in lockstep → continuità interna garantita |
| Release — ZIP workshop | sì **solo** col fix §4.5 (lo slides-rename non li tocca) | **no**: il *nome* asset (`mlt-r-*.zip`) non cambia → `releases/latest/download/<nome>` regge |
| Release — 3 deck `.html` | deck-teoria ri-renderizzato (stesso nome `mlt-overview-theory-deck.html`) | **no**: nomi invariati |

**Invariante di continuità:** i *nomi* degli asset Release non cambiano mai → i pulsanti di download del sito (`releases/latest/download/<nome>`) e le `use_course()` reggono per costruzione. Cambia solo l'URL Pages del deck, gestito aggiornando il pulsante del portale.

**Sequenza di ripubblicazione (in coda al riordino):**

1. completare Fase 1 + Fase 2;
2. `python scripts/build_all.py --release` (rigenera deck + ZIP + `docs/`) — eseguibile da Claude;
3. **utente:** `gh release upload coorte-2026 <asset…> --clobber` + `git push` di `main` — azioni verso l'esterno, mai automatiche. Claude prepara gli asset in locale e fornisce i comandi esatti.

Poiché c'è già un upload PENDING (memoria `final-revision-state`), questa diventa l'**unica** ripubblicazione: nuovi contenuti sotto nomi stabili, zero discontinuità. La memoria `final-revision-state` va aggiornata con l'eventuale nuovo comando/asset list dopo il riordino.
