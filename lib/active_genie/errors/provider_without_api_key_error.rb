# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # `config.providers.default` (or PROVIDER_NAME, or a call's `providers: { default: }`) names a
  # provider that has no API key. ActiveGenie raises rather than call another provider.
  class ProviderWithoutApiKeyError < Error
    CODE = 'AG-E007'
    MESSAGE = 'The default provider %<provider>s has no API key, so ActiveGenie will not call it or ' \
              'switch to another provider.'
    FIX = <<~FIX
      Set the %<env>s environment variable, or set the key in the config:

        ActiveGenie.configure do |config|
          config.providers.%<name>s.api_key = ENV.fetch('%<env>s')
        end

      Or set config.providers.default to a provider that has a key (%<providers>s), or leave it unset
      to use the first provider with a key.
    FIX

    def initialize(provider, providers)
      name = provider.to_s
      super(provider: name.inspect, name:, env: Config::ProvidersConfig::BUILT_IN.fetch(name.to_sym)::API_KEY_ENV,
            providers: providers.any? ? providers.join(', ') : 'none has one yet')
    end
  end
end
