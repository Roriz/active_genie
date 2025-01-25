module ActiveGenie
  autoload :DataExtractor, File.join(__dir__, 'active_genie/data_extractor')
  autoload :Scoring, File.join(__dir__, 'active_genie/scoring')
  autoload :Configuration, File.join(__dir__, 'active_genie/configuration')

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config) if block_given?
    end
    
    def [](key)
      config.values[key.to_s]
    end

    def config_by_model(model)
      config.values[model&.to_s&.downcase&.strip] || config.values.values.first || {}
    end
  end
end
