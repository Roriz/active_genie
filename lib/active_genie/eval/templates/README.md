# Evals

Each folder here is an eval of one LLM feature of this app. An eval runs the feature's real code
(prompt building, the model call, parsing) on cases you keep in this folder. It grades every answer
against its gold, and compares each change with a frozen baseline, using statistics that tell a real
change apart from model noise.

The engine comes from the `active_genie` gem. The data is yours: this folder, its datasets, gold and
baselines are versioned with the app.

```
evals/
  config.yml                    # dev model, judge, prices
  judge/<model>.jsonl           # cached judge verdicts (commit them)
  <name>/
    eval.rb                     # the code it runs, how answers are graded, the files it watches
    datasets.jsonl              # the cases: one row each, input and gold together
    gold.jsonl                  # blind labeling passes of drafted rows
    baselines/<provider>-<model>/   # frozen outputs of main (commit them)
    runs/                       # outputs of your working tree (gitignored)
```

## What an eval measures

An eval measures the harness: your code plus the LLM call, judged on what your code returns. The
`call` block runs the app's own code, and the grader reads what that code returns, not the raw model
text. If the model answers differently but your code normalizes or repairs that answer into the
expected result, the case passes. A prompt is one part of the harness: change it, then measure what
the harness returns.

## Running an eval

```shell
bin/rails active_genie:eval EVAL=ticket_router              # the dev pool
bin/rails active_genie:eval EVAL=ticket_router MODE=full    # every case
bin/rails active_genie:eval EVAL=all                        # every eval, one question, then a summary
```

Every run goes through the same four steps:

1. **What's in the eval.** How many cases run, how many wait for labels and how many were left
   out, for each pool. Then how varied the cases are: difficulty, tags, and what the gold asks for
   (for example, `field intent  4 values (billing 4 · delivery 4 · refund 4 · other 2)`).
2. **The plan.** How many cases are cached and how many it would call, with an estimate of the
   tokens, the cost and the time (from earlier runs), and any judge calls.
3. **It asks.** `Run it? [y/N]`. Only `y` spends anything. `YES=1` answers yes for you. Without a
   terminal (CI, a script), `YES=1` is required, so a run is never paid by accident.
4. **Progress, then the report.** A progress line shows the cases done, the time elapsed and left,
   the errors and the cost so far. The report is printed and also written to
   `<name>/runs/<run>/report-<mode>.md`, which you can paste into a pull request.

With `EVAL=all` (or `EVAL=a,b`), every eval shows its plan, and a total is added. One question
covers them all. Then each report prints, and the run ends with a summary table. It has one row per
eval (and per variant), with its rate, its delta against its baseline and its verdict, and then the
mean of the rates. Each eval counts the same in that mean, however many cases it has.

### Reading the report

```
Results
pass rate: 92.9% [68.5%, 98.7%] (13/14)
smallest change this many cases can reliably detect (MDE): ~27.5%
delta vs baseline: +35.7 pp [+14.3, +57.1] on 14 paired cases, McNemar p=0.062 (0 broke, 5 fixed)

Baseline vs now
                 now pass  now fail
  baseline pass  8         0 broke
  baseline fail  5 fixed   1

Field outcomes
                answered              left empty
  gold present  20 correct · 1 wrong  0 omission
  gold absent   0 invention           7 correct abstention

intent: gold ↓ · predicted →
            billing  delivery  refund  other
  billing         4         ·       ·      ·
  delivery        ·         3       ·      1
  refund          ·         ·       4      ·
  other           ·         ·       ·      2
accuracy 93% (13/14) · most confused: delivery → other (1)
```

- **Results**: the pass rate with a 95% interval, and the MDE, which is the smallest change this many
  cases can detect. A delta smaller than the MDE is not evidence.
- **Baseline vs now**: the cases that broke or got fixed since the baseline. These are what the
  McNemar p-value is computed from.
- **Field outcomes**: what was expected (present or absent) against what came back (an answer or
  nothing). Inventions and omissions are different failures, and they need different fixes.
- **A matrix per categorical field**: the gold value in each row, the predicted value in each
  column. Everything off the diagonal is a mistake, and the most confused pairs say where to look.
- **Score bands** (for `band` and `rubric`): whether each score landed below, inside or above its
  band.
