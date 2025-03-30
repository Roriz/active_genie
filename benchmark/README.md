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

### Model Performance Comparison

| Model | Overall Precision |
|-------|-------------------|
| claude-3-5-haiku-20241022 | 92.25% |
| gemini-2.0-flash-lite | 84.25% |
| gpt-4o-mini | 62.75% |
| deepseek-chat | 57.25% |

### Module Performance Breakdown

| ActiveGenie Module | Overall Precision |
|--------------------|-------------------|
| data_extractor | 96.50% |
| battle | 72.50% |
| scoring | 65.00% |
| ranking | 62.50% |

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