# frozen_string_literal: true

require_relative 'explanation'

module ActiveGenie
  module Extractor
    class Litote < ActiveGenie::BaseModule
      # Extracts data from informal text while also detecting litotes and their meanings.
      # This method extends the basic extraction by analyzing rhetorical devices.
      #
      # @param text [String] The informal text to analyze
      # @param data_to_extract [Hash] Schema defining the data structure to extract
      # @param config [Hash] Additional config for the extraction process
      #
      # @return [Hash] The extracted data including litote analysis. In addition to the
      #   schema-defined fields, includes:
      #   - message_litote: Whether the text contains a litote
      #   - litote_rephrased: The positive rephrasing of any detected litote
      #
      # @example Analyze text with litote
      #   text = "The weather isn't bad today"
      #   schema = { mood: { type: 'string', description: 'The mood of the message' } }
      #   Extractor.with_litote(text, schema)
      #   # => { mood: "positive", mood_explanation: "Speaker views weather favorably",
      #   #      message_litote: true,
      #   #      litote_rephrased: "The weather is good today" }
      def initialize(text, data_to_extract, config: {})
        @text = text
        @data_to_extract = data_to_extract
        super(config:)
      end

      def call
        response = Explanation.call(@text, extract_with_litote, config:)
        litote_rephrased = response.data[:litote_rephrased]

        if response.data[:message_litote]
          rephrased_response = Explanation.call(litote_rephrased, @data_to_extract, config:)
          litote_result(rephrased_response, rephrased_response.data, litote: true, litote_rephrased:)
        else
          clean_data = response.data.except(:message_litote, :litote_rephrased)
          litote_result(response, clean_data, litote: false, litote_rephrased:)
        end
      end

      private

      def litote_result(response, data, litote:, litote_rephrased:)
        metadata = (response.metadata || {}).merge('message_litote' => litote, 'litote_rephrased' => litote_rephrased)
        ActiveGenie::Result.new(data:, reasoning: response.reasoning, metadata:)
      end

      def extract_with_litote
        parameters = JSON.parse(File.read(File.join(__dir__, 'litote.json')), symbolize_names: true)

        @data_to_extract.merge(parameters)
      end

      def module_config
        { llm: { recommended_model: 'deepseek-flash' } }
      end
    end
  end
end
