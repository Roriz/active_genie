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

My classification of the items in [Known issues](#known-issues-and-future-improvements) below
and of the Airbnb integration feedback. Each one is a hypothesis.

- **Specification**
  - `Lister::Juries` shipped with the Family Feud prompt (#90): the instruction was simply wrong.
    Resolved in #90.
  - The juries function schema required `reasoning` while its properties defined `why_these_juries`.
    DeepSeek then sometimes returned `juries` as a string (Airbnb feedback). Resolved in 3cf43b8
    (v0.30.11): `required` names `why_these_juries`, and a `juries` string is parsed into a list.
  - "Null if the text does not say" invited abstaining on yes/no questions that needed inference.
  - `Extractor::Explanation` and litote use a strict non-nullable schema; only `min_accuracy` keeps
    them from inventing values.
- **Comprehension** (the data, or the inputs we imagined, don't match reality)
  - Migrated scorer cases describe the work ("100% test coverage") instead of containing it.
  - The comparator and lister test pools sit at the ceiling, so the eval never sees hard inputs.
  - `Player` assumed symbol keys; real callers pass parsed JSON with string keys (Airbnb feedback).
    Resolved in 3cf43b8 (v0.30.11): `Player` turns its keys into symbols.
- **Generalization**
  - Three of the four comparator failures pick the shorter reply (`tags.length`).
  - In the scorer bias pairs, distraction lowers scores most (mean -5.0).
  - DeepSeek scores on a consistently harsher curve than other providers.

Most bugs that reached users so far are specification or comprehension failures, not generalization.
More techniques won't fix those.

The three items marked resolved are fixed in the code. The rest are still open. Where each one
stands, and the run or decision that would settle it, is in
[Where the open items stand](#where-the-open-items-stand-2026-11-26) below.

## Candidate next steps, per gulf

1. **Tag failures by gulf in the eval (cheap).** Add an optional `gulf: spec | data | gen` to adjudicated
   breaks in the labeling desk and print it in the report's broke/fixed list. It forces the
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

## Known issues and future improvements

Found while building the extractor, comparator and scorer cells (2026-11-17/18, gpt-6.1-terra). Each
one is a hypothesis to test with a paired run, not a decided change.

- **`Extractor::Explanation` and litote use the same strict, non-nullable schema.** They avoid
  invented values today only because the accuracy filter (`min_accuracy`) drops low-confidence
  fields. Measure nullable non-boolean fields there too.
- **`UnifiedProvider` string-to-nil workaround** (`lib/active_genie/providers/unified_provider.rb`,
  around line 100) turns strings like "null" and "unknown" into nil. It predates nullable extractor
  fields and misses variants such as `":null"`. Re-check whether it is still needed after the fix.
  Fixed in #102. It is still needed: `Extractor.data` can answer null since #88, but `Explanation`
  and litote cannot, and a provider without strict schemas can still write "null". It now also
  catches wrapped placeholders (`":null"`, `"(unknown)"`, `"'None'"`), and it keeps a placeholder
  that the field's own enum lists (`enum: ["none", "mild"]` used to lose "none").
- **Contract case pass rate is harsh.** An `extractor.data` contract passes only when all 10 fields
  are right, so the case rate moved much more than the field rate on CUAD (about 35% vs 87%).
  Consider weighting by field or reporting both in the gate. Reporting both is done: each report
  has printed the field rate under the case rate since #86, and #102 adds a `fields` column to the
  `EVAL=all` summary. Weighting the verdict by field is still the owner's call.
- **Inference questions vs "Null if the text does not say".** On CondaQA (since removed), the model
  answered null on 7 of 15 yes/no questions that needed inference, because the description invited
  abstaining. Watch for this in drafted cases; "Null only if the text gives no basis to answer" is
  the wording to try.
- **`webmock` pulls in `addressable` (Apache-2.0).** This was a problem under the old MIT-only
  rule. Apache-2.0 is a clear open license, so it is fine now and there is no need to replace
  `webmock` with our own HTTP stub. (It is also test-only, so it never reaches users.)

- **Comparator test pool is near the ceiling.** First run (2026-11-17, gpt-6.1-terra, 41 hh-rlhf
  test cases + 10 dev cases per cell): `by_debate` 50/51, `by_fight` 47/51; same winner in both
  orders 98.0% and 96.1%. On the 41 paired test cases `by_debate` fixes 3 cases `by_fight` misses and
  loses none (exact McNemar p = 0.25): the direction supports "a longer debate makes the decision
  easier", but the sample cannot show it. Keeping only pairs both labelers agree on made the set
  easy. To test the theory, adjudicate the 17 dropped pairs where one labeler agreed with the
  crowdworker and the other said "either" (the labeling desk, phase 5), and draft harder pairs.
  Three of the four failures have the shorter reply as the winner (`tags.length`).
- **No "either" cases in the comparator test pool.** hh-rlhf always has a pick, so ties and
  taste-dependent pairs are only in the dev pool (from `test/e2e`). Draft some if consistency on
  ties matters.

- **`Lister::Juries` used the Family Feud prompt.** Resolved in #90. Since the rename in #63,
  `juries.prompt.md` was a copy of `feud.prompt.md`, so the scorer picked its juries with a survey
  prompt: 3 to 7 juries per case (mean 4.1). With a juries prompt (#90), it picks exactly 3. On the scorer
  the fix is neutral within noise: 41/45 against 42/45 (+1 / -2, and both breaks are a text
  scoring 76 against a band that ends at 75).
- **The scorer barely moves on the bias pairs.** With the juries shared across each pair (25 test
  cases, current lib): mean |gap| 3.0 points, no bias type pushes scores up, and distraction lowers
  them most (mean -5.0). When each text picked its own juries, two pairs failed on gaps of -16 and
  -11 that came from different juries, not from the change: that is why a pair now shares them.
  The pairs are easy to see through, which is good news for the method but means the set cannot
  yet show whether more viewpoints remove bias. Next: subtler pairs (a confident vs a hedged tone, a polished vs a plain layout) and a
  paired run with a single jury against the default three.
- **Five drafted scorer cases wait for a decision** (`"status": "queued"` in `evals/scorer_by_jury_bench/datasets.jsonl`).
  `draft_bias_authority_03` should probably be excluded: its invented citations are a real
  defect, so the pair does not isolate authority bias.
- **Some migrated scorer cases score claims, not work.** `engineering_code_quality`,
  `academia_scientific_rigor_high` and `legal_brief_quality` describe a pull request, a study or
  a brief ("refactors the module perfectly, 100% test coverage") instead of showing it. The model
  scores them 30-47 because the claims cannot be checked, against bands that start at 50-70.
  Rewrite them to contain the work itself, or lower the bands.

- **The lister test pool is at the ceiling.** First run (2026-11-18, gpt-6.1-terra): 40/40 (30
  drafted + 10 dev). It works as a regression gate for obvious crowd answers, but it cannot rank
  methods on how well they emulate a crowd, and its gold is partly circular (models guessing what
  a crowd says). The real measure is a Family Feud score against counted answers: a survey of our
  own (about 30 questions, 30 to 100 people), whose counts would extend the lister gold.
- **`lister.with_juries` has no test pool of its own.** It is judged through the scorer, whose
  test cases let it pick the juries.

### Where the open items stand (2026-11-26)

Checked against the code and data after #99 (#102). None of the gem's evals has a committed baseline
yet, so each paired run below starts with a full run on `main`, saved as the baseline:
`rake active_genie:eval:full EVAL=<name>`, then `rake active_genie:eval:save EVAL=<name>`. The
change then runs with `rake active_genie:eval:full EVAL=<name>` on its branch. Editing a case's input
unpairs it from the baseline, so a wording change runs as two `variant`s in the eval's `eval.rb`,
and the report compares them head to head on the same cases.

Need a paired run (nothing changed yet):

- **Nullable non-boolean fields in `Extractor::Explanation` and litote.** Give `Explanation` the
  `nullable` fields of `Extractor::Data`. Run `EVAL=extractor,extractor_with_litote`
  (74 cases × 2 variants + 36 cases). Keep it if inventions drop on the 13 non-boolean fields whose gold is absent
  (all in the `draft_explanation_*` rows of `extractor`; booleans stay as they are) and omissions don't rise. The field outcomes matrix shows both.
- **"Null only if the text gives no basis to answer".** The wording is in the callers' field
  descriptions (here, the eval sets), not in `lib/`. The current sets can't show the problem:
  CondaQA is gone, booleans stay non-nullable since #88, and no "Null if" field is a yes/no question
  that needs inference. First draft about 15 such cases into `extractor` (yes/no as a string
  enum, so null is possible), then run both wordings as variants of `extractor` (about 89 cases).
- **The comparator picks the shorter reply in three of four failures.** Four failures can't show a
  bias. After the harder pairs below, run `EVAL=comparator` (59 cases, two variants, both orders) and
  compare the failure rate of `picked_shorter` (20 test cases) with `picked_longer` (19).
- **Distraction lowers scores most; one jury against three.** Run `EVAL=scorer_by_jury_bench` (45
  cases, 15 of them twin rows) with two variants, `three_juries` and `one_jury` (the first jury
  `Lister.with_juries` picks), and compare the mean |gap| per bias in the twin pairs table. It says
  more once the subtler pairs exist.
- **DeepSeek scores on a harsher curve.** Run
  `PROVIDER=deepseek MODEL=deepseek-v4-flash rake active_genie:eval:full EVAL=scorer_by_jury_bench`
  next to the `gpt-6.1-terra` run of the same code (45 cases each). Compare the mean score and the
  score bands matrix, and count per case how often DeepSeek scores lower. A harsher curve is a fact
  about the provider to document, not a code fix.

Need data or a decision:

- **Five queued scorer cases.** Recommendation, from the two blind passes in `gold.jsonl`:
  - `draft_bias_authority_03`: exclude. Pass B scores the twin 52 against 85 because the citations
    are made up, so the pair doesn't isolate authority. Redraft it with correct attributions.
  - `draft_bias_verbosity_02`: both passes give a gap of 0, but score 78 and 55 against [35, 75].
    Widen the band to [45, 85] and confirm.
  - `draft_bias_verbosity_03`: gaps of 0 and -12 against `max_gap` 10. Confirm as is: the criteria
    ask only whether the reply answers.
  - `draft_score_06` (50 and 22 against [0, 45]) and `draft_score_09` (30 and 15 against [30, 65]):
    both passes score lower than the draft. Move the bands to [0, 55] and [10, 50] and confirm.
- **Migrated scorer cases that describe work** (`engineering_code_quality`,
  `academia_scientific_rigor_high`, `legal_brief_quality`, dev only). Rewrite them to contain the
  work: a diff, a methods section, the brief's argument. Lowering the bands would reward scoring
  claims nobody can check.
- **Harder comparator pairs.** The labels now hold 18 dropped pairs where one pass agrees with the
  crowdworker and the other says "either". Adjudicate those, and draft harder pairs.
- **"Either" cases.** There are 6, all dev. Draft about 10 test ties if consistency on ties matters.
- **Lister at the ceiling.** Whether to run our own survey (cost, and who answers) is the owner's
  call.
- **`lister_with_juries` test pool.** Recommendation: a small test pool that checks what the prompt
  now asks for (job titles, not names; no overlapping roles) with `no_item` and `min_items`, and keep
  judging quality through the scorer. `list` has no "at most n items" check, so "exactly three"
  would need an engine change.
- **Verdict by case or by field.** Recommendation: keep the verdict on cases, because one wrong
  field is a wrong result for the caller, and read the `fields` column next to it.

## Data for the next phases (license check, 2026-11-17)

The datasets first planned for the comparator, scorer and lister cells were chosen before the
MIT-only rule, and this check was first done under it. The "Usable?" column is now judged under the
current rule in [Where the cases come from](README.md#where-the-cases-come-from): any clear open
license is fine with credit (a `NOTICE.md` next to the data); no stated license, NC terms, or
share-alike/copyleft terms that would reach users are not. Checked on Hugging Face and GitHub:

| Planned or candidate source | License | Usable? |
|---|---|---|
| `Anthropic/hh-rlhf` (human pairwise preferences, ~44k downloads/month) | MIT | Yes: used for the comparator test pool (helpful-base test; only clear pairs kept, see [Where the cases come from](README.md#where-the-cases-come-from)) |
| `openbmb/UltraFeedback` and its binarized forks | MIT | No: GPT-4 labels, not human taste |
| MT-Bench human judgments, HelpSteer2/3, Community Alignment, Arena 140k | CC BY 4.0 | Yes, with credit |
| Arena human preference 55k | Apache-2.0 | Yes, with credit |
| SWOW, Anthropic global opinions / persuasion | NC licenses | No |
| SHP (Reddit), OpenAI summarize-from-feedback / WebGPT comparisons | no license stated | No |
| ProtoQA (Family Feud questions with survey answers, scraped from fan sites) | CC BY 4.0 | Yes, with credit; the answers were scraped from fan sites, so check their origin first |
| Cold-Family-Feud `games/` (570 Feud games, checked 2026-11-18) | MIT repo, but the games have no stated source and the repo ships a script that generates "realistic" point values | No: unknown origin, and the counts may be made up |

Under the MIT-only rule no source existed for the scorer (multi-rater ratings) or the lister (how
many people give each answer), so those cells got drafted cases.

Sources the current rule newly allows, as possible follow-ups (none is used yet; each needs its own
check that the data fits the cell, and a `NOTICE.md` when added):

- **CondaQA** (Apache-2.0) and **CUAD** (CC BY 4.0): the extractor sources removed under the old
  rule.
- **Arena human preference 55k** (Apache-2.0), and the CC BY 4.0 sets above (MT-Bench human
  judgments, HelpSteer2/3, Community Alignment, Arena 140k): human preference or rating data for
  the comparator and possibly the scorer. Whether any of them has the multi-rater ratings the scorer
  needs is still to check.
- **ProtoQA** (CC BY 4.0): Family Feud questions with answer counts for the lister.

Until then the scorer and lister keep their drafted cases. The lister's goal, emulating what a crowd
would say, is the hardest to draft: a small survey we run ourselves may be worth considering.
