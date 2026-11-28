# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_provider'
require_relative 'usage_logger'
require_relative 'tool_arguments'

module ActiveGenie
  module Providers
    # Provider for interacting with OpenAI Chat Completions API.
    class OpenaiProvider < BaseProvider
      USAGE_KEYS = { input: 'prompt_tokens', output: 'completion_tokens', total: 'total_tokens' }.freeze

      # Reasoning models reject function tools on /v1/chat/completions unless
      # reasoning is switched off. The error names the offending parameter, so
      # detect it and retry with reasoning disabled rather than maintaining a
      # list of which models reason by default.
      REASONING_CONFLICT_HINT = 'reasoning_effort'

      # Requests structured JSON output from the OpenAI model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema.
      def function_calling(messages, function, **)
        payload = build_payload(messages, function)
        raw_response = request_allowing_reasoning_fallback(payload)

        raise InvalidResponseError, "Invalid response: #{raw_response}" if raw_response.nil? || raw_response.keys.empty?

        parsed_data = parse_arguments(raw_response, function)
        ActiveGenie.logger.call({ code: :function_calling, fine_tune: true, payload:, response: raw_response },
                                config: @config)

        parsed_data
      end

      private

      def build_payload(messages, function)
        {
          messages:,
          tools: [function_to_tool(function)],
          tool_choice: { type: 'function', function: { name: function[:name] } },
          stream: false,
          model:,
          temperature: @config.llm.temperature
        }
      end

      # Sends the request, and if the model refuses function tools while
      # reasoning is active, disables reasoning and sends it once more.
      # Mutates payload so the caller logs whichever variant succeeded.
      def request_allowing_reasoning_fallback(payload)
        retry_with_backoff { request(payload) }
      rescue ProviderUnknownError => e
        raise if payload.key?(:reasoning_effort) || !e.message.include?(REASONING_CONFLICT_HINT)

        payload[:reasoning_effort] = 'none'
        retry_with_backoff { request(payload) }
      end

      def request(payload)
        response = post(url, payload, headers:)

        return nil if response.nil?

        UsageLogger.call(response['usage'], keys: USAGE_KEYS, model:, config: @config)

        response
      end

      # The answer is JSON in `content` or in the first tool call's arguments.
      # Anything else is an error, not an empty extraction.
      def parse_arguments(response, function)
        choice = response.dig('choices', 0) || {}
        message = choice['message'] || {}
        raise_if_unusable(choice, message)

        arguments = message.dig('tool_calls', 0, 'function', 'arguments')
        parsed = json_object(message['content']) || json_object(arguments)
        return ToolArguments.unwrap(parsed, function) if parsed

        detail = arguments.to_s.empty? ? 'no tool call' : "tool arguments that are not a JSON object: #{arguments[0, 200]}"
        raise InvalidResponseError, "OpenAI returned #{detail} (finish_reason: #{choice['finish_reason'].inspect})."
      end

      def raise_if_unusable(choice, message)
        refusal = message['refusal']
        raise RefusalError, "OpenAI declined the request: #{refusal}" unless refusal.to_s.empty?
        raise RefusalError, 'OpenAI content filter blocked the answer.' if choice['finish_reason'] == 'content_filter'
        return unless choice['finish_reason'] == 'length'

        raise InvalidResponseError, 'Answer cut off at the token limit (finish_reason: length).'
      end

      def json_object(text)
        return nil if text.to_s.empty?

        parsed = JSON.parse(text)
        parsed if parsed.is_a?(Hash)
      rescue JSON::ParserError
        nil
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
        @config.providers.openai
      end
    end
  end
end
