# frozen_string_literal: true

require_relative '../clients/unified_client'

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
      @reviewers = Array(reviewers).compact.uniq
      @config = ActiveGenie::Configuration.to_h(config)
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

      result = ::ActiveGenie::Clients::UnifiedClient.function_calling(
        messages,
        function,
        model_tier: 'lower_tier',
        config: @config
      )

      ActiveGenie::Logger.debug({
        step: :scoring,
        text: @text[0..30],
        criteria: @criteria[0..30],
        reviewers: get_or_recommend_reviewers,
        score: result['final_score'],
        reasoning: result['final_reasoning']
      })

      result
    end

    private

    def get_or_recommend_reviewers
      @get_or_recommend_reviewers ||= if @reviewers.count > 0 
        @reviewers
      else
        result = RecommendedReviewers.call(@text, @criteria, config: @config)

        [result['reviewer1'], result['reviewer2'], result['reviewer3']]
      end
    end

    PROMPT = <<~PROMPT
    Evaluate and score the provided text based on predefined criteria, using a scoring range of 0 to 100 with 100 representing the highest possible score.

    Follow the instructions below to ensure a comprehensive and objective assessment. 

    # Evaluation Process

    1. **Analysis**: 
      - Thoroughly compare the text against each criterion for a comprehensive evaluation.
      
    2. **Document Deviations**:
      - Identify and document areas where the content does not align with the specified criteria.

    3. **Highlight Strengths**:
      - Note notable features or elements that enhance the quality or effectiveness of the content.

    4. **Identify Weaknesses**:
      - Specify areas where the content fails to meet the criteria or where improvements could be made.

    # Scoring Fairness

    - Ensure the assigned score reflects both the alignment with the criteria and the content's effectiveness.
    - Consider if the fulfillment of other criteria compensates for areas lacking extreme details.

    # Scoring Range

    Segment scores into five parts before assigning a final score:
    - **Terrible**: 0-20 - Content does not meet the criteria.
    - **Bad**: 21-40 - Content is substandard but meets some criteria.
    - **Average**: 41-60 - Content meets criteria with room for improvement.
    - **Good**: 61-80 - Content exceeds criteria and is above average.
    - **Great**: 81-100 - Content exceeds all expectations.

    # Guidelines

    - Maintain objectivity and avoid biases.
    - Deconstruct each criterion into actionable components for systematic evaluation.
    - Apply reasonable judgment in assigning a score, justifying your rationale clearly.

    # Output Format

    - Provide a detailed review including:
      - A final score (0-100)
      - Specific reasoning for the assigned score, detailing all evaluated criteria
      - Include both positive aspects and suggested improvements

    # Notes

    - Consider edge cases where the text may partially align with criteria.
    - If lacking information, reasonably judge and explain your scoring approach.
    PROMPT
  end
end
