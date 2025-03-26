require_relative 'configuration/providers_config'
require_relative 'configuration/providers/openai_config'
require_relative 'configuration/providers/google_config'
require_relative 'configuration/providers/anthropic_config'
require_relative 'configuration/providers/deepseek_config'
require_relative 'configuration/log_config'

module ActiveGenie
  module Configuration
    module_function

    attr_writer :provider

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

    def provider
      @provider || providers.default.class::NAME
    end

    def log
      @log ||= LogConfig.new
    end

    def to_h(configs = {})
      {
        provider: configs[:provider] || provider,
        providers: providers.to_h(configs.dig(:providers) || {}),
        log: log.to_h(configs.dig(:log) || {})
      }
    end
  end
end
