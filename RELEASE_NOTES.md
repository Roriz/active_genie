# ActiveGenie v0.30.11 Release Notes

This release introduces improvements to debate criteria evaluation, deterministic sorting, API configuration propagation, and integration test setup.

## What's Changed

### Features & Improvements

1. **Debate Criteria Scores**: Added six detailed evaluation metrics (`adherence_score`, `quality_score`, and `risk_avoidance_score` for both players) to the debate JSON schema for more granular judging.
2. **Deterministic Player Sorting**: Ensured deterministic sorting order of players by falling back to the player's ID when their Elo/ranking scores are identical.
3. **LLM Temperature Configuration**: Passed the configured `temperature` parameter to OpenAI and DeepSeek provider API calls to respect LLM config overrides.
4. **Robust Integration Testing**: Configured the integration tests to run with unbundled environments using `Bundler.with_unbundled_env` and referencing the local path to ensure robust, offline-friendly testing.

---

## Installation

To upgrade to the latest version of `active_genie`, update your Gemfile:

```ruby
gem 'active_genie', '0.30.11'
```

And run:

```bash
bundle install
```
