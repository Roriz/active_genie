# AGENTS.md

ActiveGenie is a Ruby gem (Ruby 3.4+) of model-agnostic GenAI modules: Extractor, Comparator,
Scorer, Lister and Ranker. Users call them from their own apps, so the public API, the error
messages and the runtime dependencies are all things users live with. `README.md` has the user view,
and `docs/` is the site at activegenie.ai.

## Before you spend money

Some commands call paid provider APIs. Run them only when the owner asks, because they cost real
money and a rerun is rarely the cheapest way to learn something:

- `rake test:e2e` and `rake test:e2e:all` (live provider calls)
- `rake active_genie:eval`, `active_genie:eval:quick` and `active_genie:eval:full`. They show an
  estimate and ask first; don't pass `YES=1` to skip that question unless the owner told you to.

These are free. Run them to check a change:

```shell
bundle exec rake test:unit               # no network; API keys are cleared first
bundle exec rubocop
bundle exec rake active_genie:eval:check # the eval config and data
```

Plain `rake test` also runs `test:integration`, which builds a Rails app in `/tmp` with
`rails new` and `bundle install`. That's free but slow and needs the network.

## Where things live

- `lib/active_genie/<module>.rb` is a thin facade, and `lib/active_genie/<module>/` holds one class
  per method of doing the job. Modules are autoloaded from `lib/active_genie.rb`.
- `lib/active_genie/providers/` holds the HTTP clients. `UnifiedProvider.function_calling` is the
  only way modules reach a model: it picks the provider and model from the config and normalizes the
  response.
- `lib/active_genie/configs/` holds the config classes. `configuration.rb` wires them together.
- `lib/active_genie/errors/` holds the user-facing errors.
- `lib/active_genie/values/` holds the plain objects the modules return or pass around, such as
  `ActiveGenie::Result`. A module's own ones live in `<module>/values/`, like
  `ranker/values/players.rb`.
- `lib/active_genie/eval/` is the eval engine. It ships with the gem so apps can eval their own LLM
  features. `evals/` is the gem's own eval data, run on that same engine.
- `lib/tasks/` is shipped. `ActiveGenie.load_tasks` loads only `install.rake` and `eval.rake` into
  apps, because `test.rake` would hook an app's `rake test` and clear its API keys. Tasks only the
  gem needs go in `tasks/`, which isn't shipped.
- `test/unit/` (offline, WebMock and per-provider fixtures), `test/integration/` (installs into a
  fresh Rails app) and `test/e2e/` (live, paid).
- `tmp/` is gitignored and skipped by RuboCop. Put scratch files and downloads there.

## How a module works

Each method of a module is usually three files with the same name. For example,
`lib/active_genie/comparator/debate.rb` loads `debate.prompt.md` (the system prompt) and
`debate.json` (the function schema the model must call). Keep prompts and fixed schemas in those
files, not in Ruby strings. A schema that depends on the inputs is built in Ruby instead, as
`scorer/jury_bench.rb` and `lister/juries.rb` do.

The class subclasses `ActiveGenie::BaseModule`. It takes its inputs plus `config:`, implements
`call`, sends messages through `UnifiedProvider.function_calling`, and returns an
`ActiveGenie::Result` (`data:`, `reasoning:`, `metadata:`). It names its preferred model in
`module_config`. The facade gives each class a named entry point and points `call` at the default
(from `lib/active_genie/comparator.rb`):

```ruby
module Comparator
  module_function

  def call(...)
    Debate.call(...)
  end

  def by_fight(...)
    Fight.call(...)
  end
end
```

When you add or change a public method, update its facade, `docs/modules/<module>.md`, and the
tests. The Ranker makes no model calls of its own. It composes `Comparator.by_debate` and
`Scorer.by_jury_bench`.

## Adding a provider

Providers are a closed list, so a new one touches every place that lists them:

1. `lib/active_genie/providers/<name>_provider.rb`: subclass `BaseProvider` (Net::HTTP with retries)
   and implement `function_calling(messages, function, **)`. Modules may pass `logprobs:` and
   `top_logprobs:`, so accept them even when the API has no logprobs.
2. `lib/active_genie/configs/providers/<name>_config.rb`: subclass `ProviderBase` with `api_key`
   (with an env fallback), `api_url`, `default_model` and `valid_model?`.
3. Register it in `ProvidersConfig::BUILT_IN` and `UnifiedProvider::PROVIDER_NAME_TO_PROVIDER`.
4. Add `test/unit/fixtures/<module>-<name>.json` for each module that calls a model. Add the
   provider's key and model to the e2e lists in `lib/tasks/test.rake` and `test/e2e/test_helper.rb`.

## Errors

Users see these errors in their own apps, so write them to be acted on. Say what was wrong, show the
value that was given, and show the config that fixes it. Follow `errors/invalid_provider_error.rb`:
a `TEXT` heredoc filled with `format`, with an `ActiveGenie.configure` example.

## Dependencies and data

- The only runtime dependency is `async`, and providers use plain Net::HTTP. Ask before adding a
  runtime gem, because it lands in every user's bundle.
- External data and dependencies need a clear open license: MIT, Apache-2.0 (the gem's own), BSD or
  CC BY. Credit the source in a `NOTICE.md` next to the data. Reject data with no license,
  non-commercial terms, or share-alike terms that would reach users' own licensing. The goal is to
  keep ActiveGenie as free and open as possible for the people who use it. See `evals/README.md`.

## Evals

An eval measures the harness: our code plus the LLM call, judged on what the code returns. It
doesn't measure the prompt or the raw model output. If the model answers in a different shape and
the code normalizes or repairs it into the expected result, that's a pass. Users only ever get what
the code returns, so that is what to grade, and fixing the parsing is as valid a fix as changing a
prompt.

The gem's evals are described in `evals/README.md`. The method (running, reading a report, writing
an eval, graders, labeling) is in `lib/active_genie/eval/templates/README.md`, which is also the
guide apps get.

## Tests

Read `test/AGENTS.md` before writing or changing tests.
