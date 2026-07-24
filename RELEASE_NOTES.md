# ActiveGenie v0.30.12 Release Notes

This release introduces comprehensive real-layer test coverage and assertion improvements across core modules without artificial mocking.

## What's Changed

### Features & Test Coverage Improvements

1. **Tournament Ranker Coverage (`Ranker::Tournament`)**: Added real integration tests for score variation elimination (`variation_too_high`), Elo tier relegation (`relegation_tier`), Elo non-participant rebalancing, juries normalization, and `ranker_id` generation.
2. **JuryBench Scorer Coverage (`Scorer::JuryBench`)**: Added tests for explicit vs automatic jury recommendation, function schema property generation with underscored jury names, fallback zero scores, and provider metadata format.
3. **Juries Lister Coverage (`Lister::Juries`)**: Added tests for stringified JSON array parsing, comma-separated string parsing with space/empty string filtering, non-string element normalization, and `identify_jury` tool payload structure.
4. **Feud Lister Coverage (`Lister::Feud`)**: Added tests for dynamic `number_of_items` configuration in system prompts, missing items fallback, and recommended model configuration.
5. **Structured Data Extractor Coverage (`Extractor::Data`)**: Added new unit tests verifying schema property injection, missing explanation field exclusion, and `.compact` filtering for `nil` values in extracted data.
6. **Debate Comparator Coverage (`Comparator::Debate`)**: Added tests for `player_b` as winner, draw/nil winner handling, metadata breakdown assertions, and delegation methods.

---

## Installation

To upgrade to the latest version of `active_genie`, update your Gemfile:

```ruby
gem 'active_genie', '0.30.12'
```

And run:

```bash
bundle install
```
