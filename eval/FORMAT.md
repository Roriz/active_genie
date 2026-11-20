# Eval data format

Inputs and expected answers live in separate files, so a case can be relabeled without
touching its input, and an input can be read without seeing its answer.

```
eval/
  cells.json                 # the cells (one per public method) and their weights
  cases/<cell>.jsonl         # inputs, one case per line
  gold/<cell>.jsonl          # expected answers, one per case id
  pools.jsonl                # which pool (dev | test) and role (hard | canary) each case is in
  baselines/<system>/        # frozen outputs of main (committed)
  runs/<system>/             # outputs of your working tree (gitignored)
```

A **cell** is `<module>.<method>`, for example `extractor.data` or `comparator.by_fight`.

## Case line (`cases/<cell>.jsonl`)

```json
{"id": "hr_resume_data", "cell": "extractor.data", "source": "e2e-migration",
 "tags": {"domain": "hr", "difficulty": "easy"},
 "input": { ... }}
```

- `id`: unique within the cell, snake_case.
- `source`: where the case came from (`e2e-migration`, `cuad`, `generated`, ...).
- `tags.difficulty`: `easy`, `subtle` or `adversarial`. `tags.domain`: free text.
- `input`: the arguments for the method, by cell:

| Cell | `input` keys |
|---|---|
| `extractor.data`, `extractor.with_explanation`, `extractor.with_litote` | `text`, `schema` (the `data_to_extract` hash) |
| `comparator.by_debate`, `comparator.by_fight` | `player_a`, `player_b`, `criteria` |
| `lister.with_feud` | `theme` |
| `lister.with_juries` | `text`, `criteria` |
| `scorer.by_jury_bench` | `text`, `criteria`, optional `juries` (array) |

Any cell may also carry `input.config`, a hash passed as `config:` to the method.

## Gold line (`gold/<cell>.jsonl`)

```json
{"id": "hr_resume_data", "gold": { ... }, "why": "...", "labeled_by": "e2e-migration"}
```

`why` explains what the case checks and why that answer is correct.

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

An item matches when it contains any of the substrings, case-insensitive. A case passes when
every check passes. (Phase 4 adds human answer counts for the Family Feud score.)

### Scorer gold

```json
{"band": [60, 100]}
```

Passes when the score is within the band, inclusive.

## Pools (`pools.jsonl`)

```json
{"cell": "extractor.data", "id": "hr_resume_data", "pool": "dev", "role": null}
```

`role` is assigned from the baseline by `rake eval:save`: `canary` when the baseline passes the
case, `hard` when it fails. A `quick` run stops (STOP) if any canary breaks.
