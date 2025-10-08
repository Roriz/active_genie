# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class LlmConfig < BaseConfig
      attr_accessor :model, :recommended_model, :temperature, :max_tokens, :max_retries, :retry_delay,
                    :read_timeout, :open_timeout, :provider, :max_fibers, :provider_name

      def temperature
        @temperature ||= 0
      end

      def max_fibers
        @max_fibers ||= 10
      end

      def max_tokens
        @max_tokens ||= 4096
      end

      def provider_name=(provider_name)
        return if provider_name.nil? || provider_name.empty?

        @provider_name = provider_name.to_s.downcase.strip.to_sym
      end
    end
  end
end
