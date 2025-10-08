# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'base_provider'

module ActiveGenie
  module Providers
    # Provider for interacting with the Anthropic (Claude) API with json response
    class AnthropicProvider < BaseProvider
      # Requests structured JSON output from the Anthropic Claude model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      #   Claude uses 'user', 'assistant', and 'system' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function)
        system_message, user_messages = split_messages(messages)
        tool = function_to_tool(function)

        payload = {
          model:,
          system: system_message,
          messages: user_messages,
          tools: [tool],
          tool_choice: { name: tool[:name], type: 'tool' },
          max_tokens: @config.llm.max_tokens,
          temperature: @config.llm.temperature || 0
        }

        request(payload).dig('content', 0, 'input')
      end

      ANTHROPIC_ENDPOINT = '/v1/messages'

      private

      def split_messages(messages)
        system_message = messages.find { |m| m[:role] == 'system' }&.dig(:content) || ''
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

        ActiveGenie.logger.call(
          {
            code: :llm_usage,
            input_tokens: response.dig('usage', 'input_tokens'),
            output_tokens: response.dig('usage', 'output_tokens'),
            total_tokens: response.dig('usage',
                                       'input_tokens') + response.dig('usage',
                                                                      'output_tokens'),
            model: payload[:model],
            usage: response['usage']
          },
          config: @config
        )
        ActiveGenie.logger.call(
          {
            code: :function_calling,
            fine_tune: true,
            payload:,
            parsed_response: response.dig('content', 0, 'input')
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

      def headers
        {
          'x-api-key': @config.providers.anthropic.api_key,
          'anthropic-version': @config.providers.anthropic.anthropic_version
        }.compact
      end
    end
  end
end
