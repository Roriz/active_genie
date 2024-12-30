
require_relative 'openai'

module ActiveGenerative
  module Requester
    module_function

    def function_calling(messages, function, options = {})
      config = fetch_config(options.fetch(:model, nil))

      raise "Model not found" if config.nil?

      client = PROVIDER_TO_SDK.fetch(config.fetch('provider'))

      raise "Provider still not implemented" if client.nil?

      response = client.function_calling(
        messages,
        { type: 'function', function: },
        config
      )

      clear_invalid_values(response)
    end

    private

    PROVIDER_TO_SDK = {
      'openai' => Openai,
    }

    def all_configs
      @all_configs ||= YAML.load_file(File.join(__dir__, 'config.yml')) || []
    end

    def fetch_config(model_name)
      all_configs.fetch(model_name, nil) || all_configs.first
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
