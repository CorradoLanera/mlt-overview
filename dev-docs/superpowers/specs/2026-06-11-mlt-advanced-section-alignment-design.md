# Allineamento sezione 00 (banco di prova) + sweep registro — workshop Advanced

- **Data:** 2026-06-11
- **Modulo:** `mlt-r-advanced` (workshop 2 / modulo 3)
- **Stato:** design approvato a voce (decisioni §2), pronto per il piano
- **Tipo:** allineamento contenuto/forma + definizione di un processo riusabile per le sezioni successive

## 1. Problema

Il workshop Advanced apre con una promessa di **reload**: "riapriamo il modello validato in
Basic, non ricostruiamo nulla, niente retrain". Quella promessa **non corrisponde al codice**.
Lo step realmente generato (`workshops/mlt-r-advanced/steps/00-recap/00-recap.R`, versione
solved) ricostruisce dal vivo l'**intera** selezione di Basic: import `heart_failure.csv` →
wrangle → `tbl_summary` → split → recipe → fit logistico → `workflow_set` a 4 modelli
(penlog/knn/svm/rf) con CV 5-fold e `tune_grid` (grid 8) → finalize della RF → `last_fit` →
`final_fit` → curve ROC/PR → sanity-check su 1 riga → `torch_tensor(1)`. **Nessun `readRDS`.**
Non esiste alcuna cartella `model/`: il file `model/final_fit.rds` citato come "bundled" da
syllabus e README **non c'è**.

La narrazione di reload è quindi un *filo morto* che attraversa due workshop:

- **Basic deck** (pre-hook di chiusura): promette "Advanced reloads/reopens `final_fit` on day one".
- **Advanced deck**: cover → divider d'apertura → step 00 → payoff di chiusura, tutto "reopen / reload / never retrain / `readRDS(final_fit.rds)`".
- **Codice Advanced**: rebuild completo dal vivo.

La fonte di verità di "cosa fa lo studente" è `steps/NN/NN.R`, non il deck. Qui la narrazione
ha divergiato dal codice. Il fix è **allineare le parole al codice già implementato**, su tutto
il filo, non cambiare la pedagogia.

## 2. Decisioni (fissate)

1. **Scope live del 00:** replay completo della selezione di Basic, dal vivo. Il **codice non si
   tocca**; si muovono solo le parole.
2. **Registro:** passata piena sulle slide EN della sezione 00 (vedi regole §5).
3. **Pre-hook Basic:** correzione fattuale `reload → rebuild live` **ora** (2-3 righe del deck
   Basic), come micro-fix di coerenza del filo. NON si fa lo sweep di registro sul Basic (è
   workshop 1, va alla verifica globale).
4. **Propagazione:** la sezione 00 è il banco di prova; il processo (checklist §6 + linter §7) si
   propaga identico alle sezioni successive, una alla volta.

## 3. Scope

**Dentro (ora):**

- Filo `reload → live` nel deck Advanced: cover (L14), divider d'apertura (L81-100), step 00
  (L102-156), payoff di chiusura (L799-807).
- Sweep di registro sulle slide della **sezione 00** + le righe del filo toccate sopra.
- Sorgenti course-level che alimentano il sito e descrivono la premessa del 00: `syllabus.md`,
  `README.md`, `_manifest.yml`, `requirements.R`, `_authoring/00-recap/meta.yml`,
  `_authoring/00-recap/beat.R`.
- Pre-hook Basic (`slides/workshops/mlt-r-basic/00-basic-deck.qmd`, L1120 + L1160-1171):
  correzione **solo fattuale** `reload → rebuild live`.
- Definizione del **processo riusabile** (checklist §6) e del **linter di registro** (§7).
- Rebuild completo + verifica leggera + aggiornamento del vault.

**Fuori (rimandato, annotato):**

- Sweep di registro sulle sezioni 01-04 del deck e sul frame condiviso (cover/credits/thank-you):
  ai loro turni, una sezione alla volta.
- `_authoring/04-targets/report.qmd` L3/L45 ("*reloaded* Basic random forest"): correzione
  fattuale rimandata alla sezione 04 (annotata qui per non perderla).
- **Verifica globale di registro** (overview 10 capitoli + Basic + Advanced) col linter: **dopo**
  aver chiuso e servito il workshop 2. Lasciare un `- [ ]` nel vault.

## 4. Inventario superfici → testo bersaglio

Il sito (`docs/advanced.html`, `docs/schedule.html`) è **generato** da `scripts/build_site.py`:
la timeline prende le descrizioni dei passi dal campo `summary:` dei `meta.yml`, la pagina
Advanced da `syllabus.md` + sezioni del `README.md`. **Non** si edita `docs/`: si editano i
sorgenti e si ricostruisce.

