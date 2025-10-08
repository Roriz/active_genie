# frozen_string_literal: true

require_relative 'configs/extractor_config'
require_relative 'configs/lister_config'
require_relative 'configs/llm_config'
require_relative 'configs/log_config'
require_relative 'configs/providers_config'
require_relative 'configs/ranker_config'

module ActiveGenie
  class Configuration
    def initialize(initial_config = nil)
      @initial_config = initial_config || {}
    end

    def providers
      @providers ||= Config::ProvidersConfig.new(**@initial_config.fetch(:providers, {}))
    end

    def llm
      @llm ||= Config::LlmConfig.new(**@initial_config.fetch(:llm, {}))
    end

    def log
      @log ||= Config::LogConfig.new(**@initial_config.fetch(:log, {}))
    end

    # Modules

    def ranker
      @ranker ||= Config::RankerConfig.new(**@initial_config.fetch(:ranker, {}))
    end

    def extractor
      @extractor ||= Config::ExtractorConfig.new(**@initial_config.fetch(:extractor, {}))
    end

    def lister
      @lister ||= Config::ListerConfig.new(**@initial_config.fetch(:lister, {}))
    end

    def to_h
      {
        providers: providers.to_h,
        llm: llm.to_h,
        log: log.to_h,
        ranker: ranker.to_h,
        extractor: extractor.to_h,
        lister: lister.to_h
      }
    end
  end
end
