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
