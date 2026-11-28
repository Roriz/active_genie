# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # A provider name ActiveGenie can't call, in `config.providers.default`, PROVIDER_NAME or
  # `config.providers.add`.
  class InvalidProviderError < Error
    CODE = 'AG-E002'
    MESSAGE = 'Unknown provider %<provider>s. ActiveGenie can call: %<known>s.'
    FIX = <<~FIX
      Set config.providers.default (or the PROVIDER_NAME environment variable) to one of those names:

        ActiveGenie.configure do |config|
          config.providers.default = 'openai'
        end

      To call another OpenAI-compatible API, replace a built-in provider's config instead:
      config.providers.add(:openai, MyGatewayConfig).
    FIX

    def initialize(provider)
      super(provider: provider.to_s.inspect, known: Config::ProvidersConfig::BUILT_IN.keys.join(', '))
    end
  end
end
