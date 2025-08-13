# frozen_string_literal: true

require_relative 'configs/comparator_config'
require_relative 'configs/extractor_config'
require_relative 'configs/lister_config'
require_relative 'configs/llm_config'
require_relative 'configs/log_config'
require_relative 'configs/providers_config'
require_relative 'configs/ranker_config'
require_relative 'configs/scorer_config'

module ActiveGenie
  class Configuration
    def log
      @log ||= Config::LogConfig.new
    end

    def providers
      @providers ||= Config::ProvidersConfig.new
    end

    def ranker
      @ranker ||= Config::RankerConfig.new
    end

    def scorer
      @scorer ||= Config::ScorerConfig.new
    end

    def extractor
      @extractor ||= Config::ExtractorConfig.new
    end

    def comparator
      @comparator ||= Config::ComparatorConfig.new
    end

    def lister
      @lister ||= Config::ListerConfig.new
    end

    def llm
      @llm ||= Config::LlmConfig.new
    end

    def logger
      @logger ||= ActiveGenie::Logger.new(log_config: log)
    end

    SUB_CONFIGS = %w[log providers llm ranker scorer extractor comparator lister].freeze

    def merge(config_params = {})
      return config_params if config_params.is_a?(Configuration)

      new_configuration = dup

      SUB_CONFIGS.each do |key|
        config = new_configuration.send(key)

        next unless config.respond_to?(:merge)

        new_config = sub_config_merge(config, key, config_params)

        new_configuration.send("#{key}=", new_config)
      end
      @logger = nil

      new_configuration
    end

    # Merges a sub config with the config_params.
    # Examples:
    #   config.merge({ 'log' => { file_path: 'log/active_genie.log' } })
    #   config.merge({ log: { file_path: 'log/active_genie.log' } })
    #   config.merge({ file_path: 'log/active_genie.log' })
    # these are all the same

    def sub_config_merge(config, key, config_params)
      if config_params&.key?(key.to_s)
        config.merge(config_params[key.to_s])
      elsif config_params&.key?(key.to_sym)
        config.merge(config_params[key.to_sym])
      else
        config.merge(config_params || {})
      end
    end

    attr_writer(*SUB_CONFIGS, :logger)
  end
end
