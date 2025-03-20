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
      @elo_rounds_played = 0
      @elo_round_battle_count = 0
      @free_for_all_battle_count = 0
      @total_tokens = 0
      @start_time = Time.now
    end

    def call
      @players = PlayersCollection.new(@param_players)

      ActiveGenie::Logger.with_context(log_context, observer: method(:log_observer)) do
        starting_log

        set_initial_player_scores!
        eliminate_obvious_bad_players!

        while @players.elo_eligible?
          run_elo_round!
          eliminate_relegation_players!
        end
  
        run_free_for_all!
      end

      ActiveGenie::Logger.info({ step: :ranking_report, **report })

      @players.sorted
    end

    private

    SCORE_VARIATION_THRESHOLD = 10
    ELIMINATION_VARIATION = 'variation_too_high'
    ELIMINATION_RELEGATION = 'relegation_tier'

    def starting_log
      @players.each { |p| ActiveGenie::Logger.debug({ step: :new_player, player: p.to_h }) }
    end

    def set_initial_player_scores!
      RankingScoring.call(@players, @criteria, reviewers: @reviewers, config: @config)
    end

    def eliminate_obvious_bad_players!
      while @players.coefficient_of_variation >= SCORE_VARIATION_THRESHOLD
        @players.eligible.last.eliminated = ELIMINATION_VARIATION
      end
    end

    def run_elo_round!
      @elo_rounds_played += 1

      elo_report = EloRound.call(@players, @criteria, config: @config)

      @elo_round_battle_count += elo_report[:battles_count]
    end

    def eliminate_relegation_players!
      @players.calc_relegation_tier.each { |player| player.eliminated = ELIMINATION_RELEGATION }
    end

    def run_free_for_all!
      ffa_report = FreeForAll.call(@players, @criteria, config: @config)

      @free_for_all_battle_count += ffa_report[:battles_count]
    end

    def report
      {
        ranking_id: ranking_id,
        players_count: @players.size,
        variation_too_high: @players.select { |player| player.eliminated == ELIMINATION_VARIATION }.size,
        elo_rounds_played: @elo_rounds_played,
        elo_round_battle_count: @elo_round_battle_count,
        relegation_tier: @players.select { |player| player.eliminated == ELIMINATION_RELEGATION }.size,
        ffa_round_battle_count: @free_for_all_battle_count,
        top3: @players.eligible[0..2].map(&:id),
        total_tokens: @total_tokens,
        duration_seconds: Time.now - @start_time,
      }
    end

    def log_context
      { config: @config[:log], ranking_id: }
    end

    def log_observer(log)
      @total_tokens += log[:total_tokens] if log[:step] == :llm_stats
    end

    def ranking_id
      player_ids = @players.map(&:id).join(',')
      ranking_unique_key = [player_ids, @criteria, @config.to_json].join('-')

      Digest::MD5.hexdigest(ranking_unique_key)
    end
  end
end
