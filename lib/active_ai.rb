require_relative './active_ai/configuration'

module ActiveAI
  autoload :DataExtractor, File.expand_path('../data_extractor/data_extractor', __FILE__)

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
      config.values[model&.to_s] || config.values.values.first
    end
  end
end
