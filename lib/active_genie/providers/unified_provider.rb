# frozen_string_literal: true

require_relative 'openai_provider'
require_relative 'anthropic_provider'
require_relative 'google_provider'
require_relative 'deepseek_provider'

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

        # What a model writes when a schema forces a value it does not have: "", "null", ":null",
        # "<unknown>", "'None'". A phrase such as "None of the above" is a value.
        PLACEHOLDER = /\A\W*(?:null|none|undefined|unknown)\W*\z/i

        def function_calling(messages, function, config: {})
          model, provider_name = model_and_provider_by(config)

          provider = provider_class(provider_name)

          config.llm.model = model

          response = provider.new(config).function_calling(messages, function)

          normalize_response(response, function)
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def model_and_provider_by(config)
          model, provider_name = explicit_choice(config)
          model, provider_name = global_default(config) if model.nil? && provider_name.nil?
          model, provider_name = module_recommendation(config) if model.nil? && provider_name.nil?

          model, provider_name = infer_from_partial(config, model, provider_name) if model.nil? || provider_name.nil?
          # An explicit model no credentialed provider runs is an error, not a cue to swap in another model.
          if model && provider_name.nil? && config.providers.valid.any?
            raise InvalidModelError.new(model, config.providers.valid.keys)
          end

          model, provider_name = any_available(config) if model.nil? || provider_name.nil?

          [model, provider_name]
        end
        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

        def provider_class(provider_name)
          PROVIDER_NAME_TO_PROVIDER[provider_name&.to_sym] || raise(WithoutAvailableProviderError)
        end

        # Only the user's own default raises when it can't be called: a module's recommended model whose
        # provider has no key still falls through to a provider that has one.
        def explicit_choice(config)
          config.providers.check_default!

          [config.llm.model, config.providers.default]
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

        # A placeholder the field's own enum lists ("none", "unknown") is an answer, so it stays.
        def normalize_response(response, function)
          return response unless response.is_a?(Hash)

          properties = function.dig(:parameters, :properties)
          response.each do |key, value|
            response[key] = nil if placeholder?(value) && !enum_of(properties, key).include?(value)
          end

          response
        end

        # Function schemas come with symbol or string keys (Extractor::Data's fields have string ones).
        def enum_of(properties, key)
          field = properties && (properties[key.to_sym] || properties[key.to_s])
          field.is_a?(Hash) ? Array(field[:enum] || field['enum']) : []
        end

        def placeholder?(value)
          value.is_a?(String) && (value.strip.empty? || value.match?(PLACEHOLDER))
        end
      end
    end
  end
end
