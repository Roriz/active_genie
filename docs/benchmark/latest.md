# Benchmark 🧪

## Why Benchmark LLM Features?

Benchmarking is critical for LLM-powered applications like ActiveGenie for several key reasons:

1. **Quality Assurance**: Ensures that LLM outputs maintain consistent quality across different models and versions
2. **Performance Comparison**: Provides objective metrics to compare different LLM providers and models
3. **Cost Optimization**: Helps identify the most cost-effective models that meet quality requirements
4. **Reliability Tracking**: Monitors performance over time to detect regressions or improvements
5. **Feature Validation**: Verifies that specialized modules (extraction, scoring, etc.) perform as expected

Without rigorous benchmarking, LLM-based features can suffer from:
- Inconsistent outputs
- Hallucinations and factual errors
- Degraded performance after model updates
- Suboptimal cost-to-performance ratio

## Latest Benchmark Results

![latest](/assets/latest-benchmark.webp)

| Module | Provider | Model | Tests | Precision | Duration (s) | Requests | Tokens | Avg. Duration (s) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| extractor | openai | gpt-4.1-mini | 112/8 (120) | 93% | 426 | 166 | 100039 | 3.55 |
| extractor | google | gemini-2.5-flash-preview-05-20 | 112/8 (120) | 93% | 440 | 165 | 213353 | 3.67 |
| extractor | anthropic | claude-3-5-haiku-20241022 | 69/14 (120) | 57% | 392 | 109 | 145058 | 3.26 |
| extractor | deepseek | deepseek-chat | 111/9 (120) | 92% | 1,674 | 162 | 145282 | 13.95 |
| comparator | openai | gpt-4.1-mini | 11/1 (12) | 91% | 75 | 12 | 9672 | 6.23 |
| comparator | google | gemini-2.5-flash-preview-05-20 | 11/1 (12) | 91% | 117 | 12 | 28203 | 9.75 |
| comparator | anthropic | claude-3-5-haiku-20241022 | 11/1 (12) | 91% | 77 | 12 | 16025 | 6.44 |
| comparator | deepseek | deepseek-chat | 11/1 (12) | 91% | 215 | 12 | 11312 | 17.9 |
| scorer | openai | gpt-4.1-mini | 13/4 (17) | 76% | 84 | 17 | 15279 | 4.95 |
| scorer | google | gemini-2.5-flash-preview-05-20 | 13/4 (17) | 76% | 198 | 17 | 48656 | 11.62 |
| scorer | anthropic | claude-3-5-haiku-20241022 | 12/5 (17) | 70% | 154 | 17 | 26878 | 9.08 |
| scorer | deepseek | deepseek-chat | 14/3 (17) | 82% | 247 | 17 | 16739 | 14.55 |
| ranker | openai | gpt-4.1-mini | 2/0 (2) | 100% | 2,209 | 259 | 390023 | 1104.32 |
| ranker | google | gemini-2.5-flash-preview-05-20 | 1/0 (2) | 50% | 2,072 | 119 | 509041 | 1035.97 |
| ranker | anthropic | claude-3-5-haiku-20241022 | 0/0 (2) | 0% | 7 | 2 | 2826 | 3.66 |
| ranker | deepseek | deepseek-chat | 2/0 (2) | 100% | 5,892 | 260 | 423544 | 2945.88 |

see logs and more details in: https://github.com/Roriz/active_genie/actions/runs/15414461171

### Module Performance Breakdown

| ActiveGenie Module | Best Precision | Worst Precision | Recommended Model |
| --- | --- | --- | --- |
| extractor | 93% | 57% | `gpt-4.1-mini` |
| comparator | 91% | 91% | `gpt-4.1-mini` |
| scorer | 82% | 76% | `deepseek-chat` |
| ranker | 100% | 0% | `gpt-4.1-mini` |

## Benchmark Methodology

Our benchmarking process evaluates each model and module against a standardized test suite that includes a list of static tests found in [benchmark/test_cases](https://github.com/Roriz/active_genie/tree/main/benchmark/test_cases).
The list of tests should represent the most variable use cases possible, but the same use case can be repeated multiple times with different inputs to ensure a more accurate representation of the model's performance.

We always need more use cases; if you have any, please submit an issue or PR with your test cases. The best use cases will be used to create Case Studies.

## Running Benchmarks

To run the benchmarks yourself:

```shell
bundle exec rake active_genie:benchmark
```

To benchmark a specific module:

```shell
bundle exec rake active_genie:benchmark[extractor]
bundle exec rake active_genie:benchmark[scorer]
bundle exec rake active_genie:benchmark[comparator]
bundle exec rake active_genie:benchmark[ranker]
```

## Interpreting Results

- **Overall Precision**: Percentage of test cases where the model produced the expected output
- **Module Precision**: Performance specific to each ActiveGenie module

The objective is not necessarily to hit 100% precision, but to stay as high as possible. Each module can be harder or easier for the LLM, so each module should define its own target precision to aim for.
It is highly recommended to have some of the hardest tests possible, to try to find the limit of the module. This limit will help users know if their use cases will fit the module or not.

## Continuous Benchmarking

ActiveGenie implements continuous benchmarking as part of our development process:
- Automated benchmark runs on each release
- Historical performance tracking
- Regression detection
- Model selection optimization

## Contributing to Benchmarks

We welcome contributions to our benchmark suite:
1. Add new test cases to `benchmark/test_cases/`
2. Run the benchmarks to verify your test cases
3. Submit a PR with your changes

## Future Improvements

- Expanded test coverage for edge cases
- Multi-language support testing
- Confidence Score: Consistency of results across multiple runs
