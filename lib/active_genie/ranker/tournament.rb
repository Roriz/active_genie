# frozen_string_literal: true

require_relative '../entities/players'
require_relative 'free_for_all'
require_relative 'elo'
require_relative 'scoring'

# This class orchestrates player ranking through multiple evaluation stages
# using Elo ranking and free-for-all match simulations.
# 1. Sets initial scores
# 2. Eliminates low performers
# 3. Runs Elo ranking (for large groups)
# 4. Conducts free-for-all matches
#
# @example Basic usage
#   Ranker.tournament(players, criteria)
#
# @param param_players [Array<Hash|String>] Collection of player objects to evaluate
#   Example: ["Circle", "Triangle", "Square"]
#            or
#   [
#     { content: "Circle", score: 10 },
#     { content: "Triangle", score: 7 },
#     { content: "Square", score: 5 }
#   ]
# @param criteria [String] Evaluation criteria configuration
#   Example: "What is more similar to the letter 'O'?"
# @param config [Hash] Additional configuration config
#   Example: { model: "gpt-4o", api_key: ENV['OPENAI_API_KEY'] }
# @return [Hash] Final ranked player results
module ActiveGenie
  module Ranker
    class Tournament < ActiveGenie::BaseModule
      def initialize(players, criteria, juries: [], config: {})
        @players = Entities::Players.new(players)
        @criteria = criteria
        @juries = Array(juries).compact.uniq
        super(config:)
      end

      def call
        set_initial_player_scores!
        eliminate_obvious_bad_players!

        while @players.elo_eligible?
          elo_report = run_elo_round!
          eliminate_lower_tier_players!
          rebalance_players!(elo_report)
        end

        run_free_for_all!

        ActiveGenie::Response.new(
          data: sorted_players.map(&:content),
          raw: @players.map(&:to_h)
        )
      end

      ELIMINATION_VARIATION = 'variation_too_high'
      ELIMINATION_RELEGATION = 'relegation_tier'

      private

      def set_initial_player_scores!
        Scoring.call(@players, @criteria, juries: @juries, config:)
      end

      def eliminate_obvious_bad_players!
        while @players.coefficient_of_variation >= @config.ranker.score_variation_threshold
          @players.eligible.last.eliminated = ELIMINATION_VARIATION
        end
      end

      def run_elo_round!
        Elo.call(@players, @criteria, config:)
      end

      def eliminate_lower_tier_players!
        @players.calc_lower_tier.each { |player| player.eliminated = ELIMINATION_RELEGATION }
      end

      def rebalance_players!(elo_report)
        return if elo_report[:highest_elo_diff].negative?

        @players.eligible.each do |player|
          next if elo_report[:players_in_round].include?(player.id)

          player.elo += elo_report[:highest_elo_diff]
        end
      end

      def run_free_for_all!
        FreeForAll.call(@players, @criteria, config:)
      end

      def sorted_players
        players = @players.sorted
        ActiveGenie.logger.call({ ranker_id:, code: :ranker_final, players: players.map(&:to_h) }, config:)

        players
      end

      def ranker_id
        @ranker_id ||= begin
          player_ids = @players.map(&:id).join(',')
          ranker_unique_key = [player_ids, @criteria].join('-')

          Digest::MD5.hexdigest(ranker_unique_key)
        end
      end

      def module_config
        { log: { additional_context: { ranker_id: } } }
      end
    end
  end
end
