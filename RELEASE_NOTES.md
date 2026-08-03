# ActiveGenie v0.32.3 Release Notes

Documentation only. No library code changed. The benchmark now reports variation across repeated runs instead of a single measurement.

## What's Changed

### 1. Benchmark run three times per provider

The suite ran three full repetitions against each of the four providers, 1,200 test executions in total, on the same day and the same version of the gem.

| Provider | Model | Run 1 | Run 2 | Run 3 | Mean | Range |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| OpenAI | `gpt-5.6-luna` | 94 | 94 | 93 | 93.7% | 93 to 94 |
| Anthropic | `claude-haiku-4-5` | 91 | 94 | 93 | 92.7% | 91 to 94 |
| Google | `gemini-3.5-flash-lite` | 91 | 90 | 93 | 91.3% | 90 to 93 |
| DeepSeek | `deepseek-v4-flash` | 86 | 89 | 87 | 87.3% | 86 to 89 |

### 2. The ranking published in v0.32.2 was not reliable

That release reported a single run: OpenAI 94, Anthropic 91, Google 91, DeepSeek 86. Repeating the measurement shows those numbers sit inside a 3 point band of run-to-run noise.

The ranges for OpenAI, Anthropic, and Google overlap, so this suite provides no evidence that the three differ in quality. Anthropic produced both the joint best single run and the lowest of its own three. Anyone choosing between them should use cost, latency, or availability rather than these scores.

`deepseek-v4-flash` is the one genuine separation. Its best run still falls below every other provider's worst run, and the deficit is concentrated in `Scorer`.

### 3. Variation chart

The benchmark page now carries a dot plot showing all three runs per provider with the observed range. It is an inline SVG that follows the reader's light or dark theme, with a per-dot tooltip giving the exact run and score.

The per-module table reports the mean with the observed range wherever runs disagreed, so a stable module is visibly distinct from a volatile one. `Lister` on Google is the least stable at 16 to 18 out of 20. `Ranker` is the most stable, but that reflects a known bug rather than consistency.

### 4. Known issues unchanged

`Ranker.by_scoring` still returns the internal batching structure rather than the scored players. The same four tests fail on every provider in every run because of it, and no model can pass them until it is fixed.

`Comparator` scores 100% for three of four providers in every run, so its assertions no longer discriminate.

---

## Upgrading

Nothing to do. This release changes documentation only.

```ruby
gem 'active_genie', '0.32.3'
```
