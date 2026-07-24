# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/openai_provider'

module ActiveGenie
  module Providers
    class OpenaiProviderTest < Minitest::Test
      EXAMPLE_FUNCTION = {
        name: 'score_function',
        description: 'Score content',
        parameters: {
          type: 'object',
          properties: {
            score: { type: 'integer' }
          }
        }
      }.freeze
      EXAMPLE_MESSAGES = [{ role: 'user', content: 'Score this essay' }].freeze

      def setup
        @config = Configuration.new({
                                      llm: { model: 'gpt-5.6-luna' },
                                      providers: { openai: { api_key: 'test_key' } }
                                    })
        @provider = OpenaiProvider.new(@config)
      end

      def test_function_calling_without_logprobs
        mock_response = {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'function' => {
                      'arguments' => '{"score": 8}'
                    }
                  }
                ]
              }
            }
          ]
        }

        @provider.stub(:request, mock_response) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION)
          assert_equal({ 'score' => 8 }, result)
        end
      end

      def test_function_calling_with_logprobs
        mock_response = {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'function' => {
                      'arguments' => '{"score": 8}'
                    }
                  }
                ]
              },
              'logprobs' => {
                'content' => [
                  { 'token' => 'score', 'logprob' => -0.1, 'top_logprobs' => [{ 'token' => 'score', 'logprob' => -0.1 }] },
                  {
                    'token' => '8',
                    'logprob' => -0.22314,
                    'top_logprobs' => [
                      { 'token' => '8', 'logprob' => -0.22314 },
                      { 'token' => '7', 'logprob' => -1.60943 }
                    ]
                  }
                ]
              }
            }
          ]
        }

        captured_payload = nil
        @provider.stub(:request, lambda { |payload|
          captured_payload = payload
          mock_response
        }) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true, top_logprobs: 10)

          assert_equal true, captured_payload[:logprobs]
          assert_equal 10, captured_payload[:top_logprobs]
          assert_equal({ 'score' => 8 }, result[:data])
          refute_nil result[:logprobs]

          candidates = @provider.extract_field_logprobs(result[:logprobs], 'score')
          refute_nil candidates

          score_res = @provider.calculate_continuous_score(candidates, min_score: 1.0, max_score: 10.0)
          refute_nil score_res
          assert_in_delta 7.8, score_res.expected_value, 0.1
        end
      end
    end
  end
end
