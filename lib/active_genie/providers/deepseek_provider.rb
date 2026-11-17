# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_provider'
require_relative 'usage_logger'

module ActiveGenie
  module Providers
    class DeepseekProvider < BaseProvider
      USAGE_KEYS = { input: 'prompt_tokens', output: 'completion_tokens', total: 'total_tokens' }.freeze

      class InvalidResponseError < StandardError; end

      # Thinking-mode models reject a forced tool_choice. The error text names
      # the offending parameter, so detect it and fall back to 'auto'.
      TOOL_CHOICE_CONFLICT_HINT = 'does not support this tool_choice'

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

        response = request_allowing_tool_choice_fallback(payload)

        raise InvalidResponseError, "Invalid response: #{response}" if response.nil? || response.empty?

        ActiveGenie.logger.call({ code: :function_calling, fine_tune: true, payload:, response: }, config: @config)

        response
      end

      private

      # Sends the request, and if the model rejects a forced tool_choice,
      # falls back to letting it choose. Reasoning models refuse the forced
      # form, so detect the error rather than tracking which models reason.
      # Mutates payload so the caller logs whichever variant succeeded.
      def request_allowing_tool_choice_fallback(payload)
        retry_with_backoff { request(payload) }
      rescue ProviderUnknownError => e
        raise if payload[:tool_choice] == 'auto' || !e.message.include?(TOOL_CHOICE_CONFLICT_HINT)

        payload[:tool_choice] = 'auto'
        retry_with_backoff { request(payload) }
      end

      def request(payload)
        response = post(url, payload, headers: headers)

        return nil if response.nil?

        UsageLogger.call(response['usage'], keys: USAGE_KEYS, model:, config: @config)

        body_str = get_response_body(response)
        parsed_response = parse_json_safely(body_str)
        parsed_response['message'] || parsed_response
      end

      # Parses tool arguments, repairing unquoted string values once. A second
      # `rescue` clause would never see errors raised inside the first one, so
      # the repaired parse gets its own.
      def parse_json_safely(body_str)
        JSON.parse(body_str)
      rescue JSON::ParserError
        begin
          JSON.parse(quote_bare_values(body_str))
        rescue JSON::ParserError
          raise InvalidResponseError, "Invalid response: #{body_str}"
        end
      end

      def quote_bare_values(body_str)
        body_str.gsub(/"(\w+)":\s*([A-Za-z][^,}\n]+)/) do
          key = Regexp.last_match(1)
          val = Regexp.last_match(2).strip
          val_quoted = val.start_with?('"') ? val : "\"#{val.gsub('"', '\"')}\""
          "\"#{key}\": #{val_quoted}"
        end
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
