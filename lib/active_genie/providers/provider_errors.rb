# frozen_string_literal: true

module ActiveGenie
  module Providers
    # Builds the errors a provider raises (see lib/active_genie/errors/), each naming the provider and
    # the model the request asked for.
    module ProviderErrors
      # The provider's name in error messages; each provider sets its own, e.g. "OpenAI".
      LABEL = 'The provider'

      private

      def provider_error(klass, **values)
        klass.new(provider: self.class::LABEL, model: @config.llm.model.inspect, **values)
      end

      # The error to raise once retries run out: a gem error as it is, a network or JSON error as one.
      def exhausted(error, attempts)
        case error
        when ActiveGenie::Error then error
        when JSON::ParserError
          provider_error(InvalidResponseError, detail: "a body that is not JSON (#{error.message})")
        else provider_error(ProviderConnectionError, attempts:, error: "#{error.class}: #{error.message}")
        end
      end
    end
  end
end
