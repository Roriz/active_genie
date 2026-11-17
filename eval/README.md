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
were written alongside them. Test-pool cases come from public datasets and generated cases in later
phases.

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

## Data

See [FORMAT.md](FORMAT.md) for the case, gold and pool formats.

External data (datasets, fetched files) and gems must be MIT-licensed; never Apache. When no MIT
source exists, the cases are written here instead: drafted with their intended gold in
`eval/labeling/drafts/`, labeled by two blind passes, and merged with `rake eval:label CELL=<cell>`.
A field enters the gold only when both passes agree with the draft, or a human decision in
`eval/labeling/<cell>/decisions.jsonl` (append-only, latest wins) settles it. The extractor cells
started from CUAD (CC BY 4.0) and CondaQA (Apache-2.0); both were replaced with drafted cases for
this reason.

## Tests

The eval's own code is covered by `test/unit/eval/` (part of `rake test:unit`), including an
offline run -> baseline -> regression cycle with a stubbed model.

## Known issues and future improvements

Found while building the extractor cells (2026-11-17, gpt-6.1-terra). Each one is a hypothesis to
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
