# 01 — What is Machine Learning? · narrative

> Chapter narrative, hanging off the course [spine](../_global/spine.md). Student-facing prose in **English**; design glosses in *italiano*. Six-word, 100-word, chapter arc, and an explicit pre-hook to the next chapter (`02-classifiers`).

## Six words

> **Programs follow rules; learners find them.**

*Glossa:* scelto via `narratore-critico` su 4 varianti. La forma *è* il contenuto: due clausole simmetriche con lo stesso oggetto (`rules`) che cambia ruolo — dato in input nella programmazione tradizionale, trovato in output dal learner. Incarna la distinzione fondante del capitolo e prepara la spine ("understand the machine") senza esaurirla.

## 100 words (3 acts)

Elena opened the algorithm's manual, hunting for the rules it followed. There were none. No engineer had written "discharge if X"; the program had learned from thousands of past patients, finding patterns no one dictated. It was defined, she read, by a task, a measure of performance, and experience — the data it trained on. Even the learning came in kinds: from labelled outcomes, from unlabelled patterns, from asking, from reward. The score was not magic, then, but a learner. She still couldn't trust it. But now she knew the three questions to ask: which task, measured how, learned from whom.

*Struttura:* Bing = Elena cerca le regole nel "manuale" dell'algoritmo e non le trova | Bang = scopre che nessuno le ha scritte: il modello ha *appreso* dai pazienti passati, ed è definito da Task/Performance/Experience; e l'apprendimento ha tipi diversi (etichette / pattern / domande / reward = supervised/unsupervised/active/reinforcement) | Bongo = la scatola non è magia ma un *learner*; non si fida ancora, ma ora sa le tre domande da fare. (100 parole esatte.)

## Chapter arc — Hook → Challenge → Resolution → Payoff

| Punto | Funzione | Contenuto |
|---|---|---|
| **Hook** | aggancio | Elena looks for the rules the discharge algorithm follows — and finds that no one wrote any. |
| **Challenge / Data** | problema concreto | If nobody programmed the rules, what *is* this thing? She must learn to describe any ML system by its Task ($T$), Performance ($P$), and Experience ($E$); to tell ML from traditional programming (where the rules are the *input*, not the learned *output*, $Y \simeq f(X)$); and to recognise which *kind* of learning a problem needs. A trap waits: a model can score 95% accuracy and still be useless when one outcome is rare. |
| **Resolution** | come si affronta | She reframes a clinical task as $T/P/E$, sees the input/output swap that separates learning from programming, and sorts real scenarios into supervised, unsupervised, active, or reinforcement learning by asking where the labels come from. |
| **Payoff** | cosa resta | She can now frame a clinical problem as an ML problem and name the kind of learning it requires — the first, non-negotiable question to ask *before* trusting any model. |

### Narrative version (prose)

The discharge algorithm had a manual, and Elena read it looking for the logic — the if-then rules a programmer must have typed. She found none. The system had been *trained*: shown thousands of past patients and left to find the patterns itself. That, she realised, is the whole difference. In ordinary software you write the rules and feed in data to get answers; here you feed in data *and* answers, and the machine hands you back the rule. To describe it precisely she needed only three coordinates — the task it performs, the measure that says it's doing well, and the experience it learned from. And "learning" itself, she saw, was not one thing: some models are taught with labelled outcomes, some left to find structure alone, some ask an expert when unsure, some learn by trial and reward. The score on her screen was none of them magic. It was a learner — and she had finally learned how to ask it the right questions.

## Versione didattica (objectives recap)

Gli obiettivi formali del capitolo vivono in [objectives.md](objectives.md). In sintesi, il payoff narrativo coincide con essi: **inquadrare** un problema in $T/P/E$, **contrapporre** ML e programmazione tradizionale (swap input/output), **classificare** il paradigma di apprendimento.

## Pre-hook → 02 Classifiers

> Elena can now say *what* a learner is and *what kind* of learning her score uses — but not yet *how* it actually reaches a verdict. The simplest learner makes one decision: it draws a line and asks which side a patient falls on. That line-drawer is a **classifier** — and it is where the box opens next.

*Glossa:* il pre-hook chiude sul gancio "come decide davvero?" e introduce il classificatore come la macchina-decisione più semplice, ponte diretto al cap. `02-classifiers` (calcolato via `manifest.next_enabled`).
