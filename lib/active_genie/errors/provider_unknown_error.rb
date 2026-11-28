# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # A provider answered with an HTTP error that a retry won't fix: any non-2xx status but 408, 429
  # and 5xx. The message carries the status and the provider's own body.
  class ProviderUnknownError < Error
    CODE = 'AG-E101'
    MESSAGE = '%<provider>s answered HTTP %<status>s for model %<model>s: %<body>s'
    FIX = '%<hint>s'

    HINTS = {
      '400' => 'The provider rejected the request, and its body above names the parameter. Check that ' \
               'config.llm.model is a model this provider serves and that it supports function calling.',
      '401' => 'The provider refused the API key. Check config.providers.<name>.api_key or its ' \
               'environment variable (OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, DEEPSEEK_API_KEY).',
      '402' => 'The provider account is out of credits. Add credits or a payment method in its console.',
      '403' => 'The API key has no access to this model or endpoint. Check its permissions in the ' \
               'provider console, or pick another model with config.llm.model.',
      '404' => 'The provider does not know this model or URL. Check config.llm.model and, for a ' \
               'gateway, config.providers.<name>.api_url.'
    }.freeze
    DEFAULT_HINT = 'Read the provider body above, which names the problem. A retry of the same ' \
                   'request gets the same answer.'

    def initialize(provider:, model:, status:, body:, **values)
      status = status.to_s
      body = body.to_s.strip
      super(provider:, model:, status:, body: body.empty? ? '(empty body)' : body,
            hint: HINTS.fetch(status, DEFAULT_HINT), **values)
    end
  end
end
