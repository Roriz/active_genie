# ActiveGenie Unreleased

## Behavior changes to check before upgrading

- **The OpenAI default model is now `gpt-5.6-luna` (was `gpt-4o-mini`).** Any call that runs on
  OpenAI without `config.llm.model` set now uses it, including a call whose module's recommended
  model falls back to OpenAI because that model's provider has no key. This brings OpenAI in line
  with the other providers' current cheap tiers. To keep the old model, set
  `config.llm.model = 'gpt-4o-mini'` or `config.providers.openai.default_model = 'gpt-4o-mini'`.
- **`Ranker::Entities` is now `Ranker::Values`.** `ActiveGenie::Ranker::Entities::Player` and
  `ActiveGenie::Ranker::Entities::Players` are renamed to `ActiveGenie::Ranker::Values::Player` and
  `ActiveGenie::Ranker::Values::Players`, with no alias for the old names. Their behavior is the same.
  The files moved from `lib/active_genie/entities/` to `lib/active_genie/ranker/values/`, and
  `ActiveGenie::Result` keeps its name but now lives in `lib/active_genie/values/result.rb`.
- **Logprobs scoring is removed.** The latest models have mostly dropped token log probabilities, so
  the modules no longer request them and every result comes from what the model wrote.
  `ActiveGenie::Utils::LogprobsCalculator` is gone, along with the `extract_field_logprobs`,
  `calculate_continuous_score` and `aggregate_expected_rewards` helpers on `OpenaiProvider` and
  `GoogleProvider`. `UnifiedProvider.function_calling` no longer takes `logprobs:` or `top_logprobs:`,
  and providers return the parsed answer, never a `{ data:, logprobs: }` pair.
