# frozen_string_literal: true

require_relative 'base_config'

module ActiveGenie
  module Config
    class LogConfig < BaseConfig
      attr_reader :output
      attr_writer :file_path, :fine_tune_file_path

      def file_path
        @file_path ||= 'log/active_genie.log'
      end

      def fine_tune_file_path
        @fine_tune_file_path ||= 'log/active_genie_fine_tune.log'
      end

      def observers=(observers)
        Array(observers).each do |observer|
          add_observer(observers: [observer[:observer]], scope: observer[:scope] || {})
        end
      end

      def observers
        @observers ||= []
      end

      def additional_context
        @additional_context ||= {}
      end

      def additional_context=(context)
        @additional_context = additional_context.merge(context || {}).compact
      end

      def output=(output)
        return if output.nil?
        raise InvalidLogOutputError, output unless output.respond_to?(:call)

        @output = output
      end

      def add_observer(observers: [], scope: {}, &block)
        @observers ||= []

        raise ArgumentError, 'Scope must be a hash' if scope && !scope.is_a?(Hash)

        Array(observers).each do |observer|
          next unless observer.respond_to?(:call)

          @observers << { observer:, scope: }
        end
        @observers << { observer: block, scope: } if block_given?
      end

      def remove_observer(observers)
        Array(observers).each do |observer|
          @observers.delete_if { |obs| obs[:observer] == observer }
        end
      end

      def clear_observers
        @observers = []
      end
    end
  end
end
