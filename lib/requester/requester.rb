
require_relative 'openai'

module ActiveGenerative
  module Requester
    
    module_function

    def function_calling(messages, function, model_name = nil)
      model_name ||= ActiveGenerative.config.fetch('default_model')
      config = all_configs.fetch(model_name)
      client = PROVIDER_TO_SDK.fetch(config.fetch('provider'))

      payload = {
        model: config.fetch('model'),
        messages:
      }

      response = client.function_calling(payload, function)
      
      clear_invalid_values(response)
    end

    private

    PROVIDER_TO_SDK = {
      'openai' => Openai,
    }

    def all_configs
      @all_configs ||= YAML.load_file(File.join(__dir__, 'config.yml'))
    end
    
    INVALID_VALUES = [
      'not sure',
      'not clear',
      'not specified',
      'none',
      'null',
      'undefined',
    ].freeze

    def clear_invalid_values(data)
      data.reduce({}) do |acc, (field, value)|
        acc[field] = value unless INVALID_VALUES.include?(value)
        acc
      end
    end
  end
end
