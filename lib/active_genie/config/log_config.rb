# frozen_string_literal: true

module ActiveGenie
  module Config
    class LogConfig
      attr_writer :file_path, :fine_tune_file_path

      def file_path
        @file_path || 'log/active_genie.log'
      end

      def fine_tune_file_path
        @fine_tune_file_path || 'log/active_genie_fine_tune.log'
      end

      def output
        @output || ->(log) { $stdout.puts log }
      end

      def output=(output)
        raise InvalidLogOutputError, output unless output.respond_to?(:call)

        @output = output
      end

      def output_call(log)
        output.call(log)

        Array(@observers).each do |obs|
          next unless obs[:scope].all? { |key, value| log[key.to_sym] == value }

          obs[:observer].call(log)
        rescue StandardError => e
          ActiveGenie::Logger.call(code: :observer_error, **obs, error: e.message)
        end
      end

      def add_observer(observers: [], scope: nil, &block)
        @observers ||= []

        raise ArgumentError, 'Scope must be a hash' if !scope.nil? && !scope.is_a?(Hash)

        @observers << { observer: block, scope: scope || {} } if block_given?
        Array(observers).each do |observer|
          @observers << { observer:, scope: scope || {} }
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

      def merge(config_params = {})
        dup.tap do |config|
          config.add_observer(config_params[:observers]) if config_params[:observers]
        end
      end
    end
  end
end
