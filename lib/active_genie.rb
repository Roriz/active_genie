module ActiveGenie
  autoload :Configuration, File.join(__dir__, 'active_genie/configuration')

  # Modules
  autoload :DataExtractor, File.join(__dir__, 'active_genie/data_extractor')
  autoload :Battle, File.join(__dir__, 'active_genie/battle')
  autoload :Scoring, File.join(__dir__, 'active_genie/scoring')
  autoload :Leaderboard, File.join(__dir__, 'active_genie/leaderboard')

  class << self    
    def configure
      yield(config) if block_given?
    end

    def load_tasks
      return unless defined?(Rake)

      Rake::Task.define_task(:environment)
      Dir.glob(File.join(__dir__, 'tasks', '*.rake')).each { |r| load r }
    end

    def config
      @config ||= Configuration.new
    end

    def [](key)
      config.values[key.to_s]
    end

    def config_by_model(model = nil)
      config.values[model&.to_s&.downcase&.strip] || config.values.values.first || {}
    end
  end
end
