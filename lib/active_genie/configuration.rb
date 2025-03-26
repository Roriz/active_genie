require_relative 'configuration/providers_config'
require_relative 'configuration/openai_config'
require_relative 'configuration/gemini_config'
require_relative 'configuration/log_config'

module ActiveGenie
  module Configuration
    module_function

    def providers
      @providers ||= begin 
        p = ProvidersConfig.new
        p.register(:openai, ActiveGenie::Configuration::OpenaiConfig)
        p.register(:gemini, ActiveGenie::Configuration::GeminiConfig)
        p
      end
    end

    def log
      @log ||= LogConfig.new
    end

    def to_h(configs = {})
      {
        providers: providers.to_h(configs.dig(:providers) || {}),
        log: log.to_h(configs.dig(:log) || {})
      }
    end
  end
end
