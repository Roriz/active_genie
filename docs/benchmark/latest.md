# Benchmark

**Version**: v0.32.0
**Suite**: 100 end-to-end tests across 5 modules, 20 per module
**Providers**: OpenAI, Google, DeepSeek, Anthropic

## What this measures

Every test in this suite calls a live provider API. The suite uses no mocks, stubs, or recorded fixtures. A test passes only if the model's decision is correct, so the assertions check whether the model picked the right winner, extracted the right value, or put the right item first.

Earlier versions of this suite asserted things like "reasoning is longer than 10 characters" or "the score is between 0 and 100". Assertions like those pass almost unconditionally and measure nothing. Swapping them for assertions on decision quality dropped pass rates to between 70% and 90%, which is a more useful band. A regression is visible at that level, and the failures that remain point at real weaknesses.

**What it does not measure**: latency, cost, throughput, or behaviour on your own data. Treat the pass rates as a regression signal and a rough capability comparison.

Results vary between runs. LLM outputs are non-deterministic and providers update models without notice.

## Results

| Rank | Provider | Model | Passed | Pass rate | Measured |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 1 | OpenAI | `gpt-4o-mini` | 86 / 100 | 86% | 2026-08-02 |
| 1 | Anthropic | `claude-haiku-4-5-20251001` | 86 / 100 | 86% | 2026-08-03 |
| 3 | Google | `gemini-3.5-flash-lite` | 85 / 100 | 85% | 2026-08-02 |
| 4 | DeepSeek | `deepseek-chat` | 81 / 100 | 81% | 2026-08-02 |

The three providers measured on 2026-08-02 ran on v0.32.0. Anthropic ran on 2026-08-03, after the schema key fix described below. Rows measured on different days are not perfectly comparable, since providers update models without notice.

> [!NOTE]
> Anthropic was previously unmeasurable. `Scorer` builds its response schema from jury names, so a jury called `"Senior Software Engineer"` produced the property key `Senior Software Engineer_score`. Anthropic validates property keys against `^[a-zA-Z0-9_.-]{1,64}$` and rejected those requests with a 400, which took out `Scorer` and every `Ranker` call that depends on it. The other three providers accept spaces, so the problem only showed up here. Fixed in v0.32.1.
>
> One `Ranker` test in the run above still hit a related case, where the sanitized jury name left no room for the `_reasoning` suffix within the 64 character limit. That is also fixed in v0.32.1, and the test passes on re-run, which puts the effective figure at 87 / 100. The table reports the measured full-suite result.

## By module

| Module | OpenAI | Google | DeepSeek | Anthropic |
| :--- | :---: | :---: | :---: | :---: |
| `Comparator` | 100% (20/20) | 100% (20/20) | 100% (20/20) | 100% (20/20) |
| `Extractor` | 65% (13/20) | 70% (14/20) | 65% (13/20) | 65% (13/20) |
| `Lister` | 90% (18/20) | 85% (17/20) | 95% (19/20) | 100% (20/20) |
| `Ranker` | 75% (15/20) | 70% (14/20) | 70% (14/20) | 70% (14/20) |
| `Scorer` | 100% (20/20) | 100% (20/20) | 75% (15/20) | 95% (19/20) |
| **Total** | **86%** | **85%** | **81%** | **86%** |

`Comparator` passes everywhere, which suggests its assertions are now the loosest in the suite and are due for tightening. `Extractor` is the weakest module across every provider, and the failures cluster on strict schema key matching and litote resolution.

## Notable failures

The examples below are actual outputs from this run. They show what the pass rates on their own leave out.

### Ingredients instead of experts

- **Module**: `ActiveGenie::Lister.with_juries`
- **Test**: `test/e2e/lister/health_food_safety_juries_test.rb`
- **Prompt**: Generate expert jury roles to inspect a food poisoning outbreak at a restaurant.
- **Expected**: Roles such as `"Food Safety Inspector"`, `"Public Health Officer"`, `"Microbiologist"`.
- **Google (`gemini-3.5-flash-lite`) returned**:

```json
[
  "1. Lettuce",
  "2. Spinach",
  "3. Tomatoes",
  "4. Improper handwashing by staff",
  "5. Cross-contamination from raw meat",
  "6. Unwashed produce"
]
```

The model read "juries" as a request for causes of the outbreak and listed ingredients and hygiene failures instead of the people who would evaluate it.

### Observations instead of evaluators

