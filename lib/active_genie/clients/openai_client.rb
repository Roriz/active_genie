require 'json'
require 'net/http'

require_relative './helpers/retry'

module ActiveGenie::Clients
  class OpenaiClient    
    class OpenaiError < StandardError; end
    class RateLimitError < OpenaiError; end

    def initialize(config)
      @app_config = config
    end

    def function_calling(messages, function, model_tier: nil, config: {})
      model = config[:model] || @app_config.tier_to_model(model_tier)

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
      parsed_response = parsed_response.dig('properties') || parsed_response

      ActiveGenie::Logger.trace({step: :function_calling, payload:, parsed_response: })

      parsed_response
    rescue JSON::ParserError
      nil
    end

    private

    DEFAULT_HEADERS = {
      'Content-Type': 'application/json',
    }

    def request(payload, headers, config:)
      start_time = Time.now

      retry_with_backoff(config:) do
        response = Net::HTTP.post(
          URI("#{@app_config.api_url}/chat/completions"),
          payload.to_json,
          headers
        )

        if response.is_a?(Net::HTTPTooManyRequests)
          raise RateLimitError, "OpenAI API rate limit exceeded: #{response.body}"
        end

        raise OpenaiError, response.body unless response.is_a?(Net::HTTPSuccess)

        return nil if response.body.empty?

        parsed_body = JSON.parse(response.body)

        ActiveGenie::Logger.trace({
          step: :llm_stats,
          input_tokens: parsed_body.dig('usage', 'prompt_tokens'),
          output_tokens: parsed_body.dig('usage', 'completion_tokens'),
          total_tokens: parsed_body.dig('usage', 'prompt_tokens') + parsed_body.dig('usage', 'completion_tokens'),
          model: payload[:model],
          duration: Time.now - start_time,
          usage: parsed_body.dig('usage')
        })

        parsed_body
      end
    end
  end
end