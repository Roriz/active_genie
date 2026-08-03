# Benchmark

**Version**: v0.32.2
**Measured**: 3 August 2026
**Suite**: 100 end-to-end tests across 5 modules, 20 per module
**Providers**: OpenAI, Anthropic, Google, DeepSeek

## What this measures

Every test in this suite calls a live provider API. The suite uses no mocks, stubs, or recorded fixtures. A test passes only if the model's decision is correct, so the assertions check whether the model picked the right winner, extracted the right value, or put the right item first.

Earlier versions of this suite asserted things like "reasoning is longer than 10 characters" or "the score is between 0 and 100". Assertions like those pass almost unconditionally and measure nothing. They were replaced with assertions on decision quality, so a failure now means the model got something wrong rather than that it wrote a short sentence.

**What it does not measure**: latency, cost, throughput, or behaviour on your own data. Treat the pass rates as a regression signal and a rough capability comparison.

Results vary between runs. LLM outputs are non-deterministic and providers update models without notice.

## Results

All four providers ran the same 100 tests on the same day against the same version of the gem.

| Rank | Provider | Model | Passed | Pass rate |
| :---: | :--- | :--- | :---: | :---: |
| 1 | OpenAI | `gpt-5.6-luna` | 94 / 100 | 94% |
| 2 | Anthropic | `claude-haiku-4-5` | 91 / 100 | 91% |
| 2 | Google | `gemini-3.5-flash-lite` | 91 / 100 | 91% |
| 4 | DeepSeek | `deepseek-v4-flash` | 86 / 100 | 86% |

## By module

| Module | OpenAI | Anthropic | Google | DeepSeek |
| :--- | :---: | :---: | :---: | :---: |
| `Comparator` | 100% (20/20) | 90% (18/20) | 100% (20/20) | 100% (20/20) |
| `Extractor` | 100% (20/20) | 100% (20/20) | 95% (19/20) | 90% (18/20) |
| `Lister` | 100% (20/20) | 100% (20/20) | 90% (18/20) | 100% (20/20) |
| `Ranker` | 75% (15/20) | 70% (14/20) | 70% (14/20) | 75% (15/20) |
| `Scorer` | 95% (19/20) | 95% (19/20) | 100% (20/20) | 65% (13/20) |
| **Total** | **94%** | **91%** | **91%** | **86%** |

## How to read these numbers

Three caveats matter more than the ranking.

