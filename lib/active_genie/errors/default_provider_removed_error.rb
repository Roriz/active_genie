# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # `config.providers.default` (or PROVIDER_NAME, or a call's `providers: { default: }`) names a
  # provider that `config.providers.remove` took out. ActiveGenie raises rather than call another one.
  class DefaultProviderRemovedError < Error
    CODE = 'AG-E008'
    MESSAGE = 'The default provider %<provider>s was removed from config.providers, so ActiveGenie will ' \
              'not call it or switch to another provider.'
    FIX = <<~FIX
      Keep it configured: drop config.providers.remove(:%<name>s) (or %<name>s: nil in a call's
      providers config). Or set config.providers.default to a provider that is still configured
      with a key (%<providers>s), or leave it unset to use the first provider with a key.
    FIX

    def initialize(provider, providers)
      name = provider.to_s
      super(provider: name.inspect, name:, providers: providers.any? ? providers.join(', ') : 'none has one yet')
    end
  end
end
