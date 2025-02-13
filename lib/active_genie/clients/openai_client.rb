require 'json'
require 'net/http'

module ActiveGenie::Clients
  class OpenaiClient
    def initialize(config)
      @app_config = config
    end

    def function_calling(messages, function, config: {})
      model = config[:model]
      model = @app_config.tier_to_model(config.dig(:all_providers, :model_tier)) if model.nil? && config.dig(:all_providers, :model_tier)
      model = @app_config.lower_tier_model if model.nil?

      payload = {
        messages:,
        response_format: {
          type: 'json_schema',
          json_schema: function
        },
        model:,
      }

      api_key = config[:api_key] || @app_config.api_key
      headers = DEFAULT_HEADERS.merge(
        'Authorization': "Bearer #{api_key}"
      ).compact

      response = request(payload, headers, config:)

      parsed_response = JSON.parse(response.dig('choices', 0, 'message', 'content'))
      parsed_response.dig('properties') || parsed_response
    rescue JSON::ParserError
      nil
    end

    private

    def request(payload, headers, config:)
      start_time = Time.now
      response = Net::HTTP.post(
        URI("#{@app_config.api_url}/chat/completions"),
        payload.to_json,
        headers
      )

      raise OpenaiError, response.body unless response.is_a?(Net::HTTPSuccess)
      return nil if response.body.empty?

      parsed_body = JSON.parse(response.body)
      log_response(start_time, parsed_body, config:)

      parsed_body
    end

    DEFAULT_HEADERS = {
      'Content-Type': 'application/json',
    }

    def log_response(start_time, response, config:)
      ActiveGenie::Logger.trace(
        {
          **config.dig(:log),
          category: :llm,
          trace: "#{config.dig(:log, :trace)}/#{self.class.name}",
          total_tokens: response.dig('usage', 'total_tokens'),
          model: response.dig('model'),
          request_duration: Time.now - start_time,
          openai: response
        }
      )
    end

    # TODO: add some more rich error handling
    class OpenaiError < StandardError; end
  end
end
