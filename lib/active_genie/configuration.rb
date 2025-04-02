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
        p.register(ActiveGenie::Configuration::Providers::OpenaiConfig)
        p.register(ActiveGenie::Configuration::Providers::GoogleConfig)
        p.register(ActiveGenie::Configuration::Providers::AnthropicConfig)
        p.register(ActiveGenie::Configuration::Providers::DeepseekConfig)
        p
      end
    end

    def log
      @log ||= LogConfig.new
    end

    def runtime
      @runtime ||= RuntimeConfig.new
    end

    def to_h(configs = {})
      normalized_configs = configs.dig(:runtime) ? configs : { runtime: configs }

      {
        providers: providers.to_h(normalized_configs.dig(:providers) || {}),
        log: log.to_h(normalized_configs.dig(:log) || {}),
        runtime: runtime.to_h(normalized_configs.dig(:runtime) || {})
      }
    end
  end
end
