require_relative './players_collection'
require_relative './free_for_all'
require_relative './elo_round'
require_relative './ranking_scoring'

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
module ActiveGenie::Ranking
  class Ranking
    def self.call(...)
      new(...).call
    end

    def initialize(param_players, criteria, reviewers: [], config: {})
      @param_players = param_players
      @criteria = criteria
      @reviewers = Array(reviewers).compact.uniq
      @config = ActiveGenie::Configuration.to_h(config)
      @players = nil
    end

    def call
      @players = PlayersCollection.new(@param_players)

      ActiveGenie::Logger.with_context(log_context) do
        set_initial_player_scores!
        eliminate_obvious_bad_players!

        while @players.elo_eligible?
          run_elo_round!
          eliminate_relegation_players!
        end
  
        run_free_for_all!
      end

      @players.sorted
    end

    private

    SCORE_VARIATION_THRESHOLD = 10

    def set_initial_player_scores!
      RankingScoring.call(@players, @criteria, reviewers: @reviewers, config: @config)
    end

    def eliminate_obvious_bad_players!
      while @players.coefficient_of_variation >= SCORE_VARIATION_THRESHOLD
        @players.eligible.last.eliminated = 'variation_too_high'
      end
    end

    def run_elo_round!
      EloRound.call(@players, @criteria, config: @config)
    end

    def eliminate_relegation_players!
      @players.calc_relegation_tier.each { |player| player.eliminated = 'relegation_tier' }
    end

    def run_free_for_all!
      FreeForAll.call(@players, @criteria, config: @config)
    end

    def log_context
      { config: @config[:log], ranking_id: }
    end

    def ranking_id
      player_ids = @players.map(&:id).join(',')
      ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

      Digest::MD5.hexdigest(ranking_unique_key)
    end
  end
end
