# ActiveGenie eval

A golden-set eval for the Comparator, Extractor, Lister and Scorer modules. It replaces the old
`test/e2e` benchmark. The expected answers are data you build, version and audit, and every change to
`lib/` is measured against a frozen baseline of `main`, with statistics that tell a real change apart
from model noise.

The Ranker is out of scope; its live tests stay in `test/e2e/ranker`.

## The loop

```shell
bundle exec rake eval:check                 # free: data integrity + prompt lint
bundle exec rake eval:quick                 # prints the cost of what isn't cached yet
YES=1 bundle exec rake eval:quick           # runs it -> GO / LOOK / STOP
```

1. Edit a prompt or a method in `lib/`. A variant is simply your working tree: there is no prompt
   override, so the eval always tests the real code path.
2. `eval:quick` runs the dev pool on the dev model and compares each case with the baseline.
   - **STOP**: a canary (a case the baseline always gets right) broke.
   - **LOOK**: something else broke, or a call errored.
   - **GO**: nothing broke.
3. Before merging, `YES=1 bundle exec rake eval:full` runs every case and reports the weighted pass
   rate with a CI, the delta against the baseline with its CI and an exact McNemar p-value, and the
   cases that broke or got fixed.
4. After merging to `main`, promote the run to the new baseline:
   `YES=1 REPEAT=3 bundle exec rake eval:full && bundle exec rake eval:save`.
   `REPEAT=3` runs everything three times to measure the noise floor (how often a case flips between
   identical runs). `eval:save` refuses a run with missing or errored cases, or one whose `lib/` has
   uncommitted changes.

Outputs are cached per case in `eval/runs/<provider>-<model>-<lib hash>/r<n>/`, so nothing is paid
for twice: re-running only calls the cases that are new, or that errored last time. A change to
any file in `lib/` changes the hash and starts a fresh run. `rake eval:report` re-prints a report
from the cache for free.

## Commands

| Task | Cost | What it does |
|---|---|---|
| `eval:check` | free | Validates cases, gold and pools; lints `lib/**/*.prompt.md` and function JSON; lists what changed in `lib/` vs `main` |
| `eval:status` | free | Cases per cell, pool and role; which release models have a baseline |
| `eval:quick` | paid | Dev pool: up to 3 hard cases + 2 canaries per cell once roles exist (`ALL_DEV=1` for the whole pool) |
| `eval:full` | paid | Every case. `REPEAT=n` for replicates |
| `eval:report` | free | Re-prints the report from cached outputs (`MODE=quick\|full`) |
| `eval:save` | free | Promotes the complete run to `eval/baselines/<provider>-<model>/` and, for the dev model, assigns dev-pool roles |

Environment: `PROVIDER` and `MODEL` (default: the dev model in `config.json`), `CELLS=a,b` to run a
subset, `YES=1` to spend money, `BY=name` for `eval:save`, `FORCE=1` to save from a dirty `lib/`.

## Models

`config.json` pins the models. The dev model (`gpt-6.1-terra`) runs in the loop; the four release
models run before a release (the `Eval` GitHub workflow, triggered manually). The judge
(`claude-sonnet-5-5`) is reserved for free-text grading in later phases. Moving to a newer model is a
deliberate change: update `config.json` and save a new baseline. Add a model's price under
`usd_per_million_tokens` to get dollar estimates instead of token counts.

## Cells, pools and roles

A **cell** is one public method, such as `extractor.with_litote`. Cells have equal weights: the
headline number is the mean of the cell pass rates, so a cell with many cases doesn't drown out the
others.

Each case is in one **pool**: `dev` (what you iterate against) or `test` (only for `eval:full`, so
prompts are not tuned to it). The 80 cases migrated from `test/e2e` are dev-only, because the prompts
were written alongside them. Test-pool cases come from MIT-licensed datasets and drafted cases (see
Data).

`eval:save` gives each dev case a **role** from the baseline: `canary` if it passed in every
replicate, `hard` if it didn't.

