## Official course information

| | |
|---|---|
| **Denomination** | Machine Learning: Overview of machine learning techniques, algorithms, and applications |
| **SSD** | MEDS-24/A — Statistica medica |
| **Instructors** | Ileana Baldi, Corrado Lanera |
| **Hours / Credits** | 10 hours · 1 CFU |
| **Period** | Year I, second semester |
| **Delivery** | Dual (in-person + remote, simultaneous) |
| **Language** | English |
| **Attendance** | Mandatory (80%) |
| **Exam** | Moodle quiz |
| **Prerequisites** | None |

## Course description

A conceptual, applied overview of machine learning for biomedical and clinical graduate students. The module builds from first principles — what machine learning *is*, and how it differs from traditional programming — through the core families of models and the discipline that makes them trustworthy, up to the architectures behind today's tools. Across ten storyboard-narrated chapters students meet classifiers and the geometry of decision regions; three algorithm families ($k$-NN, SVM, random forest); model selection, cross-validation, overfitting and data leakage; deep learning (the artificial neuron, the forward pass, gradient descent); architectures for unstructured data (CNNs and RNNs); Transformers and large language models; the practical and ethical use of ChatGPT; agents and the trust boundary; and best practices for real ML projects. Every concept is anchored to a clinical application, so that students leave able to *frame*, *judge*, and *communicate* an ML approach to a medical problem — not to implement one (that is the role of the two R workshops).

## Intended learning outcomes

By the end of the module, students can:

1. **Frame** a clinical problem as a machine-learning problem via Task ($T$), Performance ($P$) and Experience ($E$), and **contrast** ML with traditional programming (in ML the model is the *output*, learned from data: $Y \simeq f(X)$).
2. **Classify** a scenario into the correct learning paradigm — supervised, unsupervised, active, reinforcement — justifying the choice from the kind and availability of supervision.
3. **Interpret** a classifier as a partition of feature space into decision regions, and **choose** performance metrics fit for the problem — recognising why accuracy misleads on imbalanced clinical outcomes.
4. **Apply** the train / validation / test split and $K$-fold cross-validation, **diagnose** overfitting, and **state** the data-leakage rule (any number you act on becomes a training number).
5. **Explain**, at the level of *why each one exists*, the modern architectures: the artificial neuron and gradient descent, CNNs and RNNs for unstructured data, and the Transformer / LLM.
6. **Judge** agentic and LLM tool use by the competence rule and by reversibility, and **plan** an ML project starting from the simplest defensible model.

## Topics & schedule

The ten chapters and their contact time are listed on the [Schedule](schedule.qmd) page. In brief:

- 01 · What is Machine Learning? — 25 min
- 02 · Classifiers — 20 min
- 03 · Algorithm examples — 35 min
- 04 · Model selection & validation — 30 min
- 05 · Deep Learning — 25 min
- 06 · Unstructured data (CNN/RNN) — 20 min
- 07 · LLMs & Transformers — 25 min
- 08 · Using ChatGPT in practice — 15 min
- 09 · Agents — 15 min
- 10 · Best practices for ML projects — 15 min

Total contact content ≈ 225 min, within the 10 officially allocated hours (the remainder covers setup, discussion, and assessment).

## Assessment

Summative assessment is a **Moodle quiz**. In addition, each chapter runs **one live, dual-mode formative/summative exercise** in which in-person and remote students converge on a single shared artifact (a table, poster, or shared document), so that mastery is observable live for both cohorts.

## Learning path

This is **Module 1** of the course. The path is **Overview → Basic → Advanced**: the Overview ends (ch. 10) by pre-hooking into the *Practice — Basic* R workshop, which in turn pre-hooks into *Advanced*.

## Reading & materials

- James, G., Witten, D., Hastie, T., & Tibshirani, R. — *An Introduction to Statistical Learning* (ISL).
- Mitchell, T. M. (1997). *Machine Learning*. McGraw-Hill — the $T/P/E$ definition.
- Vaswani, A., et al. (2017). "Attention is all you need." — the Transformer architecture.
- Lecturer-provided slides (the storyboard-narrated reveal.js deck).

*Nota docente:* l'header riporta i dati amministrativi ufficiali (Offerta Formativa). Il contenuto erogato è più ampio del blurb ufficiale dell'Offerta — che si ferma a bias-variance e metriche — e include deep learning, CNN/RNN, Transformer/LLM, uso pratico di ChatGPT e agenti: i dieci capitoli qui elencati sono la versione corrente e sono la fonte di verità per gli obiettivi.
