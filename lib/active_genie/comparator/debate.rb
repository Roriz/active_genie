# frozen_string_literal: true

require_relative '../providers/unified_provider'
require_relative '../utils/logprobs_calculator'

module ActiveGenie
  module Comparator
    # The Debate class provides a foundation for evaluating comparators between two players
    # using AI-powered evaluation. It determines a winner based on specified criteria,
    # analyzing how well each player meets the requirements and utilizing logprobs expected scores.
    #
    # @example Debate usage with two players and criteria
    #   Debate.call("Player A content", "Player B content", "Evaluate keyword usage and pattern matching")
    #
    class Debate < ActiveGenie::BaseModule
      # @param player_a [String] The content or submission from the first player
      # @param player_b [String] The content or submission from the second player
      # @param criteria [String] The evaluation criteria or rules to assess against
      # @param config [Hash] Additional configuration options that modify the comparator evaluation behavior
      # @return [ActiveGenie::Result] The evaluation result containing winner and reasoning
      def initialize(player_a, player_b, criteria, config: {})
        @player_a = player_a
        @player_b = player_b
        @criteria = criteria
        super(config:)
      end

      # @return [ActiveGenie::Result] The evaluation result containing the winner and reasoning
      def call
        messages = [
          { role: 'system', content: PROMPT },
          { role: 'user', content: "player_a: #{@player_a}" },
          { role: 'user', content: "player_b: #{@player_b}" },
          { role: 'user', content: "criteria: #{@criteria}" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages, FUNCTION, config:, logprobs: true
        )

        response_formatted(provider_response)
      end

      PROMPT = File.read(File.join(__dir__, 'debate.prompt.md'))
      FUNCTION = JSON.parse(File.read(File.join(__dir__, 'debate.json')), symbolize_names: true)

      private

      def response_formatted(provider_response)
        data = extract_data(provider_response)
        logprobs_result = extract_logprobs(provider_response)

        winner_key, logprob_metadata = determine_winner(data, logprobs_result)

        winner = case winner_key
                 when 'player_a' then @player_a
                 when 'player_b' then @player_b
                 end

        reasoning = data&.dig('impartial_judge_winner_reasoning')
        combined_metadata = (data || {}).merge(logprob_metadata)

        ActiveGenie::Result.new(data: winner, reasoning:, metadata: combined_metadata)
      end

      def extract_data(provider_response)
        if provider_response.is_a?(Hash) && provider_response.key?(:data)
          provider_response[:data]
        else
          provider_response
        end
      end

      def extract_logprobs(provider_response)
        provider_response.is_a?(Hash) ? provider_response[:logprobs] : nil
      end

      def determine_winner(data, logprobs_result)
        return [data&.dig('impartial_judge_winner'), {}] if logprobs_result.nil?

        player_a_reward = compute_player_reward(logprobs_result, 'player_a')
        player_b_reward = compute_player_reward(logprobs_result, 'player_b')
        judge_candidates = ActiveGenie::Utils::LogprobsCalculator.extract_field_candidates(
          logprobs_result, 'impartial_judge_winner'
        )

        winner_key = decide_winner_key(player_a_reward, player_b_reward, judge_candidates, data)
        logprob_metadata = build_logprob_metadata(player_a_reward, player_b_reward, judge_candidates, winner_key)

        [winner_key, logprob_metadata]
      end

      def compute_player_reward(logprobs_result, player_key)
        fields = ["#{player_key}_adherence_score", "#{player_key}_quality_score", "#{player_key}_risk_avoidance_score"]
        expected_values = fields.filter_map do |field|
          cands = ActiveGenie::Utils::LogprobsCalculator.extract_field_candidates(logprobs_result, field)
          res = ActiveGenie::Utils::LogprobsCalculator.calculate_continuous_score(cands, min_score: 1.0, max_score: 5.0)
          res&.expected_value
        end

        ActiveGenie::Utils::LogprobsCalculator.aggregate_expected_rewards(expected_values, min_score: 1.0, max_score: 5.0)
      end

      def decide_winner_key(player_a_reward, player_b_reward, judge_candidates, data)
        if player_a_reward && player_b_reward && player_a_reward.raw_expected_reward != player_b_reward.raw_expected_reward
          return player_a_reward.raw_expected_reward > player_b_reward.raw_expected_reward ? 'player_a' : 'player_b'
        end

        if judge_candidates && !judge_candidates.empty?
          prob_a = extract_token_probability(judge_candidates, 'player_a')
          prob_b = extract_token_probability(judge_candidates, 'player_b')
          return prob_a >= prob_b ? 'player_a' : 'player_b' if prob_a > 0 || prob_b > 0
        end

        data&.dig('impartial_judge_winner')
      end

      def extract_token_probability(candidates, target_token)
        found = candidates.find { |c| (c['token'] || c[:token]).to_s.include?(target_token) }
        return 0.0 unless found

        log_prob = found['logProbability'] || found[:logProbability] || 0.0
        Math.exp(log_prob)
      end

      def build_logprob_metadata(player_a_reward, player_b_reward, judge_candidates, winner_key)
        meta = { 'logprobs_used' => true, 'logprobs_winner' => winner_key }
        meta['player_a_expected_reward'] = player_a_reward.raw_expected_reward if player_a_reward
        meta['player_b_expected_reward'] = player_b_reward.raw_expected_reward if player_b_reward
        meta['player_a_normalized_score'] = player_a_reward.normalized_score if player_a_reward
        meta['player_b_normalized_score'] = player_b_reward.normalized_score if player_b_reward

        if judge_candidates && !judge_candidates.empty?
          meta['player_a_winner_probability'] = extract_token_probability(judge_candidates, 'player_a').round(4)
          meta['player_b_winner_probability'] = extract_token_probability(judge_candidates, 'player_b').round(4)
        end

        meta
      end

      def module_config
        { llm: { recommended_model: 'claude-haiku-4-5' } }
      end
    end
  end
end
