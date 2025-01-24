require 'json'
require 'net/http'

module ActiveGenie
  class Openai
    class << self
      def function_calling(messages, function, options)
        app_config = ActiveGenie.config_by_model(options[:model])

        model = options[:model] || app_config[:model]
        
        raise "Model can't be blank" if model.nil?

        payload = {
          messages:,
          response_format: {
            type: 'json_schema',
            json_schema: function
          },
          model:,
        }

        api_key = options[:api_key] || app_config[:api_key]

        headers = DEFAULT_HEADERS.merge(
          'Authorization': "Bearer #{api_key}"
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

    end
    
      
    API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
    DEFAULT_HEADERS = {
      'Content-Type': 'application/json',
    }

    # TODO: add some more rich error handling
    class OpenaiError < StandardError; end
  end
end
