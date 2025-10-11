# frozen_string_literal: true

require_relative 'openai_provider'
require_relative 'anthropic_provider'
require_relative 'google_provider'
require_relative 'deepseek_provider'
require_relative '../errors/invalid_provider_error'
require_relative '../errors/invalid_model_error'
require_relative '../errors/without_available_provider_error'

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
          model, provider_name = model_and_provider_by(config)

          provider = PROVIDER_NAME_TO_PROVIDER[provider_name&.to_sym]

          raise ActiveGenie::WithoutAvailableProviderError if provider.nil?

          config.llm.model = model

          response = provider.new(config).function_calling(messages, function)

          normalize_response(response)
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def model_and_provider_by(config)
          model, provider_name = explicit_choice(config)
          model, provider_name = global_default(config) if model.nil? && provider_name.nil?
          model, provider_name = module_recommendation(config) if model.nil? && provider_name.nil?

          model, provider_name = infer_from_partial(config, model, provider_name) if model.nil? || provider_name.nil?
          model, provider_name = any_available(config) if model.nil? || provider_name.nil?

          [model, provider_name]
        end
        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

        def explicit_choice(config)
          model = config.llm.model
          provider_name = config.llm.provider || config.llm.provider_name

          [model, provider_name]
        end

        def global_default(config)
          provider_name = config.providers.default

          [nil, provider_name]
        end

        def module_recommendation(config)
          model = config.llm.recommended_model
          provider_name = config.providers.provider_name_by_model(model) if model

          return nil if model.nil? || provider_name.nil?

          [model, provider_name]
        end

        def infer_from_partial(config, model, provider_name)
          provider_name ||= config.providers.provider_name_by_model(model) if model
          model ||= config.providers.valid[provider_name.to_sym]&.default_model if provider_name

          [model, provider_name]
        end

        def any_available(config)
          provider = config.providers.valid.first
          provider_name = provider&.first
          model = provider&.last&.default_model

          [model, provider_name]
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
