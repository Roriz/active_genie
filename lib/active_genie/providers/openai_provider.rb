# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_provider'
require_relative '../utils/logprobs_calculator'

module ActiveGenie
  module Providers
    # Provider for interacting with OpenAI Chat Completions API.
    class OpenaiProvider < BaseProvider
      class InvalidResponseError < StandardError; end

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
      # @param logprobs [Boolean] Whether to request and return token log probabilities.
      # @param top_logprobs [Integer] Number of top candidate log probabilities per token step.
      # @return [Hash, nil] The parsed JSON object matching the schema, or { data: Hash, logprobs: Hash } if logprobs requested.
      def function_calling(messages, function, logprobs: false, top_logprobs: 5)
        payload = {
          messages:,
          tools: [function_to_tool(function)],
          tool_choice: { type: 'function', function: { name: function[:name] } },
          stream: false,
          model:,
          temperature: @config.llm.temperature
        }
        if logprobs
          payload[:logprobs] = true
          payload[:top_logprobs] = top_logprobs
        end

        raw_response = request_allowing_reasoning_fallback(payload)

        raise InvalidResponseError, "Invalid response: #{raw_response}" if raw_response.nil? || raw_response.keys.empty?

        parsed_data = parse_arguments(raw_response)
        ActiveGenie.logger.call({ code: :function_calling, fine_tune: true, payload:, response: raw_response }, config: @config)

        return parsed_data unless logprobs

        logprobs_data = normalize_openai_logprobs(raw_response.dig('choices', 0, 'logprobs'))
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

      private

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

        response
      end

      def parse_arguments(response)
        content_str = response.dig('choices', 0, 'message', 'content')
        if content_str && !content_str.empty?
          parsed = JSON.parse(content_str) rescue nil
          return parsed['message'] || parsed if parsed.is_a?(Hash)
        end

        json_args = response.dig('choices', 0, 'message', 'tool_calls', 0, 'function', 'arguments')
        return {} if json_args.nil? || json_args.empty?

        parsed_response = JSON.parse(json_args) rescue {}
        parsed_response['message'] || parsed_response
      end

      def normalize_openai_logprobs(openai_logprobs)
        return nil if openai_logprobs.nil?

        content_steps = openai_logprobs['content'] || openai_logprobs[:content] || []
        return nil if content_steps.empty?

        chosen_candidates = content_steps.map do |step|
          {
            'token' => step['token'] || step[:token],
            'logProbability' => step['logprob'] || step[:logprob] || 0.0
          }
        end

        top_candidates = content_steps.map do |step|
          top_probs = step['top_logprobs'] || step[:top_logprobs] || []
          candidates = top_probs.map do |c|
            {
              'token' => c['token'] || c[:token],
              'logProbability' => c['logprob'] || c[:logprob] || 0.0
            }
          end
          { 'candidates' => candidates }
        end

        {
          'chosenCandidates' => chosen_candidates,
          'topCandidates' => top_candidates
        }
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
