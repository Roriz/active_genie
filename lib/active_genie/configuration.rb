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

      new_configuration = dup

      %w[log providers llm ranking scoring data_extractor battle].each do |key|
        config = new_configuration.send(key)

        next unless config.respond_to?(:merge)

        new_config = if config_params.key?(key.to_s)
                       config.merge(config_params[key.to_s])
                      elsif config_params.key?(key.to_sym)
                        config.merge(config_params[key.to_sym])
                      else
                       config.merge(config_params)
                     end

        new_configuration.send("#{key}=", new_config)
      end

      new_configuration
    end

    attr_writer :log, :providers, :ranking, :scoring, :data_extractor, :battle, :llm
  end
end