## Reading the report

- `rate` per cell and the weighted rate with a stratified bootstrap CI.
- `MDE`: the smallest change this many cases can reliably detect. With 30 cases per cell it is
  about 22 points per cell and 8 overall; a smaller delta is not evidence of anything.
- `delta`, `broke`, `fixed`, `p`: the paired comparison with the baseline on the same cases.
- Extractor fields get one of five outcomes: correct, wrong value, omission, correct abstention or
  invention. The field CI resamples whole cases, because fields of one document move together.
- Comparator cases run in both orders; a case passes only if both orders pick the gold winner, and
  the report shows how often the winner is the same in both orders.
- Scorer bias pairs: the mean |gap| between a text and its twin, and the mean signed gap per bias
  type (twin minus text: positive means the change that should not matter raised the score).

## Data

See [FORMAT.md](FORMAT.md) for the case, gold and pool formats.

External data (datasets, fetched files) and gems must be MIT-licensed; never Apache. When no MIT
source exists, the cases are written here instead: drafted with their intended gold in
`eval/labeling/drafts/`, labeled by two blind passes, and merged with `rake eval:label CELL=<cell>`.
A field enters the gold only when both passes agree with the draft, or a human decision in
`eval/labeling/<cell>/decisions.jsonl` (append-only, latest wins) settles it. The extractor cells
started from CUAD (CC BY 4.0) and CondaQA (Apache-2.0); both were replaced with drafted cases for
this reason.

The comparator test cases come from [hh-rlhf](sources/hh_rlhf/NOTICE.md) (MIT): one conversation,
two possible next replies, and a crowdworker's pick of the more helpful one. Those picks are noisy,
so `sources/hh_rlhf/build.rb` writes them as drafts of the `comparator` set (`rake eval:label
CELL=comparator`), and a case is kept only when both blind passes pick the same reply as the
crowdworker; any other case is dropped, not queued. Pass B sees the replies in the opposite order
to pass A, so a labeler's position bias cannot keep a case. The same cases feed `by_debate` and
`by_fight`, so the two methods are compared on paired cases. Half the drafts have the picked reply
as the longer one and half as the shorter one (`tags.length`), so preferring length does not pay.

