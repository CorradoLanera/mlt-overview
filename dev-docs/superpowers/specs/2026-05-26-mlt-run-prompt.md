# Prompt finale — esecuzione pipeline corso MLT

> **Uso:** dopo che gli strumenti del toolkit sono stati costruiti (vedi `2026-05-26-mlt-course-toolkit-design.md`),
> apri una **nuova sessione** di Claude Code con cwd = `c:\Users\corra\github\cl\mlt-overview`
> e incolla il blocco qui sotto. È volutamente conciso: i dettagli stanno nel `CLAUDE.md` del repo e nelle skill.

---

## Blocco da incollare

```
Lavoriamo al rinnovamento del corso MLT in questo repo. Tutto il comportamento (convenzioni di lingua,
naming, matematica, manifest) è nel CLAUDE.md del repo e nelle skill project-local: rispettali.

Prima di iniziare, in quest'ordine:
1. Verifica che la skill invocabile sia `storia-companion:itembank` (NON `itembank-bloom`); se è la v1, fermati e dimmelo.
2. Apri `course/_manifest.yml` e mostrami i capitoli con `include: true`, i minuti e quali fasi sono già fatte
   (esistenza di objectives/narrative/subunits/storyboard/items per capitolo). Dammi un quadro prima di agire.

Poi procediamo con l'orchestratore `/mlt`, una FASE alla volta, fermandoti al gate di conferma tra una e l'altra:

- FASE objectives  → per ogni capitolo abilitato: 2-4 obiettivi osservabili + 1 esercizio sommativo LIVE in aula
  DUALE (presenza+remoto), con la matrice di modalità (azione in presenza / equivalente remoto / artefatto
  condiviso / timing / criterio di riuscita). Coerenza via assessment-reviewer.
- FASE narrative   → spine globale (6 parole + 100 parole 3-atti + arco) e, per capitolo: 6 parole, 100 parole,
  arco hook-sfida-risoluzione-payoff + PRE-HOOK esplicito verso il capitolo successivo abilitato.
- FASE subunits    → solo sui capitoli che ti indico: sotto-unità con mini-arco + esercizio formativo proposto→risolto.
- FASE storyboard  → 6 riquadri per unità (Funzione/Visual/Testo a video/Voce docente).
- FASE items       → item bank con `itembank` v2, UNO alla volta: genera → scrivi item_NN_<slug>_<type>.md + .html →
  FERMATI e chiedimi conferma su coerenza/livello cognitivo/chiarezza. Su "procedi": RILEGGI il .md dal disco
  (potrei averlo editato a mano), aggiorna .md+.html, dedup degli obiettivi già coperti, prossimo item.
  A fine capitolo consolida items_valutativi.md + .html. Tutto in INGLESE, niente tranelli, niente dettagli marginali.
- FASE syllabus    → bozza syllabus 7 sezioni + policy IA (syllabus-2p), poi revisione POV-studente (studente-confuso):
  segnala vaghezze/burocratese/incoerenze obiettivi-valutazione/gergo, senza riscrivere.

Convenzioni non negoziabili:
- artefatti studenti in INGLESE; note docente / voce del docente / commenti di design in ITALIANO.
- ogni formula/pedice/overline in $...$ (l'HTML deve renderizzare la matematica).
- riga vuota prima di ogni lista nei .md.
- rubriche: 3 livelli base/good/excellent, descrittori osservabili.
- verifica visiva di ogni HTML renderizzato (chrome-devtools) prima di dichiararlo pronto.
- aggiorna la nota "Stato corrente" (LIFO, voce nuova in cima) in progetti/mlt-overview/ a fine di ogni fase.

Quando i contenuti sono pronti, FASE B tecnica:
- `/mlt --phase quarto` → migrazione xaringan→Quarto + _quarto.yml dal manifest (solo capitoli include:true) + tema SCSS.
- verifica visiva delle slide (chrome-devtools, 1080p + viewport stretto, overflow/taglio).
- export PDF per studenti (chrome-headless-shell).

Lavora a capitolo pilota prima (01-introduction) per validare la catena, poi propagagli il resto.
Non procedere oltre un gate senza il mio OK.
```

---

## Varianti rapide

- **Solo un capitolo:** sostituisci con `/mlt --chapter 03-algorithm-examples`.
- **Solo una fase su tutti:** `/mlt --phase narrative`.
- **Aggiungere/togliere un modulo:** edita `include:` in `course/_manifest.yml`, poi rilancia la fase.
