require_relative './openai'

module ActiveGenie::Clients
  class Router
    class << self
      def function_calling(messages, function, options = {})
        app_config = ActiveGenie.config_by_model(options[:model])

        provider = options[:provider] || app_config[:provider]
        client = PROVIDER_TO_CLIENT[provider&.downcase&.strip&.to_sym]
        raise "Provider \"#{provider}\" not supported" unless client

        response = client.function_calling(messages, function, options)

        clear_invalid_values(response)
      end

      private

      PROVIDER_TO_CLIENT = {
        openai: Openai,
      }

      INVALID_VALUES = [
        'not sure',
        'not clear',
        'not specified',
        'none',
        'null',
        'undefined',
      ].freeze

      def clear_invalid_values(data)
        data.reduce({}) do |acc, (field, value)|
          acc[field] = value unless INVALID_VALUES.include?(value)
          acc
        end
      end
    end
  end
end
