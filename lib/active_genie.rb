# frozen_string_literal: true

require_relative 'active_genie/logger'
require_relative 'active_genie/configuration'

require_relative 'active_genie/configs/providers/openai_config'
require_relative 'active_genie/configs/providers/google_config'
require_relative 'active_genie/configs/providers/anthropic_config'
require_relative 'active_genie/configs/providers/deepseek_config'

module ActiveGenie
  autoload :Extractor, File.join(__dir__, 'active_genie/extractor')
  autoload :Comparator, File.join(__dir__, 'active_genie/comparator')
  autoload :Scorer, File.join(__dir__, 'active_genie/scorer')
  autoload :Ranker, File.join(__dir__, 'active_genie/ranker')
  autoload :Lister, File.join(__dir__, 'active_genie/lister')

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