- Then the problems (errors, missing outputs, cases waiting for the judge), the list of what broke,
  got fixed or failed, and, for the dev pool, the verdict:
  - **STOP**: a canary broke. A canary is a case the baseline passed in every replicate. The task
    exits with 1.
  - **LOOK**: something else broke, errored or is missing.
  - **GO**: nothing broke.

### The loop

1. Change a prompt, a parser or a model. The eval always runs your working tree.
2. `bin/rails active_genie:eval EVAL=...` on the dev pool, until it says GO.
3. Before merging, run it with `MODE=full`: the test pool is where tuning to the dev cases shows.
4. After merging to `main`, save the new baseline. `REPEAT=3` runs everything three times to
   measure the noise floor: how often a case flips between identical runs.

   ```shell
   bin/rails active_genie:eval EVAL=... MODE=full REPEAT=3
   bin/rails active_genie:eval:save EVAL=...
   ```

Outputs are cached per case in `<name>/runs/<provider>-<model>-<code hash>/`. Re-running only calls
the cases that are new or that errored. The code hash covers the files in `watch` and `eval.rb`, so
changing any of them starts a fresh run. `active_genie:eval:report` re-prints a report for free.

| Task | Cost | What it does |
|---|---|---|
| `active_genie:eval` | paid, asks first | Overview, plan and estimate, then runs with progress and reports (`MODE=quick\|full`, `REPEAT=n`) |
| `"active_genie:eval:new[name]"` | free | Writes `<name>/eval.rb` and a starting `<name>/datasets.jsonl` |
| `active_genie:eval:check` | free | Validates every eval, `datasets.jsonl` and `gold.jsonl` (`EVAL=` for one) |
| `active_genie:eval:status` | free | One line per eval; with `EVAL=`, its size and diversity |
| `active_genie:eval:report` | free | Re-prints the report from cached outputs (`MODE=quick\|full`) |
| `active_genie:eval:save` | free | Promotes the complete run to `<name>/baselines/` |
| `active_genie:eval:blind` | free | Prints an eval's drafts without their gold, for a blind labeler |
| `active_genie:eval:label` | free | Compares the labels with the gold and writes each draft's status |

`active_genie:eval:quick` and `active_genie:eval:full` are shortcuts for `MODE=quick` and `MODE=full`.

Environment: `EVAL=<name>`, `MODE`, `REPEAT`, `PROVIDER` and `MODEL` (default: `dev` in
`config.yml`), `YES=1` to run without the question, `BY=name` for `save`, `FORCE=1` to save while
the watched files have uncommitted changes.

## Good practices

- **Read before you grade.** Before writing any gold, run the feature on 20 to 30 real inputs and
  read every output, its reasoning included. Write down the ways it fails. Those failure modes
  become your tags and your hardest cases. A gold written before reading outputs measures the
  inputs you imagined, not the ones you get.
- **Measure the harness, not the model.** `call` runs your code the way the app does. Most bugs
  live around the model call: a prompt that leaves something unsaid, a schema that forces a guess,
  a parser that drops a field.