- **Module**: `ActiveGenie::Lister.with_juries`
- **Test**: `test/e2e/lister/environmental_oil_spill_juries_test.rb`
- **Prompt**: Identify expert jury roles for evaluating an offshore oil spill.
- **Expected**: `"Marine Biologist"`, `"Environmental Scientist"`, `"Coast Guard Officer"`.
- **Google (`gemini-3.5-flash-lite`) returned**:

```json
[
  "Dead or oil-covered seabirds and wildlife",
  "Black sludge on sandy beaches",
  "Economic damage to local fishing and tourism",
  "High-pressure washing of rocks and shoreline",
  "Containment booms and skimmer boats"
]
```

This is the same failure mode. The model described the disaster instead of naming experts qualified to judge it.

### Python ranked above Scratch for seven-year-olds

- **Module**: `ActiveGenie::Ranker.by_elo`
- **Test**: `test/e2e/ranker/education_programming_elo_test.rb`
- **Prompt**: Rank programming languages (Python, Scratch, COBOL) for teaching seven-year-olds to code.
- **Expected**: Scratch first, Python second, COBOL third.
- **OpenAI (`gpt-4o-mini`) returned**:

1. `Python`: "General purpose with clean, readable syntax"
2. `Scratch`: "Visual block-based"
3. `COBOL`: "Legacy enterprise language"

The model weighted general-purpose utility over age-appropriateness and put text syntax above drag-and-drop blocks for children who are still learning to read.

### Brand ranked above price

- **Module**: `ActiveGenie::Lister.with_feud`
- **Test**: `test/e2e/lister/marketplace_search_feud_test.rb`
- **Prompt**: Survey the top search filter people use when buying electronics online.
- **Expected top answer**: `"Price"` or `"Price Range"`.
- **OpenAI (`gpt-4o-mini`) returned**: `Brand`, `Price`, `Customer Rating`.

The ordering is defensible, but it is not the survey consensus the Feud methodology is meant to reproduce.

### Numbering baked into array items

- **Module**: `ActiveGenie::Lister.with_juries`
- **Test**: `test/e2e/lister/finance_crypto_fraud_juries_test.rb`
- **Prompt**: List jury roles for a cross-border cryptocurrency fraud trial.
- **DeepSeek (`deepseek-chat`) returned**:

```json
[
  "1. Securities and Exchange Commission (SEC)",
  "2. Financial Crimes Enforcement Network (FinCEN)",
  "3. Department of Justice (DOJ)",
  "4. Interpol",
  "5. Internal Revenue Service (IRS)"
]
```

The roles are reasonable. The problem is formatting: the model wrote list numbering into the string values, which breaks exact matching on the returned items.

### Over-corrected understatement

- **Module**: `ActiveGenie::Extractor.with_litote`
- **Test**: `test/e2e/extractor/tech_software_quality_litote_test.rb`
- **Input**: *"The software is not without its flaws."*
- **Expected**: A quality assessment reading as `"moderate"`, `"imperfect"`, or `"mixed"`.
- **DeepSeek (`deepseek-chat`) returned**: `{ "quality_assessment": "Poor" }`

The model detected the litote but resolved it too far. "Not without flaws" concedes imperfection; it does not say the software is bad.

## Methodology

- **No mocks.** Every test calls a live endpoint through `ActiveGenie::Providers::UnifiedProvider`.
- **Inline data.** Test inputs live in the test file, so you can read a scenario without chasing fixtures.
- **Assertions on decisions**, per module:
  - `Comparator`: the model picks the correct winner on clear-cut pairs.
  - `Extractor`: exact field values, enum membership, and litote resolution.
  - `Lister`: the expected answers appear, in the expected order.
  - `Ranker`: the clear best and clear worst land at the correct ends.
  - `Scorer`: scores clear the expected threshold (`≥ 70` for strong inputs, `≤ 40` for weak ones).

## Running it yourself

Set the API key for the provider you want to test, then:

```shell
# One provider
PROVIDER_NAME=anthropic bundle exec rake test:e2e

# Override the model
PROVIDER_NAME=openai MODEL=gpt-4o bundle exec rake test:e2e

# A single module
PROVIDER_NAME=deepseek bundle exec ruby -Itest test/e2e/scorer/*_test.rb
```

`PROVIDER_NAME` accepts `openai`, `anthropic`, `google`, or `deepseek`, and defaults to `openai`. Each provider's default model is listed in [Configuration](/reference/config#providers-config-providers).

This suite is ActiveGenie's regression check. It runs against every supported provider before a release.
