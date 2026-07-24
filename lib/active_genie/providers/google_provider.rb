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
      # @param logprobs [Boolean] Whether to request and return token log probabilities.
      # @param top_logprobs [Integer] Number of top candidate log probabilities per token step.
      # @return [Hash, nil] The parsed JSON object, or { data: Hash, logprobs: Hash } if logprobs requested.
      def function_calling(messages, function, logprobs: false, top_logprobs: 5)
        contents = convert_messages_to_contents(messages, function)
        contents << output_as_json_schema(function)

        generation_config = {
          response_mime_type: 'application/json',
          temperature: 0.1
        }
        if logprobs
          generation_config[:responseLogprobs] = true
          generation_config[:logprobs] = top_logprobs
        end

        payload = { contents:, generationConfig: generation_config }
        params = { key: provider_config.api_key }

        response = execute_function_calling_request(payload, params, generation_config, logprobs)
        return nil if response.nil?

        json_string = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
        return nil if json_string.nil? || json_string.empty?

        ActiveGenie.logger.call(
          { code: :function_calling, fine_tune: true, payload:, parsed_response: json_string },
          config: @config
        )

        parsed_data = normalize_response(json_string)
        return parsed_data unless logprobs

        logprobs_data = response&.dig('candidates', 0, 'logprobsResult')
        { data: parsed_data, logprobs: logprobs_data }
      end

      # Extracts field candidates from logprobsResult.
      def extract_field_logprobs(logprobs_result, field_name, token_map: nil)
        ActiveGenie::Utils::LogprobsCalculator.extract_field_candidates(logprobs_result, field_name, token_map:)
      end

      # Computes expected value and normalized score from candidate logprobs.
      def calculate_continuous_score(candidates, min_score: nil, max_score: nil, token_map: nil)
        ActiveGenie::Utils::LogprobsCalculator.calculate_continuous_score(
          candidates, min_score:, max_score:, token_map:
        )
      end

      # Aggregates raw expected rewards across multiple evaluation criteria (C) and repetitions (K).
      def aggregate_expected_rewards(expected_rewards, min_score: 1.0, max_score: 5.0)
        ActiveGenie::Utils::LogprobsCalculator.aggregate_expected_rewards(
          expected_rewards, min_score:, max_score:
        )
      end

      API_VERSION_PATH = 'v1beta/models'
      ROLE_TO_GOOGLE_ROLE = {
        user: 'user',
        assistant: 'model'
      }.freeze

      private

      def execute_function_calling_request(payload, params, generation_config, logprobs_requested)
        retry_with_backoff do
          request(payload, params)
        end
      rescue ActiveGenie::Providers::BaseProvider::ProviderUnknownError => e
        raise unless logprobs_requested && e.message.include?('Logprobs is not enabled')

        generation_config.delete(:responseLogprobs)
        generation_config.delete(:logprobs)
        retry_with_backoff do
          request(payload, params)
        end
      end

      def request(payload, params)
        response = post(url, payload, headers: DEFAULT_HEADERS, params:)

        ActiveGenie.logger.call(
          {
            code: :llm_usage,
            input_tokens: response['usageMetadata']['promptTokenCount'] || 0,
            output_tokens: response['usageMetadata']['candidatesTokenCount'] || 0,
            total_tokens: response['usageMetadata']['totalTokenCount'] || (prompt_tokens + candidates_tokens),
            model:,
            usage: response['usageMetadata'] || {}
          },
          config: @config
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

      def provider_config
        @config.providers.google
      end
    end
  end
end
