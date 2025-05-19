# frozen_string_literal: true

require_relative './openai_client'
require_relative './anthropic_client'
require_relative './google_client'
require_relative './deepseek_client'

module ActiveGenie
  module Clients
    class UnifiedClient
      class InvalidProviderError < StandardError; end

      class << self
        PROVIDER_NAME_TO_CLIENT = {
          openai: OpenaiClient,
          anthropic: AnthropicClient,
          google: GoogleClient,
          deepseek: DeepseekClient
        }.freeze

        def function_calling(messages, function, config: {})
          client = config.llm.client

          unless client
            provider_name = config.llm.provider || config.providers.default
            client = PROVIDER_NAME_TO_CLIENT[provider_name.to_sym]
          end

          raise InvalidProviderError, 'Client is not valid' if client.nil?

          normalized_response = client.new(config).function_calling(messages, function)

          normalize_response(normalized_response)
        end

        private

        def normalize_response(response)
          response.each do |key, value|
            response[key] = nil if ['null', 'none', 'undefined', '', 'unknown', '<unknown>'].include?(value.to_s.strip.downcase)
          end

          response
        end
      end
    end
  end
end
