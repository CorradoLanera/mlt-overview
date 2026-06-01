# Sorgente — sezione "Agents" da StorIA_2026 (workshop Storytelling & IA)

> Nota di lavoro (IT) estratta da `docs/StorIA_2026.pptx` il 2026-05-26, prima della sua rimozione.
> Spunto **non vincolante** per ampliare la sezione **Agents** del corso MLT.
> Promemoria di proporzione: MLT è una **overview di ~4h lorde**, *non* un workshop sugli agenti.
> I dettagli applicativi andranno nei due workshop di proseguimento della settimana successiva.
> Gli artefatti studenti finali saranno in **inglese**; qui si conserva il materiale sorgente in italiano.

## 1. La tabella "4 quadranti" (2×2 → 2×3) — da portare in MLT

Modello personale del docente: **competenza** dell'utente × **livello di adozione dell'IA**.

**Versione 2×2 (era chatbot)** — assi: Inesperto/Esperto × No-IA / +Chatbot IA:

| | No-IA | + Chatbot IA |
|---|---|---|
| **Inesperto** | **Estraneo Dipendente** — si affida a terzi; non fa danni ma non porta vantaggi: fuori dal gioco, sopravvive grazie agli altri. | **Ciarlatano Smascherato** — può far danni prima di "bruciarsi"; categoria più frequentata, a tutti i livelli; sembra molto più facile di quanto sia. |
| **Esperto** | **Artigiano Resistente** — rischia l'isolamento o di essere spazzato via dal mercato; sopravvive solo se davvero unico. | **Alchimista Moderno** — dal pessimo al sublime, persino "truffe di qualità"; la figura più ambivalente e potente; padroneggia la chat e ne estrae valore. |

**Versione 2×3 (tabella finale)** — si aggiunge la colonna **+ Agenti IA** (il salto da *chiedere* a *delegare*):

| | No-IA | + Chatbot IA | + Agenti IA |
|---|---|---|---|
| **Inesperto** | Estraneo Dipendente | Ciarlatano Smascherato | **Apprendista Stregone** — come in *Fantasia*: evoca forze che non capisce né controlla; risultati strabilianti… fino a che non lo sono più. |
| **Esperto** | Artigiano Resistente | Alchimista Moderno | **Demiurgo Digitale** — orchestra agenti IA con dominio del mestiere: delega, controlla, scala. *La nuova frontiera.* "Se sei ancora alla chat… sei già indietro." |

Idea-cardine del passaggio (slide 19): *"E se il chatbot a cui «chiediamo» come fare diventasse un collaboratore a cui «deleghiamo» il fare?"*

Uso in MLT: la sezione Agents può chiudere su questa tabella come **payoff** — l'agente non risponde soltanto, **esegue**; il quadrante Demiurgo Digitale è il "dove può portare". (Direzione 2×2 vs 2×3 da decidere in fase contenuti col docente.)

## 2. "Come funzionano gli agenti" — spunti per ampliare (proporzionati a una overview)

Dal blocco agentico del workshop (slide ~18-21 e pomeriggio). Concetti chiave, da rendere in EN e in forma sintetica:

- **Da chat ad agente**: la chat *risponde*; l'agente *agisce* — legge/scrive file, esegue, delega. (slide 19-20, "Da chat ad agente").
- **Contesto persistente**: un file di istruzioni alla radice del progetto che l'agente legge a ogni avvio (chi sei, come lavori, cosa evitare) — "smetti di ripetere il prompt: il contesto vive nel progetto". (CLAUDE.md / AGENTS.md).
- **Skills**: procedure riusabili scritte una volta ("quando ti chiedo X, segui questi passi"); l'agente le attiva da solo quando la richiesta combacia con la description.
- **MCP & Tools**: connettori verso il mondo reale (file, database, API, Excel, PubMed…); un protocollo (MCP) per cui l'agente chiede "cosa puoi fare?" e poi "fai questa cosa". I 6 tool sui file + 4 tool aggiuntivi (web, delega, pianificazione).
- **Sub-agents / orchestrazione**: un'istanza separata e specializzata con la sua memoria; l'agente principale la lancia, attende, riceve un report. Context window puliti → meno token, niente bias accumulato. Un comando orchestratore può delegarne più in parallelo e poi consolidare.
- **Hooks**: eventi (Stop/SubagentStop, PreToolUse/PostToolUse…) che automatizzano controlli.

Tono per MLT: mostrare *cosa* sono e *dove portano* (autonomia, delega, esecuzione), non *come* configurarli passo-passo. Il "come" è materia dei workshop applicativi successivi — eventuale **pre-hook** della sezione Agents verso quei workshop.

## 3. Provenienza

- File: `docs/StorIA_2026.pptx` (workshop "Storytelling & IA al servizio della didattica", Corrado Lanera + Enrico Maso, 2026 — 2 giorni, da rifinire).
- Estrazione testo: `python -m markitdown` (2026-05-26). Slide di riferimento per i quadranti: 18 (2×2), 20 (2×3). Numeri di slide indicativi.
- Lo stesso deck è la fonte filosofica del plugin `storia-companion` v2 e di questa pianificazione (incl. il loop item-per-item con conferma, slide ~"Round 8").
