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

      private

      def client
        ::ActiveGenie::Providers::UnifiedProvider
      end

      def prompt
        @prompt ||= File.read(File.join(__dir__, 'juries.prompt.md'))
      end
    end
  end
end
