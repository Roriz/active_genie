# frozen_string_literal: true

module ActiveGenie
  module Providers
    # Each provider reports token usage under its own keys, and any of them may
    # be missing. Normalizing here guarantees :llm_usage carries integer counts,
    # so observers that sum tokens never see nil.
    module UsageLogger
      module_function

      # @param usage [Hash, nil] The provider's raw usage object.
      # @param keys [Hash] Where the provider puts each count: { input:, output:, total: (optional) }.
      def call(usage, keys:, model:, config:)
        usage ||= {}
        input_tokens = usage[keys[:input]].to_i
        output_tokens = usage[keys[:output]].to_i
        total_tokens = usage[keys[:total]]&.to_i || (input_tokens + output_tokens)

        ActiveGenie.logger.call(
          { code: :llm_usage, input_tokens:, output_tokens:, total_tokens:, model:, usage: },
          config:
        )
      end
    end
  end
end
