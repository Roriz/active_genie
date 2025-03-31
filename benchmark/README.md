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

| Module | Provider | Model | Tests | Precision | Duration (s) | Requests | Tokens | Avg. Duration (s) |
|----------------|-----------|---------------------------|-----------|-----|-------------|-----|------------------|
| data_extractor | anthropic | claude-3-5-haiku-20241022 | 23/0 (23) | 100 | 84.806410   | 31  | 29718  | 3.69    |
| data_extractor | deepseek  | deepseek-chat             | 23/0 (23) | 100 | 229.362400  | 32  | 17618  | 9.97    |
| data_extractor | google    | gemini-2.0-flash-lite     | 20/3 (23) | 86  | 72.642049   | 26  | 16930  | 3.16    |
| data_extractor | openai    | gpt-4o-mini               | 23/0 (23) | 100 | 42.168443   | 29  | 13244  | 1.83    |
| scoring        | anthropic | claude-3-5-haiku-20241022 | 9/4 (13)  | 69  | 100.488182  | 13  | 18492  | 7.73    |
| scoring        | deepseek  | deepseek-chat             | 9/4 (13)  | 69  | 121.876891  | 13  | 10584  | 9.38    |
| scoring        | openai    | gpt-4o-mini               | 8/5 (13)  | 61  | 30.899037   | 13  | 9959   | 2.38    |
| scoring        | google    | gemini-2.0-flash-lite     | 8/5 (13)  | 61  | 63.592440   | 12  | 11009  | 4.89    |
| battle         | anthropic | claude-3-5-haiku-20241022 | 10/0 (10) | 100 | 378.610437  | 1   | 1272   | 37.86   |
| battle         | deepseek  | deepseek-chat             | 1/9 (10)  | 10  | 69.189029   | 10  | 3933   | 6.92    |
| battle         | openai    | gpt-4o-mini               | 9/1 (10)  | 90  | 46.945714   | 10  | 8343   | 4.69    |
| battle         | google    | gemini-2.0-flash-lite     | 9/1 (10)  | 90  | 80.621382   | 10  | 13674  | 8.06    |
| ranking        | anthropic | claude-3-5-haiku-20241022 | 2/0 (2)   | 100 | 88.662300   | 2   | 2725   | 44.33   |
| ranking        | deepseek  | deepseek-chat             | 1/1 (2)   | 50  | 3745.800662 | 243 | 313242 | 1872.90 |
| ranking        | openai    | gpt-4o-mini               | 0/2 (2)   | 0   | 1858.974373 | 288 | 436665 | 929.49  |
| ranking        | google    | gemini-2.0-flash-lite     | 2/0 (2)   | 100 | 405.893377  | 80  | 133440 | 202.95  |

### Module Performance Breakdown

| ActiveGenie Module | Best Precision | Worst Precision | Recommended Model |
|--------------------|-------------------|-------------------|-------------------|
| data_extractor | 100% | 86% | `gpt-4o-mini` |
| battle | 100% | 10% | `gemini-2.0-flash-lite` |
| scoring | 69% | 61% | `claude-3-5-haiku-20241022` |
| ranking | 100% | 0% | `gemini-2.0-flash-lite` |

## Benchmark Methodology

Our benchmarking process evaluates each model and module against a standardized test suite that includes:

1. **Data Extraction Tests**: Evaluates accuracy in extracting structured data from unstructured text
2. **Scoring Tests**: Measures consistency and fairness in multi-reviewer evaluations
3. **Battle Tests**: Tests accuracy in determining winners based on specified criteria
4. **Ranking Tests**: Evaluates the reliability of multi-stage ranking algorithms

Each test case includes:
- Input data
- Expected output
- Evaluation metrics
- Edge cases

## Running Benchmarks

To run the benchmarks yourself:

```shell
bundle exec rake active_genie:benchmark
```

To benchmark a specific module:

```shell
bundle exec rake active_genie:benchmark[data_extractor]
```

## Interpreting Results

- **Overall Precision**: Percentage of test cases where the model produced the expected output
- **Module Precision**: Performance specific to each ActiveGenie module

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