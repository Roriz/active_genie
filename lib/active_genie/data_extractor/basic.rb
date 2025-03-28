
require_relative '../clients/unified_client'

module ActiveGenie::DataExtractor
  class Basic
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
      @config = ActiveGenie::Configuration.to_h(runtime: config)
    end

    def call
      messages = [
        {  role: 'system', content: PROMPT },
        {  role: 'user', content: @text }
      ]
      function = {
        name: 'data_extractor',
        description: 'Extract structured and typed data from user messages.',
        schema: {
          type: "object",
          properties: data_to_extract_with_explaination
        }
      }

      result = ::ActiveGenie::Clients::UnifiedClient.function_calling(
        messages,
        function,
        model_tier: 'lower_tier',
        config: @config
      )

      ActiveGenie::Logger.debug({
        code: :data_extractor,
        text: @text[0..30],
        data_to_extract: @data_to_extract,
        extracted_data: result
      })

      result
    end

    private

    PROMPT = <<~PROMPT
    Extract structured and typed data from user messages.
    Identify relevant information within user messages and categorize it into predefined data fields with specific data types.

    # Steps
    1. **Identify Data Types**: Determine the types of data to collect, such as names, dates, email addresses, phone numbers, etc.
    2. **Extract Information**: Use pattern recognition and language understanding to identify and extract the relevant pieces of data from the user message.
    3. **Categorize Data**: Assign the extracted data to the appropriate predefined fields.

    # Notes
    - Handle missing or partial information gracefully.
    - Manage multiple occurrences of similar data points by prioritizing the first one unless specified otherwise.
    - Be flexible to handle variations in data format and language clues.
    PROMPT

    def data_to_extract_with_explaination
      with_explaination = {}
  
      @data_to_extract.each do |key, value|
        with_explaination[key] = value
        with_explaination["#{key}_explanation"] = {
          type: 'string',
          description: "The chain of thought that led to the conclusion about: #{key}. Can be blank if the user didn't provide any context",
        }
      end
      
      with_explaination
    end
  end
end
