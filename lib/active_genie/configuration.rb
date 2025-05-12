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

      %w[log providers ranking scoring data_extractor battle llm].each do |key|
        if config_params.key?(key)
          config.send(key).merge(config_params[key]) if config.send(key).respond_to?(:merge)
        else
          config.send(key).merge(config_params) if config.send(key).respond_to?(:merge)
        end
      end

      config
    end
  end
end
