# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/providers/google_provider'

module ActiveGenie
  module Providers
    class GoogleProviderTest < Minitest::Test
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
                                      llm: { model: 'gemini-2.5-flash' },
                                      providers: { google: { api_key: 'test_key' } }
                                    })
        @provider = GoogleProvider.new(@config)
      end

      def test_function_calling_without_logprobs
        mock_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [{ 'text' => '{"score": 8}' }]
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
        mock_logprobs = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '8' }],
          'topCandidates' => [
            { 'candidates' => [{ 'token' => 'score' }] },
            { 'candidates' => [{ 'token' => '8', 'logProbability' => -0.2 }] }
          ]
        }
        mock_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [{ 'text' => '{"score": 8}' }]
              },
              'logprobsResult' => mock_logprobs
            }
          ]
        }

        captured_payload = nil
        @provider.stub(:request, lambda { |payload, _params|
          captured_payload = payload
          mock_response
        }) do
          result = @provider.function_calling(EXAMPLE_MESSAGES, EXAMPLE_FUNCTION, logprobs: true, top_logprobs: 10)

          assert_equal true, captured_payload[:generationConfig][:responseLogprobs]
          assert_equal 10, captured_payload[:generationConfig][:logprobs]
          assert_equal({ 'score' => 8 }, result[:data])
          assert_equal mock_logprobs, result[:logprobs]
        end
      end

      def test_calculate_continuous_score_helpers
        logprobs_result = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '": ' }, { 'token' => '8' }],
          'topCandidates' => [
            { 'candidates' => [{ 'token' => 'score' }] },
            { 'candidates' => [{ 'token' => '": ' }] },
            {
              'candidates' => [
                { 'token' => '8', 'logProbability' => -0.22314 },
                { 'token' => '7', 'logProbability' => -1.60943 }
              ]
            }
          ]
        }

        candidates = @provider.extract_field_logprobs(logprobs_result, 'score')
        refute_nil candidates

        score_res = @provider.calculate_continuous_score(candidates, min_score: 1.0, max_score: 10.0)
        refute_nil score_res
        assert_in_delta 7.8, score_res.expected_value, 0.1
        assert_in_delta 0.7556, score_res.normalized_score, 0.02
      end
    end
  end
end
