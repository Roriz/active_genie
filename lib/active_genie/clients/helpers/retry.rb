MAX_RETRIES = 3
BASE_DELAY = 0.5

def retry_with_backoff(config: {})
  retries = config[:runtime][:max_retries] || MAX_RETRIES

  begin
    yield
  rescue => e
    if retries > 0
      ActiveGenie::Logger.warn({ step: :retry_with_backoff, message: "Retrying request after error: #{e.message}. Attempts remaining: #{retries}" })

      retries -= 1
      backoff_time = calculate_backoff(MAX_RETRIES - retries)
      sleep(backoff_time)
      retry
    else
      raise
    end
  end
end

def calculate_backoff(retry_count)
  # Exponential backoff with jitter: 2^retry_count + random jitter
  # Base delay is 0.5 seconds, doubles each retry, plus up to 0.5 seconds of random jitter
  # Simplified example: 0.5, 1, 2, 4, 8, 12, 16, 20, 24, 28, 30 seconds
  jitter = rand * BASE_DELAY
  [BASE_DELAY * (2 ** retry_count) + jitter, 30].min # Cap at 30 seconds
end