- **`Comparator.by_debate`'s winner is always the judge's written `impartial_judge_winner`.** Before,
  on OpenAI and Google, the per-player expected rewards (or the judge token's probabilities) could
  override it. Anthropic and DeepSeek already used the written pick.
- **`Scorer.by_jury_bench`'s score is always the written `final_score`.** It is the number the model
  wrote, usually an integer, not a continuous expected value over the score tokens. A missing
  `final_score` still reads as 0.
- **Removed metadata keys.** `Comparator.by_debate` no longer sets `logprobs_used`, `logprobs_winner`,
  `player_a_expected_reward`, `player_b_expected_reward`, `player_a_normalized_score`,
  `player_b_normalized_score`, `player_a_winner_probability` or `player_b_winner_probability`.
  `Scorer.by_jury_bench` no longer sets `logprobs_used`, `continuous_final_score`,
  `final_score_expected_value`, `final_score_normalized`, `juries_raw_expected_reward` or
  `juries_normalized_score`. The fields the model writes are still in the metadata.
- **One error tree with codes (breaking).** Every error ActiveGenie raises now inherits
  `ActiveGenie::Error < StandardError`, has a stable code (`e.code`, such as `"AG-E104"`), and a
  message in three parts: what went wrong with the values involved, `How to fix:`, and a link to its
  entry in the new [errors reference](https://activegenie.ai/reference/errors). Each class lives in
  `lib/active_genie/errors/`. Rescue `ActiveGenie::Error` to catch them all.
  - **Provider errors moved.** `ActiveGenie::Providers::BaseProvider::ProviderUnknownError`,
    `ProviderTransientError`, `InvalidResponseError` and `RefusalError` (also reachable as
    `OpenaiProvider::...` and the like) are now `ActiveGenie::ProviderUnknownError`,
    `ActiveGenie::ProviderTransientError`, `ActiveGenie::InvalidResponseError` and
    `ActiveGenie::RefusalError`. Update your `rescue` clauses; there are no aliases.
  - **New provider errors.** An answer cut off at the token limit raises
    `ActiveGenie::TruncatedResponseError`, a subclass of `InvalidResponseError`. A network failure
    (`Net::OpenTimeout`, `Net::ReadTimeout`, `Errno::ECONNREFUSED`) that survives every retry raises
    `ActiveGenie::ProviderConnectionError`, with the network error as `cause`, instead of the bare
    network error. A 2xx body that isn't JSON raises `InvalidResponseError`, not
    `ProviderUnknownError`. Which errors are retried, and how often, is unchanged.
  - **Messages changed.** `ProviderUnknownError` reads `OpenAI answered HTTP 401 for model "gpt-5":
    <body>` instead of `Unexpected response: 401 - <body>`, plus a hint for the status. Match on the
    class or `e.code`, not on the text.
  - **`ArgumentError` and `NotImplementedError` are gone.** `config.providers.add` with a name
    ActiveGenie can't call raises `ActiveGenie::InvalidProviderError`. A non-Hash `scope:` for
    `config.log.add_observer` raises `ActiveGenie::InvalidLogScopeError`. A `BaseModule` subclass
    without `call` raises `ActiveGenie::CallNotImplementedError`.
  - **`ActiveGenie::ProviderServerError` is removed.** Nothing raised it.
  - **Eval errors split.** `ActiveGenie::Eval::Error` is now the base of 25 specific classes, such as
    `Eval::ConfigMissingError` and `Eval::UnknownEvalError`, each with its own code (`AG-E2xx`).
    `rescue ActiveGenie::Eval::Error` still catches them all. The eval rake tasks print any
    `ActiveGenie::Error` without a backtrace.
- **An unknown `providers.default` raises `InvalidProviderError` (breaking).** Before, a name such as
  `'cohere'` (in `config.providers.default` or `PROVIDER_NAME`) fell through to another provider with
  a key, or to `WithoutAvailableProviderError` when none had one.
- **A default provider without an API key raises `ProviderWithoutApiKeyError` (breaking).** Before,
  `config.providers.default = 'anthropic'` (or `PROVIDER_NAME=anthropic`, or a call's
  `providers: { default: 'anthropic' }`) with no `ANTHROPIC_API_KEY` silently called whichever other
  provider had a key. It now raises `ActiveGenie::ProviderWithoutApiKeyError` (`AG-E007`), which names
  the missing environment variable. A default that `config.providers.remove` took out raises
  `ActiveGenie::DefaultProviderRemovedError` (`AG-E008`), which says it was removed. With no default
  set, ActiveGenie still uses the first provider with a key, and a module's recommended model whose
  provider has no key is still skipped. `rake active_genie:eval` (and `Eval::Runner#run!`) checks the
  pinned provider, and the judge's when a case needs it, before it asks to spend, so a missing key
  stops the run once instead of failing every case.
- **A model no provider recognises raises `InvalidModelError` (breaking).** When `config.llm.model`
  is set without `config.providers.default`, ActiveGenie picks the provider from the model name. If no
  provider with a key recognises it (`o3`, a fine-tune, a gateway model), the call used to swap in
  another provider's default model without a word. It now raises `InvalidModelError`, which shows the
  `providers.default` to set. A provider's own `default_model` now always resolves to that provider.
- **Fix: `InvalidLogOutputError` was a `NameError`.** Its file was never loaded, so setting
  `config.log.output` to something that can't be called raised `NameError` instead.

---

# ActiveGenie v1.0.0.rc2 Release Notes

The second release candidate for 1.0. The eval engine the gem uses on itself now ships in the gem, so
a Rails app can measure its own LLM features the same way. The gem's own evals run on that engine.

## Evals for your Rails app

- **`ActiveGenie::Eval` (#97, #98, #99).** Define an eval of any LLM feature in your app, whether or
  not it uses ActiveGenie. The engine lives in the gem, so `bundle update` brings its fixes. The data
  lives in your app's `evals/` and is versioned with it.

  ```ruby
  ActiveGenie::Eval.define 'ticket_router' do
    call { |input, context| TicketRouter.new(model: context.model).call(input['text']) }
    grader :fields          # or :band, :list, :winner, :rubric, or a block
    watch 'app/services/ticket_router.rb'
  end
  ```

- **Rake tasks.** Add `ActiveGenie.load_tasks` to your `Rakefile`, then:
  - `active_genie:eval:install` writes `evals/config.yml`, `evals/README.md` (the method guide) and
    `evals/.gitignore`. `active_genie:eval:new[name]` starts an eval. Neither overwrites a file.
  - `active_genie:eval:check` and `active_genie:eval:status` are free.
  - `active_genie:eval EVAL=<name>` (or `a,b`, or `all`) shows the cases and the cost estimate, asks
    `Run it? [y/N]`, runs, and reports. `MODE=quick` (the default) runs the dev pool against the
    baseline and answers GO, LOOK or STOP. `MODE=full` runs every case, and `REPEAT=n` measures the
    noise floor. `active_genie:eval:quick` and `active_genie:eval:full` are shortcuts.
  - `active_genie:eval:report` re-prints a report from cached outputs, and `active_genie:eval:save`
    promotes a full run to the committed baseline.
  - `active_genie:eval:blind` prints the drafts without their gold for a blind labeler, and
    `active_genie:eval:label` compares the labels with the gold and writes each draft's `status`.
- **What a run gives you.** Nothing is called without a yes (or `YES=1` off a terminal). Outputs are
  cached per case and keyed by a hash of the watched files. The report has the pass rate with a CI,
  McNemar against the baseline, and confusion matrices (field outcomes, each categorical field, score
  bands, winners). It is also written as markdown you can paste into a pull request. Variants compare
  several methods on the same cases. Twin rows check that a change that shouldn't matter doesn't move
  the answer. A pinned LLM judge is used only as a fallback, and its verdicts are cached in a
  committed file.
- **One file per eval (#104).** Each eval is `evals/<name>/eval.rb`, `datasets.jsonl` (the cases, with
  their gold) and `gold.jsonl` (the blind labeling passes). There are no `sets/` or `labels/`
  folders, and `blind` and `label` take only `EVAL=` (`SET=` is gone).
- **Evals measure the harness (#105).** An eval grades what your code returns: the code plus the LLM
  call. It never grades a prompt or the raw model text on its own. If your code repairs the model's
  answer into the right result, the case passes.
- **`EVAL=all` summary (#102).** A `fields` column (the share of fields right) sits next to the
  all-or-nothing case rate.
- **Fix: `ActiveGenie.load_tasks` loads only `install.rake` and `eval.rake` (#97).** Before, apps also
  got the gem's `test.rake`, which hooked `rake test` and cleared the API keys.

See `docs/guides/evals.md`, and the `evals/README.md` that `install` writes.

## Behavior changes to check before upgrading

- **Placeholders wrapped in punctuation become `nil` (#102).** `UnifiedProvider` now strips the
  surrounding punctuation before it matches a placeholder, so `":null"`, `"\"None\""`, `"(unknown)"`
  and `"null."` come back as `nil`. `"None of the above"` and `"-"` stay values.
- **Enum values that look like placeholders are kept (#102).** With `enum: %w[none mild severe]`, an
  answer of `"none"` used to become `nil`, and `Extractor.data` dropped the field. A value the field's
  own enum lists is now kept.
- **Two edge cases in `LogprobsCalculator` (#111),** both on input no provider sends:
  `extract_field_candidates` reads symbol keys before string keys (it matters only when a hash has
  both with different values), and an index whose step is `nil` returns `nil` instead of raising
  `NoMethodError`.
- **No layout migration for the eval engine.** It wasn't in rc1, so nothing released changes. If you
  tried it from `main`, move `sets/<name>.jsonl` to `datasets.jsonl` and `labels/<name>.jsonl` to
  `gold.jsonl` (#104).

## Refactors

- **RuboCop todo cleared (#111).** `.rubocop_todo.yml` is gone, and every offense it hid is fixed with
  no raised limits or `rubocop:disable` comments. The logprobs calculator, the OpenAI, Google and
  unified providers, the Debate comparator, the JuryBench scorer, `Lister::Juries`, `Explanation`,
  `Litote`, Elo and free-for-all are split into named methods. Behavior is the same apart from the two
  edges above. 38 new unit tests cover them.

## The gem's own evals and repo

- **The gem's evals run on `ActiveGenie::Eval` (#99).** `eval/` is now `evals/`, one eval per method,
  run with `rake active_genie:eval`.
- **One extractor eval (#103).** `extractor_data` and `extractor_with_explanation` are joined into
  `extractor`, with `data` and `with_explanation` as variants on the same 74 cases.
- **hh-rlhf is committed (#101).** The comparator's source split is a verbatim copy in
  `evals/comparator/sources/hh_rlhf/data/`, checked against its pinned SHA-256, instead of a download.
  It isn't shipped in the gem.
- **License rule (#100).** Eval data and dependencies can use any clear open license (MIT,
  Apache-2.0, BSD, CC BY, ...), credited in a `NOTICE.md`. Data with no license, NC terms or
  share-alike terms that would reach users is still out.
- **`prompts:check` is removed (#105).** Its file checks are now a unit test,
  `test/unit/prompt_files_test.rb`.
- **Known issues triaged (#102).** `evals/NEXT_FOCUS.md` says where each open item stands.
- **The Eval workflow is removed (#108).** Evals run locally. The release models and their commands
  are listed in `evals/README.md`.
- **Cleanup.** The unused dev container (#107) and `.rspec` / `rubocop-rspec` (#110) are removed.
  Agent rules moved to `AGENTS.md` (#109) and `test/AGENTS.md` (#106).
- **Gemspec.** `changelog_uri` and `spec.files` now point at `RELEASE_NOTES.md`, not a
  `CHANGELOG.md` that didn't exist.

## Upgrading

This is a prerelease, so Bundler needs the exact version:

```ruby
gem 'active_genie', '1.0.0.rc2'
```

**Full Changelog**: https://github.com/Roriz/active_genie/compare/v1.0.0.rc1...v1.0.0.rc2

---

# ActiveGenie v1.0.0.rc1 Release Notes

The first release candidate for 1.0. The major version marks a new way of measuring the gem: a
golden-set eval in `eval/` replaces the old e2e benchmark, and every change to `lib/` is now measured
against a frozen baseline, with statistics that tell a real change apart from model noise.

This is also the first release on RubyGems since 0.30.9. Versions 0.30.10 to 0.32.4 were never
published, so their changes are included here too.

## The new eval process

- **Golden sets instead of e2e tests (#86).** Cases and their expected answers are data you version
  and audit: `eval/sets/<set>.jsonl`, one row per case. A cell is one public method (8 cells across
  Comparator, Extractor, Lister and Scorer). Cases are in a `dev` pool, which you iterate against, or
  a `test` pool, which only `eval:full` runs.
- **The loop.** `rake eval:check` is free. `rake eval:quick` runs the dev pool against the baseline and
  answers GO, LOOK or STOP. `rake eval:full` reports the weighted pass rate with a CI, the delta with
  an exact McNemar p-value, the noise floor across replicates, and what broke or got fixed. Paid runs
  print their cost and only call a model with `YES=1`, and outputs are cached per case.
- **Test pools from MIT-only data (#87, #89, #91, #92).** Extractor, scorer and lister cases are drafted
  here. Comparator cases come from Anthropic's hh-rlhf. Each drafted case runs only when two blind
  labeling passes agree with its gold.
- **Graders built for each module.** Extractor fields get one of five outcomes: correct, wrong value,
  omission, correct abstention or invention. An LLM judge handles free-text fields only when their
  deterministic check fails. Comparator cases run in both orders. Scorer bias pairs measure how much an
  irrelevant change (verbosity, authority, injection, ...) moves the score. Lister checks grade Family
  Feud style answers (#93).
- **One row per case (#95).** `rake eval:label` writes each drafted row's `status`, and
  `rake eval:blind` prints what a blind labeler sees.
- **Where to go next (#94).** `eval/NEXT_FOCUS.md` sorts the known issues by the Three Gulfs
  (comprehension, specification, generalization) and lists the next steps.

See `eval/README.md` for the full guide.

## Behavior changes to check before upgrading

- **The Extractor can return `nil` for non-boolean fields (#88).** Before, it invented placeholders
  for data the text didn't state. Boolean fields keep their type and answer `false`.
- **`Extractor.with_litote`** puts its rhetorical analysis (`message_litote`, `litote_rephrased`) in
  `result.metadata`, not `result.data`.
- **`config.extractor.min_accuracy` is enforced** (default 70). Fields whose `*_accuracy` confidence
  is below it are dropped.
- **`Ranker.by_scoring` returns an `ActiveGenie::Result`**, with its `data` sorted best first.
- **`Scorer.call` accepts `juries:`** as a keyword argument, like `Ranker.call`. The positional form
  still works.
- **Unusable provider answers raise instead of returning `{}` (#84, #85).** The new errors are
  `InvalidResponseError` and `RefusalError`, under `ActiveGenie::Providers::BaseProvider`. Schema
  fields named `message` now work with OpenAI and DeepSeek.
- **Rate limits (408, 429) and server errors (5xx) are retried with backoff (#72).** They raise
  `ProviderTransientError`, a subclass of `ProviderUnknownError`, once retries run out.
  `max_retries` now means retries after the first attempt.
- **Default models moved to each provider's newest cheap tier (#78).**
- **Ranker:**
  - An undecided Elo match is a draw, and ratings stay zero-sum (#80).
  - Elo opponents alternate (#79).
  - Free-for-all matches credit the right player (#74).
  - Every player is scored by the same jury (#75).
- **`Lister::Juries`** now uses its own prompt, not the Family Feud one (#90).
- **Logprobs continuous scoring** in the provider layer, the debate comparator and the jury bench
  scorer (0.31.0).
- **Removed:** the e2e benchmark rake tasks (`lib/tasks/benchmark.rake`, `bin/benchmark_and_report`).
  Use `rake eval:*` instead.

## Fixes

- The Google API key no longer leaks into logs (#71).
- Every system message is sent to Anthropic, not only the first (#73).
- A failing log observer or output no longer crashes the call (#76).
- A provider that omits token usage no longer crashes or logs `nil` (#77).
- `providers.add` and `providers.remove` work (#83).
- Google returns a clear error when it gives no usable answer (#84).
- The Rails integration test loads Bundler in CI (#82).
- RuboCop passes on the whole codebase (#81).

---

## Upgrading

This is a prerelease, so Bundler needs the exact version:

```ruby
gem 'active_genie', '1.0.0.rc1'
```

**Full Changelog**: https://github.com/Roriz/active_genie/compare/v0.30.9...v1.0.0.rc1
