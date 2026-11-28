# frozen_string_literal: true

require_relative 'error'

module ActiveGenie
  # `config.llm.model` names a model that no provider with an API key recognises, and no provider is
  # named next to it.
  class InvalidModelError < Error
    CODE = 'AG-E003'
    MESSAGE = 'No provider with an API key runs the model %<model>s (providers with a key: %<providers>s).'
    FIX = <<~FIX
      ActiveGenie picks the provider from the model name (gpt, claude, gemini, deepseek). For any
      other name, set the provider next to the model:

        ActiveGenie.configure do |config|
          config.providers.default = 'openai'
          config.llm.model = %<model>s
        end

      Or per call: config: { providers: { default: 'openai' }, llm: { model: %<model>s } }.
    FIX

    def initialize(model, providers)
      super(model: model.to_s.inspect, providers: providers.join(', '))
    end
  end
end
