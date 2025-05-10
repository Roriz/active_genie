# frozen_string_literal: true

require_relative 'configuration/providers_config'
require_relative 'configuration/log_config'
require_relative 'configuration/providers/openai_config'
require_relative 'configuration/providers/google_config'
require_relative 'configuration/providers/anthropic_config'
require_relative 'configuration/providers/deepseek_config'

module ActiveGenie
  class Configuration
    def initialize(max_tokens: nil, temperature: nil, max_retries: nil, model: nil, api_key: nil)
      @max_tokens = max_tokens || 4096
      @temperature = temperature || 0.1
      @max_retries = max_retries || 3
      @model = model
      @api_key = api_key
    end

    attr_accessor :model, :api_key, :max_tokens, :temperature, :max_retries

    def log
      @log ||= LogConfig.new
    end

    def observer
      @observer ||= ObserverConfig.new
    end

    def providers
      @providers ||= ProvidersConfig.new
    end

    def merge(config_params = {})
      config = dup

      config_params.each do |key, value|
        if config.respond_to?("#{key}=")
          config.send("#{key}=", value)
        elsif config.respond_to?(key) && config.send(key).respond_to?(:merge)
          config.send(key).merge(value)
        end
      end

      config
    end
  end
end
