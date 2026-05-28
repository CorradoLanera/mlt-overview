# MLT course — narrative spine (global)

> Whole-course narrative backbone for **"Machine Learning — An Applied Overview"** (UBEP, biomedical/clinical graduate students, ~240 min, 10 chapters). Student-facing prose in **English**; design glosses in *italiano*. Every chapter's own arc (see each `narrative.md`) hangs off this spine.

## Six words

> **Understand the machine before trusting it.**

*Glossa:* scelto via `narratore-critico` su 4 varianti. È l'unica che codifica una *sequenza* (`before`: capire → fidarsi) anziché una constatazione, e regge su tutti i 10 capitoli — ogni capitolo è un gradino dell'"understand" che precede il "trust". Prende posizione contro entrambi gli estremi del brief: né data scientist, né fiducia cieca. L'antagonista del corso è l'**opacità**, non la macchina.

## 100 words (3 acts)

The risk score flashed red on Elena's screen, recommending a discharge she doubted. The hospital had bought the algorithm; nobody could tell her why it decided. She felt overruled by a black box, signing off what a machine dictated. So she began asking how it learned: what task, what data, what counted as success. Class by class the box opened — classifiers, validation, the patients it never saw during training. One morning the score flashed red again. This time Elena read its reasoning, found the blind spot, and overruled it with evidence. She no longer obeyed the machine. She understood it.

*Struttura:* Bing = una clinica (Elena) riceve un punteggio di rischio opaco e si sente scavalcata da una scatola nera | Bang = inizia a chiedersi *come* l'algoritmo abbia imparato (task/dati/successo, classificatori, validazione, i pazienti mai visti in training): la scatola si apre capitolo per capitolo | Bongo = davanti allo stesso punteggio ne legge il ragionamento, ne trova il punto cieco e lo scavalca *con evidenza* — non obbedisce più, capisce. (100 parole esatte.)

## Course arc — Hook → Challenge → Resolution → Payoff

| Punto | Funzione | Contenuto |
|---|---|---|
| **Hook** | aggancio emotivo/visivo | A red risk score tells Elena to discharge a patient she's worried about. The vendor's algorithm won't say why; she's signing off a decision a black box made for her. |
| **Challenge / Data** | problema concreto, misurabile | In 240 minutes she must open that box. A model can boast 95% accuracy and still be useless on imbalanced data; another fits the training set perfectly and fails on new patients. Across 10 chapters: what is *Task / Performance / Experience*, how classifiers decide, why models overfit, what deep nets and LLMs actually "see", where ChatGPT and agents help or mislead. |
| **Resolution** | come si affronta, cosa si trova | Chapter by chapter she learns to interrogate each layer: reframe the problem as $T/P/E$, pick a metric that survives class imbalance, expose overfitting with cross-validation, locate a model's blind spot, and check an LLM's output against evidence. |
| **Payoff** | cosa resta allo studente | The clinician can now *evaluate and use* ML with judgement — trusting it where the evidence holds, overriding it where it doesn't — without becoming a data scientist. |

### Narrative version (prose)

A red flag fills Elena's screen: discharge recommended, and she disagrees. The hospital bought the algorithm, but no one can tell her how it reached that verdict, and signing off feels like obeying a box she cannot see into. Over the following weeks she stops accepting the number and starts questioning it. She learns what task the model was built for, what "performance" really means when one outcome is rare, and which patients it never met during training. She watches a flawless-looking model collapse on new data, and learns the test that would have caught it. She sees what deep networks and language models can and cannot perceive, and where a confident chatbot quietly invents. By the end, the same red flag appears — and this time Elena reads its reasoning, finds the blind spot, and overrides it with evidence. She hasn't become an engineer. She has become a clinician who understands the machine before trusting it.

## Expected student transformation (course level)

- **Before:** subisce gli output del ML come verdetti opachi; non sa distinguere un modello valido da uno solo apparentemente accurato, né dove i suoi limiti rendano rischioso fidarsi.
- **After:** inquadra, interroga e giudica un sistema ML rispetto a un compito clinico, riconoscendo metriche ingannevoli, overfitting e limiti dei modelli moderni, e decide su base di evidenza quando fidarsi e quando scavalcare.

**Course-level objectives (measurable):**

1. Saper **inquadrare** un problema clinico come problema di ML ($T/P/E$) e **scegliere** una misura di performance adeguata anche con classi sbilanciate.
2. Saper **diagnosticare** la validità di un modello distinguendo buona generalizzazione da overfitting tramite evidenza di validazione/selezione.
3. Saper **valutare** uso appropriato e limiti degli strumenti ML moderni (deep learning, dati non strutturati, LLM, ChatGPT, agenti) per un compito clinico dato.
4. Saper **argomentare**, con evidenza, quando fidarsi, mettere in dubbio o scavalcare l'output di un sistema ML.

*Nota di bilanciamento:* il filo "Elena" è forte; tenere il payoff su *understand → evaluate → use*, mai su *win* (niente "clinico batte algoritmo"). I 10 capitoli sono molti per un solo arco: ciascuno avrà il proprio micro-arco (per-chapter `narrative.md`) agganciato a questa spine, con un pre-hook esplicito al capitolo successivo.
