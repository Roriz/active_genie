
module ActiveGenerative
  module Requester
    module Openai
      module_function

      def function_calling(payload, function)
        # payload[:messages] = payload[:messages] # TODO: convert internal messages to OpenAI format
        payload[:response_format] = { type: 'json_schema', json_schema: function }

        response = request(payload)

        JSON.parse(response.dig('choices', 0, 'message', 'content'))
      rescue JSON::ParserError
        nil
      end

      def request(payload, headers = default_headers)
        response = Net::HTTP.post(
          URI(API_URL),
          payload.to_json,
          headers
        )

        raise OpenaiError, response.body unless response.is_a?(Net::HTTPSuccess)
        return nil unless response.body.empty?

        JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end

      private
      
      API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
      API_KEY = ENV['OPENAI_API_KEY']

      # TODO: add some more rich error handling
      class OpenaiError < StandardError; end

      def default_headers 
        {
          'Content-Type': 'application/json',
          'Authorization': "Bearer #{API_KEY}"
        }
      end

      def texts_to_messages(texts, role: 'user')
        Array(texts).map { |text| { role: 'user', content: text } }
      end
    end
  end
end
