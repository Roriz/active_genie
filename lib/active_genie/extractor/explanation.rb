# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Extractor
    class Explanation < ActiveGenie::BaseModule
      # Extracts structured data from text based on a predefined schema.
      #
      # @param text [String] The input text to analyze and extract data from
      # @param data_to_extract [Hash] Schema defining the data structure to extract.
      #   Each key in the hash represents a field to extract, and its value defines the expected type and constraints.
      # @param config [Hash] Additional config for the extraction process
      #
      # @return [Hash] The extracted data matching the schema structure. Each field will include
      #   both the extracted value and an explanation of how it was derived.
      #
      # @example Extract a person's details
      #   schema = {
      #     name: { type: 'string', description: 'Full name of the person' },
      #     age: { type: 'integer', description: 'Age in years' }
      #   }
      #   text = "John Doe is 25 years old"
      #   Extractor.with_explanation(text, schema)
      #   # => { name: "John Doe", name_explanation: "Found directly in text",
      #   #      age: 25, age_explanation: "Explicitly stated as 25 years old" }
      def initialize(text, data_to_extract, config: {})
        @text = text
        @data_to_extract = data_to_extract
        @initial_config = config
      end

      def call
        messages = [
          {  role: 'system', content: prompt },
          {  role: 'user', content: @text }
        ]

        properties = data_to_extract_with_explanation

        function = JSON.parse(File.read(File.join(__dir__, 'explanation.json')), symbolize_names: true)
        function[:parameters][:properties] = properties
        function[:parameters][:required] = properties.keys

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          function,
          config: config
        )

        response_formatted(provider_response)
      end

      private

      def data_to_extract_with_explanation
        return @data_to_extract unless config.extractor.with_explanation

        with_explanation = {}

        @data_to_extract.each do |key, value|
          with_explanation[key] = value
          with_explanation["#{key}_explanation"] = {
            type: 'string',
            description: "
            The chain of thought that led to the conclusion about: #{key}.
            Can be blank if the user didn't provide any context
            "
          }
          with_explanation["#{key}_accuracy"] = {
            type: 'integer',
            description: '
            The accuracy of the extracted data, what is the percentage of confidence?
            When 100 it means the data is explicitly stated in the text.
            When 0 it means is no way to discover the data from the text
            '
          }
        end

        with_explanation
      end

      def response_formatted(provider_response)
        data = provider_response.reject do |key, value|
          value.nil? || (provider_response.key?("#{key}_accuracy") && provider_response["#{key}_accuracy"] < min_accuracy)
        end

        first_reasoning_key = data.find { |key, _value| key.to_s.end_with?('_explanation') }

        ActiveGenie::Response.new(
          data:,
          reasoning: first_reasoning_key,
          raw: provider_response
        )
      end

      def min_accuracy
        config.extractor.min_accuracy # default 70
      end

      def prompt
        File.read(File.join(__dir__, 'explanation.prompt.md'))
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
