# frozen_string_literal: true

require_relative 'config/providers_config'
require_relative 'config/log_config'
require_relative 'config/ranking_config'
require_relative 'config/scoring_config'
require_relative 'config/data_extractor_config'
require_relative 'config/battle_config'
require_relative 'config/llm_config'

module ActiveGenie
  class Configuration
    def log
      @log ||= Config::LogConfig.new
    end

    def observer
      @observer ||= Config::ObserverConfig.new
    end

    def providers
      @providers ||= Config::ProvidersConfig.new
    end

    def ranking
      @ranking ||= Config::RankingConfig.new
    end

    def scoring
      @scoring ||= Config::ScoringConfig.new
    end

    def data_extractor
      @data_extractor ||= Config::DataExtractorConfig.new
    end

    def battle
      @battle ||= Config::BattleConfig.new
    end

    def llm
      @llm ||= Config::LlmConfig.new
    end

    def merge(config_params = {})
      return config_params if config_params.is_a?(Configuration)

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
