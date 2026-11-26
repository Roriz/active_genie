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
   - **STOP**: a canary broke: a case the baseline passed in every replicate.
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
| `eval:check` | free | Validates the sets and labels; lints `lib/**/*.prompt.md` and function JSON; lists what changed in `lib/` vs `main` |
| `eval:status` | free | Cases per cell and pool, rows per set and status, which release models have a baseline |
| `eval:quick` | paid | Every dev-pool case |
| `eval:full` | paid | Every case. `REPEAT=n` for replicates |
| `eval:report` | free | Re-prints the report from cached outputs (`MODE=quick\|full`) |
| `eval:save` | free | Promotes the complete run to `eval/baselines/<provider>-<model>/` |
| `eval:blind` | free | Prints a set's `draft` rows without their gold, for a blind labeler (`SET=<set>`) |
| `eval:label` | free | Compares the blind labels with the gold and writes each drafted row's `status` (`SET=<set>`) |

Environment: `PROVIDER` and `MODEL` (default: the dev model in `config.json`), `CELLS=a,b` to run a
subset, `SET=<set>` for labeling, `YES=1` to spend money, `BY=name` for `eval:save`, `FORCE=1` to save
from a dirty `lib/`.

## Models

`config.json` pins the models. The dev model (`gpt-6.1-terra`) runs in the loop; the four release
models run before a release (the `Eval` GitHub workflow, triggered manually). The judge
(`claude-sonnet-5-5`) grades gold fields marked `judge: true` when their deterministic check fails. It
is only called by a paid run with `YES=1`; its verdicts are cached in `eval/judge/<model>.jsonl`
(committed, created on the first verdict), so reports stay free. Moving to a newer model is a
deliberate change: update `config.json` and save a new baseline. Add a model's price under
`usd_per_million_tokens` to get dollar estimates instead of token counts.

## Cells and pools

A **cell** is one public method, such as `extractor.with_litote`. Cells have equal weights: the
headline number is the mean of the cell pass rates, so a cell with many cases doesn't drown out the
others.

