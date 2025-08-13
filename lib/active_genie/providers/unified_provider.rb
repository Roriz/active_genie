# frozen_string_literal: true

require_relative 'openai_provider'
require_relative 'anthropic_provider'
require_relative 'google_provider'
require_relative 'deepseek_provider'
require_relative '../errors/invalid_provider_error'

module ActiveGenie
  module Providers
    class UnifiedProvider
      class << self
        PROVIDER_NAME_TO_CLIENT = {
          openai: OpenaiProvider,
          anthropic: AnthropicProvider,
          google: GoogleProvider,
          deepseek: DeepseekProvider
        }.freeze

        def function_calling(messages, function, config: {})
          provider = config.llm.provider

          unless provider
            provider_name = config.llm.provider || config.providers.default
            provider = PROVIDER_NAME_TO_CLIENT[provider_name.to_sym]
          end

          raise ActiveGenie::InvalidProviderError, provider_name if provider.nil?

          response = provider.new(config).function_calling(messages, function)

          normalize_response(response)
        end

        private

        def normalize_response(response)
          response.each do |key, value|
            response[key] = nil if ['null', 'none', 'undefined', '', 'unknown',
                                    '<unknown>'].include?(value.to_s.strip.downcase)
          end

          response
        end
      end
    end
  end
end
