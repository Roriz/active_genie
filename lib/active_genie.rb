# frozen_string_literal: true

# Every error the runtime raises, one file each (the eval engine loads its own from errors/eval/).
Dir[File.join(__dir__, 'active_genie/errors/*.rb')].each { |file| require file }
require_relative 'active_genie/logger'
require_relative 'active_genie/configuration'

require_relative 'active_genie/values/result'
require_relative 'active_genie/utils/base_module'
require_relative 'active_genie/utils/deep_merge'

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

    def new_configuration(new_config)
      return new_config if new_config.instance_of?(Configuration)

      Configuration.new(
        DeepMerge.call(@configuration.to_h, new_config)
      )
    end

    def logger
      @logger ||= Logger.new
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      # Only the tasks meant for apps. tasks/test.rake is the gem's own test suite: loaded into an app,
      # it would hook `rake test` and clear the app's API keys.
      %w[install eval eval_install].each { |name| load File.join(__dir__, 'tasks', "#{name}.rake") }
    end
  end
end
