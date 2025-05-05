# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class LogConfig
      attr_writer :log_level

      def log_level
        @log_level ||= :info
      end

      def to_h(config = {})
        { log_level: }.merge(config)
      end
    end
  end
end
