require 'json'
require 'net/http'
require 'uri'
require_relative './helpers/retry'

module ActiveGenie
  module Clients
    # Client for interacting with the Anthropic (Claude) API with json response
    class AnthropicClient
      class AnthropicError < StandardError; end
      class RateLimitError < AnthropicError; end

      def initialize(config)
        @app_config = config
      end

      # Requests structured JSON output from the Anthropic Claude model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      #   Claude uses 'user', 'assistant', and 'system' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @param model_tier [Symbol, nil] A symbolic representation of the model quality/size tier.
      # @param config [Hash] Optional configuration overrides:
      #   - :api_key [String] Override the default API key.
      #   - :model [String] Override the model name directly.
      #   - :max_retries [Integer] Max retries for the request.
      #   - :retry_delay [Integer] Initial delay for retries.
      #   - :anthropic_version [String] Override the default Anthropic API version.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function, model_tier: nil, config: {})
        model = config[:runtime][:model] || @app_config.tier_to_model(model_tier)

        system_message = messages.find { |m| m[:role] == 'system' }&.dig(:content) || ''
        user_messages = messages.select { |m| m[:role] == 'user' || m[:role] == 'assistant' }
          .map { |m| { role: m[:role], content: m[:content] } }

        anthropic_function = function
        anthropic_function[:input_schema] = function[:parameters]
        anthropic_function.delete(:parameters)

        payload = {
          model:,
          system: system_message,
          messages: user_messages,
          tools: [anthropic_function],
          tool_choice: { name: anthropic_function[:name], type: 'tool' },
          max_tokens: config[:runtime][:max_tokens],
          temperature: config[:runtime][:temperature] || 0,
        }

        api_key = config[:runtime][:api_key] || @app_config.api_key
        headers = DEFAULT_HEADERS.merge(
          'x-api-key': api_key,
          'anthropic-version': config[:anthropic_version] || ANTHROPIC_VERSION
        ).compact

        retry_with_backoff(config:) do
          response = request(payload, headers, config:)
          content = response.dig('content', 0, 'input')

          ActiveGenie::Logger.trace({code: :function_calling, payload:, parsed_response: content})
        
          content
        end
      end

      private

      DEFAULT_HEADERS = {
        'Content-Type': 'application/json',
      }
      ANTHROPIC_VERSION = '2023-06-01'

      def request(payload, headers, config:)
        start_time = Time.now

        retry_with_backoff(config:) do
          response = Net::HTTP.post(
            URI("#{@app_config.api_url}/v1/messages"),
            payload.to_json,
            headers
          )

          if response.is_a?(Net::HTTPTooManyRequests)
            raise RateLimitError, "Anthropic API rate limit exceeded: #{response.body}"
          end

          raise AnthropicError, response.body unless response.is_a?(Net::HTTPSuccess)

          return nil if response.body.empty?

          parsed_body = JSON.parse(response.body)

          ActiveGenie::Logger.trace({
            code: :llm_usage,
            input_tokens: parsed_body.dig('usage', 'input_tokens'),
            output_tokens: parsed_body.dig('usage', 'output_tokens'),
            total_tokens: parsed_body.dig('usage', 'input_tokens') + parsed_body.dig('usage', 'output_tokens'),
            model: payload[:model],
            duration: Time.now - start_time,
            usage: parsed_body.dig('usage')
          })

          parsed_body
        end
      end
    end
  end
end