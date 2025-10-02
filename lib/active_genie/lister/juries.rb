# frozen_string_literal: true

require_relative '../providers/unified_provider'

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
    #   # => [ "API Architect", "Technical Writer", "Developer Advocate" ]
    #
    class Juries < ActiveGenie::BaseModule
      # Initializes a new jury recommendation instance
      #
      # @param text [String] The text content to analyze for jury recommendations
      # @param criteria [String] The evaluation criteria that will guide jury selection
      # @param config [Hash] Additional configuration config that modify the recommendation process
      def initialize(text, criteria, config: {})
        @text = text
        @criteria = criteria
        @initial_config = config
      end

      def call
        messages = [
          {  role: 'system', content: prompt },
          {  role: 'user', content: "<criteria> #{@criteria}</criteria>" },
          {  role: 'user', content: "<text-to-score>#{@text}</text-to-score>" }
        ]

        function = {
          name: 'identify_jury',
          description: 'Discover a list of juries based on the text and given criteria.',
          parameters: {
            type: 'object',
            properties: {
              why_these_juries: {
                type: 'string',
                description: 'A brief explanation of why these juries were chosen.'
              },
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

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          function,
          config:
        )

        ActiveGenie::Response.new(
          data: provider_response['juries'] || [],
          reasoning: provider_response['why_these_juries'],
          raw: provider_response
        )
      end

      private

      def prompt
        @prompt ||= File.read(File.join(__dir__, 'juries.prompt.md'))
      end

      def config
        @config ||= begin
          c = ActiveGenie.configuration.merge(@initial_config)
          c.llm.recommended_model = 'deepseek-chat' unless c.llm.recommended_model

          c
        end
      end
    end
  end
end
