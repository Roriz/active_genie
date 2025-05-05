# frozen_string_literal: true

module ActiveGenie
  module Concerns
    module Loggable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def with_logging_context(context_method, observer_proc = nil)
          original_method = instance_method(:call)

          define_method(:call) do |*args, **kwargs, &block|
            context = send(context_method, *args, **kwargs)
            bound_observer = observer_proc ? ->(log) { instance_exec(log, &observer_proc) } : nil

            ActiveGenie::Logger.with_context(context, observer: bound_observer) do
              original_method.bind(self).call(*args, **kwargs, &block)
            end
          end
        end
      end

      def info(log)
        ::ActiveGenie::Logger.info(log)
      end

      def error(log)
        ::ActiveGenie::Logger.error(log)
      end

      def warn(log)
        ::ActiveGenie::Logger.warn(log)
      end

      def debug(log)
        ::ActiveGenie::Logger.debug(log)
      end

      def trace(log)
        ::ActiveGenie::Logger.trace(log)
      end
    end
  end
end
