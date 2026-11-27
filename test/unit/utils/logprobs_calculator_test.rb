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
        assert_in_delta(4.5, res.raw_expected_reward)
        # Normalized: (4.5 - 1.0) / 4.0 = 0.875
        assert_in_delta(0.875, res.normalized_score)
        assert_equal 3, res.count
      end

      def test_calculate_continuous_score_returns_nil_for_empty_candidates
        result = LogprobsCalculator.calculate_continuous_score([])

        assert_nil result
      end

      def test_calculate_continuous_score_returns_nil_for_nil_candidates
        assert_nil LogprobsCalculator.calculate_continuous_score(nil)
      end

      def test_calculate_continuous_score_drops_tokens_outside_the_scale_and_punctuation
        candidates = [
          { token: '":', logProbability: -0.1 },
          { token: '11', logProbability: -0.2 },
          { token: 'high', logProbability: -0.3 },
          { token: ' 7', logProbability: -0.5 }
        ]

        result = LogprobsCalculator.calculate_continuous_score(candidates)

        assert_equal [{ score: 7.0, probability: 1.0, token: ' 7' }], result.probabilities
        assert_in_delta 7.0, result.expected_value
        # The default numeric scale is 1..10.
        assert_in_delta 0.6667, result.normalized_score
        assert_equal '":', result.top_token
      end

      def test_calculate_continuous_score_returns_nil_when_no_token_is_a_score
        candidates = [{ token: 'yes', logProbability: -0.1 }, { token: '42', logProbability: -0.2 }]

        assert_nil LogprobsCalculator.calculate_continuous_score(candidates)
      end

      def test_calculate_continuous_score_returns_nil_when_every_probability_underflows
        candidates = [{ token: '5', logProbability: -10_000.0 }]

        assert_nil LogprobsCalculator.calculate_continuous_score(candidates)
      end

      def test_calculate_continuous_score_reads_string_keys_and_snake_case_log_probability
        candidates = [
          { 'token' => '4', 'logProbability' => Math.log(0.5) },
          { token: '2', log_probability: Math.log(0.5) }
        ]

        result = LogprobsCalculator.calculate_continuous_score(candidates, min_score: 1.0, max_score: 5.0)

        assert_in_delta 3.0, result.expected_value
        assert_in_delta 0.5, result.normalized_score
        assert_equal '4', result.top_token
      end

      def test_calculate_continuous_score_treats_a_missing_log_probability_as_certain
        result = LogprobsCalculator.calculate_continuous_score([{ token: '3' }, { token: '5' }], max_score: 5.0)

        assert_equal([0.5, 0.5], result.probabilities.map { |c| c[:probability] })
        assert_in_delta 0.75, result.normalized_score
      end

      def test_calculate_continuous_score_matches_token_map_keys_case_insensitively
        token_map = { 'A' => 5.0, 'B' => 4.0, 'C' => 3.0, 'D' => 2.0, 'E' => 1.0 }

        result = LogprobsCalculator.calculate_continuous_score([{ token: '"b', logProbability: 0.0 }], token_map:)

        assert_in_delta 4.0, result.expected_value
        assert_in_delta 0.75, result.normalized_score
      end

      def test_calculate_continuous_score_on_a_single_point_scale_scores_zero
        result = LogprobsCalculator.calculate_continuous_score([{ token: '3', logProbability: 0.0 }],
                                                               min_score: 3.0, max_score: 3.0)

        assert_in_delta 3.0, result.expected_value
        assert_in_delta 0.0, result.normalized_score
      end

      def test_aggregate_expected_rewards_ignores_missing_passes
        res = LogprobsCalculator.aggregate_expected_rewards([5.0, nil, 3.0], min_score: 1.0, max_score: 5.0)

        assert_in_delta 4.0, res.raw_expected_reward
        assert_in_delta 0.75, res.normalized_score
        assert_equal 2, res.count
      end

      def test_aggregate_expected_rewards_clamps_to_the_scale
        res = LogprobsCalculator.aggregate_expected_rewards([7.0], min_score: 1.0, max_score: 5.0)

        assert_in_delta 1.0, res.normalized_score
      end

      def test_aggregate_expected_rewards_on_a_single_point_scale_scores_zero
        res = LogprobsCalculator.aggregate_expected_rewards([2.0], min_score: 2.0, max_score: 2.0)

        assert_in_delta 0.0, res.normalized_score
      end

      def test_aggregate_expected_rewards_returns_nil_without_rewards
        assert_nil LogprobsCalculator.aggregate_expected_rewards(nil)
        assert_nil LogprobsCalculator.aggregate_expected_rewards([])
        assert_nil LogprobsCalculator.aggregate_expected_rewards([nil, nil])
      end

      def test_extract_field_candidates_finds_a_numeric_value_without_token_map
        logprobs_result = {
          chosenCandidates: [{ token: 'name' }, { token: '":"' }, { token: '9' }, { token: 'score' }, { token: '": ' },
                             { token: '7' }],
          topCandidates: Array.new(5) { { candidates: [] } } << { candidates: [{ token: '7', logProbability: -0.1 }] }
        }

        candidates = LogprobsCalculator.extract_field_candidates(logprobs_result, :score)

        assert_equal [{ token: '7', logProbability: -0.1 }], candidates
      end

      def test_extract_field_candidates_looks_at_most_three_tokens_past_the_field
        logprobs_result = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '"' }, { 'token' => ':' }, { 'token' => ' "' },
                                 { 'token' => '8' }],
          'topCandidates' => Array.new(5) { { 'candidates' => [] } }
        }

        assert_nil LogprobsCalculator.extract_field_candidates(logprobs_result, 'score')
      end

      def test_extract_field_candidates_with_token_map_ignores_numeric_values
        logprobs_result = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '": ' }, { 'token' => '5' }],
          'topCandidates' => Array.new(3) { { 'candidates' => [] } }
        }

        assert_nil LogprobsCalculator.extract_field_candidates(logprobs_result, 'score', token_map: { 'A' => 5.0 })
      end

      def test_extract_field_candidates_returns_nil_when_the_value_step_is_missing
        logprobs_result = {
          'chosenCandidates' => [{ 'token' => 'score' }, { 'token' => '5' }],
          'topCandidates' => [{ 'candidates' => [] }]
        }

        assert_nil LogprobsCalculator.extract_field_candidates(logprobs_result, 'score')
      end

      def test_extract_field_candidates_returns_nil_without_logprobs
        assert_nil LogprobsCalculator.extract_field_candidates(nil, 'score')
        assert_nil LogprobsCalculator.extract_field_candidates({ 'chosenCandidates' => [] }, 'score')
        assert_nil LogprobsCalculator.extract_field_candidates({ 'topCandidates' => [] }, 'score')
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
