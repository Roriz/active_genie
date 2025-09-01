# frozen_string_literal: true

module ActiveGenie
  module Config
    class LlmConfig
      attr_accessor :model, :recommended_model, :temperature, :max_tokens, :max_retries, :retry_delay,
                    :model_tier, :read_timeout, :open_timeout, :provider, :max_fibers
      attr_reader :provider_name

      def initialize
        set_defaults
      end

      def provider_name=(provider_name)
        return if provider_name.nil? || provider_name.empty?

        @provider_name = provider_name.to_s.downcase.strip.to_sym
      end

      def merge(config_params = {})
        dup.tap do |config|
          config_params.each do |key, value|
            config.send("#{key}=", value) if config.respond_to?("#{key}=")
          end
        end
      end

      private

      def set_defaults
        @model = @recommended_model = @provider_name = @provider = nil
        @max_retries = @retry_delay = @read_timeout = @open_timeout = nil
        @temperature = 0
        @max_tokens = 4096
        @model_tier = 'lower_tier'
        @max_fibers = 10
      end
    end
  end
end
