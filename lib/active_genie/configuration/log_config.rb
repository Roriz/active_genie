
module ActiveGenie::Configuration
  class LogConfig
    attr_writer :log_level

    def log_level
      @log_level ||= :info
    end

    def to_h(config = {})
      self.attributes.merge(config)
    end
  end
end
