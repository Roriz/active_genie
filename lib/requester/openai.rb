require 'json'
require 'net/http'

module ActiveAI
  class Openai
    class << self
      def function_calling(messages, function, config)
        payload = {
          messages:,
          response_format: { type: 'json_schema', json_schema: function },
          model: config.fetch('model'),
        }
        
        raise "Model can't be blank" if payload[:model].nil?

        headers = DEFAULT_HEADERS.merge(
          'Authorization': "Bearer #{config.fetch('api_key')}",
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
        return nil if response.body.empty?

        JSON.parse(response.body)
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
