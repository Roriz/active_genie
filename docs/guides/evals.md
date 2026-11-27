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
    sets/ticket_router.jsonl  # example cases to replace with your own
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

## The loop

```shell
bin/rails active_genie:eval:check                          # free: validates the data
bin/rails active_genie:eval:quick EVAL=ticket_router       # prints what the run would cost
YES=1 bin/rails active_genie:eval:quick EVAL=ticket_router # runs the dev cases -> GO / LOOK / STOP
```

1. Change a prompt, a model or the code around the call.
2. `quick` runs the dev cases and compares them with the baseline:
   - **STOP** means a case that always passed now fails.
   - **LOOK** means something else broke or errored.
   - **GO** means nothing broke.
3. Before merging, `full` runs every case. It reports the pass rate with a confidence interval, the
   change against the baseline with an exact McNemar p-value, and the cases that broke or got fixed.
4. After merging, save the new baseline:
   `YES=1 REPEAT=3 bin/rails active_genie:eval:full EVAL=ticket_router` and then
   `bin/rails active_genie:eval:save EVAL=ticket_router`. `REPEAT=3` measures how often a case flips
   between identical runs.

Paid tasks always print their cost first, and only call a model when you pass `YES=1`.

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
  before they go into a set.

The `evals/README.md` that the task writes covers every grader, the case format and labeling in
detail.
