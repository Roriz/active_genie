# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../lib/active_genie/utils/logprobs_calculator'

module ActiveGenie
  module Utils
    class LogprobsCalculatorTest < Minitest::Test
      def test_calculate_continuous_score_with_valid_numeric_candidates
        candidates = [
          { token: '8', logProbability: -0.22314 },
          { token: '7', logProbability: -1.60943 }
        ]

        result = LogprobsCalculator.calculate_continuous_score(candidates, min_score: 1.0, max_score: 10.0)

        refute_nil result
        assert_in_delta 7.8, result.expected_value, 0.1
        assert_in_delta 0.7556, result.normalized_score, 0.02
        assert_equal '8', result.top_token
        assert_equal 2, result.probabilities.size
      end

      def test_calculate_continuous_score_with_letter_tokens_mapping
        token_map = { 'A' => 5.0, 'B' => 4.0, 'C' => 3.0, 'D' => 2.0, 'E' => 1.0 }
        candidates = [
          { token: 'A', logProbability: -0.22314 }, # prob ~ 0.8
          { token: 'B', logProbability: -1.60943 }  # prob ~ 0.2
        ]

        result = LogprobsCalculator.calculate_continuous_score(candidates, token_map:)

        refute_nil result
        # Expected value: 5.0*0.8 + 4.0*0.2 = 4.8
        assert_in_delta 4.8, result.expected_value, 0.1
        # Normalized score: (4.8 - 1.0) / 4.0 = 0.95
        assert_in_delta 0.95, result.normalized_score, 0.02
        assert_equal 'A', result.top_token
      end

      def test_aggregate_expected_rewards_across_criteria_and_repetitions
        # 3 criteria passes: [4.8, 4.2, 4.5]
        expected_rewards = [4.8, 4.2, 4.5]
        res = LogprobsCalculator.aggregate_expected_rewards(expected_rewards, min_score: 1.0, max_score: 5.0)

        refute_nil res
        # Average: (4.8 + 4.2 + 4.5) / 3 = 4.5
        assert_equal 4.5, res.raw_expected_reward
        # Normalized: (4.5 - 1.0) / 4.0 = 0.875
        assert_equal 0.875, res.normalized_score
        assert_equal 3, res.count
      end

      def test_calculate_continuous_score_returns_nil_for_empty_candidates
        result = LogprobsCalculator.calculate_continuous_score([])
        assert_nil result
      end

      def test_extract_field_candidates_locates_target_field
        logprobs_result = {
          'chosenCandidates' => [
            { 'token' => '{\n  "' },
            { 'token' => 'score' },
            { 'token' => '": "' },
            { 'token' => 'A' }
          ],
          'topCandidates' => [
            { 'candidates' => [{ 'token' => '{\n  "' }] },
            { 'candidates' => [{ 'token' => 'score' }] },
            { 'candidates' => [{ 'token' => '": "' }] },
            {
              'candidates' => [
                { 'token' => 'A', 'logProbability' => -0.2 },
                { 'token' => 'B', 'logProbability' => -1.8 }
              ]
            }
          ]
        }

        token_map = { 'A' => 5.0, 'B' => 4.0, 'C' => 3.0, 'D' => 2.0, 'E' => 1.0 }
        candidates = LogprobsCalculator.extract_field_candidates(logprobs_result, 'score', token_map:)

        refute_nil candidates
        assert_equal 2, candidates.size
        assert_equal 'A', candidates.first['token']
      end
    end
  end
end
