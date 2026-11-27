# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'base_provider'
require_relative 'usage_logger'
require_relative 'tool_arguments'
require_relative '../utils/logprobs_calculator'

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
      # @param logprobs [Boolean] Whether to request and return token log probabilities.
      # @param top_logprobs [Integer] Number of top candidate log probabilities per token step.
      # @return [Hash, nil] The parsed JSON object matching the schema, or { data: Hash, logprobs: Hash } if logprobs requested.
      def function_calling(messages, function, logprobs: false, top_logprobs: 5)
        payload = build_payload(messages, function, logprobs ? { logprobs: true, top_logprobs: } : {})
        raw_response = request_allowing_reasoning_fallback(payload)

        raise InvalidResponseError, "Invalid response: #{raw_response}" if raw_response.nil? || raw_response.keys.empty?

        parsed_data = parse_arguments(raw_response, function)
        ActiveGenie.logger.call({ code: :function_calling, fine_tune: true, payload:, response: raw_response },
                                config: @config)

        return parsed_data unless logprobs

        { data: parsed_data, logprobs: normalize_openai_logprobs(raw_response.dig('choices', 0, 'logprobs')) }
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

      def build_payload(messages, function, logprobs_options)
        {
          messages:,
          tools: [function_to_tool(function)],
          tool_choice: { type: 'function', function: { name: function[:name] } },
          stream: false,
          model:,
          temperature: @config.llm.temperature,
          **logprobs_options
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

      # Reshapes OpenAI's per-token logprobs into Gemini's logprobsResult,
      # the shape LogprobsCalculator reads.
      def normalize_openai_logprobs(openai_logprobs)
        content_steps = openai_logprobs && value_at(openai_logprobs, 'content')
        return nil if content_steps.nil? || content_steps.empty?

        {
          'chosenCandidates' => content_steps.map { |step| logprob_candidate(step) },
          'topCandidates' => content_steps.map do |step|
            { 'candidates' => Array(value_at(step, 'top_logprobs')).map { |c| logprob_candidate(c) } }
          end
        }
      end

      def logprob_candidate(entry)
        { 'token' => value_at(entry, 'token'), 'logProbability' => value_at(entry, 'logprob') || 0.0 }
      end

      def value_at(hash, key)
        hash[key] || hash[key.to_sym]
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
