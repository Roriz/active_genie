# frozen_string_literal: true

require_relative 'configuration/providers_config'
require_relative 'configuration/providers/openai_config'
require_relative 'configuration/providers/google_config'
require_relative 'configuration/providers/anthropic_config'
require_relative 'configuration/providers/deepseek_config'
require_relative 'configuration/log_config'
require_relative 'configuration/runtime_config'

module ActiveGenie
  module Configuration
    module_function

    def providers
      @providers ||= begin
        p = ProvidersConfig.new
        p.add(ActiveGenie::Configuration::Providers::OpenaiConfig)
        p.add(ActiveGenie::Configuration::Providers::GoogleConfig)
        p.add(ActiveGenie::Configuration::Providers::AnthropicConfig)
        p.add(ActiveGenie::Configuration::Providers::DeepseekConfig)
        p
      end
    end

    def log
      @log ||= LogConfig.new
    end

    def runtime
      @runtime ||= RuntimeConfig.new
    end

    def observer
      @observer ||= ObserverConfig.new
    end

    def to_h(configs = {})
      normalized_configs = configs[:runtime] ? configs : { runtime: configs }

      {
        providers: providers.to_h(normalized_configs[:providers] || {}),
        log: log.to_h(normalized_configs[:log] || {}),
        runtime: runtime.to_h(normalized_configs[:runtime] || {})
      }
    end
  end
end
