module ActiveGenie::DataExtractor
  class FromInformal
    class << self
      # Extracts data from informal text while also detecting litotes and their meanings.
      # This method extends the basic extraction by analyzing rhetorical devices.
      #
      # @param text [String] The informal text to analyze
      # @param data_to_extract [Hash] Schema defining the data structure to extract
      # @param options [Hash] Additional options for the extraction process
      #
      # @return [Hash] The extracted data including litote analysis. In addition to the
      #   schema-defined fields, includes:
      #   - message_litote: Whether the text contains a litote
      #   - litote_rephrased: The positive rephrasing of any detected litote
      #
      # @example Analyze text with litote
      #   text = "The weather isn't bad today"
      #   schema = { mood: { type: 'string', description: 'The mood of the message' } }
      #   DataExtractor.from_informal(text, schema)
      #   # => { mood: "positive", mood_explanation: "Speaker views weather favorably",
      #   #      message_litote: true,
      #   #      litote_rephrased: "The weather is good today" }
      def from_informal(text, data_to_extract, options = {})
        properties = data_to_extract
        properties[:message_litote] = {
          type: 'boolean',
          description: 'Return true if the message is a litote. A litote is a figure of speech that uses understatement to emphasize a point by stating a negative to further affirm a positive, often incorporating double negatives for effect.'
        }
        properties[:litote_rephrased] = {
          type: 'string',
          description: 'The true meaning of the litote. Rephrase the message to a positive statement.'
        }

        response = Basic.call(text, properties, options:)

        if response['message_litote']
          response = Basic.call(response['litote_rephrased'], data_to_extract, options:)
        end

        response
      end
    end
  end
end
