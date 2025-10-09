# frozen_string_literal: true

require_relative '../providers/unified_provider'

module ActiveGenie
  module Extractor
    class Data < ActiveGenie::BaseModule
      # Extracts structured data from text based on a predefined schema.
      #
      # @param text [String] The input text to analyze and extract data from
      # @param data_to_extract [Hash] Schema defining the data structure to extract.
      #   Each key in the hash represents a field to extract, and its value defines the expected type and constraints.
      # @param config [Hash] Additional config for the extraction process
      #
      # @return [Hash] The extracted data matching the schema structure. Each field will include
      #   both the extracted value.
      #
      # @example Extract a person's details
      #   schema = {
      #     name: { type: 'string', description: 'Full name of the person' },
      #     age: { type: 'integer', description: 'Age in years' }
      #   }
      #   text = "John Doe is 25 years old"
      #   Extractor.with_explanation(text, schema)
      #   # => { name: "John Doe", age: 25 }
      def initialize(text, data_to_extract, config: {})
        @text = text
        @data_to_extract = data_to_extract
        @initial_config = config
        super
      end

      def call
        messages = [
          {  role: 'system', content: prompt },
          {  role: 'user', content: @text }
        ]

        function = JSON.parse(File.read(File.join(__dir__, 'data.json')), symbolize_names: true)
        function[:parameters][:properties] = @data_to_extract
        function[:parameters][:required] = @data_to_extract.keys

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          function,
          config: config
        )

        response_formatted(provider_response)
      end

      private

      def response_formatted(provider_response)
        data = provider_response.compact

        ActiveGenie::Response.new(
          data:,
          raw: provider_response
        )
      end

      def prompt
        File.read(File.join(__dir__, 'data.prompt.md'))
      end

      def config
        @config ||= ActiveGenie.new_configuration(
          ActiveGenie::DeepMerge.call(
            { llm: { recommended_model: 'deepseek-chat' } },
            @initial_config
          )
        )
      end
    end
  end
end
