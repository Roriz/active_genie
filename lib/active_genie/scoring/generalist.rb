# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie
  module Scoring
    # The Generalist class provides a foundation for scoring text content against specified criteria
    # using AI-powered evaluation. It supports both single and multiple reviewer scenarios,
    # with the ability to automatically recommend reviewers when none are specified.
    #
    # The scoring process evaluates text based on given criteria and returns detailed feedback
    # including individual reviewer scores, reasoning, and a final aggregated score.
    #
    # @example Generalist usage with a single reviewer
    #   Generalist.call("Sample text", "Evaluate grammar and clarity", ["Grammar Expert"])
    #
    # @example Usage with automatic reviewer recommendation
    #   Generalist.call("Sample text", "Evaluate technical accuracy")
    #
    class Generalist
      # @param text [String] The text content to be evaluated
      # @param criteria [String] The evaluation criteria or rubric to assess against
      # @param reviewers [Array<String>] Optional list of specific reviewers. If empty,
      #   reviewers will be automatically recommended based on the content and criteria
      # @param config [Hash] Additional configuration config that modify the scoring behavior
      # @return [Hash] The evaluation result containing the scores and reasoning
      #   @return [Number] :final_score The final score of the text based on the criteria and reviewers
      #   @return [String] :final_reasoning Detailed explanation of why the final score was reached
      def self.call(...)
        new(...).call
      end

      def initialize(text, criteria, reviewers = [], config: {})
        @text = text
        @criteria = criteria
        @param_reviewers = Array(reviewers).compact.uniq
        @config = ActiveGenie.configuration.merge(config)
      end

      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "Scoring criteria: #{@criteria}" },
          {  role: 'user', content: "Text to score: #{@text}" }
        ]

        result = ::ActiveGenie::Clients::UnifiedClient.function_calling(
          messages,
          build_function,
          config: @config
        )

        result['final_score'] = 0 if result['final_score'].nil?

        @config.logger.call({
                              code: :scoring,
                              text: @text[0..30],
                              criteria: @criteria[0..30],
                              reviewers: reviewers,
                              score: result['final_score'],
                              reasoning: result['final_reasoning']
                            })

        result
      end

      PROMPT = File.read(File.join(__dir__, 'generalist.md'))

      private

      def build_function
        properties = build_properties

        function = JSON.parse(File.read(File.join(__dir__, 'generalist.json')), symbolize_names: true)
        function[:parameters][:properties] = properties
        function[:parameters][:required] = properties.keys

        function
      end

      def build_properties
        properties = {}
        reviewers.each do |reviewer|
          properties["#{reviewer}_reasoning"] = {
            type: 'string',
            description: "The reasoning of the scoring process by #{reviewer}."
          }
          properties["#{reviewer}_score"] = {
            type: 'number',
            description: "The score given by #{reviewer}.",
            min: 0,
            max: 100
          }
        end

        properties[:final_score] = {
          type: 'number',
          description: 'The final score based on the previous reviewers'
        }
        properties[:final_reasoning] = {
          type: 'string',
          description: 'The final reasoning based on the previous reviewers'
        }

        properties
      end

      def reviewers
        @reviewers ||= if @param_reviewers.count.positive?
                         @param_reviewers
                       else
                         result = RecommendedReviewers.call(@text, @criteria, config: @config)

                         [result['reviewer1'], result['reviewer2'], result['reviewer3']]
                       end
      end
    end
  end
end
