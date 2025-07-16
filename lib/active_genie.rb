# frozen_string_literal: true

require_relative 'active_genie/logger'
require_relative 'active_genie/configuration'

require_relative 'active_genie/config/providers/openai_config'
require_relative 'active_genie/config/providers/google_config'
require_relative 'active_genie/config/providers/anthropic_config'
require_relative 'active_genie/config/providers/deepseek_config'

module ActiveGenie
  autoload :DataExtractor, File.join(__dir__, 'active_genie/data_extractor')
  autoload :Battle, File.join(__dir__, 'active_genie/battle')
  autoload :Scoring, File.join(__dir__, 'active_genie/scoring')
  autoload :Ranking, File.join(__dir__, 'active_genie/ranking')
  autoload :Factory, File.join(__dir__, 'active_genie/factory')

  VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip

  class << self
    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= initialize_configuration
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      Dir.glob(File.join(__dir__, 'tasks', '*.rake')).each { |r| load r }
    end

    private

    def initialize_configuration
      config = Configuration.new

      config.providers.add(Config::Providers::OpenaiConfig)
      config.providers.add(Config::Providers::GoogleConfig)
      config.providers.add(Config::Providers::AnthropicConfig)
      config.providers.add(Config::Providers::DeepseekConfig)

      config
    end
  end
end
