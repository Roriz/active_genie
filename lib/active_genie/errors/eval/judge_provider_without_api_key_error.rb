# frozen_string_literal: true

require_relative 'error'
require_relative '../provider_without_api_key_error'

module ActiveGenie
  module Eval
    # A case needs the LLM judge, and the provider evals/config.yml pins it to (`judge: { provider }`)
    # has no API key. The run stops before anything is asked or spent.
    class JudgeProviderWithoutApiKeyError < Error
      CODE = 'AG-E226'
      MESSAGE = 'The eval judge\'s provider %<provider>s (judge: in evals/config.yml) has no API key, so ' \
                'the judge can\'t be asked.'
      FIX = <<~FIX
        Set the %<env>s environment variable, or set the key in the config:

          ActiveGenie.configure do |config|
            config.providers.%<name>s.api_key = ENV.fetch('%<env>s')
          end

        Or pin a judge whose provider has a key (%<providers>s) in evals/config.yml:

          judge:
            provider: <provider>
            model: <model>

        Its verdicts are cached per model, so a new judge means a new baseline.
      FIX

      def initialize(provider, providers)
        super(**ProviderWithoutApiKeyError.values(provider, providers))
      end
    end
  end
end
