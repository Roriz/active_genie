module ActiveGenie::DataExtractor
  class FromInformal
    def self.call(text, data_to_extract, config: {})
      new(text, data_to_extract, config:).call()
    end

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
    #   DataExtractor.from_informal(text, schema)
    #   # => { mood: "positive", mood_explanation: "Speaker views weather favorably",
    #   #      message_litote: true,
    #   #      litote_rephrased: "The weather is good today" }
    def initialize(text, data_to_extract, config: {})
      @text = text
      @data_to_extract = data_to_extract
      @config = ActiveGenie::Configuration.to_h(config)
    end

    def call
      response = Basic.call(@text, data_to_extract_with_litote, config:)

      if response['message_litote']
        response = Basic.call(response['litote_rephrased'], @data_to_extract, config:)
      end

      response
    end

    private

    def data_to_extract_with_litote
      {
        **@data_to_extract,
        message_litote: {
          type: 'boolean',
          description: 'Return true if the message is a litote. A litote is a figure of speech that uses understatement to emphasize a point by stating a negative to further affirm a positive, often incorporating double negatives for effect.'
        },
        litote_rephrased: {
          type: 'string',
          description: 'The true meaning of the litote. Rephrase the message to a positive and active statement.'
        }
      }
    end

    def config
      {
        all_providers: { model_tier: 'lower_tier' },
        **@config,
        log: {
          **@config.dig(:log),
          trace: self.class.name,
        },
      }
    end
  end
end
