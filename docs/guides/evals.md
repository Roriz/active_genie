# Evaluating your features

An LLM feature can break without any test failing. A new model, a reworded prompt or a parser
change can turn a right answer into a plausible wrong one. ActiveGenie ships the eval engine we use
on the gem itself, so you can measure your own features the same way.

An eval runs your feature's **real code**: the prompt building, the model call and the parsing,
exactly as your app does them. It runs on cases you keep in your repository and grades every answer
against its gold. Then it compares each change with a frozen baseline of `main`, using statistics
that tell a real change apart from model noise. Your feature doesn't need to use ActiveGenie for
this to work.

The engine comes from the gem, so `bundle update` brings its fixes. The data is yours: the cases,
labels and baselines live in `evals/` and are versioned with your app.

## Setup

In a Rails app, load the tasks in your `Rakefile` (see [Installation](/introduction/installation)):

```ruby
ActiveGenie.load_tasks
```

Then create an eval for a feature:

```shell
bin/rails "active_genie:eval:new[ticket_router]"
```

This writes:

```
evals/
  config.yml                  # dev model, judge model, prices
  README.md                   # the full guide: the loop, graders, labeling, good practices
  .gitignore                  # keeps runs/ out of git
  ticket_router/
    eval.rb                   # what to call and how to grade it
    datasets.jsonl            # example cases to replace with your own
```

Point `eval.rb` at your feature:

```ruby
ActiveGenie::Eval.define 'ticket_router' do
  call { |input, context| TicketRouter.new(model: context.model).call(input['text']) }
  grader :fields
  watch 'app/services/ticket_router.rb', 'app/prompts/ticket_router/**/*'
end
```

- `call` gets each case's `input`, plus the provider and model of the run.
- `grader` sets how answers are checked: `:fields` for answers with named parts (with checks such as
  `eq`, `one_of`, `regex`, `contains_any`, numeric ranges and dates), `:band` for a score, `:list`
  for lists, `:rubric` for free text scored by an LLM judge, or your own block.
- `watch` lists the files the feature depends on. When one of them changes, the next run starts
  fresh. Until then, each case's output is cached and never paid for twice.

## Running it

```shell
bin/rails active_genie:eval EVAL=ticket_router              # the dev cases
bin/rails active_genie:eval EVAL=ticket_router MODE=full    # every case
```

A run shows the eval first: how many cases are in each pool, how varied they are (difficulty, tags,
the values the gold asks for), how many are cached, and what the rest would cost and how long they
would take. Then it asks `Run it? [y/N]`. `YES=1` answers for you. In CI, where there is no terminal,
`YES=1` is required, so nothing is ever paid by accident.

While it runs, a progress line shows the cases done, the time left, the errors and the cost so far.
When it finishes, the report is printed, and also written as markdown you can paste into a pull
request:

```
intent: gold ↓ · predicted →
            billing  delivery  refund  other
  billing         ·         ·       4      ·
  delivery        ·         3       ·      1
  refund          ·         ·       4      ·
  other           ·         ·       ·      2
accuracy 64% (9/14) · most confused: billing → refund (4), delivery → other (1)
```

The report has:
- the pass rate with its confidence interval, and the smallest change this many cases can detect (MDE)
- the change against the baseline, with an exact McNemar p-value
- four confusion matrices: baseline vs now, field outcomes (expected present or absent against
  answered or left empty), one per categorical field (as above), and score bands
- the cases that broke, got fixed or failed

On the dev cases, it ends with a verdict:
- **STOP**: a case that always passed now fails.
- **LOOK**: something else broke or errored.
- **GO**: nothing broke.

1. Change a prompt, a model or the code around the call, and run it until it says GO.
2. Before merging, run it with `MODE=full`.
3. After merging, save the new baseline. `REPEAT=3` measures how often a case flips between identical
   runs.

   ```shell
   bin/rails active_genie:eval EVAL=ticket_router MODE=full REPEAT=3
   bin/rails active_genie:eval:save EVAL=ticket_router
   ```

## Comparing versions and checking for bias

- **Variants.** `variant(:v1) { ... }` and `variant(:v2) { ... }` in one eval run two prompts, models
  or designs on the same cases. The report compares them head to head:
  `v1 vs v2 on 30 shared cases: +1 / -6, McNemar p=0.125`.
- **Twin rows.** A row with a `twin` holds the same input with one change that should not matter, such
  as a claimed credential, padding or the author's name. It passes only when the answer doesn't move.
  For scores, `max_gap` limits how far the two may drift, and the report shows the mean gap per
  `tags.bias`.
- **Several evals at once.** `EVAL=all` runs every eval behind one confirmation and ends with a summary
  table.

## Gold you can trust

A gold answer you write alone is a guess. For drafted cases, give two labelers the cases without
the answers (`active_genie:eval:blind`), record their answers, and let `active_genie:eval:label`
compare them with your gold. A case runs only when both labelers agree with it, or after you settle
the disagreement yourself.

## Good practices

- **Read before you grade.** Run the feature on 20 to 30 real inputs and read every output before
  you write any gold. The ways it fails become your hardest cases.
- **Fix the prompt first.** If an output shows the prompt never asked for what you expected, fix the
  prompt. Measure, and reach for stronger techniques, only when the prompt is clear and the failure
  remains.
- **Keep a test pool you never tune on**, and change one thing at a time.
- **Don't trust a change smaller than the MDE.** The report prints the smallest change your number of
  cases can detect.
- **Never commit personal data.** Take cases from real traffic, but remove names, emails and secrets
  before they go into `datasets.jsonl`.

The `evals/README.md` that the task writes covers every grader, the case format and labeling in
detail.
