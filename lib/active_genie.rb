# frozen_string_literal: true

require_relative 'active_genie/logger'
require_relative 'active_genie/configuration'

require_relative 'active_genie/entities/response'
require_relative 'active_genie/utils/base_module'

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
      @configuration ||= Configuration.new
    end

    def logger
      @logger ||= ActiveGenie::Logger.new()
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      Dir.glob(File.join(__dir__, 'tasks', '*.rake')).each { |r| load r }
    end
  end
end
