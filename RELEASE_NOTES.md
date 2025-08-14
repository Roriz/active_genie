# Release Notes

## Version 0.30.0 - Breaking Changes

### Interface Refactoring

This release includes significant interface changes to improve consistency and clarity across the ActiveGenie API. The following methods have been renamed or moved:

#### Data Extraction

- `ActiveGenie::DataExtractor.call` → `ActiveGenie::Extractor.call`
- `ActiveGenie::DataExtractor.generalist` → `ActiveGenie::Extractor.with_explanation`
- `ActiveGenie::DataExtractor.from_informal` → `ActiveGenie::Extractor.with_litote`

#### Comparison Operations

- `ActiveGenie::Battle.call` → `ActiveGenie::Comparator.call`
- `ActiveGenie::Battle.generalist` → `ActiveGenie::Comparator.debate`

#### Scoring and Ranking

- `ActiveGenie::Scoring.call` → `ActiveGenie::Scorer.call`
- `ActiveGenie::Scoring.generalist` → `ActiveGenie::Scorer.jury_bench`
- `ActiveGenie::Scoring.recommended_reviewers` → `ActiveGenie::Lister.juries`
- `ActiveGenie::Ranking.call` → `ActiveGenie::Ranker.call`

#### List Operations

- `ActiveGenie::Factory.feud` → `ActiveGenie::Lister.feud`

### Migration Guide

To migrate your code to the new interface:

1. Replace all occurrences of the old method names with their new equivalents
2. Update any references to the renamed classes
3. Test your implementation to ensure compatibility

### Example Migration

**Before:**
```ruby
# Old interface
result = ActiveGenie::DataExtractor.call(data)
explanation = ActiveGenie::DataExtractor.generalist(content)
comparison = ActiveGenie::Battle.call(item_a, item_b)
score = ActiveGenie::Scoring.call(items)
```

**After:**
```ruby
# New interface
result = ActiveGenie::Extractor.call(data)
explanation = ActiveGenie::Extractor.with_explanation(content)
comparison = ActiveGenie::Comparator.call(item_a, item_b)
score = ActiveGenie::Scorer.call(items)
```

### Rationale

These changes were made to:
- Improve API consistency across all modules
- Provide more descriptive method names
- Better organize functionality under appropriate class namespaces
- Prepare for future enhancements and features

⚠️ **Important**: These are breaking changes. Please update your code accordingly before upgrading to version 0.30.0.
