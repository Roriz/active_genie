# Observability

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
