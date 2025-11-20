# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class LlmConfig < BaseConfig
      attr_accessor :model, :recommended_model, :max_retries, :retry_delay,
                    :read_timeout, :open_timeout
      attr_writer :temperature, :max_fibers, :max_tokens
      attr_reader :provider_name

      def temperature
        @temperature ||= 0
      end

      def max_fibers
        @max_fibers ||= 10
      end

      def max_tokens
        @max_tokens ||= 4096
      end
    end
  end
end
