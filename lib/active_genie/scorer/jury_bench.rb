# frozen_string_literal: true

require_relative '../providers/unified_provider'
require_relative '../utils/text_case'

module ActiveGenie
  module Scorer
    # The JuryBench class provides a foundation for Scorer text content against specified criteria
    # using AI-powered evaluation. It supports both single and multiple jury scenarios,
    # with the ability to automatically recommend juries when none are specified.
    #
    # The Scorer process evaluates text based on given criteria and returns detailed feedback
    # including individual jury scores, reasoning, and the final score the model writes from them.
    #
    # @example JuryBench usage with a single jury
    #   JuryBench.call("Sample text", "Evaluate grammar and clarity", ["Grammar Expert"])
    #
    # @example Usage with automatic jury recommendation
    #   JuryBench.call("Sample text", "Evaluate technical accuracy")
    #
    class JuryBench < ActiveGenie::BaseModule
      # @param text [String] The text content to be evaluated
      # @param criteria [String] The evaluation criteria or rubric to assess against
      # @param positional_juries [Array<String>] Optional list of specific juries (positional)
      # @param juries [Array<String>] Optional list of specific juries (keyword)
      # @param config [Hash] Additional configuration config that modify the Scorer behavior
      # @return [ActiveGenie::Result] The evaluation result containing scores and reasoning
      def initialize(text, criteria, positional_juries = [], juries: nil, config: {})
        @text = text
        @criteria = criteria
        chosen_juries = juries || positional_juries
        @param_juries = Array(chosen_juries).compact.uniq
        super(config:)
      end

      def call
        messages = [
          { role: 'system', content: PROMPT },
          { role: 'user', content: "Scorer criteria: #{@criteria}" },
          { role: 'user', content: "Text to score: #{@text}" }
        ]

        response_formatted(ActiveGenie::Providers::UnifiedProvider.function_calling(messages, build_function, config:))
      end

      PROMPT = File.read(File.join(__dir__, 'jury_bench.prompt.md'))

      # Longest suffix appended to a jury key when building schema properties.
      JURY_KEY_SUFFIX = '_reasoning'

      private

      # A missing final_score reads as 0; Eval::Judge relies on the metadata to tell the two apart.
      def response_formatted(data)
        ActiveGenie::Result.new(
          data: data&.dig('final_score') || data&.dig(:final_score) || 0,
          reasoning: data&.dig('final_reasoning'),
          metadata: data || {}
        )
      end

      def build_function
        {
          name: 'scorer',
          description: 'Score the text based on the given criteria.',
          parameters: {
            type: 'object',
            properties: properties,
            required: properties.keys
          }
        }
      end

      def properties
        @properties ||= juries.map { |jury| jury_properties(jury) }.reduce({}, :merge).merge(final_properties)
      end

      def jury_properties(jury)
        jury_key = jury_key_for(jury)
        {
          "#{jury_key}_reasoning" => {
            type: 'string',
            description: "The reasoning of the Scorer process by #{jury}."
          },
          "#{jury_key}_score" => {
            type: 'number',
            description: "The score given by #{jury}.",
            min: 0,
            max: 100
          }
        }
      end

      def final_properties
        {
          final_score: {
            type: 'number',
            description: 'The final score based on the previous juries'
          },
          final_reasoning: {
            type: 'string',
            description: 'The final reasoning based on the previous juries'
          }
        }
      end

      # Jury names become JSON schema property keys, which providers cap at 64
      # characters. Reserve room for the suffix so the combined key still fits.
      def jury_key_for(jury)
        ActiveGenie::TextCase.underscore(
          jury,
          max_length: ActiveGenie::TextCase::MAX_KEY_LENGTH - JURY_KEY_SUFFIX.length
        )
      end

      def juries
        @juries ||= if @param_juries.any?
                      @param_juries
                    else
                      ::ActiveGenie::Lister::Juries.call(@text, @criteria, config:).data
                    end
      end

      def module_config
        { llm: { recommended_model: 'deepseek-flash' } }
      end
    end
  end
end
