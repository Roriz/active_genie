# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_provider'

module ActiveGenie
  module Providers
    class DeepseekProvider < BaseProvider
      class InvalidResponseError < StandardError; end

      # Requests structured JSON output from the Deepseek model based on a schema.
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

        response = retry_with_backoff do
          request(payload)
        end

        raise InvalidResponseError, "Invalid response: #{response}" if response.keys.empty?
        raise InvalidResponseError, 'Invalid response: empty' if response.nil?

        ActiveGenie.logger.call({ code: :function_calling, fine_tune: true, payload:, response: }, config: @config)

        response
      end

      private

      def request(payload)
        response = post(url, payload, headers: headers)

        return nil if response.nil?

        ActiveGenie.logger.call(
          {
            code: :llm_usage,
            input_tokens: response.dig('usage', 'prompt_tokens'),
            output_tokens: response.dig('usage', 'completion_tokens'),
            total_tokens: response.dig('usage', 'total_tokens'),
            model:,
            usage: response['usage']
          }, config: @config
        )

        parsed_response = JSON.parse(get_response_body(response))
        parsed_response['message'] || parsed_response
      rescue JSON::ParserError
        raise InvalidResponseError, "Invalid response: #{get_response_body(response)}"
      end

      def get_response_body(response)
        response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments')
                .gsub(', " "', '')
                .strip
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
        @config.llm.model
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
        @config.providers.deepseek
      end
    end
  end
end
