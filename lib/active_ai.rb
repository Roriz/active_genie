module ActiveAI
  autoload :DataExtractor, File.join(__dir__, 'data_extractor/data_extractor')
  autoload :Configuration, File.join(__dir__, 'active_ai/configuration')

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
      config.values[model&.to_s] || config.values.values.first || {}
    end
  end
end
