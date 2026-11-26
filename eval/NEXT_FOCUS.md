# Next focus: the Three Gulfs

Source: Shreya Shankar and Hamel Husain, *Evals for AI Engineers* (O'Reilly, 2027), chapter 1. The model
is adapted from Shankar et al. (2025). The book uses the **Three Gulfs** to name the three places where
LLM application development tends to break down. The book also gives a fix for each one, and
ActiveGenie can help with each.

| Gulf | Between | It breaks when | The book's fix |
|---|---|---|---|
| **Comprehension** | developer and data | you design for the inputs you imagine and judge the system by a few good outputs | read real traces and describe inputs and outputs at scale |
| **Specification** | developer and LLM | the prompt or schema leaves something unsaid, so the model guesses and guesses differently on each run | make the expectation explicit, matched to the real data |
| **Generalization** | data and LLM | the spec is clear and the model still fails on some inputs | measure the rate, then apply stronger levers: examples, decomposition, a different design |

The book's diagnosis rule: read outputs first. If the prompt never stated the requirement, fix the
prompt; that's a specification failure and needs no evaluator. If the prompt is clear and the failure
remains, it's a generalization failure: measure how often it happens, then intervene.

## Where ActiveGenie sits today

- **Generalization is the core.** Jury bench, debate, survey simulation and the Elo tournament are all
  generalization interventions. They are "stronger levers", aimed at relative criteria and matters of
  taste, a case the book's list doesn't cover.
- **Specification is half covered.** One return type, function schemas and one prompt per job close the
  gulf on the gem's side. The other half belongs to the user: the `criteria`, the schema descriptions
  and the list they pass in. The gem does nothing to help them write those.
- **Comprehension is the gap.** Logging covers tokens, retries and latency
  (`docs/reference/observability.md`). It doesn't help a user read what went in, what came out and the
  `reasoning`, and that is exactly where failure modes show up.
- **The eval is the Measure step.** It has no explicit Analyze step: reading outputs and naming failure
  modes before writing gold or picking a technique.

## The known issues, sorted by gulf

My classification of the items in [README › Known issues](README.md#known-issues-and-future-improvements)
and of the Airbnb integration feedback. Each one is a hypothesis.

- **Specification**
  - `Lister::Juries` shipped with the Family Feud prompt (#90): the instruction was simply wrong.
  - The juries function schema required `reasoning` while its properties defined `why_these_juries`.
    DeepSeek then sometimes returned `juries` as a string (Airbnb feedback).
  - "Null if the text does not say" invited abstaining on yes/no questions that needed inference.
  - `Extractor::Explanation` and litote use a strict non-nullable schema; only `min_accuracy` keeps
    them from inventing values.
- **Comprehension** (the data, or the inputs we imagined, don't match reality)
  - Migrated scorer cases describe the work ("100% test coverage") instead of containing it.
  - The comparator and lister test pools sit at the ceiling, so the eval never sees hard inputs.
  - `Player` assumed symbol keys; real callers pass parsed JSON with string keys (Airbnb feedback).
- **Generalization**
  - Three of the four comparator failures pick the shorter reply (`tags.length`).
  - In the scorer bias pairs, distraction lowers scores most (mean -5.0).
  - DeepSeek scores on a consistently harsher curve than other providers.

Most bugs that reached users so far are specification or comprehension failures, not generalization.
More techniques won't fix those.

## Candidate next steps, per gulf

1. **Tag failures by gulf in the eval (cheap).** Add an optional `gulf: spec | data | gen` to adjudicated
   breaks in the labeling desk and print it in `eval:full`'s broke/fixed list. It forces the
   diagnosis before anyone picks a fix. A `spec` break gets a prompt or schema fix, and a `gen` break
   becomes a case to measure a technique against.
2. **Add an Analyze step to the bootstrap flow.** Before an LLM judge drafts labels, a person reads 20
   to 30 outputs, including `reasoning`, and writes down the failure modes. Those modes become the gold's
   tags and the cells to watch. This also answers a reviewer who knows the book and asks why the
   judge comes first.
3. **Comprehension for gem users (the biggest gap).** Make it easy to sample real calls into a review
   file: input, `data`, `reasoning` and model, written as JSONL in the gold format. That gives the
   path "a case found after the deploy → a gold case → checked on the next deploy" a concrete tool,
   and it feeds `rake eval:bootstrap`.
4. **Specification help for gem users (later).** Ideas to test: warn when `Scorer` criteria have no
   anchors for the scale; flag reasoning that says the model is assuming something; run a case several
   times and, when results swing, suggest checking the criteria before reaching for a technique.
5. **Keep generalization honest.** Measure each technique against a single-call baseline on harder
   pools (the existing known issues: adjudicated comparator pairs, subtler bias pairs, a crowd survey
   for the lister). Use techniques only for failures that survive a clear spec.

Recommended order: 1 → 2 → 3. Steps 1 and 2 are mostly process and need little code. Step 3 is the first
new feature, and it also backs the Tropical on Rails 2027 eval talk (draft 6, parts 1 and 5).
