module ActiveGenie::Clients
  class UnifiedClient
    class << self
      def function_calling(messages, function, config: {})
        provider_name = config[:provider]&.downcase&.strip&.to_sym
        provider = ActiveGenie.configuration.providers.all[provider_name] || ActiveGenie.configuration.providers.default

        raise InvalidProviderError if provider.nil? || provider.client.nil?

        provider.client.function_calling(messages, function, config:)
      end

      private

      # TODO: improve error message
      class InvalidProviderError < StandardError; end
    end
  end
end
