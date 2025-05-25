# frozen_string_literal: true

require_relative '../clients/unified_client'

module ActiveGenie
  module DataExtractor
    class Generalist
      def self.call(...)
        new(...).call
      end

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
      #   DataExtractor.call(text, schema)
      #   # => { name: "John Doe", name_explanation: "Found directly in text",
      #   #      age: 25, age_explanation: "Explicitly stated as 25 years old" }
      def initialize(text, data_to_extract, config: {})
        @text = text
        @data_to_extract = data_to_extract
        @config = ActiveGenie.configuration.merge(config)
      end

      def call
        messages = [
          {  role: 'system', content: prompt },
          {  role: 'user', content: @text }
        ]

        properties = data_to_extract_with_explanation

        function = JSON.parse(File.read(File.join(__dir__, 'generalist.json')), symbolize_names: true)
        function[:parameters][:properties] = properties
        function[:parameters][:required] = properties.keys

        response = function_calling(messages, function)

        simplify_response(response)
      end

      private

      def data_to_extract_with_explanation
        return @data_to_extract unless @config.data_extractor.with_explanation

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

      def function_calling(messages, function)
        response = ::ActiveGenie::Clients::UnifiedClient.function_calling(
          messages,
          function,
          config: @config
        )

        ActiveGenie::Logger.call(
          {
            code: :data_extractor,
            text: @text[0..30],
            data_to_extract: function[:parameters][:properties],
            extracted_data: response
          }
        )

        response
      end

      def simplify_response(response)
        return response if @config.data_extractor.verbose

        simplified_response = {}

        @data_to_extract.each_key do |key|
          next unless response.key?(key.to_s)
          next if response.key?("#{key}_accuracy") && response["#{key}_accuracy"] < min_accuracy

          simplified_response[key] = response[key.to_s]
        end

        simplified_response
      end

      def min_accuracy
        @config.data_extractor.min_accuracy # default 70
      end

      def prompt
        File.read(File.join(__dir__, 'generalist.md'))
      end
    end
  end
end
