# frozen_string_literal: true

require_relative 'concerns/loggable'
require_relative 'players_collection'
require_relative 'free_for_all'
require_relative 'elo_round'
require_relative 'ranking_scoring'

# This class orchestrates player ranking through multiple evaluation stages
# using Elo ranking and free-for-all match simulations.
# 1. Sets initial scores
# 2. Eliminates low performers
# 3. Runs Elo ranking (for large groups)
# 4. Conducts free-for-all matches
#
# @example Basic usage
#   Ranking.call(players, criteria)
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
  module Ranking
    class Ranking
      include ActiveGenie::Concerns::Loggable

      def self.call(...)
        new(...).call
      end

      def initialize(param_players, criteria, reviewers: [], config: {})
        @param_players = param_players
        @criteria = criteria
        @reviewers = Array(reviewers).compact.uniq
        @config = ActiveGenie.configuration.merge(config)
        @players = nil
      end

      def call
        @players = create_players

        ActiveGenie::Logger.with_context(log_context) do
          set_initial_player_scores!
          eliminate_obvious_bad_players!

          while @players.elo_eligible?
            elo_report = run_elo_round!
            eliminate_relegation_players!
            rebalance_players!(elo_report)
          end

          run_free_for_all!
        end

        sorted_players
      end

      ELIMINATION_VARIATION = 'variation_too_high'
      ELIMINATION_RELEGATION = 'relegation_tier'

      private

      def create_players
        players = PlayersCollection.new(@param_players)
        players.each { |p| ActiveGenie::Logger.call({ code: :new_player, player: p.to_h }) }

        players
      end

      def set_initial_player_scores!
        RankingScoring.call(@players, @criteria, reviewers: @reviewers, config: @config)
      end

      def eliminate_obvious_bad_players!
        while @players.coefficient_of_variation >= @config.ranking.score_variation_threshold
          @players.eligible.last.eliminated = ELIMINATION_VARIATION
        end
      end

      def run_elo_round!
        EloRound.call(@players, @criteria, config: @config)
      end

      def eliminate_relegation_players!
        @players.calc_relegation_tier.each { |player| player.eliminated = ELIMINATION_RELEGATION }
      end

      def rebalance_players!(elo_report)
        return if elo_report[:highest_elo_diff].negative?

        @players.eligible.each do |player|
          next if elo_report[:players_in_round].include?(player.id)

          player.elo += elo_report[:highest_elo_diff]
        end
      end

      def run_free_for_all!
        FreeForAll.call(@players, @criteria, config: @config)
      end

      def sorted_players
        players = @players.sorted
        ActiveGenie::Logger.call({ code: :ranking_final, players: players.map(&:to_h) })

        players.map(&:to_h)
      end

      def log_context
        { ranking_id: }
      end

      def ranking_id
        player_ids = @players.map(&:id).join(',')
        ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

        Digest::MD5.hexdigest(ranking_unique_key)
      end
    end
  end
end
