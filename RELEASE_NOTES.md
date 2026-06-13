# ActiveGenie v0.30.9 Release Notes

This release contains bug fixes to improve LLM compatibility, data safety, and Elo tournament ranking.

## What's Changed

### Bug Fixes

1. **Elo Tournament Relegation Indexing**: Fixed array slicing in `ActiveGenie::Ranker::Entities::Players` (`calc_higher_tier` / `calc_lower_tier`) to target and eliminate the actual worst-performing players.
2. **Player Circular Reference**: Fixed `Player` initialization to avoid circular references and JSON serialization crashes (`JSON::NestingError`) when passed hashes with string keys.
3. **Lister Juries Schema Mismatch**: Fixed required field name mismatch (`why_these_juries` vs `reasoning`) in the JSON schema and added robust coercion for stringified arrays.

---

## Installation

To upgrade to the latest version of `active_genie`, update your Gemfile:

```ruby
gem 'active_genie', '0.30.9'
```

And run:

```bash
bundle install
```
