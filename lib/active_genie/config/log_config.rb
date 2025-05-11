# frozen_string_literal: true

module ActiveGenie
  module Config
    class LogConfig
      def add_observer(observers, scope: nil)
        @observers ||= []
        Array(observers).each do |observer|
          @observers << { observer:, scope: }
        end
      end

      def remove_observer(observers)
        Array(observers).each do |observer|
          @observers.delete_if { |obs| obs[:observer] == observer }
        end
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

      def merge(config_params = {})
        dup.tap do |config|
          config.add_observer(config_params[:observers]) if config_params[:observers]
        end
      end
    end
  end
end