### 4a. Deck Advanced — filo reload→live (fattuale + registro)

- **L14 cover:** `Advanced — Open the validated model: …` → `Advanced · Rebuild Basic's
  validated model, then go further: interpret it, go deep, reach an LLM, seal it`
- **L81 divider:** `# Open the model you validated in Basic` → `# Rebuild the model you
  validated in Basic`
- **L92-93:** togliere l'iperbole "is not the end — it is the **subject**"; "we **open** … not
  rebuild" → "we **rebuild** that validated random forest live, then push past it".
- **L95-98 bullet:** `— ` (label/descr.) → `: ` (`**Interpret it:** permutation VIMP …`).
- **L104 commento:** `Step 00 (demo, 12 min): reload …` → `Step 00 (~30 min): rebuild Basic's
  full selection live → final_fit; predict 1 row; pre-warm torch`.
- **L106 "Why first":** "doesn't rebuild anything — it **reopens** … Day one reloads that exact
  `final_fit`" → "starts by **rebuilding** the model you validated in Basic, live: we re-run that
  exact selection to land `final_fit` again".
- **L108 bullet:** `Reload … extract_workflow(readRDS("final_fit.rds"))` → `Rebuild Basic's
  selection live, then extract_workflow(final_fit) on the finalized random forest`.
- **L119 titolo:** `Live check — did the model reload, is torch warm?` → `Live check: is the
  model rebuilt, is torch warm?`
- **L123:** togliere "no retrain" (abbiamo appena fittato): "the live-fitted workflow predicts".
- **L131 titolo:** `GREEN — Basic's model, reopened (not retrained)` → `GREEN: Basic's model,
  rebuilt live`.
- **L135-137:** "the model is baked in, no `fit()`" / "`model/final_fit.rds` → `readRDS()`" →
  "`final_fit` came from the live selection we just ran" / "`extract_workflow(final_fit)`, the RF
  that won on `roc_auc`".
- **L139:** "Reload from the checkpoint" → "Re-run the selection block".
- **L146-151 Go to code:** "reload Basic's `final_fit`" → "rebuild Basic's selection live to
  `final_fit`"; "We never retrain — Advanced opens the model" → "We rebuild it live — Advanced
  re-derives the model Basic validated".
- **L799-807 payoff:** "Basic **promised** … Advanced would **reload** … we **reopened** … never
  retrained" → "Basic **built** the validated model; Advanced **re-derived it live** on day one
  and pushed past it". Note IT (L806-807) allineate.

(Note del docente in IT allineate ovunque dicano "ricarica/riapre/senza retrain".)

### 4b. Sorgenti course-level (premessa del 00 → sito)

- **`syllabus.md` L18 + L44:** togliere "reopen a validated … (bundled)" e "already-fitted random
  forest from `model/final_fit.rds` (bundled)" → "rebuilt live from `data-raw/heart_failure.csv`;
  nothing pre-fitted is bundled".
