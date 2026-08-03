# Benchmark

**Version**: v0.32.3
**Measured**: 3 August 2026
**Suite**: 100 end-to-end tests across 5 modules, 20 per module
**Repetitions**: 3 full runs per provider, 1,200 test executions in total
**Providers**: OpenAI, Anthropic, Google, DeepSeek

## What this measures

Every test calls a live provider API. There are no mocks, no stubs, and no recorded fixtures. A test passes only when the model's decision is correct: the right winner chosen, the right value extracted, the right item ranked first. Assertions that a response merely parsed, or that a score fell between 0 and 100, do not count as passes here.

The suite does not measure latency, cost, throughput, or behaviour on your own data. Use it as a regression signal and a rough capability comparison, not as a service-level guarantee.

## Results

The suite ran three times against each provider, on the same day and against the same version of the gem, because one run is not enough to rank anything. LLM outputs are non-deterministic and providers update models without notice, so the same model can move several points between identical runs.

<svg class="viz-root" viewBox="0 0 760 282" width="100%" role="img" aria-label="Benchmark pass rate across 3 runs for four providers" xmlns="http://www.w3.org/2000/svg" font-family="system-ui, sans-serif">
  <style>
    .viz-root{--surface-1:#fcfcfb;--text-primary:#0b0b0b;--text-secondary:#52514e;--series-1:#2a78d6;--grid:#e4e3df}
    @media (prefers-color-scheme: dark){:root:where(:not([data-theme="light"])) .viz-root{--surface-1:#1a1a19;--text-primary:#fff;--text-secondary:#c3c2b7;--series-1:#3987e5;--grid:#33322f}}
    :root[data-theme="dark"] .viz-root{--surface-1:#1a1a19;--text-primary:#fff;--text-secondary:#c3c2b7;--series-1:#3987e5;--grid:#33322f}
    .viz-bg{fill:var(--surface-1)}
    .viz-grid{stroke:var(--grid);stroke-width:1}
    .viz-tick{fill:var(--text-secondary);font-size:11px}
    .viz-name{fill:var(--text-primary);font-size:13px;font-weight:600}
    .viz-model{fill:var(--text-secondary);font-size:10.5px}
    .viz-range{stroke:var(--series-1);stroke-width:2;opacity:.32;stroke-linecap:round}
    .viz-dot{fill:var(--series-1);stroke:var(--surface-1);stroke-width:2}
    .viz-mean{fill:var(--text-primary);font-size:13px;font-weight:600;font-variant-numeric:tabular-nums}
    .viz-spread{fill:var(--text-secondary);font-size:10.5px;font-variant-numeric:tabular-nums}
    .viz-title{fill:var(--text-primary);font-size:14px;font-weight:600}
    .viz-sub{fill:var(--text-secondary);font-size:11.5px}
  </style>
  <rect class="viz-bg" x="0" y="0" width="760" height="282" rx="6"/>
  <text class="viz-title" x="16" y="24">Pass rate across 3 runs</text>
  <text class="viz-sub" x="16" y="41">Each dot is one full 100-test run. Bar shows the range.</text>
  <line class="viz-grid" x1="132.0" y1="48" x2="132.0" y2="228"/>
  <text class="viz-tick" x="132.0" y="248" text-anchor="middle">80%</text>
  <line class="viz-grid" x1="266.0" y1="48" x2="266.0" y2="228"/>
  <text class="viz-tick" x="266.0" y="248" text-anchor="middle">85%</text>
  <line class="viz-grid" x1="400.0" y1="48" x2="400.0" y2="228"/>
  <text class="viz-tick" x="400.0" y="248" text-anchor="middle">90%</text>
  <line class="viz-grid" x1="534.0" y1="48" x2="534.0" y2="228"/>
  <text class="viz-tick" x="534.0" y="248" text-anchor="middle">95%</text>
  <line class="viz-grid" x1="668.0" y1="48" x2="668.0" y2="228"/>
  <text class="viz-tick" x="668.0" y="248" text-anchor="middle">100%</text>
  <text class="viz-name" x="16" y="63">OpenAI</text>
  <text class="viz-model" x="16" y="78">gpt-5.6-luna</text>
  <line class="viz-range" x1="480.4" y1="66" x2="507.2" y2="66"/>
  <circle class="viz-dot" cx="507.2" cy="66" r="5"><title>run 1: 94/100</title></circle>
  <circle class="viz-dot" cx="507.2" cy="66" r="5"><title>run 2: 94/100</title></circle>
  <circle class="viz-dot" cx="480.4" cy="66" r="5"><title>run 3: 93/100</title></circle>
  <text class="viz-mean" x="684" y="65">93.7%</text>
  <text class="viz-spread" x="684" y="79">1 pt range</text>
  <text class="viz-name" x="16" y="109">Anthropic</text>
  <text class="viz-model" x="16" y="124">claude-haiku-4-5</text>
  <line class="viz-range" x1="426.8" y1="112" x2="507.2" y2="112"/>
  <circle class="viz-dot" cx="426.8" cy="112" r="5"><title>run 1: 91/100</title></circle>
  <circle class="viz-dot" cx="507.2" cy="112" r="5"><title>run 2: 94/100</title></circle>
  <circle class="viz-dot" cx="480.4" cy="112" r="5"><title>run 3: 93/100</title></circle>
  <text class="viz-mean" x="684" y="111">92.7%</text>
  <text class="viz-spread" x="684" y="125">3 pt range</text>
  <text class="viz-name" x="16" y="155">Google</text>
  <text class="viz-model" x="16" y="170">gemini-3.5-flash-lite</text>
  <line class="viz-range" x1="400.0" y1="158" x2="480.4" y2="158"/>
  <circle class="viz-dot" cx="426.8" cy="158" r="5"><title>run 1: 91/100</title></circle>
  <circle class="viz-dot" cx="400.0" cy="158" r="5"><title>run 2: 90/100</title></circle>
  <circle class="viz-dot" cx="480.4" cy="158" r="5"><title>run 3: 93/100</title></circle>
  <text class="viz-mean" x="684" y="157">91.3%</text>
  <text class="viz-spread" x="684" y="171">3 pt range</text>
  <text class="viz-name" x="16" y="201">DeepSeek</text>
  <text class="viz-model" x="16" y="216">deepseek-v4-flash</text>
  <line class="viz-range" x1="292.8" y1="204" x2="373.2" y2="204"/>
  <circle class="viz-dot" cx="292.8" cy="204" r="5"><title>run 1: 86/100</title></circle>
  <circle class="viz-dot" cx="373.2" cy="204" r="5"><title>run 2: 89/100</title></circle>
  <circle class="viz-dot" cx="319.6" cy="204" r="5"><title>run 3: 87/100</title></circle>
  <text class="viz-mean" x="684" y="203">87.3%</text>
  <text class="viz-spread" x="684" y="217">3 pt range</text>
</svg>

| Provider | Model | Run 1 | Run 2 | Run 3 | Mean | Range |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| OpenAI | `gpt-5.6-luna` | 94 | 94 | 93 | **93.7%** | 93 to 94 |
| Anthropic | `claude-haiku-4-5` | 91 | 94 | 93 | **92.7%** | 91 to 94 |
| Google | `gemini-3.5-flash-lite` | 91 | 90 | 93 | **91.3%** | 90 to 93 |
| DeepSeek | `deepseek-v4-flash` | 86 | 89 | 87 | **87.3%** | 86 to 89 |

## By module

Mean across the three runs, with the observed range where runs disagreed.

| Module | OpenAI | Anthropic | Google | DeepSeek |
| :--- | :---: | :---: | :---: | :---: |
| `Comparator` | 100% (20/20) | 97% (18-20/20) | 100% (20/20) | 100% (20/20) |
| `Extractor` | 100% (20/20) | 100% (20/20) | 99% (19-20/20) | 92% (18-19/20) |
| `Lister` | 100% (20/20) | 100% (20/20) | 87% (16-18/20) | 100% (20/20) |
| `Ranker` | 75% (15/20) | 74% (14-15/20) | 72% (14-15/20) | 75% (15/20) |
| `Scorer` | 94% (18-19/20) | 94% (18-19/20) | 100% (20/20) | 70% (13-15/20) |
| **Mean total** | **93.7%** | **92.7%** | **91.3%** | **87.3%** |

## How to read these numbers

Every provider clears 87%, and the top three sit within run-to-run noise of each other. OpenAI ranged 93 to 94, Anthropic 91 to 94, and Google 90 to 93, so this suite gives no reason to prefer one of the three on quality. Anthropic produced both the joint highest single run and the lowest of its own three. Choose between them on cost, latency, or whichever provider you already have credentials for.

`deepseek-v4-flash` is the one clear gap. Its best run sits below every other provider's worst, and most of the difference is in `Scorer`, where it scores well below the threshold on content the other models rate highly.

A single run is not a measurement. Three of the four providers moved by 3 points between identical runs, which is wider than the gap separating first place from third. Treat any individual number as approximate and compare ranges rather than points.

`Ranker` scores below the other modules. Four of its twenty tests exercise a scoring path with a known defect, so that column understates what the models are capable of.

## Notable failures

The suite is built to fail on real weaknesses rather than to produce a flattering number. These are actual outputs from this run.

### Every model ranks Python above Scratch for seven-year-olds

- **Module**: `ActiveGenie::Ranker.by_elo`
- **Prompt**: Rank programming languages for teaching seven-year-olds to code.
- **Expected**: `Scratch` first.
- **All four providers returned**: `{"language":"Python","paradigm":"General purpose"}` first.

No provider gets this right. Every model weights general-purpose utility over age-appropriateness and puts text syntax ahead of drag-and-drop blocks for children who are still learning to read. Where a ranking depends on context the model cannot infer, say so in the criteria.

### Severity scored as quality

- **Module**: `ActiveGenie::Scorer`
- **Prompt**: Score the security posture of a system with SQL injection, persistent XSS, and credentials committed to a public repository. A vulnerable system should score low.
- **Expected**: 40 or below.
- **Anthropic (`claude-haiku-4-5`) returned**: **96**, reasoning that the posture is "critically compromised" and represents "a catastrophic security failure".
- **DeepSeek (`deepseek-v4-flash`) returned**: 58.

The reasoning is correct and the number is inverted. Both models described the system accurately as catastrophically insecure, then scored that description highly, grading how well the text characterises the problem rather than how good the posture is. State which direction a score runs whenever it is not obvious, or an ambiguous criteria will return a confident number pointing the wrong way.

### Observations returned instead of experts

- **Module**: `ActiveGenie::Lister.with_juries`
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

Two failure modes at once. The model listed observations of the disaster rather than people qualified to judge it, and it wrote list numbering into the string values. If you match on returned items, strip leading numbering before comparing.

### Consistently harsh scoring

- **Module**: `ActiveGenie::Scorer`
- **Expected**: 50 or above for a well-written legal brief.
- **DeepSeek (`deepseek-v4-flash`) returned**: 24, while its own reasoning called the text "polished, clear, and grammatically impeccable" and credited "thorough research, relevant precedent, sound structure".

The pattern is consistent across the run: DeepSeek acknowledges the strengths and then scores well below where the other models land. Scores are comparable within a provider, not across them, so calibrate thresholds against the model you actually use rather than reusing numbers tuned elsewhere.

### Empty winner on fight comparisons

- **Module**: `ActiveGenie::Comparator.by_fight`
- **Anthropic (`claude-haiku-4-5`) returned**: `nil` for the winner.

Both failures returned no winner rather than the wrong one, while `by_debate` passed every test on the same model. Handle an empty result when you use `by_fight`, the same way you would handle any call that can come back without an answer.

## Methodology

Every test calls a live endpoint through `ActiveGenie::Providers::UnifiedProvider`, with no mocks anywhere in the path. Test inputs live inline in each test file, so a scenario is readable without chasing fixtures.

What each module has to get right:

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

`PROVIDER_NAME` accepts `openai`, `anthropic`, `google`, or `deepseek`, and defaults to `openai`. Each provider's benchmark model is the one listed in the results table above. Those are separate from the library's own defaults, which are documented in [Configuration](/reference/config#providers-config-providers).

This suite runs against every supported provider before a release.
