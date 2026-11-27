# Evals

Each folder here is an eval of one LLM feature of this app. An eval runs the feature's real code
(prompt building, the model call, parsing) on cases you keep in this folder. It grades every answer
against its gold, and compares each change with a frozen baseline, using statistics that tell a real
change apart from model noise.

The engine comes from the `active_genie` gem. The data is yours: this folder, its sets, labels and
baselines are versioned with the app.

```
evals/
  config.yml                    # dev model, judge, prices
  judge/<model>.jsonl           # cached judge verdicts (commit them)
  <name>/
    eval.rb                     # the code it runs, how answers are graded, the files it watches
    sets/<set>.jsonl            # the cases: one row each, input and gold together
    labels/<set>.jsonl          # blind labeling passes of drafted rows
    baselines/<provider>-<model>/   # frozen outputs of main (commit them)
    runs/                       # outputs of your working tree (gitignored)
```

## The loop

```shell
bin/rails "active_genie:eval:new[ticket_router]"      # once per feature (quoted for zsh)
bin/rails active_genie:eval:check                     # free: data integrity
bin/rails active_genie:eval:quick EVAL=ticket_router  # prints the cost of what isn't cached
YES=1 bin/rails active_genie:eval:quick EVAL=ticket_router   # runs the dev pool -> GO / LOOK / STOP
```

1. Change a prompt, a parser or a model in the app. The eval always runs your working tree.
2. `quick` runs the dev pool and compares each case with the baseline:
   - **STOP**: a canary broke. A canary is a case the baseline passed in every replicate.
   - **LOOK**: something else broke, errored or is missing.
   - **GO**: nothing broke.
3. Before merging, `YES=1 bin/rails active_genie:eval:full EVAL=...` runs every case. It reports the
   pass rate with a CI, the delta against the baseline with its CI and an exact McNemar p-value, and
   the cases that broke or got fixed.
4. After merging to `main`, promote the run to the new baseline:
   `YES=1 REPEAT=3 bin/rails active_genie:eval:full EVAL=... && bin/rails active_genie:eval:save EVAL=...`.
   `REPEAT=3` runs everything three times to measure the noise floor: how often a case flips between
   identical runs.

Outputs are cached per case in `<name>/runs/<provider>-<model>-<code hash>/`. Re-running only calls
the cases that are new or that errored. The code hash covers the files in `watch` and `eval.rb`, so
changing any of them starts a fresh run. `active_genie:eval:report` re-prints a report for free.

| Task | Cost | What it does |
|---|---|---|
| `active_genie:eval:new[name]` | free | Writes `<name>/eval.rb` and a starting set |
| `active_genie:eval:check` | free | Validates every eval, set and labels file (`EVAL=` for one) |
| `active_genie:eval:status` | free | Cases per eval, pool and status, and which baselines exist |
| `active_genie:eval:quick` | paid | The dev pool, compared with the baseline |
| `active_genie:eval:full` | paid | Every case. `REPEAT=n` for replicates |
| `active_genie:eval:report` | free | Re-prints the report from cached outputs (`MODE=quick\|full`) |
| `active_genie:eval:save` | free | Promotes the complete run to `<name>/baselines/` |
| `active_genie:eval:blind` | free | Prints a set's drafts without their gold, for a blind labeler (`SET=`) |
| `active_genie:eval:label` | free | Compares the labels with the gold and writes each draft's status (`SET=`) |

Environment: `EVAL=<name>`, `PROVIDER` and `MODEL` (default: `dev` in `config.yml`), `YES=1` to
spend money, `SET=<set>` for labeling, `BY=name` for `save`, `FORCE=1` to save while the watched
files have uncommitted changes.

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
  remove names, emails and anything secret before they go into a set. A set is committed.
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
- **`grader`** is `:fields`, `:band`, `:list` or `:rubric` (below), or a block
  `{ |output, gold, record| ... }` that returns true/false, or a Hash with `"pass"` and any details
  to show in the report.
- **`watch`** lists the files the feature depends on, as globs from the app root. Keep it narrow:
  a change to any watched file starts a fresh, paid run.

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

### `rubric`: free text

`{"rubric": "Answers the question asked, cites the order number, no promises of a refund date.",
"band": [70, 100]}`. The judge scores the output 0 to 100 against the rubric, with ActiveGenie's
Scorer, and the case passes inside the band. Rubric rows are graded only after a run with `YES=1`;
until then they show as `unjudged`.

## Labeling

A gold you write alone is a guess. For drafted cases, get two blind answers:

1. Add the row with `"status": "draft"` and your intended gold.
2. `bin/rails active_genie:eval:blind EVAL=<name> SET=<set>` prints the drafts without their gold,
   with the `fields` each answer must name. Give them to two labelers (two people, or a person and
   a model).
3. Append their answers to `<name>/labels/<set>.jsonl`, one line per answer:
   `{"id": "...", "pass": "a", "labeler": "ana", "values": {"intent": "refund"}}`. `values` has one
   entry per graded field: the field names for `fields`, `score` for `band` and `rubric`, `list`
   for `list`.
4. `bin/rails active_genie:eval:label EVAL=<name> SET=<set>` sets each draft's status:

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
