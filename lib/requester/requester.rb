
require 'yaml'
require_relative 'openai'

module ActiveAI
  class Requester    
    class << self
      def function_calling(messages, function, options = {})
        config = fetch_config(options.fetch(:model, nil))

        raise "Model can't be blank" if config.nil?

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
        return {} if !File.exist?(PATH_TO_CONFIG)

        @all_configs ||= YAML.load_file(PATH_TO_CONFIG) || []
      end

      def fetch_config(model_name)
        all_configs.fetch(model_name, nil) || all_configs.first
      end

      PATH_TO_CONFIG = File.join(__dir__, 'config.yml').freeze
      
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
end
