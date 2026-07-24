# frozen_string_literal: true

module ActiveGenie
  module Utils
    # Calculates expected values and continuous normalized scores from candidate token log probabilities,
    # supporting letter-based token mappings phi(v_g) and multi-pass C x K aggregation.
    class LogprobsCalculator
      # ContinuousScoreResult contains the computed expected score metrics.
      ContinuousScoreResult = Struct.new(
        :expected_value,
        :normalized_score,
        :probabilities,
        :top_token,
        keyword_init: true
      )

      # AggregatedRewardResult contains the aggregated expected reward across criteria and repetitions.
      AggregatedRewardResult = Struct.new(
        :raw_expected_reward,
        :normalized_score,
        :count,
        keyword_init: true
      )

      DEFAULT_LETTER_MAP = {
        'A' => 5.0,
        'B' => 4.0,
        'C' => 3.0,
        'D' => 2.0,
        'E' => 1.0
      }.freeze

      class << self
        # Calculates continuous expected value and normalized 0..1 score from log probability candidates.
        #
        # Intent: Converts discrete token probabilities (letters or numbers) into a continuous expected value.
        # @example Using letter tokens mapping:
        #   LogprobsCalculator.calculate_continuous_score(
        #     [{ token: "A", logProbability: -0.22 }, { token: "B", logProbability: -1.89 }],
        #     token_map: { 'A' => 5.0, 'B' => 4.0, 'C' => 3.0, 'D' => 2.0, 'E' => 1.0 }
        #   )
        #
        # @param candidates [Array<Hash>] List of token candidates with log probabilities.
        # @param min_score [Numeric, nil] Minimum score of the scale (derived from token_map if nil).
        # @param max_score [Numeric, nil] Maximum score of the scale (derived from token_map if nil).
        # @param token_map [Hash, nil] Optional token-to-scalar mapping phi(v_g).
        # @return [ContinuousScoreResult, nil] Continuous score metrics or nil if no valid score tokens exist.
        def calculate_continuous_score(candidates, min_score: nil, max_score: nil, token_map: nil)
          return nil if candidates.nil? || candidates.empty?

          parsed_candidates = parse_candidates(candidates, token_map, min_score, max_score)
          return nil if parsed_candidates.empty?

          total_raw_probability = parsed_candidates.sum { |c| c[:raw_probability] }
          return nil if total_raw_probability.zero?

          normalized_candidates = build_normalized_probabilities(parsed_candidates, total_raw_probability)
          expected_value = normalized_candidates.sum { |c| c[:score] * c[:probability] }

          min_val = min_score || (token_map ? token_map.values.map(&:to_f).min : 1.0)
          max_val = max_score || (token_map ? token_map.values.map(&:to_f).max : 10.0)

          score_range = max_val - min_val
          normalized_score = score_range.zero? ? 0.0 : (expected_value - min_val) / score_range.to_f
          normalized_score = normalized_score.clamp(0.0, 1.0)

          top_token = candidates.first[:token] || candidates.first['token']

          ContinuousScoreResult.new(
            expected_value: expected_value.round(4),
            normalized_score: normalized_score.round(4),
            probabilities: normalized_candidates,
            top_token:
          )
        end

        # Aggregates raw expected rewards across multiple evaluation criteria (C) and repetitions (K).
        #
        # Intent: Computes the average raw continuous expected reward R(x, tau) = (1 / (C * K)) * sum(E_{c,k}),
        # and linearly normalizes R(x, tau) into [0, 1].
        # @example
        #   LogprobsCalculator.aggregate_expected_rewards([4.2, 4.5, 4.1], min_score: 1.0, max_score: 5.0)
        #
        # @param expected_rewards [Array<Numeric>] List of expected rewards E_{c,k} from each pass.
        # @param min_score [Numeric] Minimum score bound of the evaluation scale.
        # @param max_score [Numeric] Maximum score bound of the evaluation scale.
        # @return [AggregatedRewardResult, nil] Aggregated raw reward and normalized continuous score.
        def aggregate_expected_rewards(expected_rewards, min_score: 1.0, max_score: 5.0)
          return nil if expected_rewards.nil? || expected_rewards.empty?

          valid_rewards = expected_rewards.compact
          return nil if valid_rewards.empty?

          raw_expected_reward = (valid_rewards.sum.to_f / valid_rewards.size).round(4)
          score_range = max_score - min_score
          normalized_score = score_range.zero? ? 0.0 : (raw_expected_reward - min_score) / score_range.to_f
          normalized_score = normalized_score.clamp(0.0, 1.0).round(4)

          AggregatedRewardResult.new(
            raw_expected_reward:,
            normalized_score:,
            count: valid_rewards.size
          )
        end

        # Extracts candidate log probabilities for a target field from Gemini logprobsResult structure.
        #
        # Intent: Scans token sequence in logprobsResult to locate the candidate step for field_name.
        # @param logprobs_result [Hash] The logprobsResult object returned by Gemini API.
        # @param field_name [String, Symbol] Name of the target field to find logprobs for.
        # @param token_map [Hash, nil] Optional token-to-scalar mapping to match non-numeric tokens.
        # @return [Array<Hash>, nil] Candidate tokens at the target field position or nil if not found.
        def extract_field_candidates(logprobs_result, field_name, token_map: nil)
          return nil if logprobs_result.nil?

          top_candidates_steps = logprobs_result['topCandidates'] || logprobs_result[:topCandidates]
          chosen_candidates = logprobs_result['chosenCandidates'] || logprobs_result[:chosenCandidates]
          return nil if top_candidates_steps.nil? || chosen_candidates.nil?

          field_key = field_name.to_s
          field_token_index = find_field_value_token_index(chosen_candidates, field_key, token_map)
          return nil if field_token_index.nil? || field_token_index >= top_candidates_steps.size

          step_data = top_candidates_steps[field_token_index]
          step_data['candidates'] || step_data[:candidates]
        end

        private

        def parse_candidates(candidates, token_map, min_score, max_score)
          candidates.filter_map do |candidate|
            token = (candidate[:token] || candidate['token']).to_s
            cleaned_token = token.tr('",:{}[] ', '')
            next if cleaned_token.empty?

            score_val = resolve_token_score(cleaned_token, token_map)
            next if score_val.nil?

            min_val = min_score || (token_map ? token_map.values.map(&:to_f).min : 1.0)
            max_val = max_score || (token_map ? token_map.values.map(&:to_f).max : 10.0)
            next if score_val < min_val || score_val > max_val

            log_prob = candidate[:logProbability] || candidate['logProbability'] || candidate[:log_probability] || 0.0
            raw_prob = Math.exp(log_prob)

            { score: score_val, raw_probability: raw_prob, token: }
          end
        end

        def resolve_token_score(cleaned_token, token_map)
          if token_map
            key = token_map.keys.find { |k| k.to_s.casecmp(cleaned_token).zero? }
            return token_map[key].to_f if key
          end

          numeric?(cleaned_token) ? cleaned_token.to_f : nil
        end

        def build_normalized_probabilities(parsed_candidates, total_raw_probability)
          parsed_candidates.map do |c|
            {
              score: c[:score],
              probability: (c[:raw_probability] / total_raw_probability).round(6),
              token: c[:token]
            }
          end
        end

        def find_field_value_token_index(chosen_candidates, field_key, token_map)
          tokens = chosen_candidates.map { |c| (c[:token] || c['token']).to_s }

          tokens.each_with_index do |token, idx|
            next unless token.include?(field_key)

            # Look ahead for the value token after ':'
            (idx + 1...[idx + 4, tokens.size].min).each do |value_idx|
              val_token = tokens[value_idx].tr('",:{}[] ', '')
              valid_value = if token_map
                              token_map.keys.any? { |k| k.to_s.casecmp(val_token).zero? }
                            else
                              numeric?(val_token)
                            end
              return value_idx if valid_value
            end
          end

          nil
        end

        def numeric?(str)
          Float(str, exception: false) != nil
        end
      end
    end
  end
end
