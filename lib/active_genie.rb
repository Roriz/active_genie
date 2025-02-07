module ActiveGenie
  autoload :Providers, File.join(__dir__, 'active_genie/providers')

  # Modules
  autoload :DataExtractor, File.join(__dir__, 'active_genie/data_extractor')
  autoload :Battle, File.join(__dir__, 'active_genie/battle')
  autoload :Scoring, File.join(__dir__, 'active_genie/scoring')
  autoload :Leaderboard, File.join(__dir__, 'active_genie/leaderboard')

  class << self
    def configure
      providers.register_internal_providers
      yield(providers) if block_given?
    end

    def providers
      @providers ||= Providers
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      Dir.glob(File.join(__dir__, 'tasks', '*.rake')).each { |r| load r }
    end
  end
end
