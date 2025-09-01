# frozen_string_literal: true

require_relative 'openai_provider'
require_relative 'anthropic_provider'
require_relative 'google_provider'
require_relative 'deepseek_provider'
require_relative '../errors/invalid_provider_error'
require_relative '../errors/invalid_model_error'

module ActiveGenie
  module Providers
    class UnifiedProvider
      class << self
        PROVIDER_NAME_TO_PROVIDER = {
          openai: OpenaiProvider,
          anthropic: AnthropicProvider,
          google: GoogleProvider,
          deepseek: DeepseekProvider
        }.freeze

        def function_calling(messages, function, config: {})
          provider = provider(config)
          define_llm_model(config)

          response = provider.new(config).function_calling(messages, function)

          normalize_response(response)
        end

        private

        def provider(config)
          provider_name = config.llm.provider_name || config.providers.default

          unless config.providers.valid.keys.include?(provider_name.to_sym)
            raise ActiveGenie::InvalidProviderError,
                  provider_name
          end

          provider = PROVIDER_NAME_TO_PROVIDER[provider_name.to_sym]

          raise ActiveGenie::InvalidProviderError, provider_name if provider.nil?

          provider
        end

        def define_llm_model(config)
          if config.llm.model.nil?
            raise ActiveGenie::InvalidModelError unless config.llm.recommended_model

            config.llm.model = config.llm.recommended_model

          end

          config.llm.model
        end

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
