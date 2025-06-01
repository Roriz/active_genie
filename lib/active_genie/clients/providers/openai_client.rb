# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_client'

module ActiveGenie
  module Clients
    class OpenaiClient < BaseClient
      class InvalidResponseError < StandardError; end

      # Requests structured JSON output from the OpenAI model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function)
        payload = {
          messages:,
          tools: [function_to_tool(function)],
          tool_choice: { type: 'function', function: { name: function[:name] } },
          stream: false,
          model:
        }

        retry_with_backoff do
          response = request(payload)

          raise InvalidResponseError, "Invalid response: #{response}" if response.nil? || response.keys.empty?

          ActiveGenie::Logger.call({ code: :function_calling, fine_tune: true, payload:, response: })

          response
        end
      end

      private

      def request(payload)
        response = post(url, payload, headers: headers)

        return nil if response.nil?

        ActiveGenie::Logger.call(
          {
            code: :llm_usage,
            input_tokens: response.dig('usage', 'prompt_tokens'),
            output_tokens: response.dig('usage', 'completion_tokens'),
            total_tokens: response.dig('usage', 'total_tokens'),
            model:,
            usage: response['usage']
          }
        )

        parsed_response = JSON.parse(response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments'))
        parsed_response['message'] || parsed_response
      end

      def function_to_tool(function)
        {
          type: 'function',
          function: {
            **function,
            parameters: {
              **function[:parameters],
              additionalProperties: false
            },
            strict: true
          }.compact
        }
      end

      def model
        @config.llm.model || provider_config.tier_to_model(@config.llm.model_tier)
      end

      def url
        "#{provider_config.api_url}/chat/completions"
      end

      def headers
        {
          Authorization: "Bearer #{provider_config.api_key}",
          'Content-Type': 'application/json'
        }.compact
      end

      def provider_config
        @config.providers.openai
      end
    end
  end
end
