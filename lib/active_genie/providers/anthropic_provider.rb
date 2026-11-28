# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'base_provider'
require_relative 'usage_logger'

module ActiveGenie
  module Providers
    # Provider for interacting with the Anthropic (Claude) API with json response
    class AnthropicProvider < BaseProvider
      LABEL = 'Anthropic'
      USAGE_KEYS = { input: 'input_tokens', output: 'output_tokens' }.freeze

      # Requests structured JSON output from the Anthropic Claude model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      #   Claude uses 'user', 'assistant', and 'system' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function, **_options)
        system_message, user_messages = split_messages(messages)
        tool = function_to_tool(function)

        # No temperature: Claude 4.7+ models (claude-haiku-5-5 included) reject
        # any non-default sampling value with a 400. The forced tool call is what
        # keeps the output structured.
        payload = {
          model:,
          system: system_message,
          messages: user_messages,
          tools: [tool],
          tool_choice: { name: tool[:name], type: 'tool' },
          max_tokens: @config.llm.max_tokens
        }

        response = retry_with_backoff do
          request(payload)
        end

        tool_input(response)
      end

      ANTHROPIC_ENDPOINT = '/v1/messages'

      private

      # Anthropic takes a single top-level system prompt, so every system message
      # is joined in order rather than keeping only the first.
      def split_messages(messages)
        system_message = messages.select { |m| m[:role] == 'system' }.map { |m| m[:content] }.join("\n\n")
        user_messages = messages.select { |m| %w[user assistant].include?(m[:role]) }
                                .map { |m| m.slice(:role, :content) }

        [system_message, user_messages]
      end

      def function_to_tool(function)
        function.dup.tap do |f|
          f[:input_schema] = function[:parameters]
          f.delete(:parameters)
        end
      end

      def request(payload)
        response = post(url, payload, headers:)

        UsageLogger.call(response['usage'], keys: USAGE_KEYS, model:, config: @config)
        ActiveGenie.logger.call(
          {
            code: :function_calling,
            fine_tune: true,
            payload:,
            parsed_response: tool_use_block(response)&.dig('input')
          },
          config: @config
        )

        response
      end

      def url
        "#{@config.providers.anthropic.api_url}#{ANTHROPIC_ENDPOINT}"
      end

      def model
        @config.llm.model
      end

      # Current models may put thinking blocks before the tool call, so find the
      # tool_use block by type. A refusal or a cut-off answer has no usable input.
      def tool_input(response)
        stop_reason = response['stop_reason']
        raise provider_error(RefusalError, detail: refusal_detail(response)) if stop_reason == 'refusal'
        if stop_reason == 'max_tokens'
          raise provider_error(TruncatedResponseError, detail: 'stop_reason: max_tokens',
                                                       max_tokens: @config.llm.max_tokens)
        end

        tool_use_block(response)&.dig('input') ||
          raise(provider_error(InvalidResponseError, detail: "no tool_use block (stop_reason: #{stop_reason.inspect})"))
      end

      def refusal_detail(response)
        details = response['stop_details'] || {}
        "stop_reason refusal, category #{details['category'].inspect}. #{details['explanation']}".strip
      end

      def tool_use_block(response)
        Array(response['content']).find { |block| block['type'] == 'tool_use' }
      end

      def headers
        {
          'x-api-key': @config.providers.anthropic.api_key,
          'anthropic-version': @config.providers.anthropic.anthropic_version
        }.compact
      end
    end
  end
end
