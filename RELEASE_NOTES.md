# ActiveGenie v0.32.1 Release Notes

A documentation accuracy release. Every page was verified line by line against the source, which turned up one provider compatibility bug and a set of documented APIs that did not match the code. No public API changed.

## What's Changed

### 1. Fixed: schema property keys rejected by Anthropic

`Scorer` builds its response schema from jury names, so a jury called `"Senior Software Engineer"` produced the property key `Senior Software Engineer_score`. Anthropic validates property keys against `^[a-zA-Z0-9_.-]{1,64}$` and rejected the request with a 400. OpenAI, DeepSeek, and Google accept spaces, so the failure only appeared on Anthropic.

`ActiveGenie::TextCase.underscore` had two gaps behind this:

- It returned the input unchanged when the string had no uppercase letter, hyphen, or `::`, so a lowercase jury name kept its spaces.
- On the main path it only translated spaces and hyphens, leaving `&`, `(`, `)`, and `'` in place.

It now sanitizes to the allowed character set, collapses repeated separators, truncates at 64 characters, and falls back to `unnamed` when nothing usable remains. Previously working names such as `"Senior Software Engineer"` and `"Front-End Developer"` produce the same keys as before.

A second case sat behind the same limit. `Scorer` appends `_reasoning` and `_score` to the sanitized name, so a 64 character key became a 74 character property. `underscore` now takes a `max_length:` keyword and `Scorer` reserves room for the longest suffix.

This restores `Scorer` and `Ranker` on Anthropic, which were failing on every call that reached the jury schema. Added `test/unit/utils/text_case_test.rb` with 13 regression tests; the helper previously had none.

Measured effect on the 100 test end-to-end suite against `claude-haiku-4-5-20251001`: 73 passing before the fix, 87 after. `Scorer` went from 12/20 to 19/20 and `Ranker` from 8/20 to 15/20.

### 2. Corrected documented APIs that did not match the code

The return shapes were wrong for four of the five modules. `Result#data` is narrow, and the detail lives in `metadata`:

- `Comparator` returns the winning input itself, not a hash. There is no `loser` key.
- `Scorer` returns the final score as a number, not a hash of per-jury scores.
- `Ranker` returns a plain array ordered best first. There is no `rank` or `statistics` key.
- `Extractor` returns only the schema fields. The `*_explanation` and `*_accuracy` fields are in `metadata`.
- `Extractor.call` returns symbol keys while `Extractor.data` returns string keys.

The per-call `config:` hash is nested by section. Every documented example used a flat form that ActiveGenie silently ignores:

```ruby
config: { model: 'deepseek-chat' }          # ignored, raises nothing
config: { llm: { model: 'deepseek-chat' } } # correct
```

Configuration reference corrections: `config.ranking` is `config.ranker`, `config.data_extractor` is `config.extractor`, `config.llm.provider` is `provider_name` and is read only, and `providers.add` takes `(name, provider_configs)`. The settings `with_explanation`, `verbose`, and `llm.client` do not exist and were removed from the docs. `config.lister.number_of_items`, `config.llm.max_fibers`, and `config.llm.recommended_model` were undocumented and are now covered.

Also removed several model identifiers that do not exist, including `gpt-5.6-luna`, `deepseek-v4-flash`, and the `gpt-999` placeholder. Model IDs now live in a single table in the configuration reference, sourced from the provider defaults and each module's `recommended_model`.

### 3. Documented behaviour that was previously undocumented

- The five error classes, and which of them actually get raised.
- Retries cover connection timeouts and refused connections only. A non-2xx response becomes `ProviderUnknownError`, which the retry path does not catch, so rate limits and provider outages are not retried.
- Requests run concurrently through `async` in batches of `config.llm.max_fibers`, default 10.
- Call volume per module. `Ranker` debates every surviving pair, so cost grows quadratically: 4 items is 6 debates, 30 items is 435.
- Ruby 3.4.0 or newer is required.
- How to stub `ActiveGenie::Providers::UnifiedProvider.function_calling` when testing application code.
- `Comparator.by_debate` and `Extractor.data`, both public and both previously absent from the docs.

### 4. Known issues now stated in the docs rather than left implicit

- `config.extractor.min_accuracy` has no effect. The private `min_accuracy` method in `explanation.rb` is never called, and nothing filters on the `*_accuracy` values the model returns.
- `ActiveGenie::ProviderServerError`, `InvalidModelError`, and `InvalidProviderError` are defined but never raised.
- `Ranker.by_scoring` returns the internal batching structure instead of an `ActiveGenie::Result`.

### 5. Documentation restructure

All five module pages follow one template. Installation is framework agnostic with Rails in its own section, rather than assuming Rails throughout. The benchmark history page was removed along with its charts, leaving a single benchmark page. The landing page CTA no longer points at an unreachable host, and the feature cards link to their module pages.

Prose across all 13 pages and the README was rewritten in one plain, direct voice.

---

## Upgrading

No code changes are required. Anyone using `Scorer` or `Ranker` with Anthropic should upgrade, since those paths were failing before this release.

Update your Gemfile:

```ruby
gem 'active_genie', '0.32.1'
```

And run:

```bash
bundle install
```
