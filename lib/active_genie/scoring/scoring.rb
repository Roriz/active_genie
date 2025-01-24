require_relative '../requester/requester.rb'

module ActiveGenie::Scoring
  class Scoring
    class << self
      # Extracts data from user_texts based on the schema defined in data_to_extract.
      # @param text [String] The text to extract data from.
      # @param criteria [String] The criteria to extract data from the text.
      # @param reviewers [Array<String>] The reviewers to score the text.
      # @param options [Hash] The options to pass to the function.
      # @return [Hash] The extracted data.
      def call(text, criteria, reviewers = [], options: {})
        reviewers = Array(reviewers).compact.uniq
        reviewers = reviewers.count > 0 ? reviewers : discover_reviewers(text, criteria)

        messages = [
          {  role: 'system', content: SCORING_PROMPT },
          {  role: 'user', content: "Scoring criteria: #{criteria}" },
          {  role: 'user', content: "Text to score: #{text}" }, 
        ]

        properties = {}
        reviewers.each do |reviewer|
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

        ::ActiveGenie::Requester.function_calling(messages, function, options)
      end

      def discover_reviewers(text, criteria, options: {})
        messages = [
          {  role: 'system', content: DISCOVERING_REVIEWERS_PROMPT },
          {  role: 'user', content: "Scoring criteria: #{criteria}" },
          {  role: 'user', content: "Text to score: #{text}" },
        ]

        function = {
          name: 'identify_reviewers',
          description: 'Discover reviewers based on the text and given criteria.',
          schema: {
            type: "object",
            properties: {
              reasoning: { type: 'string' },
              reviewer1: { type: 'string' },
              reviewer2: { type: 'string' },
              reviewer3: { type: 'string' },
            }
          }
        }

        response = ::ActiveGenie::Requester.function_calling(messages, function, options)
      
        [response['reviewer1'], response['reviewer2'], response['reviewer3']]
      end

      private

      SCORING_PROMPT = <<~PROMPT
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

      DISCOVERING_REVIEWERS_PROMPT = <<~PROMPT
      Identify the top 3 suitable reviewer titles or roles based on the provided text and criteria. Selected reviewers must possess subject matter expertise, offer valuable insights, and ensure diverse yet aligned perspectives on the content.

      # Instructions
      1. **Analyze the Text and Criteria**: Examine the content and criteria to identify relevant reviewer titles or roles.
      2. **Determine Subject Matter Expertise**: Select reviewers with substantial knowledge or experience in the subject area.
      3. **Evaluate Insight Contribution**: Prioritize titles or roles capable of providing meaningful and actionable feedback on the content.
      4. **Incorporate Perspective Diversity**: Ensure the selection includes reviewers with varied but complementary viewpoints while maintaining alignment with the criteria.

      # Constraints
      - Selected reviewers must align with the content’s subject matter and criteria.
      - Include reasoning for how each choice supports a thorough and insightful review.
      - Avoid redundant or overly similar titles/roles to maintain diversity.
      PROMPT
    end
  end
end
