module ActiveGenie
  class Client
    class << self
      def function_calling(messages, function, options: {})
        provider_name = options[:provider]&.downcase&.strip&.to_sym
        provider = ActiveGenie.providers.providers[provider_name] || ActiveGenie.providers.default_provider

        raise InvalidProviderError if provider.nil? || provider.client.nil?

        provider.client.function_calling(messages, function, options:)
      end

      private

      # TODO: improve error message
      class InvalidProviderError < StandardError; end
    end
  end
end