No MIT source has multi-rater scores, so the `scorer.by_jury_bench` test cases are drafted: 12
calibration cases (a gold band, including texts whose polish and quality disagree, such as an
eloquent essay full of false claims) and 18 bias pairs, three for each of six biases from the
LLM-as-a-judge literature: verbosity, authority, bandwagon, injection (a note telling the
evaluator what score to give), identity (the author's name, age or origin) and distraction. The
labelers see both versions of a pair side by side. 25 of the 30 passed labeling (10 calibration
cases and 15 pairs); until the queue is decided, verbosity has one pair and authority two, so
their per-bias gaps rest on one or two cases. The test cases leave `juries` out, so the scorer
picks its own with `Lister::Juries`: that is how `lister.with_juries` is judged, by its effect on
the scorer.

No MIT source has real crowd answer counts either, so the `lister.with_feud` test cases are drafted
Family Feud questions whose top answers are near-certain common knowledge ("Name a fruit that is
red"). Each gold asks for the crowd's #1 answer in the first two items (`top_k_any`), at least three
of the usual answers (`min_groups`) and, in 18 of the 30, none of a few correct but unusual answers
(`no_item`: "theremin" for an instrument, "katydid" for an insect), which catches listing like an
expert instead of like the crowd. The blind labelers each play the survey (the top 5 answers of 100
average adults), and a case is kept when both lists pass its checks.

## Tests

The eval's own code is covered by `test/unit/eval/` (part of `rake test:unit`), including an
offline run -> baseline -> regression cycle with a stubbed model.

## Known issues and future improvements

Found while building the extractor, comparator and scorer cells (2026-11-17/18, gpt-6.1-terra). Each one is a hypothesis to
test with a paired run, not a decided change.

- **`Extractor::Explanation` and litote use the same strict, non-nullable schema.** They avoid
  invented values today only because the accuracy filter (`min_accuracy`) drops low-confidence
  fields. Measure nullable non-boolean fields there too.
- **`UnifiedProvider` string-to-nil workaround** (`lib/active_genie/providers/unified_provider.rb`,
  around line 100) turns strings like "null" and "unknown" into nil. It predates nullable extractor
  fields and misses variants such as `":null"`. Re-check whether it is still needed after the fix.
- **Contract case pass rate is harsh.** An `extractor.data` contract passes only when all 10 fields
  are right, so the case rate moved much more than the field rate on CUAD (about 35% vs 87%).
  Consider weighting by field or reporting both in the gate.
- **Inference questions vs "Null if the text does not say".** On CondaQA (since removed), the model
  answered null on 7 of 15 yes/no questions that needed inference, because the description invited
  abstaining. Watch for this in drafted cases; "Null only if the text gives no basis to answer" is
  the wording to try.
- **`webmock` pulls in `addressable` (Apache-2.0).** It is a test-only dependency of the library's
  unit tests. Replacing it means our own minimal HTTP stub in `test/`; decide separately.

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

- **`Lister::Juries` used the Family Feud prompt.** Since the rename in #63, `juries.prompt.md` was
  a copy of `feud.prompt.md`, so the scorer picked its juries with a survey prompt: 3 to 7 juries
  per case (mean 4.1). With a juries prompt (fix/juries-prompt), it picks exactly 3. On the scorer
  the fix is neutral within noise: 41/45 against 42/45 (+1 / -2, and both breaks are a text
  scoring 76 against a band that ends at 75).
- **The scorer barely moves on the bias pairs.** With the juries shared across each pair (25 test
  cases, current lib): mean |gap| 3.0 points, no bias type pushes scores up, and distraction lowers
  them most (mean -5.0). When each text picked its own juries, two pairs failed on gaps of -16 and
  -11 that came from different juries, not from the change: that is why a pair now shares them.
  The pairs are easy to see through, which is good news for the method but means the set cannot
  yet show whether more viewpoints remove bias. Next: subtler pairs (a confident vs a hedged tone, a polished vs a plain layout) and a
  paired run with a single jury against the default three.
- **Five drafted scorer cases wait for a decision** (`eval/labeling/scorer.by_jury_bench/queue.jsonl`).
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

## Data for the next phases (license check, 2026-11-17)

The datasets first planned for the comparator, scorer and lister cells were chosen before the
MIT-only rule. Checked on Hugging Face and GitHub:

| Planned or candidate source | License | Usable? |
|---|---|---|
| `Anthropic/hh-rlhf` (human pairwise preferences, ~44k downloads/month) | MIT | Yes: used for the comparator test pool (helpful-base test; only clear pairs kept, see Data) |
| `openbmb/UltraFeedback` and its binarized forks | MIT | No: GPT-4 labels, not human taste |
| MT-Bench human judgments, HelpSteer2/3, Community Alignment, Arena 140k, ProtoQA | CC BY 4.0 | No |
| Arena human preference 55k | Apache-2.0 | No |
| SWOW, Anthropic global opinions / persuasion | NC licenses | No |
| SHP (Reddit), OpenAI summarize-from-feedback / WebGPT comparisons | no license stated | No |
| ProtoQA (Family Feud questions with survey answers, scraped from fan sites) | CC BY 4.0 | No |
| Cold-Family-Feud `games/` (570 Feud games, checked 2026-11-18) | MIT repo, but the games have no stated source and the repo ships a script that generates "realistic" point values | No: unknown origin, and the counts may be made up |

No MIT-licensed source exists for the scorer (multi-rater ratings) or the lister (how many people
give each answer), so those cells need drafted cases. The lister's goal, emulating what a crowd
would say, is the hardest to draft: a small survey we run ourselves may be worth considering.
