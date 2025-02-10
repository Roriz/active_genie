require 'securerandom'

require_relative './players_collection'
require_relative './free_for_all'
require_relative './elo_ranking'
require_relative '../scoring/recommended_reviews'

# This class orchestrates player ranking through multiple evaluation stages
# using Elo ranking and free-for-all match simulations.
# 1. Sets initial scores
# 2. Eliminates low performers
# 3. Runs Elo ranking (for large groups)
# 4. Conducts free-for-all matches
#
# @example Basic usage
#   League.call(players, criteria)
#
# @param param_players [Array] Collection of player objects to evaluate
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
module ActiveGenie::League
  class League
    def self.call(param_players, criteria, config: {})
      new(param_players, criteria, config:).call
    end

    def initialize(param_players, criteria, config: {})
      @param_players = param_players
      @criteria = criteria
      @config = config
      @league_id = SecureRandom.uuid
      @start_time = Time.now
    end

    def call
      set_initial_score_players
      eliminate_obvious_bad_players
      run_elo_ranking if players.eligible_size > 10
      run_free_for_all

      ActiveGenie::Logger.info({ **log, step: :league_end, top5: players.first(5).map(&:id) })
      players.to_h
    end

    private

    SCORE_VARIATION_THRESHOLD = 10

    def set_initial_score_players
      players_without_score = players.reject { |player| player.score }
      players_without_score.each do |player|
        player.score = generate_score(player.content) # This can take a while, can be parallelized
        ActiveGenie::Logger.trace({ **log, step: :player_score, player_id: player.id, score: player.score })
      end

      ActiveGenie::Logger.info({ **log, step: :initial_score, evaluated_players: players_without_score.size })
    end

    def generate_score(content)
      ActiveGenie::Scoring::Basic.call(content, @criteria, reviewers, config:)['final_score']
    end

    def eliminate_obvious_bad_players
      eliminated_count = 0
      while players.coefficient_of_variation >= SCORE_VARIATION_THRESHOLD
        players.eligible.last.eliminated = 'variation_too_high'
        eliminated_count += 1
      end

      ActiveGenie::Logger.info({ **log, step: :eliminate_obvious_bad_players, eliminated_count: })
    end

    def run_elo_ranking
      EloRanking.call(players, @criteria, config:)
    end

    def run_free_for_all
      FreeForAll.call(players, @criteria, config:)
    end

    def reviewers
      [recommended_reviews['reviewer1'], recommended_reviews['reviewer2'], recommended_reviews['reviewer3']]
    end

    def recommended_reviews
      @recommended_reviews ||= ActiveGenie::Scoring::RecommendedReviews.call(
        [players.sample.content, players.sample.content].join("\n\n"),
        @criteria,
        config:
      )
    end

    def players
      @players ||= PlayersCollection.new(@param_players)
    end

    def config
      { log:, **@config }
    end

    def log
      {
        **(@config.dig(:log) || {}),
        league_id: @league_id,
        league_start_time: @start_time,
        duration: Time.now - @start_time
      }
    end
  end
end
