# frozen_string_literal: true

module ActiveGenie
  module Concerns
    module Loggable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def call_with_log_context(context_method)
          original_method = instance_method(:call)

          define_method(:call) do |*args, **kwargs, &block|
            context = send(context_method, *args, **kwargs)

            ActiveGenie::Logger.with_context(context) do
              original_method.bind(self).call(*args, **kwargs, &block)
            end
          end
        end

        def logger(...)
          ActiveGenie::Logger.call(...)
        end
      end
    end
  end
end
