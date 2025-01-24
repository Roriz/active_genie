require_relative '../requester/requester.rb'

module ActiveGenie
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
      Review and score the text based on the given criteria, which can include a set of rules, keywords, or patterns.
      Score should be between 0 and 100, with 100 being the highest score.

      Ensure the scoring process is accurate by following the outlined steps.

      # Steps

      1. **Analyze**: Compare the content against each criterion comprehensively.
      2. **Document Deviations**: Note parts where the content deviates from the criteria.
      3. **Highlight Strengths**: Identify and highlight elements that significantly enhance the content’s quality or purpose.
      4. **Spot Weaknesses**: Pinpoint areas where the content fails to meet the criteria or areas that could be improved.

      # Output Format

      Provide a detailed review score and reasoning for each reviewer.

      # Notes

      - Remain objective and avoid any biases or preconceived notions about the content.
      - Break down each criterion into actionable items for coherent evaluation.
      - If details in the text are lacking, use informed judgment to assign a score.
      PROMPT

      DISCOVERING_REVIEWERS_PROMPT = <<~PROMPT
      Identify reviewers based on the text and given criteria. List the best 3 titles or roles to review the text, ensuring they have subject matter expertise, can provide valuable insights, and offer a diverse but aligned perspective on the content.

      # Steps

      1. **Discover Potential Reviewers**: Analyze the text and criteria to find relevant titles or roles.
      2. **Evaluate Expertise**: Ensure reviewers have significant expertise in the subject matter.
      3. **Assess Value**: Determine if reviewers can offer valuable insights on the content.
      4. **Ensure Diverse Perspective**: Choose reviewers who bring different viewpoints but remain aligned with the scoring criteria.

      # Output Format

      Provide a structured list including:
      - Top 3 Reviewer Titles/Roles
      - Justification for each choice focusing on expertise and perspective diversity.

      # Notes

      - Reviewers must align with the content and criteria while providing insightful evaluations.
      - Ensure selected reviewers can contribute to a comprehensive analysis of the text.
      PROMPT
    end
  end
end
