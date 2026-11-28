# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'base_provider'
require_relative 'usage_logger'

module ActiveGenie
  module Providers
    # Provider for interacting with the Google Generative Language API.
    class GoogleProvider < BaseProvider
      USAGE_KEYS = { input: 'promptTokenCount', output: 'candidatesTokenCount', total: 'totalTokenCount' }.freeze

      # Requests structured JSON output from the Google Generative Language model based on a schema.
      #
      # @param messages [Array<Hash>] A list of messages representing the conversation history.
      #   Each hash should have :role ('user' or 'model') and :content (String).
      #   Google Generative Language uses 'user' and 'model' roles.
      # @param function [Hash] A JSON schema definition describing the desired output format.
      # @return [Hash] The parsed JSON object.
      # @raise [RefusalError] when Gemini blocks the prompt or the answer.
      # @raise [InvalidResponseError] when the answer is missing, cut off, or not a JSON object.
      def function_calling(messages, function, **)
        contents = convert_messages_to_contents(messages, function) << output_as_json_schema(function)
        payload = { contents:, generationConfig: { response_mime_type: 'application/json', temperature: 0.1 } }

        response = retry_with_backoff { request(payload) }
        json_string = answer_text(response)

        ActiveGenie.logger.call(
          { code: :function_calling, fine_tune: true, payload:, parsed_response: json_string },
          config: @config
        )

        normalize_response(json_string)
      end

      API_VERSION_PATH = 'v1beta/models'
      # finishReason values that mean Gemini blocked the answer.
      BLOCKED_FINISH_REASONS = %w[SAFETY RECITATION BLOCKLIST PROHIBITED_CONTENT SPII IMAGE_SAFETY].freeze
      ROLE_TO_GOOGLE_ROLE = {
        user: 'user',
        assistant: 'model'
      }.freeze

      private

      # The API key travels in a header, never the query string, so it cannot
      # leak through logged URLs, proxies, or error messages.
      def request(payload)
        response = post(url, payload, headers:)

        UsageLogger.call(response['usageMetadata'], keys: USAGE_KEYS, model:, config: @config)

        response
      end

      def answer_text(response)
        candidate = response&.dig('candidates', 0) || {}
        raise_if_unusable(response, candidate['finishReason'])

        text = candidate.dig('content', 'parts', 0, 'text')
        return text unless text.nil? || text.empty?

        raise InvalidResponseError, "Google returned no answer text (finishReason: #{candidate['finishReason'].inspect})."
      end

      # Gemini reports blocks and truncation in the body of a 200 response
      # (promptFeedback, finishReason), so check them before reading the text.
      def raise_if_unusable(response, finish_reason)
        block_reason = response&.dig('promptFeedback', 'blockReason')
        raise RefusalError, "Google blocked the prompt (blockReason: #{block_reason})." if block_reason

        if BLOCKED_FINISH_REASONS.include?(finish_reason)
          raise RefusalError, "Google blocked the answer (finishReason: #{finish_reason})."
        end
        raise InvalidResponseError, 'Answer cut off (finishReason: MAX_TOKENS).' if finish_reason == 'MAX_TOKENS'
      end

      def normalize_response(json_string)
        output = unwrap_array(parse_json(json_string))
        raise InvalidResponseError, "Google answer is not a JSON object: #{json_string[0, 200]}" unless output.is_a?(Hash)

        output.dig('input_schema', 'properties') || output
      end

      def parse_json(json_string)
        JSON.parse(json_string)
      rescue JSON::ParserError
        raise InvalidResponseError, "Google answer is not valid JSON: #{json_string[0, 200]}"
      end

      # Gemini sometimes wraps the object in an array, or answers with the schema shape itself.
      def unwrap_array(parsed_response)
        return parsed_response unless parsed_response.is_a?(Array)

        parsed_response.dig(0, 'properties') || parsed_response[0]
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

          <json_schema>
          #{JSON.pretty_generate(function_schema[:parameters])}
          </json_schema>

          IMPORTANT: Only output the raw JSON object. Do not include any other text, explanations, or markdown formatting like ```json ... ``` wrappers around the final output.
        PROMPT

        {
          role: 'user',
          parts: [{ text: json_instruction }]
        }
      end

      def model
        @config.llm.model
      end

      def url
        "#{provider_config.api_url}/#{API_VERSION_PATH}/#{model}:generateContent"
      end

      def headers
        { 'x-goog-api-key': provider_config.api_key }.compact
      end

      def provider_config
        @config.providers.google
      end
    end
  end
end