- **`README.md` L5/L30/L32/L84-86:** idem (via il riferimento all'rds inesistente).
- **`_manifest.yml` L6:** `dataset: "… (reloaded Basic model) …"` → drop di "(reloaded Basic model)".
- **`requirements.R` L8:** commento `reload the Basic RF` → `rebuild the Basic RF live`.
- **`_authoring/00-recap/meta.yml` L4:** `summary:` "Reopen the validated Basic random forest …"
  → "Rebuild Basic's validated random forest live and warm up the `torch` backend." (entra nella
  timeline/schedule del sito; `minutes: 30` resta).
- **`_authoring/00-recap/beat.R` L1:** commento "Sanity-check the **reloaded** Basic model …" →
  "… the model we just **rebuilt** live …".

### 4c. Pre-hook Basic (solo fattuale, niente registro)

- **`00-basic-deck.qmd` L1120:** "Advanced **reopens** on day one" → "Advanced **rebuilds live**
  on day one".
- **L1160 titolo:** `## Next: open the model — Advanced` → `## Next: rebuild the model — Advanced`
  (em-dash lasciato: registro del Basic rimandato al globale).
- **L1162:** "Advanced opens this very model:" → "Advanced rebuilds this very model, then extends it:".
- **L1168:** "Advanced **reloads** on day one" → "Advanced **rebuilds live** on day one".
- Note IT (L1171) allineate.

(Da verificare in implementazione: che `README.md`/`syllabus.md` del Basic non ripetano la stessa
promessa di reload; se sì, stessa correzione fattuale.)

## 5. Regole di registro (slide EN, da `CLAUDE.md` "Registro di scrittura")

- **Em-dash `—`:** nei **titoli** → `:`; nei **label** → `·` (separatore di casa, vedi "Step 00 ·
  Recap"); nel **corpo** → riscrittura, parentesi o punto. Mai lasciare `—`.
- **Niente auto-certificazioni:** via "honestly / truly / clearly / obviously / of course".
- **Niente iperbole / slogan / costruzioni a effetto:** es. "is not the end — it is the subject",
  "the punchline", "killer".
- **Niente intensificatori di riempimento:** "really / just / very / actually" quando non
  aggiungono informazione.
- **La precisione tecnica resta:** non annacquare il contenuto; i termini tecnici e i nomi di
  funzione/pacchetto non si toccano.

## 6. Processo riusabile per sezione (il deliverable del banco di prova)

Per ogni sezione `NN`, in ordine:

1. **Leggi la verità:** `workshops/mlt-r-advanced/steps/NN-slug/NN-slug.R` (cosa esegue davvero lo studente).
2. **Confronta:** le claim del deck (sezione `NN`) vs il codice; segna i drift (come reload-vs-rebuild).
3. **Allinea narrativa + note** del deck al codice.
4. **Aggiorna i derivati:** `_authoring/NN-slug/meta.yml` `summary:` (→ timeline sito) ed eventuali
   `report.qmd`/`_targets.R` con stringhe narrative.
5. **Sweep di registro** sulla sezione (regole §5).
6. **Rebuild + verifica leggera** (§8).
7. **Aggiorna il vault** (`progetti/mlt-overview/mlt-overview.md`, voce LIFO in "Stato corrente").

## 7. Linter di registro leggero

Uno script `scripts/check_register.py` (stdlib, deterministico, sul pattern di `parity.R` /
`check-masking.R`) che, dati path, segnala:

- em-dash `—` (U+2014) fuori dai blocchi codice;
- parole-bandiera del registro (lista §5, case-insensitive, word-boundary);
- termini reload residui ("reload", "reopen", "`final_fit.rds`", "never retrain") quando usati come
  claim narrativa.

Output: elenco `file:riga` con la categoria. Exit non-zero se trova hit (così è usabile come gate).
Uso: per-sezione durante il lavoro, e **una volta a tappeto** alla verifica globale di fine
progetto (overview + Basic + Advanced) — rende quella verifica un comando solo.

(Non è un riscrittore automatico: le sostituzioni di registro sono sensibili al contesto e restano
manuali. Lo script *segnala*, non *edita*.)

## 8. Build / Definition of Done

- `beat.R`/`meta.yml` modificati → rebuild step + solved (`/mlt-workshop-build mlt-r-advanced`).
- Deck modificato → re-render.
- `syllabus.md`/`README.md`/`meta.yml` → rebuild sito (`scripts/build_site.py`).
- Tutto incatenato da `/mlt-build` (`scripts/build_all.py`), **con R 4.6.0**:
  `$env:MLT_RSCRIPT="C:\Program Files\R\R-4.6.0\bin\Rscript.exe"` (col default R 4.5.2 `rebuild.R`
  fallisce `no package called 'quarto'`).
- **Verifica leggera:** build verde + le slide 00 + la pagina Advanced + la schedule mostrano il
  nuovo testo; nessun residuo di reload nella sezione 00 (linter §7 pulito sul perimetro toccato).
  Verifica grafica non enfatizzata (problema è forma/contenuto, non layout).
- **Vault:** voce LIFO in "Stato corrente"; `- [ ]` per la verifica globale di registro (scope:
  overview + Basic + Advanced, **dopo** aver servito il workshop 2).
- **Git:** commit separati per cambiamento logico (filo reload→live; sweep registro 00; pre-hook
  Basic; linter). Niente push (lo fa il docente).

## 9. Non-goal

- Non si cambia la pedagogia né il codice eseguito dal 00 (replay completo confermato).
- Non si fa lo sweep di registro fuori dalla sezione 00 (sezioni 01-04, frame condiviso, Basic):
  rimandato.
- Non si edita `docs/` a mano (è generato).
- Non si re-tagga né si ritocca la Release `coorte-2026` in questo giro.

## 10. Rischi

- **Timing del 00:** un replay completo live (4 modelli + CV) è più pesante del "12 min reload"
  citato. Si tiene `minutes: 30` (recap veloce di contenuto già visto in Basic), si corregge solo
  il commento del deck. Da ri-tarare se in aula sfora i 30 min.
- **Drift residuo non sul perimetro:** il linter §7 sul perimetro toccato mitiga; la coda completa
  resta per la verifica globale.
