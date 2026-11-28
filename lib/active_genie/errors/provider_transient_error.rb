# frozen_string_literal: true

require_relative 'provider_unknown_error'

module ActiveGenie
  # A rate limit (429), request timeout (408) or server error (5xx) that still failed after every
  # retry. It subclasses ProviderUnknownError, so `rescue ActiveGenie::ProviderUnknownError` sees it.
  class ProviderTransientError < ProviderUnknownError
    CODE = 'AG-E102'
    MESSAGE = '%<provider>s answered HTTP %<status>s for model %<model>s after %<max_retries>s retries: %<body>s'
    FIX = <<~FIX
      The provider is rate-limiting or failing for now. Wait longer between retries with
      config.llm.max_retries and config.llm.retry_delay (the delay doubles each retry), or retry the
      call later from a background job.
    FIX
  end
end
