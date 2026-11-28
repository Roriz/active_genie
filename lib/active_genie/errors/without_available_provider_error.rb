# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # No provider has an API key, so a module call has nowhere to go.
  class WithoutAvailableProviderError < Error
    CODE = 'AG-E001'
    MESSAGE = 'No provider has an API key, so ActiveGenie has no model to call.'
    FIX = <<~FIX
      Set the API key of at least one provider, from its environment variable
      (OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY or DEEPSEEK_API_KEY) or in the config:

        ActiveGenie.configure do |config|
          config.providers.openai.api_key = ENV.fetch('OPENAI_API_KEY')
        end
    FIX
  end
end
