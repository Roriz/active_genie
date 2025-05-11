# frozen_string_literal: true

require_relative './openai_client'
require_relative './anthropic_client'
require_relative './google_client'
require_relative './deepseek_client'

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
          provider_name = config.llm.provider || config.providers.default
          client = PROVIDER_NAME_TO_CLIENT[provider_name]

          raise InvalidProviderError, "Provider #{provider_name} is not valid" if client.nil?

          client.new(config).function_calling(messages, function)
        end

        # TODO: improve error message
        class InvalidProviderError < StandardError; end
      end
    end
  end
end
