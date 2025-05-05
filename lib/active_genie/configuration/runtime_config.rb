# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class RuntimeConfig
      attr_writer :max_tokens, :temperature, :provider, :max_retries

      def max_tokens
        @max_tokens ||= 4096
      end

      def temperature
        @temperature ||= 0.1
      end

      attr_accessor :model, :api_key

      def provider
        @provider ||= ActiveGenie.configuration.providers.default
      end

      def max_retries
        @max_retries ||= 3
      end

      def to_h(config = {})
        {
          max_tokens:, temperature:, model:, provider:, api_key:, max_retries:
        }.merge(config)
      end
    end
  end
end
