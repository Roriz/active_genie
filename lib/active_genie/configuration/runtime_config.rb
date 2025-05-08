# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class RuntimeConfig
      attr_writer :max_tokens, :temperature, :provider, :max_retries
      attr_accessor :model, :api_key

      def max_tokens
        @max_tokens ||= 4096
      end

      def temperature
        @temperature ||= 0.1
      end

      def provider
        @provider ||= ActiveGenie.configuration.providers.default
      end

      def max_retries
        @max_retries ||= 3
      end
    end
  end
end
