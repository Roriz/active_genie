# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie
  module Lister
    # The Juries class intelligently suggests appropriate jury roles
    # for evaluating text content based on specific criteria. It uses AI to analyze
    # the content and criteria to identify the most suitable subject matter experts.
    #
    # The class ensures a balanced and comprehensive review process by recommending
    # three distinct jury roles with complementary expertise and perspectives.
    #
    # @example Getting jury for technical content
    #   Juries.call("Technical documentation about API design",
    #                           "Evaluate technical accuracy and clarity")
    #   # => { jury1: "API Architect", jury2: "Technical Writer",
    #   #      jury3: "Developer Advocate", reasoning: "..." }
    #
    class Juries
      def self.call(...)
        new(...).call
      end

      # Initializes a new jury recommendation instance
      #
      # @param text [String] The text content to analyze for jury recommendations
      # @param criteria [String] The evaluation criteria that will guide jury selection
      # @param config [Hash] Additional configuration config that modify the recommendation process
      def initialize(text, criteria, config: {})
        @text = text
        @criteria = criteria
        @config = ActiveGenie.configuration.merge(config)
      end

      def call
        messages = [
          {  role: 'system', content: PROMPT },
          {  role: 'user', content: "Scoring criteria: #{@criteria}" },
          {  role: 'user', content: "Text to score: #{@text}" }
        ]

        function = {
          name: 'identify_jury',
          description: 'Discover a list of juries based on the text and given criteria.',
          parameters: {
            type: 'object',
            properties: {
              reasoning: { type: 'string' },
              juries: {
                type: 'array',
                description: 'The list of best juries',
                items: {
                  type: 'string'
                }
              }
            },
            required: %w[reasoning juries]
          }
        }

        result = client.function_calling(
          messages,
          function,
          config: @config
        )

        result['juries'] || []
      end

      PROMPT = <<~PROMPT
        Identify the top 3 suitable jury titles or roles based on the provided text and criteria. Selected jury must possess subject matter expertise, offer valuable insights, and ensure diverse yet aligned perspectives on the content.

        # Instructions
        1. **Analyze the Text and Criteria**: Examine the content and criteria to identify relevant jury titles or roles.
        2. **Determine Subject Matter Expertise**: Select jury with substantial knowledge or experience in the subject area.
        3. **Evaluate Insight Contribution**: Prioritize titles or roles capable of providing meaningful and actionable feedback on the content.
        4. **Incorporate Perspective Diversity**: Ensure the selection includes jury with varied but complementary viewpoints while maintaining alignment with the criteria.

        # Constraints
        - Selected jury must align with the content’s subject matter and criteria.
        - Include reasoning for how each choice supports a thorough and insightful review.
        - Avoid redundant or overly similar titles/roles to maintain diversity.
      PROMPT

      private

      def client
        ::ActiveGenie::Clients::UnifiedClient
      end
    end
  end
end
