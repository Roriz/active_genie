# ActiveGenie v0.32.4 Release Notes

Comprehensive documentation & code alignment. Harmonized API signatures, standardized module return contracts, enforced extraction confidence thresholds, and reconciled model recommendations.

## What's Changed

### 1. Harmonized `juries` parameter syntax across modules
`ActiveGenie::Scorer.call` now accepts `juries:` as a keyword argument (`juries: [...]`), matching `ActiveGenie::Ranker.call` while preserving positional argument compatibility.

### 2. Standardized `Ranker.by_scoring` return contract
`Ranker.by_scoring` now returns a standard `ActiveGenie::Result` object with `data` containing players sorted best-first by score, fixing the return type contract and eliminating internal batch array leakage.

### 3. Isolated litote analysis metadata in Extractor
`Extractor.with_litote` now places rhetorical analysis keys (`message_litote`, `litote_rephrased`) strictly into `result.metadata`. `result.data` strictly contains your requested schema fields.

### 4. Enforced `config.extractor.min_accuracy` thresholding
`Extractor.call` / `.with_explanation` now actively filters out extracted fields whose `*_accuracy` confidence score falls below `config.extractor.min_accuracy` (default 70).

### 5. Reconciled documentation & model recommendations
Updated documentation across all modules, configuration references, and Vitepress assets to align recommended default models with live benchmark results and clarify provider score calibration.

---

## Upgrading

```ruby
gem 'active_genie', '0.32.4'
```
