# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Scorer
    # The JuryBench class provides a foundation for Scorer text content against specified criteria
    # using AI-powered evaluation. It supports both single and multiple jury scenarios,
    # with the ability to automatically recommend juries when none are specified.
    #
    # The Scorer process evaluates text based on given criteria and returns detailed feedback
    # including individual jury scores, reasoning, and a final aggregated score.
    #
    # @example JuryBench usage with a single jury
    #   JuryBench.call("Sample text", "Evaluate grammar and clarity", ["Grammar Expert"])
    #
    # @example Usage with automatic jury recommendation
    #   JuryBench.call("Sample text", "Evaluate technical accuracy")
    #
    class JuryBench
      # @param text [String] The text content to be evaluated
      # @param criteria [String] The evaluation criteria or rubric to assess against
      # @param juries [Array<String>] Optional list of specific juries. If empty,
      #   juries will be automatically recommended based on the content and criteria
      # @param config [Hash] Additional configuration config that modify the Scorer behavior
      # @return [Hash] The evaluation result containing the scores and reasoning
      #   @return [Number] :final_score The final score of the text based on the criteria and juries
      #   @return [String] :final_reasoning Detailed explanation of why the final score was reached
      def self.call(...)
        new(...).call
      end

      def initialize(text, criteria, juries = [], config: {})
        @text = text
        @criteria = criteria
        @param_juries = Array(juries).compact.uniq
        @config = ActiveGenie.configuration.merge(config)
      end

      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "Scorer criteria: #{@criteria}" },
          {  role: 'user', content: "Text to score: #{@text}" }
        ]

        result = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          build_function,
          config: @config
        )

        result['final_score'] = 0 if result['final_score'].nil?

        @config.logger.call({
                              code: :Scorer,
                              text: @text[0..30],
                              criteria: @criteria[0..30],
                              juries: juries,
                              score: result['final_score'],
                              reasoning: result['final_reasoning']
                            })

        result
      end

      PROMPT = File.read(File.join(__dir__, 'jury_bench.prompt.md'))

      private

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
        @properties ||= begin
          tmp = {}
          juries.each do |jury|
            tmp["#{jury}_reasoning"] = {
              type: 'string',
              description: "The reasoning of the Scorer process by #{jury}."
            }
            tmp["#{jury}_score"] = {
              type: 'number',
              description: "The score given by #{jury}.",
              min: 0,
              max: 100
            }
          end

          tmp[:final_score] = {
            type: 'number',
            description: 'The final score based on the previous juries'
          }
          tmp[:final_reasoning] = {
            type: 'string',
            description: 'The final reasoning based on the previous juries'
          }

          tmp
        end
      end

      def juries
        @juries ||= if @param_juries.any?
                      @param_juries
                    else
                      ::ActiveGenie::Lister::Juries.call(@text, @criteria, config: @config)
                    end
      end
    end
  end
end
