# frozen_string_literal: true

require_relative '../providers/unified_provider'

require 'json'

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
        super(config:)
      end

      def call
        messages = [
          {  role: 'system', content: prompt },
          {  role: 'user', content: "<criteria> #{@criteria}</criteria>" },
          {  role: 'user', content: "<text-to-score>#{@text}</text-to-score>" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          FUNCTION,
          config:
        )

        ActiveGenie::Result.new(
          data: normalize_juries(provider_response['juries'] || []),
          reasoning: provider_response['why_these_juries'],
          metadata: provider_response
        )
      end

      FUNCTION = {
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
          required: %w[why_these_juries juries]
        }
      }.freeze

      private

      # Models sometimes answer the array as a JSON string or a comma-separated list.
      def normalize_juries(juries)
        juries = parse_juries_string(juries) if juries.is_a?(String)
        Array(juries).map(&:to_s).map(&:strip).reject(&:empty?)
      end

      def parse_juries_string(juries)
        JSON.parse(juries)
      rescue JSON::ParserError
        juries.split(',').map(&:strip)
      end

      def prompt
        @prompt ||= File.read(File.join(__dir__, 'juries.prompt.md'))
      end

      def module_config
        { llm: { recommended_model: 'deepseek-flash' } }
      end
    end
  end
end
