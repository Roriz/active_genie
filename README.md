# ActiveGenie 🧞‍♂️
> The Lodash for GenAI: Real Value + Consistent + Model-Agnostic

[![Gem Version](https://badge.fury.io/rb/active_genie.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/active_genie)
[![Ruby](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml/badge.svg)](https://github.com/roriz/active_genie/actions/workflows/benchmark.yml)

ActiveGenie is a Ruby gem that helps developers build reliable, future-proof GenAI features without worrying about changing models, prompts, or providers. Like Lodash for GenAI, it offers simple, reusable modules for tasks like data extraction, scoring, and ranking, so you can focus on your app’s logic, not the shifting AI landscape.

Behind the scenes, a custom benchmarking system keeps everything consistent across LLM vendors and versions, release after release.

## Benchmarking 🧪

ActiveGenie includes a comprehensive benchmarking system to ensure consistent, high-quality outputs across different LLM models and providers.

```ruby
# Run all benchmarks
bundle exec rake active_genie:benchmark

# Run benchmarks for a specific module
bundle exec rake active_genie:benchmark[data_extractor]
```

### Latest Results

| Model | Overall Precision |
|-------|-------------------|
| claude-3-5-haiku-20241022 | 92.25% |
| gemini-2.0-flash-lite | 84.25% |
| gpt-4o-mini | 62.75% |
| deepseek-chat | 57.25% |

See the [Benchmark README](benchmark/README.md) for detailed results, methodology, and how to contribute to our test suite.


## Observability
Fundamental to managing any production system, observability is crucial for GenAI features. At a minimum, track these key metrics:

- Usage Rate (e.g., uses_per_minute): Detect anomalies like sudden traffic spikes (potential DDoS) or drops (feature outage or declining usage).
- Failure/Retry Rate (e.g., retry_count, fail_count): Monitor the frequency of errors. Exceeding a defined threshold should trigger downtime or degradation alerts.
- Token Consumption (e.g., tokens_used): Track usage to monitor costs. Set alerts if tokens_used * price_per_token exceeds budget thresholds.

```ruby
ActiveGenie.configure do |config|
  config.log.add_observer(scope: { code: :llm_usage }) do |log|
    puts "LLM Usage: #{log[:model]} - #{log[:total_tokens]} tokens"
  end
  config.log.add_observer(scope: { code: :retry_attempt }) do |log|
    puts "Retry Attempt: #{log[:attempt]} of #{log[:max_retries]}"
  end
end
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 License - see the [LICENSE](LICENSE) file for details.
