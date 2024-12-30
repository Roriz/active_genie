
require_relative '../requester/requester.rb'

module ActiveAI
  module DataExtractor
    module_function

    # Extracts data from user_texts based on the schema defined in data_to_extract.
    # @param text [String] The text to extract data from.
    # @param data_to_extract [Hash] The schema to extract data from the text.
    # @return [Hash] The extracted data.
    def call(text, data_to_extract, options = {})
      messages = [
        {  role: 'system', content: PROMPT },
        {  role: 'user', content: text }
      ]
      function = {
        name: 'data_extractor',
        description: 'Extract structured and typed data from user messages.',
        parameters: {
          type: "object",
          properties: data_to_extract_with_explaination(data_to_extract),
        }
      }

      ::ActiveAI::Requester.function_calling(messages, function, options)
    end

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

    private

    def data_to_extract_with_explaination(data_to_extract)
      data_to_extract.reduce({}) do |acc, (field, value)|
        acc[field] = value
        acc["#{field}_explaination"] = {
          type: 'string',
          description: "The chain of thought that led to the conclusion about: #{field}. Can be blank if the user didn't provide any context",
        }
      end

      data_to_extract_with_explaination[:message_litote] = {
        type: 'boolean',
        description: `Return true if the message is a litote. A litote is a figure of speech that uses understatement to emphasize a point by stating a negative to further affirm a positive, often incorporating double negatives for effect.`
      }

      data_to_extract_with_explaination[:litote_rephrased] = {
        type: 'string',
        description: `The true meaning of the litote. Rephrase the message to a positive statement.`
      }

      data_to_extract_with_explaination
    end
  end
end
