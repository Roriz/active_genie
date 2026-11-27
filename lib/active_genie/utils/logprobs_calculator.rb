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
      # `count` shadows Struct#count on purpose: it is part of the public result.
      # rubocop:disable Lint/StructNewOverride
      AggregatedRewardResult = Struct.new(
        :raw_expected_reward,
        :normalized_score,
        :count,
        keyword_init: true
      )
      # rubocop:enable Lint/StructNewOverride

      DEFAULT_LETTER_MAP = {
        'A' => 5.0,
        'B' => 4.0,
        'C' => 3.0,
        'D' => 2.0,
        'E' => 1.0
      }.freeze

      # Token characters that belong to the JSON around a value, not to the value.
      JSON_PUNCTUATION = '",:{}[] '

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

          min_val, max_val = score_bounds(token_map, min_score, max_score)
          probabilities = normalized_probabilities(parse_candidates(candidates, token_map, min_val, max_val))
          return nil if probabilities.nil?

          expected_value = weighted_mean(probabilities)
          ContinuousScoreResult.new(
            expected_value: expected_value.round(4),
            normalized_score: normalize(expected_value, min_val, max_val).round(4),
            probabilities:,
            top_token: field(candidates.first, :token)
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
          valid_rewards = Array(expected_rewards).compact
          return nil if valid_rewards.empty?

          raw_expected_reward = (valid_rewards.sum.to_f / valid_rewards.size).round(4)
          AggregatedRewardResult.new(
            raw_expected_reward:,
            normalized_score: normalize(raw_expected_reward, min_score, max_score).round(4),
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

          top_candidates_steps = field(logprobs_result, :topCandidates)
          chosen_candidates = field(logprobs_result, :chosenCandidates)
          return nil if top_candidates_steps.nil? || chosen_candidates.nil?

          field_token_index = find_field_value_token_index(chosen_candidates, field_name.to_s, token_map)
          step_data = field_token_index && top_candidates_steps[field_token_index]
          field(step_data, :candidates) if step_data
        end

        private

        # Logprobs arrive with symbol or string keys depending on who built them.
        def field(hash, key)
          hash[key] || hash[key.to_s]
        end

        # Without explicit bounds the scale spans the token map's values, or 1..10 for numeric tokens.
        def score_bounds(token_map, min_score, max_score)
          values = token_map ? token_map.values.map(&:to_f) : [1.0, 10.0]
          [min_score || values.min, max_score || values.max]
        end

        # Linear position of value inside min..max, clamped to 0..1 (0.0 on a single-point scale).
        def normalize(value, min_score, max_score)
          score_range = max_score - min_score
          return 0.0 if score_range.zero?

          ((value - min_score) / score_range.to_f).clamp(0.0, 1.0)
        end

        def parse_candidates(candidates, token_map, min_val, max_val)
          candidates.filter_map do |candidate|
            token = field(candidate, :token).to_s
            score_val = resolve_token_score(token.tr(JSON_PUNCTUATION, ''), token_map)
            next unless score_val&.between?(min_val, max_val)

            { score: score_val, raw_probability: Math.exp(log_probability(candidate)), token: }
          end
        end

        def log_probability(candidate)
          field(candidate, :logProbability) || candidate[:log_probability] || 0.0
        end

        def resolve_token_score(cleaned_token, token_map)
          return nil if cleaned_token.empty?

          key = token_map&.keys&.find { |k| k.to_s.casecmp(cleaned_token).zero? }
          return token_map[key].to_f if key

          numeric?(cleaned_token) ? cleaned_token.to_f : nil
        end

        # Rescales raw probabilities to sum to 1; nil when there is nothing to rescale.
        def normalized_probabilities(parsed_candidates)
          total_raw_probability = parsed_candidates.sum { |c| c[:raw_probability] }
          return nil if total_raw_probability.zero?

          parsed_candidates.map do |c|
            {
              score: c[:score],
              probability: (c[:raw_probability] / total_raw_probability).round(6),
              token: c[:token]
            }
          end
        end

        def weighted_mean(probabilities)
          probabilities.sum { |c| c[:score] * c[:probability] }
        end

        def find_field_value_token_index(chosen_candidates, field_key, token_map)
          tokens = chosen_candidates.map { |c| field(c, :token).to_s }

          tokens.each_index do |idx|
            next unless tokens[idx].include?(field_key)

            value_idx = value_token_index_after(tokens, idx, token_map)
            return value_idx if value_idx
          end

          nil
        end

        # The value sits within the three tokens after the field name (past the `": ` separator).
        def value_token_index_after(tokens, field_idx, token_map)
          ((field_idx + 1)...[field_idx + 4, tokens.size].min).find do |value_idx|
            value_token?(tokens[value_idx].tr(JSON_PUNCTUATION, ''), token_map)
          end
        end

        def value_token?(val_token, token_map)
          return numeric?(val_token) unless token_map

          token_map.keys.any? { |k| k.to_s.casecmp(val_token).zero? }
        end

        def numeric?(str)
          Float(str, exception: false) != nil
        end
      end
    end
  end
end
