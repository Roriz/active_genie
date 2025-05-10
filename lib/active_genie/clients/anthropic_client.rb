# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative './helpers/retry'
require_relative './base_client'

module ActiveGenie
  module Clients
    # Client for interacting with the Anthropic (Claude) API with json response
    class AnthropicClient < BaseClient
      class AnthropicError < ClientError; end
      class RateLimitError < AnthropicError; end

      ANTHROPIC_VERSION = '2023-06-01'
      ANTHROPIC_ENDPOINT = '/v1/messages'

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
        model = config.model || @app_config.tier_to_model(model_tier)

        system_message = messages.find { |m| m[:role] == 'system' }&.dig(:content) || ''
        user_messages = messages.select { |m| %w[user assistant].include?(m[:role]) }
                                .map { |m| { role: m[:role], content: m[:content] } }

        anthropic_function = function.dup
        anthropic_function[:input_schema] = function[:parameters]
        anthropic_function.delete(:parameters)

        payload = {
          model:,
          system: system_message,
          messages: user_messages,
          tools: [anthropic_function],
          tool_choice: { name: anthropic_function[:name], type: 'tool' },
          max_tokens: config.max_tokens,
          temperature: config.temperature || 0
        }

        api_key = config.api_key || @app_config.api_key
        headers = {
          'x-api-key': api_key,
          'anthropic-version': config.anthropic_version || ANTHROPIC_VERSION
        }.compact

        retry_with_backoff(config:) do
          start_time = Time.now

          response = post(ANTHROPIC_ENDPOINT, payload, headers: headers, config: config)

          content = response.dig('content', 0, 'input')

          ActiveGenie::Logger.trace({
                                      code: :llm_usage,
                                      input_tokens: response.dig('usage', 'input_tokens'),
                                      output_tokens: response.dig('usage', 'output_tokens'),
                                      total_tokens: response.dig('usage',
                                                                 'input_tokens') + response.dig('usage',
                                                                                                'output_tokens'),
                                      model: payload[:model],
                                      duration: Time.now - start_time,
                                      usage: response['usage']
                                    })

          ActiveGenie::Logger.trace({ code: :function_calling, payload:, parsed_response: content })

          content
        end
      end
    end
  end
end
