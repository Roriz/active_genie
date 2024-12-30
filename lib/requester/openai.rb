
module ActiveGenerative
  module Requester
    module Openai
      module_function

      def function_calling(messages, function, config)
        payload = {
          messages:,
          response_format: { type: 'json_schema', json_schema: },
          model: config.fetch('model'),
        }
        
        raise "Model not found" if payload[:model].nil?

        headers = DEFAULT_HEADERS.merge(
          'Authorization': "Bearer #{options.fetch(:api_key)}",
          'Openai-Organization': config.fetch('organization'),
        ).compact

        response = request(payload, headers)

        JSON.parse(response.dig('choices', 0, 'message', 'content'))
      rescue JSON::ParserError
        nil
      end

      def request(payload, headers)
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
      DEFAULT_HEADERS = {
        'Content-Type': 'application/json',
      }

      # TODO: add some more rich error handling
      class OpenaiError < StandardError; end
    end
  end
end
