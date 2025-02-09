# frozen_string_literal: true

require_relative '../client'

module ActiveGenie::Scoring
  # The Basic class provides a foundation for scoring text content against specified criteria
  # using AI-powered evaluation. It supports both single and multiple reviewer scenarios,
  # with the ability to automatically recommend reviewers when none are specified.
  #
  # The scoring process evaluates text based on given criteria and returns detailed feedback
  # including individual reviewer scores, reasoning, and a final aggregated score.
  #
  # @example Basic usage with a single reviewer
  #   Basic.call("Sample text", "Evaluate grammar and clarity", ["Grammar Expert"])
  #
  # @example Usage with automatic reviewer recommendation
  #   Basic.call("Sample text", "Evaluate technical accuracy")
  #
  class Basic
    # @param text [String] The text content to be evaluated
    # @param criteria [String] The evaluation criteria or rubric to assess against
    # @param reviewers [Array<String>] Optional list of specific reviewers. If empty,
    #   reviewers will be automatically recommended based on the content and criteria
    # @param options [Hash] Additional configuration options that modify the scoring behavior
    # @option options [Boolean] :detailed_feedback Request more detailed feedback in the reasoning
    # @option options [Hash] :reviewer_weights Custom weights for different reviewers
    # @return [Hash] The evaluation result containing the scores and reasoning
    #   @return [Number] :final_score The final score of the text based on the criteria and reviewers
    #   @return [String] :final_reasoning Detailed explanation of why the final score was reached
    def self.call(text, criteria, reviewers = [], options: {})
      new(text, criteria, reviewers, options:).call
    end

    def initialize(text, criteria, reviewers = [], options: {})
      @text = text
      @criteria = criteria
      @reviewers = Array(reviewers).compact.uniq
      @options = options
    end

    def call
      messages = [
        {  role: 'system', content: PROMPT },
        {  role: 'user', content: "Scoring criteria: #{@criteria}" },
        {  role: 'user', content: "Text to score: #{@text}" }, 
      ]

      properties = {}
      get_or_recommend_reviewers.each do |reviewer|
        properties["#{reviewer}_reasoning"] = {
          type: 'string',
          description: "The reasoning of the scoring process by #{reviewer}.",
        }
        properties["#{reviewer}_score"] = {
          type: 'number',
          description: "The score given by #{reviewer}.",
          min: 0,
          max: 100
        }
      end

      function = {
        name: 'scoring',
        description: 'Score the text based on the given criteria.',
        schema: {
          type: "object",
          properties: {
            **properties,
            final_score: {
              type: 'number',
              description: 'The final score based on the previous reviewers',
            },
            final_reasoning: {
              type: 'string',
              description: 'The final reasoning based on the previous reviewers',
            }
          }
        }
      }

      ::ActiveGenie::Client.function_calling(messages, function, options:)
    end

    private

    def get_or_recommend_reviewers
      @get_or_recommend_reviewers ||= if @reviewers.count > 0 
        @reviewers
      else
        recommended_reviews = RecommendedReviews.call(@text, @criteria, options:)

        [recommended_reviews[:reviewer1], recommended_reviews[:reviewer2], recommended_reviews[:reviewer3]]
      end
    end

    PROMPT = <<~PROMPT
    Evaluate and score the provided text based on predefined criteria, which may include rules, keywords, or patterns. Use a scoring range of 0 to 100, with 100 representing the highest possible score. Follow the instructions below to ensure an accurate and objective assessment.

    # Evaluation Process
    1. **Analysis**: Thoroughly compare the text against each criterion to ensure comprehensive evaluation.
    2. **Document Deviations**: Clearly identify and document any areas where the content does not align with the specified criteria.
    3. **Highlight Strengths**: Emphasize notable features or elements that enhance the overall quality or effectiveness of the content.
    4. **Identify Weaknesses**: Specify areas where the content fails to meet the criteria or where improvements could be made.

    # Output Requirements
    Provide a detailed review, including:
      - A final score (0-100)
      - Specific reasoning for the assigned score, covering all evaluated criteria.
      - Ensure the reasoning includes both positive aspects and suggested improvements.

    # Guidelines
    - Maintain objectivity, avoiding biases or preconceived notions.
    - Deconstruct each criterion into actionable components for a systematic evaluation.
    - If the text lacks information, apply reasonable judgment to assign a score while clearly explaining the rationale.
    PROMPT

    def options
      {
        model_tier: 'lower_tier',
        log: {
          **(@options.dig(:log) || {}),
          start_time: @options.dig(:start_time) || Time.now,
          trace: self.class.name,
        },
        **@options
      }
    end
  end
end
