require_relative '../requester/requester.rb'

module ActiveGenie
  module DataExtractor
    # The DataExtractor class handles the extraction of structured data from text inputs
    # using AI models through function calling.
    class DataExtractor
      class << self
        # Extracts structured data from text based on a predefined schema.
        #
        # @param text [String] The input text to analyze and extract data from
        # @param data_to_extract [Hash] Schema defining the data structure to extract.
        #   Each key in the hash represents a field to extract, and its value defines the expected type and constraints.
        # @param options [Hash] Additional options for the extraction process
        #   @option options [String] :model The model to use for the extraction
        #   @option options [String] :api_key The API key to use for the extraction
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
        def call(text, data_to_extract, options: {})
          messages = [
            {  role: 'system', content: PROMPT },
            {  role: 'user', content: text }
          ]
          function = {
            name: 'data_extractor',
            description: 'Extract structured and typed data from user messages.',
            schema: {
              type: "object",
              properties: data_to_extract_with_explaination(data_to_extract)
            }
          }

          ::ActiveGenie::Requester.function_calling(messages, function, options)
        end

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
          messages = [
            {  role: 'system', content: PROMPT },
            {  role: 'user', content: text }
          ]
          properties = data_to_extract_with_explaination(data_to_extract)
          properties[:message_litote] = {
            type: 'boolean',
            description: 'Return true if the message is a litote. A litote is a figure of speech that uses understatement to emphasize a point by stating a negative to further affirm a positive, often incorporating double negatives for effect.'
          }
          properties[:litote_rephrased] = {
            type: 'string',
            description: 'The true meaning of the litote. Rephrase the message to a positive statement.'
          }

          function = {
            name: 'data_extractor',
            description: 'Extract structured and typed data from user messages.',
          schema: { type: "object", properties: }
          }

          ::ActiveGenie::Requester.function_calling(messages, function, options)
        end

        private

        PROMPT = <<~PROMPT
        Extract structured and typed data from user messages.
        Identify relevant information within user messages and categorize it into predefined data fields with specific data types.

        # Steps
        1. **Identify Data Types**: Determine the types of data to collect, such as names, dates, email addresses, phone numbers, etc.
        2. **Extract Information**: Use pattern recognition and language understanding to identify and extract the relevant pieces of data from the user message.
        3. **Categorize Data**: Assign the extracted data to the appropriate predefined fields.
        4. **Structure Data**: Format the extracted and categorized data in a structured format, such as JSON.

        # Output Format
        The output should be a JSON object containing fields with their corresponding extracted values. If a value is not found, the field should still be included with a null value.

        # Notes
        - Handle missing or partial information gracefully.
        - Manage multiple occurrences of similar data points by prioritizing the first one unless specified otherwise.
        - Be flexible to handle variations in data format and language clues.
        PROMPT

        def data_to_extract_with_explaination(data_to_extract)
          with_explaination = {}
      
          data_to_extract.each do |key, value|
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
  end
end