**`Ranker` is depressed by a library bug, not by the models.** Four of the six `Ranker` failures are the same four tests on every provider, and they fail because [`Ranker.by_scoring`](/modules/ranker#by-scoring-players-criteria-juries-config) returns the internal batching structure instead of the scored players. A test asking for three scored bugs gets one batch back. Those four tests cannot pass on any model until that is fixed. Discount roughly 4 points from every provider's `Ranker` column when comparing models to each other.

**`Comparator` barely discriminates.** Three of four providers score 100%. Assertions that almost everything passes are not measuring much, and they are due for tightening.

**`Extractor` results changed meaning this release.** Six tests in this module read string-keyed results with symbol keys, and three declared array schemas without an `items` type. They failed on every provider for reasons unrelated to model quality. Both are fixed, which is why `Extractor` jumped from roughly 65% to 90% and above. Comparisons with benchmark figures from before v0.32.2 are not meaningful for this module.

## Notable failures

Real outputs from this run.

### Every model ranks Python above Scratch for seven-year-olds

- **Module**: `ActiveGenie::Ranker.by_elo`
- **Test**: `test/e2e/ranker/education_programming_elo_test.rb`
- **Prompt**: Rank programming languages for teaching seven-year-olds to code.
- **Expected**: `Scratch` first.
- **All four providers returned**: `{"language":"Python","paradigm":"General purpose"}` first.

This is the only test in the suite that fails on every provider for genuine model reasons. Each model weights general-purpose utility over age-appropriateness and puts text syntax ahead of drag-and-drop blocks for children who are still learning to read.

### Severity scored as quality

- **Module**: `ActiveGenie::Scorer`
- **Test**: `test/e2e/scorer/security_system_posture_low_test.rb`
- **Prompt**: Score the security posture of a system with SQL injection, persistent XSS, and credentials committed to a public repository. A vulnerable system should score low.
- **Expected**: 40 or below.
- **Anthropic (`claude-haiku-4-5`) returned**: **96**, reasoning that the posture is "critically compromised" and represents "a catastrophic security failure".
- **DeepSeek (`deepseek-v4-flash`) returned**: 58.

The reasoning is correct and the number is inverted. Both models described the system accurately as catastrophically insecure, then scored that description highly. They graded how well the text characterises the problem rather than how good the posture is. This is the clearest example in the suite of an ambiguous criteria producing a confidently wrong number, and it is a good argument for stating explicitly which direction a score runs.

### Observations returned instead of experts

- **Module**: `ActiveGenie::Lister.with_juries`
- **Test**: `test/e2e/lister/environmental_oil_spill_juries_test.rb`
- **Prompt**: Identify expert jury roles for evaluating an offshore oil spill.
- **Expected**: An environmental scientist or ecologist among the roles.
- **Google (`gemini-3.5-flash-lite`) returned**:

```json
[
  "1. Dead fish and wildlife",
  "2. Oil-covered beaches",
  "3. Boom containment floating barriers",
  "4. Chemical dispersants",
  "5. Pressure washing rocks",
  "6. Volunteer bird rescue"
]
```

Two failure modes at once. The model listed observations of the disaster rather than people qualified to judge it, and it wrote list numbering into the string values, which breaks exact matching on the returned items.

### Consistently harsh scoring

- **Module**: `ActiveGenie::Scorer`
- **Test**: `test/e2e/scorer/legal_brief_quality_test.rb`
- **Expected**: 50 or above for a well-written legal brief.
- **DeepSeek (`deepseek-v4-flash`) returned**: 24, while its own reasoning called the text "polished, clear, and grammatically impeccable" and credited "thorough research, relevant precedent, sound structure".

DeepSeek accounts for 7 of the 13 `Scorer` failures across all providers, and the pattern is consistent: it acknowledges the strengths and then scores well below the threshold. If you use `Scorer` with this model, calibrate your thresholds against it rather than reusing thresholds tuned on another provider.

### Empty winner on fight comparisons

- **Module**: `ActiveGenie::Comparator.by_fight`
- **Tests**: `test/e2e/comparator/medical_device_process_fight_test.rb`, `test/e2e/comparator/wedding_catering_fight_test.rb`
- **Anthropic (`claude-haiku-4-5`) returned**: `nil` for the winner.

Both of Anthropic's `Comparator` failures are `by_fight` returning no winner rather than the wrong one. `by_debate` passed every test on the same model, so this looks specific to the fight prompt and worth investigating as a possible library issue rather than a model preference.

## Methodology

- **No mocks.** Every test calls a live endpoint through `ActiveGenie::Providers::UnifiedProvider`.
- **Inline data.** Test inputs live in the test file, so a scenario is readable without chasing fixtures.
- **Assertions on decisions**, per module:
  - `Comparator`: the correct winner is chosen on clear-cut pairs.
  - `Extractor`: exact field values, enum membership, and litote resolution.
  - `Lister`: expected answers appear, in the expected order.
  - `Ranker`: the clear best and clear worst land at the correct ends.
  - `Scorer`: scores clear the expected threshold (`≥ 70` for strong inputs, `≤ 40` for weak ones).

## Running it yourself

Set the API key for the provider you want to test, then:

```shell
# One provider, using that provider's default benchmark model
PROVIDER_NAME=anthropic bundle exec rake test:e2e

# Override the model
PROVIDER_NAME=openai MODEL=gpt-4o-mini bundle exec rake test:e2e

# A single module
PROVIDER_NAME=deepseek bundle exec ruby -Itest -e 'Dir.glob("test/e2e/scorer/*_test.rb").each { |f| require File.expand_path(f) }'
```

`PROVIDER_NAME` accepts `openai`, `anthropic`, `google`, or `deepseek`, and defaults to `openai`. The model defaults per provider are set in `test/e2e/test_helper.rb` and are the four listed in the results table above. They are deliberately separate from the library's own defaults in [Configuration](/reference/config#providers-config-providers), so benchmarking a new model does not change what the gem does for everyone else.

This suite is ActiveGenie's regression check. It runs against every supported provider before a release.
