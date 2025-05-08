# frozen_string_literal: true

module ActiveGenie
  module Configuration
    class LogConfig
      def add_observer(observer, scope: nil)
        @observers ||= []
        @observers << { observer:, scope: }
      end

      def remove_observer(observer)
        @observers.delete_if { |obs| obs[:observer] == observer }
      end

      def clear_observers
        @observers = []
      end

      def call_observers(log)
        Array(@observers).each do |obs|
          next unless obs[:scope].nil? || obs[:scope].all? { |key, value| log[key.to_sym] == value }

          obs[:observer].call(log)
        end
      end
    end
  end
end
