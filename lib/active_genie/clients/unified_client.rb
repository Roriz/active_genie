# frozen_string_literal: true

require_relative './providers/openai_client'
require_relative './providers/anthropic_client'
require_relative './providers/google_client'
require_relative './providers/deepseek_client'
require_relative '../errors/invalid_provider_error'

module ActiveGenie
  module Clients
    class UnifiedClient
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

          raise ActiveGenie::InvalidProviderError, provider_name if client.nil?

          client.new(config).function_calling(messages, function)
        end
      end
    end
  end
end
