# Observability & errors

GenAI features fail differently from ordinary code. The same call can succeed once and fail the next time, every failed attempt still costs money, and some failures never raise at all. This page covers what ActiveGenie logs, the errors it raises, and what its retry path actually covers.

## Logging

Every notable action emits a log entry. An entry is a hash with a `:code`, a `:timestamp`, a `:process_id`, and anything you have set in `config.log.additional_context`.

ActiveGenie writes each entry to `config.log.file_path`, passes it to `config.log.output`, and hands it to any observers.

### Event codes

| Code | Emitted when |
| :--- | :--- |
| `:http_request` | Every provider HTTP call completes. Carries `uri`, `method`, `status`, `duration`, `response_size`. |
| `:llm_usage` | A provider returns token usage. Carries `input_tokens`, `output_tokens`, `total_tokens`, `model`, `usage`. |
| `:retry_attempt` | A retryable failure is about to be retried. Carries `attempt`, `max_retries`, `next_retry_in_seconds`, `error`. |
| `:function_calling` | A structured-output call is issued. |
| `:new_score` | `Scorer` produces a score. |
| `:new_juries` | `Lister.with_juries` selects a jury. |
| `:elo_report` | `Ranker` finishes an ELO round. |
| `:free_for_all` | `Ranker` runs a free-for-all match. |
| `:free_for_all_report` | `Ranker` finishes the free-for-all stage. |
| `:ranker_final` | `Ranker` produces its final ordering. |
| `:output_error` | `config.log.output` raised while handling an entry. Carries `error` (the message) and `failed_code` (the code of the entry being handled). |
| `:observer_error` | An observer raised while handling an entry. Carries `error` and `failed_code`. |

### Observers

`add_observer` registers a callback. The `scope:` hash filters which entries reach it: every key must match the entry exactly.

```ruby
ActiveGenie.configure do |config|
  config.log.add_observer(scope: { code: :llm_usage }) do |log|
    StatsD.count('genie.tokens', log[:total_tokens], tags: ["model:#{log[:model]}"])
  end

  config.log.add_observer(scope: { code: :retry_attempt }) do |log|
    Sentry.capture_message("ActiveGenie retry #{log[:attempt]}/#{log[:max_retries]}: #{log[:error]}")
  end

  config.log.add_observer(scope: { code: :http_request }) do |log|
    StatsD.histogram('genie.request_duration', log[:duration])
  end
end
```

If an observer raises, ActiveGenie catches the error, logs it as `:observer_error`, and lets the call continue. The other observers still run. A failure while delivering an `:observer_error` or `:output_error` entry is dropped, so an observer that always raises can't loop.

Use `remove_observer(observers)` to drop specific ones, or `clear_observers` to drop all.

### What to watch

- For token spend, sum `total_tokens` from `:llm_usage` and multiply by your per-token price. Alert on budget.
- For request volume, count `:http_request`. A single `Ranker.call` produces many of them, so a sudden climb usually means a larger input list rather than more traffic.
- For retry rate, watch how often `:retry_attempt` fires. It is the earliest indicator of provider trouble.
- For latency, read `duration` on `:http_request`.

## Errors

### What gets raised

| Error | Raised when |
| :--- | :--- |
| `ActiveGenie::Providers::BaseProvider::ProviderUnknownError` | Any non-2xx response from a provider, or a response body that isn't valid JSON. This is the error you will see most: bad API key, exhausted credits, rate limiting, model not found, provider outage. |
| `ActiveGenie::Providers::BaseProvider::ProviderTransientError` | A subclass of `ProviderUnknownError` for rate limits (429), request timeouts (408) and server errors (5xx) that were still failing after all retries. Rescue it to treat these differently from permanent failures. |
| `ActiveGenie::WithoutAvailableProviderError` | No configured provider has a usable API key. |
| `ActiveGenie::InvalidLogOutputError` | `config.log.output` was set to something that doesn't respond to `call`. |
| `Net::OpenTimeout`, `Net::ReadTimeout`, `Errno::ECONNREFUSED` | Network-level failure that survived all retries. |

`ProviderUnknownError` carries the status code and the raw body, so you still get the provider's own message:

```ruby
begin
  ActiveGenie::Scorer.call(text, criteria)
rescue ActiveGenie::Providers::BaseProvider::ProviderUnknownError => e
  # "Unexpected response: 400 - {"error":"Your credit balance is too low..."}"
  Rails.logger.error(e.message)
end
```

> [!NOTE]
> `ActiveGenie::ProviderServerError`, `ActiveGenie::InvalidModelError`, and `ActiveGenie::InvalidProviderError` are defined but are not raised by any code path in the current version. Rescuing them has no effect.

### Retries

ActiveGenie retries transient failures with exponential backoff: `retry_delay * (2 ** attempt)`, up to `max_retries` retries after the first attempt. Transient failures are network errors (connection timeouts, refused connections) and HTTP 408, 429 and 5xx responses. Other 4xx responses, such as a bad API key or an invalid request, fail immediately.

| Setting | Effective default | Description |
| :--- | :--- | :--- |
| `config.llm.max_retries` | `3` | Retry attempts before giving up. |
| `config.llm.retry_delay` | `1` second | Base delay; doubles each attempt. |
| `config.llm.read_timeout` | `60` seconds | How long to wait for the response body. |
| `config.llm.open_timeout` | `10` seconds | How long to wait for the connection to open. |

These read `nil` from the configuration object until you set them. The values above are the defaults applied at request time.

> [!NOTE]
> The backoff does not read the `Retry-After` header. With the defaults, a rate-limited call gives up after about 7 seconds of waiting. If your provider's limits reset per minute, raise `retry_delay` or `max_retries`, or let a background job retry `ProviderTransientError` later.

### Where to handle failures

Provider calls are slow and fail intermittently. Run them in a background job rather than a request cycle, and let the job runner own the retry and backoff policy. A job runner handles that better than an inline `rescue`, and its retries survive process restarts.