- **Fix the spec before reaching for a technique.** If a failing output shows the prompt never
  asked for what you expected, fix the prompt. That needs no eval. If the prompt is clear and the
  failure remains, measure how often it happens, then try stronger levers (examples, a different
  design, ActiveGenie's juries or debates).
- **Use real cases, without real people in them.** Take inputs from logs or support tickets, and
  remove names, emails and anything secret before they go into `datasets.jsonl`. It is committed.
- **Keep a test pool you never tune on.** Iterate against `dev`. Run `test` only in `full`, so a
  prompt fitted to the dev cases can't hide a regression.
- **Change one thing at a time.** Each run compares with the baseline on the same cases. Two
  changes in one run can't be told apart.
- **Don't trust a delta smaller than the MDE.** The report prints the smallest change your number
  of cases can detect (about 22 points with 30 cases). A smaller delta is not evidence. Add cases,
  or measure the noise floor with `REPEAT=3`.
- **Use the judge as a fallback.** Deterministic checks first. The LLM judge only sees fields marked
  `judge: true` whose check failed, or `rubric` rows. Its verdicts are cached and committed, so
  reports stay free and auditable.
- **One eval per feature.** Add a folder when you add an LLM feature. A small eval you run on every
  change beats a big one you never run.

## Writing an eval

`bin/rails "active_genie:eval:new[ticket_router]"` writes `ticket_router/eval.rb`:

```ruby
ActiveGenie::Eval.define 'ticket_router' do
  call { |input, context| TicketRouter.new(model: context.model).call(input['text']) }
  grader :fields
  watch 'app/services/ticket_router.rb', 'app/prompts/ticket_router/**/*'
end
```

- **`call`** gets the row's `input`, plus a context with the run's `provider`, `model` and `row`.
  It returns what the feature returns. An `ActiveGenie::Result` keeps its `data` and `reasoning`;
  anything else is stored as JSON. In a Rails app, each case runs inside the app's executor, like
  a request.
- **`grader`** is `:fields`, `:band`, `:list`, `:rubric` or `:winner` (below), or a block
  `{ |output, gold, record| ... }` that returns true/false, or a Hash with `"pass"` and any details
  to show in the report.
- **`watch`** lists the files the feature depends on, as globs from the app root. Keep it narrow:
  a change to any watched file starts a fresh, paid run. Without it, the eval uses `watch:` from
  `config.yml` (one list for every eval), else the app's `app/`, `lib/` and `config/`.

### Variants: two versions, head to head

To compare two prompts, two models or two designs, run them as **variants** of one eval instead
of two evals. Each variant runs every case, so the comparison is paired:

```ruby
ActiveGenie::Eval.define 'ticket_router' do
  variant(:v1) { |input| TicketRouter.new(prompt: :v1).call(input['text']) }
  variant(:v2) { |input| TicketRouter.new(prompt: :v2).call(input['text']) }
  grader :fields
end
```

The report shows each variant's rate, then a line per pair:
`v1 vs v2 on 30 shared cases: +1 / -6, McNemar p=0.125`. That counts how often each variant passes
where the other fails. Each variant also gets its own matrices, and is compared with its own
baseline. `context.variant` tells the block which variant it's running.

### Twin rows: an answer that must not move

A twin row is the same input with one change that should not matter: padding, a claimed
credential, the author's name, a reordered list. The eval runs the input and its twin, and the row
passes only when both outputs pass:

```json
{"id": "refund_with_title", "pool": "test", "tags": {"bias": "authority"},
 "input": {"text": "I was charged twice for order 1234."},
 "twin": {"text": "As a senior engineer, I can tell you I was charged twice for order 1234."},
 "gold": {"fields": {"intent": {"present": true, "check": "eq", "value": "refund"}}}}
```

`twin` is merged over `input`, so it only names what changes. For the `band` and `rubric` graders,
`max_gap` in the gold also limits how far apart the two scores may be. The report's "Twin pairs"
table shows the mean gap (twin minus input) for each `tags.bias`. Both calls of a pair get the same
`context.shared` Hash, for whatever they must share, so the gap comes from the change alone:

```ruby
call do |input, context|
  juries = context.shared[:juries] ||= pick_juries(input) # picked once per pair
  MyScorer.call(input['text'], juries:)
end
```

## Rows

```json
{"id": "refund_double_charge", "pool": "dev", "status": "confirmed",
 "tags": {"difficulty": "easy", "source": "support-ticket"},
 "input": {"text": "I was charged twice for order 1234."},
 "gold": {"fields": {"intent": {"present": true, "check": "eq", "value": "refund"}}},
 "why": "A plain refund request that names its order."}
```

- `id`: snake_case, unique within the eval.
- `pool`: `dev` or `test`.
- `input`: whatever your `call` block reads.
- `gold`: the expected answer, in the grader's format.
- `why`: what the case checks and why that answer is right. Write it for the person who reads a
  failure six months from now.
- `tags`: free form. `difficulty` (`easy`, `subtle`, `adversarial`) helps you see where failures
  cluster.
- `status`: see Labeling below. A row with no status always runs.

## Graders

### `fields`: an answer with named parts

The output is a Hash. Any other value is read as `{"value": output}`. Only the listed fields are
graded, and each gets an outcome: `correct`, `wrong_value`, `omission` (expected, missing),
`correct_abstention` (expected absent, absent) or `invention` (expected absent, but answered). A
case passes when every field is `correct` or `correct_abstention`.

```json
{"fields": {
  "intent":   {"present": true, "check": "one_of", "value": ["refund", "billing_issue"]},
  "order_id": {"present": false},
  "summary":  {"present": true, "check": "contains_any", "value": ["charged twice"],
               "judge": true, "question": "What is the customer asking for?",
               "reference": "a refund for a double charge"}
}}
```

`present: false` means the right answer is nothing (`nil`, `""`, `[]`). `present: "optional"`
accepts either nothing or a value that passes the check. All string checks ignore case and extra
spaces.

| `check` | Passes when the value... |
|---|---|
| `eq` | equals `value` (numbers numerically) |
| `one_of` | equals any item of `value` |
| `regex` | matches the pattern in `value` |
| `contains_any` / `contains_all` | contains any / every substring in `value` |
| `gte` / `lte` / `between` / `near` | is a number `>=`, `<=`, within `[lo, hi]`, or within `delta` of `value` |
| `nonempty` | is present and not empty |
| `date` | is a written date equal to the ISO `value` (`2026-02-10`) |

A field with `judge: true` and a `question` goes to the judge when its check fails. The judge
compares it with `reference`, a plain-language version of the gold.

### `band`: a number

`{"band": [60, 100]}` passes when the output (or the output's `"score"`) is within the band,
inclusive.

### `list`: a list of answers

```json
{"checks": [
  {"type": "top_k_any", "k": 2, "any_of": ["apple", "strawberr"]},
  {"type": "min_groups", "min": 3, "groups": [["apple"], ["cherr"], ["raspberr", "strawberr"]]},
  {"type": "no_item", "any_of": ["lychee"]}
]}
```

A term matches where a word starts: "rain" matches "Rainy day" but not "train". The check types
are:
- `top_k_any`: one of the first `k` items matches.
- `bottom_k_none`: none of the last `k` items matches.
- `any_item`: some item matches.
- `no_item`: no item matches.
- `min_items`: at least `n` items.
- `min_groups`: at least `min` of the groups are filled, each by a different item.

### `winner`: a pick between two

`{"winner": "a"}` with `"a"`, `"b"` or `"either"`. The output is the side picked (`"a"`, `"b"`,
`"either"`, or `nil` for no pick). Position bias is common in pairwise judges, so run both orders
and return `{"ab": side, "ba": side}`, with each side mapped back to the row's own a/b. Then both
orders must give the gold winner, `either` passes on any two picks, and the report shows how often
the two orders agreed.

### `rubric`: free text

`{"rubric": "Answers the question asked, cites the order number, no promises of a refund date.",
"band": [70, 100]}`. The judge scores the output 0 to 100 against the rubric, with ActiveGenie's
Scorer, and the case passes inside the band. Rubric rows are graded only by a run you confirm (or
run with `YES=1`); until then they show as `unjudged`.

## Labeling

A gold you write alone is a guess. For drafted cases, get two blind answers:

1. Add the row with `"status": "draft"` and your intended gold.
2. `bin/rails active_genie:eval:blind EVAL=<name>` prints the drafts without their gold,
   with the `fields` each answer must name. Give them to two labelers (two people, or a person and
   a model).
3. Append their answers to `<name>/gold.jsonl`, one line per answer:
   `{"id": "...", "pass": "a", "labeler": "ana", "values": {"intent": "refund"}}`. `values` has one
   entry per graded field: the field names for `fields`, `score` for `band` and `rubric`, `list`
   for `list`.
4. `bin/rails active_genie:eval:label EVAL=<name>` sets each draft's status:

| `status` | Set by | Meaning | Runs? |
|---|---|---|---|
| none | you | Hand-written, no labeling step | yes |
| `draft` | you | Not labeled by both passes yet | no |
| `confirmed` | `label` | Both passes agree with the gold | yes |
| `queued` | `label` | The passes disagree, or only the judge could accept one: decide | no |
| `dropped` | `label` | `"on_disagreement": "drop"` and a pass disagreed | no |
| `decided` | you | You settled it: fix the gold if needed, and explain in `why` | yes |
| `excluded` | you | Left out on purpose | no |

`label` re-computes `draft`, `queued`, `confirmed` and `dropped` every time. It never changes
`decided`, `excluded` or a row with no status.
