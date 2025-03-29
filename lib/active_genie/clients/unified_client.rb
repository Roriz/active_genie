module ActiveGenie::Clients
  class UnifiedClient
    class << self
      def function_calling(messages, function, model_tier: nil, config: {})
        provider_name = config[:runtime][:provider]&.to_s&.downcase&.strip&.to_sym || ActiveGenie.configuration.providers.default
        provider_instance = ActiveGenie.configuration.providers.valid[provider_name]

        raise InvalidProviderError if provider_instance.nil? || provider_instance.client.nil?

        provider_instance.client.function_calling(messages, function, model_tier:, config:)
      end

      private

      # TODO: improve error message
      class InvalidProviderError < StandardError; end
    end
  end
end
