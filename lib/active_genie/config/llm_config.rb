# frozen_string_literal: true

module ActiveGenie
  module Config
    class LlmConfig
      attr_accessor :model, :temperature, :max_tokens, :max_retries, :retry_delay,
        :model_tier, :read_timeout, :open_timeout, :client
      attr_reader :provider

      def initialize
        @model = nil
        @provider = nil
        @client = nil
        @temperature = 0
        @max_tokens = 4096
        @max_retries = nil
        @retry_delay = nil
        @model_tier = 'lower_tier'
        @read_timeout = nil
        @open_timeout = nil
      end

      def provider=(provider)
        @provider = provider&.to_s&.downcase&.strip&.to_sym
      end

      def merge(config_params = {})
        dup.tap do |config|
          config_params.each do |key, value|
            if config.respond_to?("#{key}=")
              config.send("#{key}=", value)
            end
          end
        end
      end
    end
  end
end
