# frozen_string_literal: true

require_relative 'active_genie/logger'
require_relative 'active_genie/configuration'

module ActiveGenie
  autoload :DataExtractor, File.join(__dir__, 'active_genie/data_extractor')
  autoload :Battle, File.join(__dir__, 'active_genie/battle')
  autoload :Scoring, File.join(__dir__, 'active_genie/scoring')
  autoload :Ranking, File.join(__dir__, 'active_genie/ranking')

  class << self
    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Configuration.new do |config|
        config.providers.add(Providers::OpenaiConfig)
        config.providers.add(Providers::GoogleConfig)
        config.providers.add(Providers::AnthropicConfig)
        config.providers.add(Providers::DeepseekConfig)
      end
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      Dir.glob(File.join(__dir__, 'tasks', '*.rake')).each { |r| load r }
    end
  end
end
