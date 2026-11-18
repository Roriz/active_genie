# frozen_string_literal: true

module ActiveGenie
  module Providers
    module ToolArguments
      module_function

      # Some models wrap tool arguments as {"message": {...}}. Unwrap only that
      # shape, so a schema that defines its own `message` field comes back intact.
      def unwrap(arguments, function)
        return arguments unless arguments.is_a?(Hash) && arguments['message'].is_a?(Hash)

        properties = function&.dig(:parameters, :properties) || {}
        return arguments if properties.key?(:message) || properties.key?('message')

        arguments['message']
      end
    end
  end
end
