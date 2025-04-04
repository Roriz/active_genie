require 'json'
require 'net/http'

require_relative './helpers/retry'
require_relative './base_client'

module ActiveGenie::Clients
  class OpenaiClient < BaseClient
    class OpenaiError < ClientError; end
    class RateLimitError < OpenaiError; end
    class InvalidResponseError < StandardError; end

    def initialize(config)
      super(config)
    end

    # Requests structured JSON output from the OpenAI model based on a schema.
    #
    # @param messages [Array<Hash>] A list of messages representing the conversation history.
    #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
    # @param function [Hash] A JSON schema definition describing the desired output format.
    # @param model_tier [Symbol, nil] A symbolic representation of the model quality/size tier.
    # @param config [Hash] Optional configuration overrides:
    #   - :api_key [String] Override the default API key.
    #   - :model [String] Override the model name directly.
    #   - :max_retries [Integer] Max retries for the request.
    #   - :retry_delay [Integer] Initial delay for retries.
    # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
    def function_calling(messages, function, model_tier: nil, config: {})
      model = config[:runtime][:model] || @app_config.tier_to_model(model_tier)

      payload = {
        messages:,
        tools: [{
          type: 'function',
          function: {
            **function,
            parameters: {
              **function[:parameters],
              additionalProperties: false
            },
            strict: true
          }.compact
        }],
        tool_choice: { type: 'function', function: { name: function[:name] } },
        stream: false,
        model:,
      }

      api_key = config[:runtime][:api_key] || @app_config.api_key
      headers = {
        'Authorization': "Bearer #{api_key}"
      }.compact

      retry_with_backoff(config:) do
        response = request_openai(payload, headers, config:)

        parsed_response = JSON.parse(response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments'))
        parsed_response = parsed_response.dig('message') || parsed_response

        raise InvalidResponseError, "Invalid response: #{parsed_response}" if parsed_response.nil? || parsed_response.keys.size.zero?

        ActiveGenie::Logger.trace({code: :function_calling, payload:, parsed_response: })

        parsed_response
      end
    end


    private

    # Make a request to the OpenAI API
    #
    # @param payload [Hash] The request payload
    # @param headers [Hash] Additional headers
    # @param config [Hash] Configuration options
    # @return [Hash] The parsed response
    def request_openai(payload, headers, config:)
      start_time = Time.now

      response = post("/chat/completions", payload, headers: headers, config: config)

      return nil if response.nil?

      ActiveGenie::Logger.trace({
        code: :llm_usage,
        input_tokens: response.dig('usage', 'prompt_tokens'),
        output_tokens: response.dig('usage', 'completion_tokens'),
        total_tokens: response.dig('usage', 'total_tokens'),
        model: payload[:model],
        duration: Time.now - start_time,
        usage: response.dig('usage')
      })

      response
    end
  end
end