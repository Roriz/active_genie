require 'json'
require 'net/http'

module ActiveGenie::Clients
  class OpenaiClient
    MAX_RETRIES = 3
    
    class OpenaiError < StandardError; end
    class RateLimitError < OpenaiError; end

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
      retries = config[:max_retries] || MAX_RETRIES
      start_time = Time.now
      
      begin
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
        log_response(start_time, parsed_body, config:)

        parsed_body
      rescue OpenaiError, Net::HTTPError, JSON::ParserError, Errno::ECONNRESET, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        if retries > 0
          retries -= 1
          backoff_time = calculate_backoff(MAX_RETRIES - retries)
          ActiveGenie::Logger.trace(
            {
              category: :llm,
              trace: "#{config.dig(:log, :trace)}/#{self.class.name}",
              message: "Retrying request after error: #{e.message}. Attempts remaining: #{retries}",
              backoff_time: backoff_time
            }
          )
          sleep(backoff_time)
          retry
        else
          ActiveGenie::Logger.trace(
            {
              category: :llm,
              trace: "#{config.dig(:log, :trace)}/#{self.class.name}",
              message: "Max retries reached. Failing with error: #{e.message}"
            }
          )
          raise
        end
      end
    end

    BASE_DELAY = 0.5
    def calculate_backoff(retry_count)
      # Exponential backoff with jitter: 2^retry_count + random jitter
      # Base delay is 0.5 seconds, doubles each retry, plus up to 0.5 seconds of random jitter
      # Simplified example: 0.5, 1, 2, 4, 8, 12, 16, 20, 24, 28, 30 seconds
      jitter = rand * BASE_DELAY
      [BASE_DELAY * (2 ** retry_count) + jitter, 30].min # Cap at 30 seconds
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
  end
end
