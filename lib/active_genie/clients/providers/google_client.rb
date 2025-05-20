# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative './base_client'

module ActiveGenie
  module Clients
    # Client for interacting with the Google Generative Language API.
    class GoogleClient < BaseClient
      class RateLimitError < GoogleError; end

      API_VERSION_PATH = '/v1beta/models'

      # Requests structured JSON output from the Google Generative Language model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user' or 'model') and :content (String).
      #   Google Generative Language uses 'user' and 'model' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash, nil] The parsed JSON object matching the schema, or nil if parsing fails or content is empty.
      def function_calling(messages, function)
        model = @config.llm.model || provider_config.tier_to_model(@config.llm.model_tier)

        contents = convert_messages_to_contents(messages, function)
        contents << output_as_json_schema(function)

        payload = {
          contents: contents,
          generationConfig: {
            response_mime_type: 'application/json',
            temperature: 0.1
          }
        }

        endpoint = "#{API_VERSION_PATH}/#{model}:generateContent"
        params = { key: provider_config.api_key }
        headers = DEFAULT_HEADERS

        retry_with_backoff do
          start_time = Time.now
          url = "#{provider_config.api_url}#{endpoint}"

          response = post(url, payload, headers:, params:)

          json_string = response&.dig('candidates', 0, 'content', 'parts', 0, 'text')
          return nil if json_string.nil? || json_string.empty?

          parsed_response = JSON.parse(json_string)

          # Log usage metrics
          usage_metadata = response['usageMetadata'] || {}
          prompt_tokens = usage_metadata['promptTokenCount'] || 0
          candidates_tokens = usage_metadata['candidatesTokenCount'] || 0
          total_tokens = usage_metadata['totalTokenCount'] || (prompt_tokens + candidates_tokens)

          ActiveGenie::Logger.call({
                                     code: :llm_usage,
                                     input_tokens: prompt_tokens,
                                     output_tokens: candidates_tokens,
                                     total_tokens: total_tokens,
                                     model: model,
                                     duration: Time.now - start_time,
                                     usage: usage_metadata
                                   })

          ActiveGenie::Logger.call({ code: :function_calling, fine_tune: true, payload:, parsed_response: })

          normalize_function_output(parsed_response)
        end
      end

      def provider_config
        @config.providers.google
      end

      private

      def normalize_function_output(output)
        output = if output.is_a?(Array)
                   output.dig(0, 'properties') || output[0]
                 else
                   output
                 end

        output.dig('input_schema', 'properties') || output
      end

      ROLE_TO_GOOGLE_ROLE = {
        user: 'user',
        assistant: 'model'
      }.freeze

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
    end
  end
end
