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
      def function_calling(messages, function, **_options)
        payload = {
          messages:,
          tools: [function_to_tool(function)],
          tool_choice: { type: 'function', function: { name: function[:name] } },
          stream: false,
          model:,
          temperature: @config.llm.temperature
        }

        response = retry_with_backoff do
          request(payload)
        end

        raise InvalidResponseError, "Invalid response: #{response}" if response.nil? || response.empty?

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

        body_str = get_response_body(response)
        parsed_response = parse_json_safely(body_str)
        parsed_response['message'] || parsed_response
      end

      def parse_json_safely(body_str)
        JSON.parse(body_str)
      rescue JSON::ParserError
        repaired = body_str.gsub(/"(\w+)":\s*([A-Za-z][^,\}\n]+)/) do
          key = Regexp.last_match(1)
          val = Regexp.last_match(2).strip
          val_quoted = val.start_with?('"') ? val : "\"#{val.gsub('"', '\"')}\""
          "\"#{key}\": #{val_quoted}"
        end
        JSON.parse(repaired)
      rescue JSON::ParserError
        raise InvalidResponseError, "Invalid response: #{body_str}"
      end

      def get_response_body(response)
        body = response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments')
        return '' if body.nil?

        body.strip
      end

      def function_to_tool(function)
        {
          type: 'function',
          function: function
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
