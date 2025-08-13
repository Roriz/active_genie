# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'base_provider'

module ActiveGenie
  module Providers
    # Provider for interacting with the Google Generative Language API.
    class GoogleProvider < BaseProvider
      # Requests structured JSON output from the Google Generative Language model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user' or 'model') and :content (String).
      #   Google Generative Language uses 'user' and 'model' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function)
        contents = convert_messages_to_contents(messages, function)
        contents << output_as_json_schema(function)

        payload = {
          contents:,
          generationConfig: {
            response_mime_type: 'application/json',
            temperature: 0.1
          }
        }
        params = { key: provider_config.api_key }

        response = request(payload, params)

        json_string = response&.dig('candidates', 0, 'content', 'parts', 0, 'text')
        return nil if json_string.nil? || json_string.empty?

        @config.logger.call({ code: :function_calling, fine_tune: true, payload:, parsed_response: json_string })

        normalize_response(json_string)
      end

      API_VERSION_PATH = 'v1beta/models'
      ROLE_TO_GOOGLE_ROLE = {
        user: 'user',
        assistant: 'model'
      }.freeze

      private

      def request(payload, params)
        response = post(url, payload, headers: DEFAULT_HEADERS, params:)

        @config.logger.call(
          {
            code: :llm_usage,
            input_tokens: response['usageMetadata']['promptTokenCount'] || 0,
            output_tokens: response['usageMetadata']['candidatesTokenCount'] || 0,
            total_tokens: response['usageMetadata']['totalTokenCount'] || (prompt_tokens + candidates_tokens),
            model:,
            usage: response['usageMetadata'] || {}
          }
        )

        response
      end

      def normalize_response(json_string)
        parsed_response = JSON.parse(json_string)

        output = if parsed_response.is_a?(Array)
                   parsed_response.dig(0, 'properties') || parsed_response[0]
                 else
                   parsed_response
                 end

        output.dig('input_schema', 'properties') || output
      end

      # Converts standard message format to Google's 'contents' format
      # and injects JSON schema instructions.
      # @param messages [Array<Hash>] Array of { role: 'user'/'assistant'/'system', content: '...' }
      # @param function_schema [Hash] The JSON schema for the desired output.
      # @return [Array<Hash>] Array formatted for Google's 'contents' field.
      def convert_messages_to_contents(messages, _function_schema)
        messages.map do |message|
          {
            role: ROLE_TO_GOOGLE_ROLE[message[:role].to_sym] || 'user',
            parts: [{ text: message[:content] }]
          }
        end
      end

      def output_as_json_schema(function_schema)
        json_instruction = <<~PROMPT
          Generate a JSON object that strictly adheres to the following JSON schema:

          ```json
          #{JSON.pretty_generate(function_schema[:parameters])}
          ```

          IMPORTANT: Only output the raw JSON object. Do not include any other text, explanations, or markdown formatting like ```json ... ``` wrappers around the final output.
        PROMPT

        {
          role: 'user',
          parts: [{ text: json_instruction }]
        }
      end

      def model
        @config.llm.model || provider_config.tier_to_model(@config.llm.model_tier)
      end

      def url
        "#{provider_config.api_url}/#{API_VERSION_PATH}/#{model}:generateContent"
      end

      def provider_config
        @config.providers.google
      end
    end
  end
end