Each case is in one **pool**: `dev` (what you iterate against) or `test` (only for `eval:full`, so
prompts are not tuned to it). The 80 cases migrated from `test/e2e` are dev-only, because the prompts
were written alongside them. Test-pool cases come from MIT-licensed datasets and drafted cases (see
[Where the cases come from](#where-the-cases-come-from)).

A **canary** is a case the saved baseline passed in every replicate. The report works this out from
`eval/baselines/` each time; nothing about it is stored in the data.

## Reading the report

- `rate` per cell and the weighted rate with a stratified bootstrap CI.
- `MDE`: the smallest change this many cases can reliably detect. With 30 cases per cell it is
  about 22 points per cell and 8 overall; a smaller delta is not evidence of anything.
- `delta`, `broke`, `fixed`, `p`: the paired comparison with the baseline on the same cases.
- Extractor fields get one of five outcomes: correct, wrong value, omission, correct abstention or
  invention (or `unjudged`, counted as wrong, while a judge verdict is missing). The field CI
  resamples whole cases, because fields of one document move together.
- Comparator cases run in both orders; a case passes only if both orders pick the gold winner, and
  the report shows how often the winner is the same in both orders.
- Scorer bias pairs: the mean |gap| between a text and its twin, and the mean signed gap per bias
  type (twin minus text: positive means the change that should not matter raised the score).

## Data format

```
eval/
  cells.json             # the cells (one per public method) and their weights
  sets/<set>.jsonl       # the cases: one row each, input and gold together
  labels/<set>.jsonl     # blind labeling passes of the set's drafted rows
  judge/<model>.jsonl    # cached judge verdicts (committed)
  baselines/<system>/    # frozen outputs of main (committed)
  runs/<system>/         # outputs of your working tree (gitignored)
```

A **set** is one file of cases. It usually feeds one cell and is named after it
(`sets/extractor.data.jsonl`); the comparator cells share `sets/comparator.jsonl`, so `by_debate` and
`by_fight` run on the same pairs.

### A row

```json
{"id": "draft_feud_red_fruit", "cells": ["lister.with_feud"], "pool": "test", "status": "confirmed",
 "source": "drafted", "tags": {"domain": "food", "difficulty": "subtle"},
 "input": {"theme": "Name a fruit that is red"},
 "gold": {"checks": [{"type": "top_k_any", "k": 2, "any_of": ["apple", "strawberr", "cherr"]}]},
 "why": "Apples, strawberries and cherries dominate; a crowd names familiar supermarket fruit."}
```

- `id`: unique within the set, snake_case. A cell runs it once per cell listed in `cells`.
- `pool`: `dev` or `test`. `source`: where it came from (`e2e-migration`, `drafted`, `hh-rlhf`).
- `tags.difficulty`: `easy`, `subtle` or `adversarial`. `tags.domain`: free text. Scorer bias pairs
  add `tags.bias`.
- `why`: what the case checks and why that answer is correct.
- `on_disagreement: "drop"`: for a noisy source, a pass that disagrees drops the row instead of
  queueing it.
- `input`: the arguments for the method. Any cell may also take `input.config`, a hash passed as
  `config:` to the method.

| Cell | `input` keys |
|---|---|
| `extractor.data`, `extractor.with_explanation`, `extractor.with_litote` | `text`, `schema` (the `data_to_extract` hash) |
| `comparator.by_debate`, `comparator.by_fight` | `player_a`, `player_b`, `criteria` |
| `lister.with_feud` | `theme` |
| `lister.with_juries` | `text`, `criteria` |
| `scorer.by_jury_bench` | `text`, `criteria`, optional `juries` (array), optional `twin` (bias pair) |

### Status

| `status` | Set by | Meaning | Runs? |
|---|---|---|---|
| none | you | Hand-written or migrated; no labeling step | yes |
| `draft` | you or a builder | Drafted; a blind pass has not labeled it yet (`eval:blind` shows it) | no |
| `confirmed` | `eval:label` | Both blind passes agree with the gold | yes |
| `queued` | `eval:label` | The passes disagree; waits for you | no |
| `dropped` | `eval:label` | `on_disagreement: drop` and a pass disagreed | no |
| `decided` | you | You settled it: edit the gold if needed and explain in `why` | yes |
| `excluded` | you | Left out on purpose | no |

`eval:label` re-computes `draft`, `queued`, `confirmed` and `dropped` from the labels every time, so a
row follows its labels and its gold. It never touches `decided`, `excluded` or a row with no status.

### Labels (`labels/<set>.jsonl`)

```json
{"id": "draft_feud_red_fruit", "pass": "a", "labeler": "codex/gpt-6.1-sol", "values": {"list": ["Apple", "Cherry"]}, "at": "..."}
```

`pass` is `a` or `b`; the latest successful label per id and pass counts. `values` has one entry per
graded field of the gold: the extractor's field names, a comparator's `winner` (always in the row's
own a/b terms, whatever `order` the labeler saw), a scorer's `score` (`{"text", "twin"}` for a bias
pair) or a lister's `list`. A field agrees when the gold accepts the value, using the same matchers
as grading.

### Extractor gold

```json
{"fields": {
  "candidate_name":   {"present": true, "check": "eq", "value": "Alex Rivera"},
  "years_experience": {"present": true, "check": "gte", "value": 8},
  "primary_skills":   {"present": true, "check": "nonempty"},
  "salary":           {"present": false}
}}
```

Only the fields listed are graded. `present: false` means the right answer is "absent"
(nil, empty string or empty array). `present: "optional"` accepts either: absent counts as a
correct abstention, and a value must pass the check (used when a human decides both readings
are right). `check: "date"` compares a written date with an ISO `value` (`2014-02-10`). A field
with `judge: true` and a `question` goes to the LLM judge when its check fails; the judge compares
it with `reference` (a human-readable gold, for when `value` is a check operand such as a list of
substrings). Checks, all case-insensitive for strings:

| `check` | Passes when the extracted value... |
|---|---|
| `eq` | equals `value` (strings compared trimmed and case-insensitive, numbers numerically) |
| `one_of` | equals any item of `value` (array) |
| `regex` | matches the pattern in `value` |
| `contains_any` | contains any substring in `value` (array); for an array, any item does |
| `contains_all` | contains every substring in `value`; for an array, across its items |
| `gte` / `lte` | is a number >= / <= `value` |
| `between` | is a number within `value` = `[lo, hi]`, inclusive |
| `near` | is a number within `delta` of `value` |
| `nonempty` | is present and not empty |
| `date` | is a written date (ISO, `2/10/14`, `February 10th, 2014`, ...) equal to the ISO `value` |

Each field gets one of five outcomes: `correct`, `wrong_value`, `omission` (gold present,
nothing extracted), `correct_abstention` (gold absent, nothing extracted) or `invention`
(gold absent, something extracted), plus `unjudged` for a judge field whose verdict is not cached
yet (it counts as wrong until a run with `YES=1` judges it). A case passes when every field is
`correct` or `correct_abstention`.

### Comparator gold

```json
{"winner": "a"}
```

`a`, `b` or `either` (a tie, or no objectively better side). Every case runs in both orders;
a case passes only when both orders pick the gold winner. `either` cases always pass on
agreement and only count towards consistency.

### Lister gold

```json
{"checks": [
  {"type": "top_k_any", "k": 1, "any_of": ["pepperoni", "cheese", "margherita"]},
  {"type": "any_item", "any_of": ["inspector", "food safety"]},
  {"type": "no_item", "any_of": ["astronaut"]},
  {"type": "min_items", "n": 3}
]}
```

An item matches a term when the term starts one of its words, case-insensitive: "rain" matches
"Rainy day" and "bee" matches "Bees", but "rain" does not match "train" nor "apple" "Pineapple". A
term may be a stem ("hanuk" for Hanukkah and Hanukah) or several words ("ice cream"). A case passes
when every check passes. `min_groups` (`{"min": 3, "groups": [["dog"], ["cat"], ["bird", "parrot"]]}`)
needs at least `min` of the groups, each a list of synonyms, filled by different items: "Ice cream"
fills the ice group or the ice cream group, not both, and the grader picks whichever assignment
fills the most groups. `bottom_k_none` needs none of `any_of` in the last `k` items. `eval:check`
requires each check's settings (`k`, `min`, `n`, `any_of`, `groups`) and rejects any other key. (Human answer counts for a Family Feud score need a survey of our own; see [NEXT_FOCUS.md](NEXT_FOCUS.md).)

### Scorer gold

```json
{"band": [60, 100]}
```

Passes when the score is within the band, inclusive.

A **bias pair** adds `input.twin`: the same text with one change that should not matter (padding,
a claimed credential, "most people agree", a note telling the evaluator what score to give, the
author's name or age, an impressive but irrelevant detail), named in `tags.bias`. Both texts are
scored with everything else the same, including the juries (the case's own, or juries picked once
from the text), and the gold adds `max_gap`:

```json
{"band": [35, 75], "max_gap": 10}
```

It passes when both scores are in the band and at most `max_gap` apart. The report shows the mean
gap (twin minus text) per bias type, so a positive number means the change raised the score.

## Where the cases come from

External data (datasets, fetched files) and gems must be MIT-licensed; never Apache. When no MIT
source exists, the cases are written here instead: added to a set with `"status": "draft"` and their
intended gold, labeled by two blind passes (`rake eval:blind SET=<set>` prints what they see), and
checked with `rake eval:label SET=<set>`. A row runs only when both passes agree with its gold, or a
person settles it. The extractor cells
started from CUAD (CC BY 4.0) and CondaQA (Apache-2.0); both were replaced with drafted cases for
this reason.

The comparator test cases come from [hh-rlhf](sources/hh_rlhf/NOTICE.md) (MIT): one conversation,
two possible next replies, and a crowdworker's pick of the more helpful one. Those picks are noisy,
so `sources/hh_rlhf/build.rb` adds them as drafts to the `comparator` set (`rake eval:label
SET=comparator`), and a case is kept only when both blind passes pick the same reply as the
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
red"). Each gold asks for one of the crowd's top answers in the first two items (`top_k_any`), at
least three groups of the usual answers (`min_groups`) and, in 18 of the 30, none of a few correct
but unusual answers (`no_item`: "theremin" for an instrument, "katydid" for an insect), which
catches listing like an expert instead of like the crowd. The blind labelers each play the survey
(the top 5 answers of 100 average adults), and a case is kept when both lists pass its checks.

## Tests

The eval's own code is covered by `test/unit/eval/` (part of `rake test:unit`), including an
offline run -> baseline -> regression cycle with a stubbed model.

## Known issues

[NEXT_FOCUS.md](NEXT_FOCUS.md) lists the known issues found while building the cells, sorted by the
Three Gulfs, with what to work on next, and the license check of the data planned for later phases.
