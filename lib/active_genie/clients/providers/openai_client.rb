# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative './base_client'

module ActiveGenie
  module Clients
    class OpenaiClient < BaseClient
      class OpenaiError < ClientError; end
      class RateLimitError < OpenaiError; end
      class InvalidResponseError < StandardError; end

      # Requests structured JSON output from the OpenAI model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user', 'assistant', or 'system') and :content (String).
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function)
        model = @config.llm.model || provider_config.tier_to_model(@config.llm.model_tier)

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
          model:
        }

        headers = {
          'Authorization': "Bearer #{provider_config.api_key}"
        }.compact

        retry_with_backoff do
          response = request_openai(payload, headers)

          parsed_response = JSON.parse(response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments'))
          parsed_response = parsed_response['message'] || parsed_response

          if parsed_response.nil? || parsed_response.keys.empty?
            raise InvalidResponseError,
                  "Invalid response: #{parsed_response}"
          end

          ActiveGenie::Logger.call({ code: :function_calling, payload:, parsed_response: })

          parsed_response
        end
      end

      def provider_config
        @config.providers.openai
      end

      private

      # Make a request to the OpenAI API
      #
      # @param payload [Hash] The request payload
      # @param headers [Hash] Additional headers
      # @return [Hash] The parsed response
      def request_openai(payload, headers)
        start_time = Time.now
        url = "#{provider_config.api_url}/chat/completions"

        response = post(url, payload, headers: headers)

        return nil if response.nil?

        ActiveGenie::Logger.call({
                                   code: :llm_usage,
                                   input_tokens: response.dig('usage', 'prompt_tokens'),
                                   output_tokens: response.dig('usage', 'completion_tokens'),
                                   total_tokens: response.dig('usage', 'total_tokens'),
                                   model: payload[:model],
                                   duration: Time.now - start_time,
                                   usage: response['usage']
                                 })

        response
      end
    end
  end
end
